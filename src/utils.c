#include "utils.h"

void bail_if(int err, const char *what){
  if (err) {
    const git_error *info = giterr_last();
    if (info){
      Rf_error("libgit2 error in %s: %s (%d)\n", what, info->message, info->klass);
    } else {
      Rf_error("Unknown libgit2 error in %s", what);
    }
  }
}

void bail_if_null(void * ptr, const char * what){
  if(!ptr)
    bail_if(-1, what);
}

SEXP safe_string(const char *x){
  return Rf_ScalarString(safe_char(x));
}

SEXP safe_char(const char *x){
  if(x == NULL)
    return NA_STRING;
  return Rf_mkCharCE(x, CE_UTF8);
}
