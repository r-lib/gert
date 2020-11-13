#include <string.h>
#include "utils.h"

static int submodule_count(git_submodule *submod, const char *name, void *payload){
  int *count = payload;
  *count = ++(*count);
  return 0;
}

static int submodule_fill(git_submodule *sm, const char *name, void *payload){
  SEXP df = payload;
  SEXP names = VECTOR_ELT(df, 0);
  SEXP paths = VECTOR_ELT(df, 1);
  SEXP urls = VECTOR_ELT(df, 2);
  SEXP branches = VECTOR_ELT(df, 3);
  SEXP heads = VECTOR_ELT(df, 4);
  for(int i = 0; i < Rf_length(names); i++){
    if(Rf_length(STRING_ELT(names, i)) == 0){
      SET_STRING_ELT(names, i, safe_char(git_submodule_name(sm)));
      SET_STRING_ELT(paths, i, safe_char(git_submodule_path(sm)));
      SET_STRING_ELT(urls, i, safe_char(git_submodule_url(sm)));
      SET_STRING_ELT(branches, i, safe_char(git_submodule_branch(sm)));
      SET_STRING_ELT(heads, i, safe_char(git_oid_tostr_s(git_submodule_head_id(sm))));
      return 0;
    }
  }
  return 1;
}

SEXP R_git_submodule_list(SEXP ptr){
  int n = 0;
  git_repository *repo = get_git_repository(ptr);
  git_submodule_foreach(repo, submodule_count, &n);
  SEXP df = PROTECT(build_tibble(5,
                         "name", PROTECT(Rf_allocVector(STRSXP, n)),
                         "path", PROTECT(Rf_allocVector(STRSXP, n)),
                         "url", PROTECT(Rf_allocVector(STRSXP, n)),
                         "branch", PROTECT(Rf_allocVector(STRSXP, n)),
                         "head", PROTECT(Rf_allocVector(STRSXP, n))));
  git_submodule_foreach(repo, submodule_fill, df);
  UNPROTECT(1);
  return df;
}
