#include <string.h>
#include "utils.h"

static int count_commit_ancestors(git_commit *x, int max, int64_t time_min){
  git_commit *y = NULL;
  for(int i = 1; i < max; i++){
    int64_t time = git_commit_time(x);
    if(time < time_min)
      i--; //do not count this commit, continue searching because history may be non linear
    int res = git_commit_parent(&y, x, 0);
    if(i > 1)
      git_commit_free(x);
    if(res == GIT_ENOTFOUND)
      return i;
    bail_if(res, "git_commit_parent");
    x = y;
  } //reached max
  git_commit_free(y);
  return max;
}

static SEXP make_author(const git_signature *p){
  char buf[2000] = "";
  if(p->name && p->email){
    snprintf(buf, 1999, "%s <%s>", p->name, p->email);
  } else if(p->name){
    snprintf(buf, 1999, "%s", p->name);
  } else if(p->email){
    snprintf(buf, 1999, "%s", p->email);
  }
  return safe_char(buf);
}

static git_diff *commit_to_diff(git_repository *repo, git_commit *commit){
  git_diff *diff = NULL;
  git_tree *old_tree = NULL;
  git_tree *new_tree = NULL;
  git_commit *parent = NULL;
  bail_if(git_commit_tree(&new_tree, commit), "git_commit_tree");
  if(git_commit_parentcount(commit) > 0){
    /* Parent may not be available in case of shallow clone */
    if(git_commit_parent(&parent, commit, 0)){
      git_tree_free(new_tree);
      return NULL;
    }
    bail_if(git_commit_tree(&old_tree, parent), "git_commit_tree");
    git_commit_free(parent);
  }
  git_diff_options opt = GIT_DIFF_OPTIONS_INIT;
  bail_if(git_diff_tree_to_tree(&diff, repo, old_tree, new_tree, &opt), "git_diff_tree_to_tree");
  git_tree_free(old_tree);
  git_tree_free(new_tree);
  return diff;
}

static int count_commit_changes(git_repository *repo, git_commit *commit){
  git_diff *diff = commit_to_diff(repo, commit);
  if(diff == NULL)
    return NA_INTEGER;
  int count = git_diff_num_deltas(diff);
  git_diff_free(diff);
  return count;
}

static SEXP signature_data(git_signature *sig){
  SEXP name = PROTECT(safe_string(sig->name));
  SEXP email = PROTECT(safe_string(sig->email));
  SEXP time = PROTECT(Rf_ScalarReal(sig->when.time));
  SEXP offset = PROTECT(Rf_ScalarInteger(sig->when.offset));
  Rf_setAttrib(time, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  Rf_setAttrib(time, PROTECT(Rf_install("tz")), PROTECT(safe_string("UTC")));
  UNPROTECT(2);
  SEXP out = build_list(4, "name", name, "email", email, "time", time, "offset", offset);
  UNPROTECT(4);
  return out;
}

SEXP R_git_signature_default(SEXP ptr){
  git_signature *sig;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_signature_default(&sig, repo), "git_signature_default");
  return signature_data(sig);
}

SEXP R_git_signature_create(SEXP name, SEXP email, SEXP time, SEXP offset){
  const char *cname = CHAR(STRING_ELT(name, 0));
  const char *cmail = CHAR(STRING_ELT(email, 0));
  git_signature *sig;
  if(!Rf_length(time)){
    bail_if(git_signature_now(&sig, cname, cmail), "git_signature_now");
  } else {
    double ctime = Rf_asReal(time);
    int coff = Rf_asInteger(offset);
    bail_if(git_signature_new(&sig, cname, cmail, ctime, coff), "git_signature_new");
  }
  return signature_data(sig);
}

static git_signature *parse_signature(SEXP x){
  const char *str = CHAR(STRING_ELT(x, 0));
  git_signature *sig = NULL;
  bail_if(git_signature_from_buffer(&sig, str), "git_signature_from_buffer");
  if(sig->when.time > 0){
    return sig;
  }
  git_signature *now = NULL;
  bail_if(git_signature_now(&now, sig->name, sig->email), "git_signature_now");
  git_signature_free(sig);
  return now;
}

SEXP R_git_signature_parse(SEXP x){
  return signature_data(parse_signature(x));
}

static void free_commit_list(const git_commit **list, int len){
  for(int i = 0; i < len; i++){
    git_commit_free((git_commit*) list[i]);
  }
}

static int create_commit_list(const git_commit **list, git_repository *repo, SEXP merge_parents){
  git_commit *commit = NULL;
  git_reference *head = NULL;
  int err = git_repository_head(&head, repo);
  if (err == GIT_EUNBORNBRANCH || err == GIT_ENOTFOUND)
    return 0;
  bail_if(err, "git_repository_head");
  bail_if(git_commit_lookup(&commit, repo, git_reference_target(head)), "git_commit_lookup");
  git_reference_free(head);
  list[0] = commit;
  for(int i = 0; i < Rf_length(merge_parents); i++){
    git_oid oid = {{0}};
    git_commit *parent = NULL;
    bail_if(git_oid_fromstr(&oid, CHAR(STRING_ELT(merge_parents, i))), "git_oid_fromstr");
    bail_if(git_commit_lookup(&parent, repo, &oid), "git_commit_lookup");
    list[i+1] = parent;
  }
  return Rf_length(merge_parents) + 1;
}

SEXP R_git_commit_create(SEXP ptr, SEXP message, SEXP author, SEXP committer,
                         SEXP merge_parents){
  git_buf msg = {0};
  git_oid tree_id = {{0}};
  git_oid commit_id = {{0}};
  git_tree *tree = NULL;
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  git_signature *authsig = parse_signature(author);
  git_signature *commitsig = parse_signature(committer);
  bail_if(git_message_prettify(&msg, Rf_translateCharUTF8(STRING_ELT(message, 0)), 0, 0),
          "git_message_prettify");
  const git_commit *parents[10] = {0};
  int number_parents = create_commit_list(parents, repo, merge_parents);

  // Setup tree, see: https://libgit2.org/docs/examples/init/
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  bail_if(git_index_write_tree(&tree_id, index), "git_index_write_tree");
  bail_if(git_tree_lookup(&tree, repo, &tree_id), "git_tree_lookup");
  bail_if(git_commit_create(&commit_id, repo, "HEAD", authsig, commitsig, "UTF-8",
                            msg.ptr, tree, number_parents, no_const_workaround parents), "git_commit_create");
  if(number_parents > 1)
    bail_if(git_repository_state_cleanup(repo), "git_repository_state_cleanup");
  free_commit_list(parents, number_parents);
  git_buf_free(&msg);
  git_tree_free(tree);
  git_index_free(index);
  return safe_string(git_oid_tostr_s(&commit_id));
}

SEXP R_git_commit_log(SEXP ptr, SEXP ref, SEXP max, SEXP after){
  git_commit *commit = NULL;
  git_repository *repo = get_git_repository(ptr);
  git_commit *head = ref_to_commit(ref, repo);

  /* Find out how many ancestors we have */
  int min_date = Rf_length(after) ? Rf_asInteger(after) : 0;
  int len = count_commit_ancestors(head, Rf_asInteger(max), min_date);
  SEXP ids = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP msg = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP author = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP times = PROTECT(Rf_allocVector(REALSXP, len));
  SEXP files = PROTECT(Rf_allocVector(INTSXP, len));
  SEXP merger = PROTECT(Rf_allocVector(LGLSXP, len));

  for(int i = 0; i < len; i++){
    if(git_commit_time(head) > min_date){
      SET_STRING_ELT(ids, i, safe_char(git_oid_tostr_s(git_commit_id(head))));
      SET_STRING_ELT(msg, i, safe_char(git_commit_message(head)));
      SET_STRING_ELT(author, i, make_author(git_commit_author(head)));
      REAL(times)[i] = git_commit_time(head);
      INTEGER(files)[i] = count_commit_changes(repo, head);
      LOGICAL(merger)[i] = git_commit_parentcount(head) > 1;
    } else {
      i--;
    }
    /* traverse to next commit (except for the final one) */
    if(i < len-1)
      bail_if(git_commit_parent(&commit, head, 0), "git_commit_parent");
    git_commit_free(head);
    head = commit;
  }
  Rf_setAttrib(times, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  SEXP out = build_tibble(6, "commit", ids, "author", author, "time", times,
                      "files", files, "merge", merger, "message", msg);
  UNPROTECT(6);
  return out;
}

SEXP R_git_diff_list(SEXP ptr, SEXP ref){
  git_diff *diff = NULL;
  git_repository *repo = get_git_repository(ptr);
  git_diff_options opt = GIT_DIFF_OPTIONS_INIT;
  if(Rf_length(ref)){
    git_commit *commit = ref_to_commit(ref, repo);
    diff = commit_to_diff(repo, commit);
  } else {
    // NB: this does not list 'staged' changes, as does: git_diff_tree_to_workdir_with_index()
    bail_if(git_diff_index_to_workdir(&diff, repo, NULL, &opt), "git_diff_index_to_workdir");
  }
  if(diff == NULL) //e.g. shallow clone
    return R_NilValue;
  int n = git_diff_num_deltas(diff);
  SEXP patches = PROTECT(Rf_allocVector(STRSXP, n));
  SEXP oldfiles = PROTECT(Rf_allocVector(STRSXP, n));
  SEXP newfiles = PROTECT(Rf_allocVector(STRSXP, n));
  SEXP status = PROTECT(Rf_allocVector(STRSXP, n));
  for(int i = 0; i < n ; i++){
    git_buf buf = {0};
    git_patch *patch = NULL;
    const git_diff_delta *delta = git_diff_get_delta(diff, i);
    SET_STRING_ELT(oldfiles, i, safe_char(delta->old_file.path));
    SET_STRING_ELT(newfiles, i, safe_char(delta->new_file.path));
    char s = git_diff_status_char(delta->status);
    SET_STRING_ELT(status, i, Rf_mkCharLen(&s, 1));
    if(!git_patch_from_diff(&patch, diff, i) && patch){
      bail_if(git_patch_to_buf(&buf, patch), "git_patch_to_buf");
      SET_STRING_ELT(patches, i, Rf_mkCharLenCE(buf.ptr, buf.size, CE_UTF8));
      git_patch_free(patch);
      git_buf_free(&buf);
    }
  }
  git_diff_free(diff);
  SEXP out = build_tibble(4, "status", status, "old", oldfiles, "new", newfiles, "patch", patches);
  UNPROTECT(4);
  return out;
}

static SEXP get_parents(git_commit *commit){
  int n = git_commit_parentcount(commit);
  SEXP out = PROTECT(Rf_allocVector(STRSXP, n));
  for(int i = 0; i < n; i++){
    SET_STRING_ELT(out, i, safe_char(git_oid_tostr_s(git_commit_parent_id(commit, i))));
  }
  UNPROTECT(1);
  return out;
}

SEXP R_git_commit_info(SEXP ptr, SEXP ref){
  git_repository *repo = get_git_repository(ptr);
  git_commit *commit = ref_to_commit(ref, repo);
  SEXP id = PROTECT(safe_string(git_oid_tostr_s(git_commit_id(commit))));
  SEXP parents = PROTECT(get_parents(commit));
  SEXP author = PROTECT(Rf_ScalarString(make_author(git_commit_author(commit))));
  SEXP committer = PROTECT(Rf_ScalarString(make_author(git_commit_committer(commit))));
  SEXP message = PROTECT(safe_string(git_commit_message(commit)));
  SEXP times = PROTECT(Rf_ScalarReal(git_commit_time(commit)));
  Rf_setAttrib(times, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  SEXP out = build_list(6, "id", id, "parents", parents, "author", author, "committer", committer,
                    "message", message, "time", times);
  UNPROTECT(6);
  return out;
}

SEXP R_git_commit_descendant(SEXP ptr, SEXP ref, SEXP ancestor){
  git_repository *repo = get_git_repository(ptr);
  git_object *a = resolve_refish(ref, repo);
  git_object *b = resolve_refish(ancestor, repo);
  int res = git_graph_descendant_of(repo, git_object_id(a), git_object_id(b));
  if(res == 1 || res == 0)
    return Rf_ScalarLogical(res);
  bail_if(res, "git_graph_descendant_of");
  return R_NilValue;
}

SEXP R_git_commit_id(SEXP ptr, SEXP ref){
  git_repository *repo = get_git_repository(ptr);
  git_commit *commit = ref_to_commit(ref, repo);
  return safe_string(git_oid_tostr_s(git_commit_id(commit)));
}

SEXP R_git_commit_stats(SEXP ptr, SEXP ref){
  git_repository *repo = get_git_repository(ptr);
  git_commit *commit = ref_to_commit(ref, repo);
  git_diff *diff = commit_to_diff(repo, commit);
  if(diff){
    git_diff_stats *stats = NULL;
    if(!git_diff_get_stats(&stats, diff) && stats){
      SEXP id = PROTECT(safe_string(git_oid_tostr_s(git_commit_id(commit))));
      SEXP statsfiles = PROTECT(Rf_ScalarInteger(git_diff_stats_files_changed(stats)));
      SEXP insertions = PROTECT(Rf_ScalarInteger(git_diff_stats_insertions(stats)));
      SEXP deletions = PROTECT(Rf_ScalarInteger(git_diff_stats_deletions(stats)));
      git_diff_stats_free(stats);
      SEXP out = build_list(4,"id", id, "files", statsfiles, "insertions", insertions, "deletions", deletions);
      UNPROTECT(4);
      return out;
    }
  }
  return R_NilValue;
}

SEXP R_git_stat_files(SEXP ptr, SEXP files, SEXP ref){
  git_commit *parent = NULL;
  git_repository *repo = get_git_repository(ptr);
  git_commit *commit = ref_to_commit(ref, repo);

  int nfiles = Rf_length(files);
  SEXP created = PROTECT(Rf_allocVector(REALSXP, nfiles));
  SEXP modified = PROTECT(Rf_allocVector(REALSXP, nfiles));
  SEXP changes = PROTECT(Rf_allocVector(INTSXP, nfiles));
  SEXP hashes = PROTECT(Rf_allocVector(STRSXP, nfiles));

  for(int fi = 0; fi < nfiles; fi++){
    REAL(created)[fi] = NA_REAL;
    REAL(modified)[fi] = NA_REAL;
    INTEGER(changes)[fi] = 0L;
    SET_STRING_ELT(hashes, fi, NA_STRING);
  }
  while(1) {
    git_diff *diff = commit_to_diff(repo, commit);
    if(diff == NULL)
      Rf_error("Failed to get parent commit. Is this a shallow clone?");
    for(int di = 0; di < git_diff_num_deltas(diff); di++){
      const git_diff_delta *delta = git_diff_get_delta(diff, di);
      for(int fi = 0; fi < nfiles; fi++){
        int count = INTEGER(changes)[fi];
        const char *filename = CHAR(STRING_ELT(files, fi));
        if(!strcmp(filename, delta->new_file.path) || !strcmp(filename, delta->old_file.path)){
          if(count == 0){
            REAL(modified)[fi] = git_commit_time(commit);
            SET_STRING_ELT(hashes, fi, safe_char(git_oid_tostr_s(git_commit_id(commit))));
          }
          REAL(created)[fi] = git_commit_time(commit);
          INTEGER(changes)[fi] = count + 1;
        }
      }
      if(di % 100 == 0) R_CheckUserInterrupt();
    }
    git_diff_free(diff);
    if(git_commit_parentcount(commit) == 0)
      break;
    bail_if(git_commit_parent(&parent, commit, 0), "git_commit_parent");
    commit = parent;
  }
  Rf_setAttrib(created, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  Rf_setAttrib(modified, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  SEXP out = build_tibble(5, "file", files, "created", created, "modified",
                          modified, "commits", changes, "head", hashes);
  UNPROTECT(4);
  return out;
}
