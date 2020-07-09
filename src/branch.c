#include <string.h>
#include "utils.h"

SEXP R_git_reset(SEXP ptr, SEXP ref, SEXP typenum){
  git_object *revision = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_revparse_single(&revision, repo, CHAR(STRING_ELT(ref, 0))), "git_revparse_single");
  git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
  opts.checkout_strategy = GIT_CHECKOUT_SAFE;
  set_checkout_notify_cb(&opts);
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
  set_checkout_notify_cb(&opts);
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

SEXP R_git_delete_branch(SEXP ptr, SEXP branch){
  git_reference *ref;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_branch_lookup(&ref, repo, CHAR(STRING_ELT(branch, 0)), GIT_BRANCH_LOCAL), "git_branch_lookup");
  bail_if(git_branch_delete(ref), "git_branch_delete");
  git_reference_free(ref);
  return R_NilValue;
}

SEXP R_git_checkout_branch(SEXP ptr, SEXP branch, SEXP force){
  git_reference *ref;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_branch_lookup(&ref, repo, CHAR(STRING_ELT(branch, 0)), GIT_BRANCH_LOCAL), "git_branch_lookup");

  /* Set checkout options */
  git_checkout_options opts = GIT_CHECKOUT_OPTIONS_INIT;
  opts.checkout_strategy = Rf_asLogical(force) ? GIT_CHECKOUT_FORCE : GIT_CHECKOUT_SAFE;
  set_checkout_notify_cb(&opts);

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
  set_checkout_notify_cb(&opts);

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
  SEXP strings = PROTECT(Rf_allocVector(STRSXP, size));
  SEXP directions = PROTECT(Rf_allocVector(STRSXP, size));
  for(int i = 0; i < size; i++){
    const git_refspec *refspec = git_remote_get_refspec(remote, i);
    SET_STRING_ELT(strings, i, safe_char(git_refspec_string(refspec)));
    SET_STRING_ELT(directions, i, safe_char(git_refspec_direction(refspec) == GIT_DIRECTION_FETCH ? "fetch" : "push"));
  }
  return build_tibble(2, "refspec", strings, "direction", directions);
}

SEXP R_git_remote_list(SEXP ptr){
  git_strarray remotes = {0};
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_remote_list(&remotes, repo), "git_remote_list");
  SEXP names = PROTECT(Rf_allocVector(STRSXP, remotes.count));
  SEXP url = PROTECT(Rf_allocVector(STRSXP, remotes.count));
  for(int i = 0; i < remotes.count; i++){
    git_remote *remote = NULL;
    char *name = remotes.strings[i];
    SET_STRING_ELT(names, i, safe_char(name));
    if(!git_remote_lookup(&remote, repo, name)){
      SET_STRING_ELT(url, i, safe_char(git_remote_url(remote)));
      git_remote_free(remote);
    }
    free(name);
  }
  return build_tibble(2, "name", names, "url", url);
}

SEXP R_git_remote_add(SEXP ptr, SEXP name, SEXP url, SEXP refspec){
  const char *curl = CHAR(STRING_ELT(url, 0));
  const char *cname = CHAR(STRING_ELT(name, 0));
  git_repository *repo = get_git_repository(ptr);
  if(!git_remote_is_valid_name(cname))
    Rf_error("Invalid remote name %s", cname);
  git_remote *remote = NULL;
  if(Rf_length(refspec)){
    const char *crefspec = CHAR(STRING_ELT(refspec, 0));
    bail_if(git_remote_create_with_fetchspec(&remote, repo, cname, curl, crefspec), "git_remote_create_with_fetchspec");
  } else {
    bail_if(git_remote_create(&remote, repo, cname, curl), "git_remote_create");
  }
  SEXP out = safe_string(git_remote_name(remote));
  git_remote_free(remote);
  return out;
}

SEXP R_git_remote_set_url(SEXP ptr, SEXP name, SEXP url){
  git_remote * remote = NULL;
  const char *curl = Rf_length(url) ? CHAR(STRING_ELT(url, 0)) : NULL;
  const char *cname = CHAR(STRING_ELT(name, 0));
  git_repository *repo = get_git_repository(ptr);
  /* git_remote_lookup validates that the remote exists */
  bail_if(git_remote_lookup(&remote, repo, cname), "git_remote_lookup");
  bail_if(git_remote_set_url(repo, cname, curl), "git_remote_set_url");
  SEXP out = safe_string(git_remote_url(remote));
  git_remote_free(remote);
  return out;
}

SEXP R_git_remote_set_pushurl(SEXP ptr, SEXP name, SEXP url){
  git_remote * remote = NULL;
  const char *curl = Rf_length(url) ? CHAR(STRING_ELT(url, 0)) : NULL;
  const char *cname = CHAR(STRING_ELT(name, 0));
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_remote_lookup(&remote, repo, cname), "git_remote_lookup");
  bail_if(git_remote_set_pushurl(repo, cname, curl), "git_remote_set_url");
  SEXP out = safe_string(git_remote_pushurl(remote));
  git_remote_free(remote);
  return out;
}

SEXP R_git_remote_remove(SEXP ptr, SEXP name){
  const char *cname = CHAR(STRING_ELT(name, 0));
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_remote_delete(repo, cname), "git_remote_delete");
  return R_NilValue;
}

SEXP R_git_branch_set_upstream(SEXP ptr, SEXP remote, SEXP branch){
  git_reference *ref;
  git_repository *repo = get_git_repository(ptr);
  if(Rf_length(branch)){
    bail_if(git_branch_lookup(&ref, repo, CHAR(STRING_ELT(branch, 0)), GIT_BRANCH_LOCAL), "git_branch_lookup");
  } else {
    bail_if(git_repository_head(&ref, repo), "git_repository_head");
  }
  bail_if(git_branch_set_upstream(ref, CHAR(STRING_ELT(remote, 0))), "git_branch_set_upstream");
  git_reference_free(ref);
  return ptr;
}

SEXP R_git_remote_refspecs(SEXP ptr, SEXP name){
  git_remote *remote = NULL;
  const char *cname = CHAR(STRING_ELT(name, 0));
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_remote_lookup(&remote, repo, cname), "git_remote_lookup");
  size_t len = git_remote_refspec_count(remote);
  SEXP names = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP urls = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP directions = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP string = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP src = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP dest = PROTECT(Rf_allocVector(STRSXP, len));
  SEXP force = PROTECT(Rf_allocVector(LGLSXP, len));
  for(size_t i = 0; i < len; i++){
    const git_refspec *refspec = git_remote_get_refspec(remote, i);
    SET_STRING_ELT(names, i, safe_char(git_remote_name(remote)));
    SET_STRING_ELT(urls, i, safe_char(git_remote_url(remote)));
    SET_STRING_ELT(directions, i, safe_char(git_refspec_direction(refspec) == GIT_DIRECTION_FETCH ? "fetch" : "push"));
    SET_STRING_ELT(string, i, safe_char(git_refspec_string(refspec)));
    SET_STRING_ELT(src, i, safe_char(git_refspec_src(refspec)));
    SET_STRING_ELT(dest, i, safe_char(git_refspec_dst(refspec)));
    LOGICAL(force)[i] = git_refspec_force(refspec);
  }
  return build_tibble(7, "name", names, "url", urls, "direction", directions,
                      "refspec", string, "src", src, "dest", dest, "force", force);
}

SEXP R_git_remote_info(SEXP ptr, SEXP name){
  git_remote *remote = NULL;
  const char *cname = CHAR(STRING_ELT(name, 0));
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_remote_lookup(&remote, repo, cname), "git_remote_lookup");
  git_strarray fetchspecs = {0};
  git_strarray pushspecs = {0};
  bail_if(git_remote_get_fetch_refspecs(&fetchspecs, remote), "git_remote_get_fetch_refspecs");
  bail_if(git_remote_get_push_refspecs(&pushspecs, remote), "git_remote_get_fetch_refspecs");
  SEXP fetch = PROTECT(Rf_allocVector(STRSXP, fetchspecs.count));
  SEXP push = PROTECT(Rf_allocVector(STRSXP, pushspecs.count));
  for(int i = 0; i < fetchspecs.count; i++)
    SET_STRING_ELT(fetch, i, safe_char(fetchspecs.strings[i]));
  for(int i = 0; i < pushspecs.count; i++)
    SET_STRING_ELT(push, i, safe_char(pushspecs.strings[i]));
  git_strarray_free(&fetchspecs);
  git_strarray_free(&pushspecs);
  char buf[1000] = {0};
  sprintf(buf, "refs/remotes/%s/HEAD", git_remote_name(remote));
  git_reference *remote_head = NULL;
  int has_default = git_reference_lookup(&remote_head, repo, buf) == GIT_OK;
  SEXP out = build_list(6,
    "name", PROTECT(string_or_null(git_remote_name(remote))),
    "url", PROTECT(string_or_null(git_remote_url(remote))),
    "push_url", PROTECT(string_or_null(git_remote_pushurl(remote))),
    "head", PROTECT(string_or_null(has_default ? git_reference_symbolic_target(remote_head) : NULL)),
    "fetch", fetch,
    "push", push
  );
  git_remote_free(remote);
  return out;
}
