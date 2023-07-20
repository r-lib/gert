#include <string.h>
#include "utils.h"

SEXP R_git_ignore_path_is_ignored(SEXP ptr, SEXP path){
  git_repository *repo = get_git_repository(ptr);
  const R_len_t n = LENGTH(path);
  SEXP ret = PROTECT(Rf_allocVector(LGLSXP, n));
  int * ignored = INTEGER(ret);
  for(R_len_t i = 0; i < n; ++i, ++ignored){
    const char * path_i = CHAR(STRING_ELT(path, i));
    bail_if(git_ignore_path_is_ignored(ignored, repo, path_i),
            "git_ignore_path_is_ignored");
  }
  UNPROTECT(1);
  return ret;
}
