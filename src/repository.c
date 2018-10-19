#include <git2.h>
#include <Rinternals.h>
#include <string.h>
#include "utils.h"

static SEXP safe_string(const char *x){
  if(x == NULL)
    return Rf_ScalarString(NA_STRING);
  return Rf_mkString(x);
}

static SEXP safe_char(const char *x){
  if(x == NULL)
    return NA_STRING;
  return Rf_mkCharCE(x, CE_UTF8);
}

static void fin_git_repository(SEXP ptr){
  if(!R_ExternalPtrAddr(ptr)) return;
  git_repository_free(R_ExternalPtrAddr(ptr));
  R_ClearExternalPtr(ptr);
}

static SEXP new_git_repository(git_repository *repo){
  SEXP ptr = PROTECT(R_MakeExternalPtr(repo, R_NilValue, R_NilValue));
  R_RegisterCFinalizerEx(ptr, fin_git_repository, 1);
  Rf_setAttrib(ptr, R_ClassSymbol, Rf_mkString("git_repository"));
  UNPROTECT(1);
  return ptr;
}

static git_repository *get_git_repository(SEXP ptr){
  if(TYPEOF(ptr) != EXTPTRSXP || !Rf_inherits(ptr, "git_repository"))
    Rf_error("handle is not a git_repository");
  if(!R_ExternalPtrAddr(ptr))
    Rf_error("pointer is dead");
  return R_ExternalPtrAddr(ptr);
}

static int fetch_progress(const git_transfer_progress *stats, void *payload){
  R_CheckUserInterrupt();
  unsigned int tot = stats->total_objects;
  unsigned int cur = stats->received_objects;
  static size_t prev = 0;
  if(prev != cur){
    prev = cur;
    REprintf("\rReceived %d of %d objects...", cur, tot);
    if(cur == tot) 
      REprintf("done!\n");
  }
  return 0;
}

static void checkout_progress(const char *path, size_t cur, size_t tot, void *payload){
  R_CheckUserInterrupt();
  static size_t prev = 0;
  if(prev != cur){
    prev = cur;
    REprintf("\rChecked out %d of %d commits...", cur, tot);
    if(cur == tot) 
      REprintf(" done!\n");
  }
}

SEXP R_git_repository_init(SEXP path){
  git_repository *repo = NULL;
  bail_if(git_repository_init(&repo, CHAR(STRING_ELT(path, 0)), 0), "git_repository_init");
  return new_git_repository(repo);
}

SEXP R_git_repository_open(SEXP path){
  git_repository *repo = NULL;
  bail_if(git_repository_open(&repo, CHAR(STRING_ELT(path, 0))), "git_repository_open");
  return new_git_repository(repo);
}

SEXP R_git_repository_clone(SEXP url, SEXP path, SEXP branch, SEXP verbose){
  git_repository *repo = NULL;
  git_clone_options clone_opts = GIT_CLONE_OPTIONS_INIT;
  clone_opts.checkout_opts.checkout_strategy = GIT_CHECKOUT_SAFE;
  if(Rf_asLogical(verbose)){
    clone_opts.checkout_opts.progress_cb = checkout_progress;
  
#if LIBGIT2_VER_MAJOR > 0 || LIBGIT2_VER_MINOR >= 23
    clone_opts.fetch_opts.callbacks.transfer_progress = fetch_progress;
#endif
  }
  
  /* specify branch to checkout */
  if(Rf_length(branch))
    clone_opts.checkout_branch = CHAR(STRING_ELT(branch, 0));

  /* try to clone */
  bail_if(git_clone(&repo, CHAR(STRING_ELT(url, 0)), CHAR(STRING_ELT(path, 0)), 
                    &clone_opts), "git_clone");
  bail_if_null(repo, "failed to clone repo");
  return new_git_repository(repo);
}

SEXP R_git_repository_info(SEXP ptr){
  git_strarray ref_list;
  git_repository *repo = get_git_repository(ptr);
  
  bail_if(git_reference_list(&ref_list, repo), "git_reference_list");
  SEXP refs = PROTECT(Rf_allocVector(STRSXP, ref_list.count));
  for(int i = 0; i < ref_list.count; i++){
    SET_STRING_ELT(refs, i, Rf_mkChar(ref_list.strings[i]));
  }
  SEXP list = PROTECT(Rf_allocVector(VECSXP, 4));
  SEXP names = PROTECT(Rf_allocVector(STRSXP, Rf_length(list)));
  SET_STRING_ELT(names, 0, Rf_mkChar("path"));
  SET_STRING_ELT(names, 1, Rf_mkChar("ref"));
  SET_STRING_ELT(names, 2, Rf_mkChar("shorthand"));
  SET_STRING_ELT(names, 3, Rf_mkChar("reflist"));
  SET_VECTOR_ELT(list, 0, safe_string(git_repository_workdir(repo)));
  
  git_reference *head = NULL;
  if(git_repository_head(&head, repo) == 0){
    SET_VECTOR_ELT(list, 1, safe_string(git_reference_name(head)));
    SET_VECTOR_ELT(list, 2, safe_string(git_reference_shorthand(head)));    
  } else {
    SET_VECTOR_ELT(list, 1, Rf_ScalarString(NA_STRING));
    SET_VECTOR_ELT(list, 2, Rf_ScalarString(NA_STRING));    
  }
  SET_VECTOR_ELT(list, 3, refs);
  Rf_setAttrib(list, R_NamesSymbol, names);
  UNPROTECT(3);
  git_reference_free(head);
  git_strarray_free(&ref_list);
  return list;
}

SEXP R_git_repository_ls(SEXP ptr){
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  
  size_t entry_count = git_index_entrycount(index);
  SEXP paths = PROTECT(Rf_allocVector(STRSXP, entry_count));
  SEXP sizes = PROTECT(Rf_allocVector(REALSXP, entry_count));
  SEXP mtimes = PROTECT(Rf_allocVector(REALSXP, entry_count));
  
  for(size_t i = 0; i < entry_count; i++){
    const git_index_entry *entry = git_index_get_byindex(index, i);
    git_index_time timeval = entry->mtime;
    SET_STRING_ELT(paths, i, safe_char(entry->path));
    REAL(sizes)[i] = (double) entry->file_size;
    REAL(mtimes)[i] = (double) timeval.seconds + timeval.nanoseconds * 1e-9;
  }
  git_index_free(index);
  SEXP df = PROTECT(Rf_allocVector(VECSXP, 3));
  SET_VECTOR_ELT(df, 0, paths);
  SET_VECTOR_ELT(df, 1, sizes);
  SET_VECTOR_ELT(df, 2, mtimes);
  UNPROTECT(4);
  return df;
}

SEXP R_git_repository_add(SEXP ptr, SEXP files, SEXP force){
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  git_strarray paths;
  int len = Rf_length(files);
  paths.count = len;
  paths.strings = malloc(len);
  for(int i = 0; i < Rf_length(files); i++)
    paths.strings[i] = strdup(CHAR(STRING_ELT(files, i)));
  git_index_add_option_t flags = Rf_asLogical(force) ? GIT_INDEX_ADD_FORCE : GIT_INDEX_ADD_DEFAULT;
  bail_if(git_index_add_all(index, &paths, flags, NULL, NULL), "git_index_add_bypath");
  git_index_free(index);
  for(int i = 0; i < Rf_length(files); i++)
    free(paths.strings[i]);
  return ptr;
}

SEXP R_git_repository_rm(SEXP ptr, SEXP files){
  git_index *index = NULL;
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_repository_index(&index, repo), "git_repository_index");
  for(int i = 0; i < Rf_length(files); i++){
    bail_if(git_index_remove_bypath(index, CHAR(STRING_ELT(files, i))), "git_index_remove_bypath");
  }
  git_index_free(index);
  return ptr;
}

SEXP R_git_checkout(SEXP ptr, SEXP ref, SEXP force){
  git_repository *repo = get_git_repository(ptr);
  
  /* Set checkout options */
  #if LIBGIT2_VER_MAJOR > 0 || LIBGIT2_VER_MINOR >= 21
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

