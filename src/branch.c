#include <string.h>
#include "utils.h"

#if ! AT_LEAST_LIBGIT2(0, 21)
#define git_checkout_options git_checkout_opts
#define GIT_CHECKOUT_OPTIONS_INIT GIT_CHECKOUT_OPTS_INIT
#endif

SEXP R_git_reset(SEXP ptr, SEXP ref, SEXP typenum){
  git_object *revision = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_revparse_single(&revision, repo, CHAR(STRING_ELT(ref, 0))), "git_revparse_single");
  git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
  opts.checkout_strategy = GIT_CHECKOUT_SAFE;
  git_reset_t reset_type = Rf_asInteger(typenum);
  bail_if(git_reset(repo, revision, reset_type, &opts), "git_reset");
  return ptr;
}

SEXP R_git_create_branch(SEXP ptr, SEXP name, SEXP ref, SEXP checkout){
  git_object *obj;
  git_commit *commit = NULL;
  git_object *revision = NULL;
  git_reference *branch = NULL;
  git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
  opts.checkout_strategy = GIT_CHECKOUT_SAFE;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_revparse_single(&revision, repo, CHAR(STRING_ELT(ref, 0))), "git_revparse_single");
  bail_if(git_commit_lookup(&commit, repo, git_object_id(revision)), "git_commit_lookup");
  git_object_free(revision);
  bail_if(git_branch_create(&branch, repo, CHAR(STRING_ELT(name, 0)), commit, 0), "git_branch_create");
  git_commit_free(commit);
  if(Rf_asInteger(checkout)){
    bail_if(git_object_lookup(&obj, repo, git_reference_target(branch), GIT_OBJ_ANY), "git_object_lookup");
    bail_if(git_checkout_tree(repo, obj, &opts), "git_checkout_tree");
    git_object_free(obj);
    bail_if(git_repository_set_head(repo, git_reference_name(branch)), "git_repository_set_head");
  }
  return ptr;
}

SEXP R_git_checkout_branch(SEXP ptr, SEXP branch, SEXP force){
  git_reference *ref;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_branch_lookup(&ref, repo, CHAR(STRING_ELT(branch, 0)), GIT_BRANCH_LOCAL), "git_branch_lookup");

  /* Set checkout options */
  git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
  opts.checkout_strategy = Rf_asLogical(force) ? GIT_CHECKOUT_FORCE : GIT_CHECKOUT_SAFE;

  git_object *obj;
  bail_if(git_object_lookup(&obj, repo, git_reference_target(ref), GIT_OBJ_ANY), "git_object_lookup");
  bail_if(git_checkout_tree(repo, obj, &opts), "git_checkout_tree");
  bail_if(git_repository_set_head(repo, git_reference_name(ref)), "git_repository_set_head");
  git_reference_free(ref);
  return ptr;
}

SEXP R_git_checkout_ref(SEXP ptr, SEXP ref, SEXP force){
  git_repository *repo = get_git_repository(ptr);
  git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
  opts.checkout_strategy = Rf_asLogical(force) ? GIT_CHECKOUT_FORCE : GIT_CHECKOUT_SAFE;

  /* Parse the branch/tag/ref string */
  git_object *treeish = NULL;
  const char *refstring = CHAR(STRING_ELT(ref, 0));
  bail_if(git_revparse_single(&treeish, repo, refstring), "git_revparse_single");
  bail_if(git_checkout_tree(repo, treeish, &opts), "git_checkout_tree");
  git_object_free(treeish);
  char buf[1000];
  snprintf(buf, 999, "refs/heads/%s", refstring);
  bail_if(git_repository_set_head(repo, buf), "git_repository_set_head");
  return ptr;
}

SEXP R_git_tag_list(SEXP ptr, SEXP pattern){
  git_repository *repo = get_git_repository(ptr);
  git_strarray tag_list;
  bail_if(git_tag_list_match(&tag_list, CHAR(STRING_ELT(pattern, 0)), repo), "git_tag_list");
  SEXP names = PROTECT(Rf_allocVector(STRSXP, tag_list.count));
  SEXP refs = PROTECT(Rf_allocVector(STRSXP, tag_list.count));
  SEXP ids = PROTECT(Rf_allocVector(STRSXP, tag_list.count));
  for(int i = 0; i < tag_list.count; i++){
    git_oid oid;
    char refstr[1000];
    snprintf(refstr, 999, "refs/tags/%s", tag_list.strings[i]);
    SET_STRING_ELT(names, i, safe_char(tag_list.strings[i]));
    SET_STRING_ELT(refs, i, safe_char(refstr));
    if(git_reference_name_to_id(&oid, repo, refstr) == 0)
      SET_STRING_ELT(ids, i, safe_char(git_oid_tostr_s(&oid)));
  }
  git_strarray_free(&tag_list);
  return build_tibble(3, "name", names, "ref", refs, "commit", ids);
}

SEXP R_git_branch_list(SEXP ptr){
  int res = 0;
  int count = 0;
  git_branch_t type;
  git_reference *ref;
  git_branch_iterator *iter;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_branch_iterator_new(&iter, repo, GIT_BRANCH_ALL), "git_branch_iterator_new");
  while((res = git_branch_next(&ref, &type, iter)) != GIT_ITEROVER){
    bail_if(res, "git_branch_next");
    git_reference_free(ref);
    count++;
  }
  git_branch_iterator_free(iter);

  SEXP names = PROTECT(Rf_allocVector(STRSXP, count));
  SEXP islocal = PROTECT(Rf_allocVector(LGLSXP, count));
  SEXP refs = PROTECT(Rf_allocVector(STRSXP, count));
  SEXP ids = PROTECT(Rf_allocVector(STRSXP, count));
  SEXP upstreams = PROTECT(Rf_allocVector(STRSXP, count));
  bail_if(git_branch_iterator_new(&iter, repo, GIT_BRANCH_ALL), "git_branch_iterator_new");
  for(int i = 0; i < count; i++){
    bail_if(git_branch_next(&ref, &type, iter), "git_branch_next");
    const char * name = NULL;
    if(git_branch_name(&name, ref) == 0)
      SET_STRING_ELT(names, i, safe_char(name));
    LOGICAL(islocal)[i] = (type == GIT_BRANCH_LOCAL);
    SET_STRING_ELT(refs, i, safe_char(git_reference_name(ref)));
    if(git_reference_target(ref))
      SET_STRING_ELT(ids, i, safe_char(git_oid_tostr_s(git_reference_target(ref))));
    git_reference *upstream = NULL;
    SET_STRING_ELT(upstreams, i, safe_char(git_branch_upstream(&upstream, ref) ? NULL : git_reference_name(upstream)));
    git_reference_free(ref);
  }
  git_branch_iterator_free(iter);
  return build_tibble(5, "name", names, "local", islocal, "ref", refs,"upstream", upstreams, "commit", ids);
}

static SEXP make_refspecs(git_remote *remote){
  int size = git_remote_refspec_count(remote);
  SEXP out = PROTECT(Rf_allocVector(STRSXP, size));
  for(int i = 0; i < size; i++){
    SET_STRING_ELT(out, i, safe_char(git_refspec_string(git_remote_get_refspec(remote, i))));
  }
  UNPROTECT(1);
  return out;
}

SEXP R_git_remote_list(SEXP ptr){
  git_strarray remotes = {0};
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_remote_list(&remotes, repo), "git_remote_list");
  SEXP names = PROTECT(Rf_allocVector(STRSXP, remotes.count));
  SEXP url = PROTECT(Rf_allocVector(STRSXP, remotes.count));
  SEXP refspecs = PROTECT(Rf_allocVector(VECSXP, remotes.count));
  for(int i = 0; i < remotes.count; i++){
    git_remote *remote = NULL;
    char *name = remotes.strings[i];
    SET_STRING_ELT(names, i, safe_char(name));
    if(!git_remote_lookup(&remote, repo, name)){
      SET_STRING_ELT(url, i, safe_char(git_remote_url(remote)));
      SET_VECTOR_ELT(refspecs, i, make_refspecs(remote));
      git_remote_free(remote);
    }
    free(name);
  }
  return build_tibble(3, "name", names, "url", url, "refspecs", refspecs);
}

SEXP R_git_remote_add(SEXP ptr, SEXP name, SEXP url){
  const char *curl = CHAR(STRING_ELT(url, 0));
  const char *cname = CHAR(STRING_ELT(name, 0));
  git_repository *repo = get_git_repository(ptr);
  if(!git_remote_is_valid_name(cname))
    Rf_error("Invalid remote name %s", cname);
  git_remote *remote = NULL;
  bail_if(git_remote_create(&remote,repo, cname, curl), "git_remote_create");
  return make_refspecs(remote);
}

SEXP R_git_remote_remove(SEXP ptr, SEXP name){
  const char *cname = CHAR(STRING_ELT(name, 0));
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_remote_delete(repo, cname), "git_remote_delete");
  return R_NilValue;
}
