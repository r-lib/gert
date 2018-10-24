#include "utils.h"

SEXP R_git_checkout(SEXP ptr, SEXP ref, SEXP force){
  git_repository *repo = get_git_repository(ptr);

  /* Set checkout options */
#if AT_LEAST_LIBGIT2(0, 21)
  git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
#else
  git_checkout_opts opts = GIT_CHECKOUT_OPTS_INIT;
#endif
  opts.checkout_strategy = Rf_asLogical(force) ? GIT_CHECKOUT_FORCE : GIT_CHECKOUT_SAFE;

  /* Parse the branch/tag/ref string */
  git_object *treeish = NULL;
  const char *refstring = CHAR(STRING_ELT(ref, 0));
  bail_if(git_revparse_single(&treeish, repo, refstring), "git_revparse_single");
  bail_if(git_checkout_tree(repo, treeish, &opts), "git_checkout_tree");
  git_object_free(treeish);
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
  return make_tibble_and_unprotect(3, "tag", names, "ref", refs, "id", ids);
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
    git_reference_free(ref);
  }
  git_branch_iterator_free(iter);
  return make_tibble_and_unprotect(4, "name", names, "local", islocal, "ref", refs, "id", ids);
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

SEXP R_git_remotes_list(SEXP ptr){
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
  return make_tibble_and_unprotect(3, "remote", names, "url", url, "refspecs", refspecs);
}
