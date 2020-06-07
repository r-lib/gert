#include <string.h>
#include "utils.h"

static int count_commit_ancestors(git_commit *x, int max){
  git_commit *y = NULL;
  for(int i = 1; i < max; i++){
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

static git_signature *get_signature(SEXP ptr){
  if(TYPEOF(ptr) != EXTPTRSXP || !Rf_inherits(ptr, "git_sig_ptr"))
    Rf_error("handle is not a git_sig_ptr");
  if(!R_ExternalPtrAddr(ptr))
    Rf_error("pointer is dead");
  return R_ExternalPtrAddr(ptr);
}

static void fin_git_sig(SEXP ptr){
  if(!R_ExternalPtrAddr(ptr)) return;
  git_signature_free(R_ExternalPtrAddr(ptr));
  R_ClearExternalPtr(ptr);
}

static SEXP new_git_sig(git_signature *repo){
  SEXP ptr = PROTECT(R_MakeExternalPtr(repo, R_NilValue, R_NilValue));
  R_RegisterCFinalizerEx(ptr, fin_git_sig, 1);
  Rf_setAttrib(ptr, R_ClassSymbol, Rf_mkString("git_sig_ptr"));
  UNPROTECT(1);
  return ptr;
}

static git_commit *find_commit_from_string(git_repository *repo, const char * ref){
  git_commit *commit = NULL;
  git_object *revision = NULL;
  bail_if(git_revparse_single(&revision, repo, ref), "git_revparse_single");
  bail_if(git_commit_lookup(&commit, repo, git_object_id(revision)), "git_commit_lookup");
  git_object_free(revision);
  return commit;
}

static git_diff *commit_to_diff(git_repository *repo, git_commit *commit){
  git_diff *diff = NULL;
  git_tree *old_tree = NULL;
  git_tree *new_tree = NULL;
  git_commit *parent = NULL;
  bail_if(git_commit_tree(&new_tree, commit), "git_commit_tree");
  if(git_commit_parentcount(commit) > 0){
    bail_if(git_commit_parent(&parent, commit, 0), "git_commit_parent");
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
  int count = git_diff_num_deltas(diff);
  git_diff_free(diff);
  return count;
}

SEXP R_git_signature_default(SEXP ptr){
  git_signature *sig;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_signature_default(&sig, repo), "git_signature_default");
  return new_git_sig(sig);
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
  return new_git_sig(sig);
}

SEXP R_git_signature_parse(SEXP str){
  git_signature *sig = NULL;
  bail_if(git_signature_from_buffer(&sig, CHAR(STRING_ELT(str, 0))), "git_signature_from_buffer");
  if(sig->when.time > 0){
    return new_git_sig(sig);
  }
  git_signature *now = NULL;
  bail_if(git_signature_now(&now, sig->name, sig->email), "git_signature_now");
  git_signature_free(sig);
  return new_git_sig(now);
}

SEXP R_git_signature_info(SEXP ptr){
  git_signature *sig = get_signature(ptr);
  SEXP author = PROTECT(Rf_ScalarString(make_author(sig)));
  SEXP time = PROTECT(Rf_ScalarReal(sig->when.time));
  SEXP offset = PROTECT(Rf_ScalarInteger(sig->when.offset));
  Rf_setAttrib(time, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  return build_list(3, "author", author, "time", time, "offset", offset);
}

SEXP R_git_commit_create(SEXP ptr, SEXP message, SEXP author, SEXP committer){
  git_buf msg = {0};
  git_tree *tree;
  git_index *index;
  git_commit *commit = NULL;
  git_reference *head = NULL;
  git_oid tree_id, commit_id;
  git_repository *repo = get_git_repository(ptr);
  git_signature *authsig = get_signature(author);
  git_signature *commitsig = get_signature(committer);
  if(git_repository_head(&head, repo) == 0){
    bail_if(git_commit_lookup(&commit, repo, git_reference_target(head)), "git_commit_lookup");
  }
  bail_if(git_message_prettify(&msg, Rf_translateCharUTF8(STRING_ELT(message, 0)), 0, 0), "git_message_prettify");

  // Setup tree, see: https://libgit2.org/docs/examples/init/
  const git_commit *parents[1] = {commit};
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  bail_if(git_index_write_tree(&tree_id, index), "git_index_write_tree");
  bail_if(git_tree_lookup(&tree, repo, &tree_id), "git_tree_lookup");
  bail_if(git_commit_create(&commit_id, repo, "HEAD", authsig, commitsig, "UTF-8",
                            msg.ptr, tree, commit ? 1 : 0, parents), "git_commit_create");
  git_buf_free(&msg);
  git_tree_free(tree);
  git_index_free(index);
  git_commit_free(commit);
  git_reference_free(head);
  return safe_string(git_oid_tostr_s(&commit_id));
}

SEXP R_git_commit_log(SEXP ptr, SEXP ref, SEXP max){
  git_commit *commit = NULL;
  git_repository *repo = get_git_repository(ptr);
  git_commit *head = find_commit_from_string(repo, CHAR(STRING_ELT(ref, 0)));

  /* Find out how many ancestors we have */
  int len = count_commit_ancestors(head, Rf_asInteger(max));
  SEXP ids = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP msg = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP author = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP time = PROTECT(Rf_allocVector(REALSXP, len));
  SEXP deltas = PROTECT(Rf_allocVector(INTSXP, len));

  for(int i = 0; i < len; i++){
    SET_STRING_ELT(ids, i, safe_char(git_oid_tostr_s(git_commit_id(head))));
    SET_STRING_ELT(msg, i, safe_char(git_commit_message(head)));
    SET_STRING_ELT(author, i, make_author(git_commit_author(head)));
    REAL(time)[i] = git_commit_time(head);
    INTEGER(deltas)[i] = count_commit_changes(repo, head);

    /* traverse to next commit (except for the final one) */
    if(i < len-1)
      bail_if(git_commit_parent(&commit, head, 0), "git_commit_parent");
    git_commit_free(head);
    head = commit;
  }
  Rf_setAttrib(time, R_ClassSymbol, make_strvec(2, "POSIXct", "POSIXt"));
  return build_tibble(5, "commit", ids, "author", author, "time", time,
                      "deltas", deltas, "message", msg);
}

SEXP R_git_commit_diff(SEXP ptr, SEXP ref){
  git_repository *repo = get_git_repository(ptr);
  git_commit *commit = find_commit_from_string(repo, CHAR(STRING_ELT(ref, 0)));
  git_diff *diff = commit_to_diff(repo, commit);
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
  return build_tibble(4, "status", status, "old", oldfiles, "new", newfiles, "patch", patches);
}

SEXP R_git_commit_info(SEXP ptr, SEXP ref){
  git_repository *repo = get_git_repository(ptr);
  git_commit *commit = find_commit_from_string(repo, CHAR(STRING_ELT(ref, 0)));
  SEXP id = PROTECT(safe_string(git_oid_tostr_s(git_commit_id(commit))));
  SEXP parent = PROTECT(safe_string(git_oid_tostr_s(git_commit_parent_id(commit, 0))));
  SEXP author = PROTECT(Rf_ScalarString(make_author(git_commit_author(commit))));
  SEXP committer = PROTECT(Rf_ScalarString(make_author(git_commit_committer(commit))));
  SEXP message = PROTECT(safe_string(git_commit_message(commit)));
  SEXP diff = PROTECT(R_git_commit_diff(ptr, ref));
  return build_list(6, "id", id, "parent", parent, "author", author, "committer", committer,
                    "message", message, "diff", diff);
}
