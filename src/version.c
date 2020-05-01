#include <git2.h>
#include <Rinternals.h>
#include "utils.h"

SEXP R_libgit2_config(){
  char buffer[100];
  snprintf(buffer, 99, "%d.%d.%d", LIBGIT2_VER_MAJOR, LIBGIT2_VER_MINOR, LIBGIT2_VER_REVISION);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 6));
  SET_VECTOR_ELT(out, 0, Rf_mkString(buffer));
#if AT_LEAST_LIBGIT2(0, 21)
  int features = git_libgit2_features();
  SET_VECTOR_ELT(out, 1, Rf_ScalarLogical(features & GIT_FEATURE_SSH));
  SET_VECTOR_ELT(out, 2, Rf_ScalarLogical(features & GIT_FEATURE_HTTPS));
  SET_VECTOR_ELT(out, 3, Rf_ScalarLogical(features & GIT_FEATURE_THREADS));
#else
  SET_VECTOR_ELT(out, 1, Rf_ScalarLogical(NA_LOGICAL));
  SET_VECTOR_ELT(out, 2, Rf_ScalarLogical(NA_LOGICAL));
  SET_VECTOR_ELT(out, 3, Rf_ScalarLogical(NA_LOGICAL));
#endif
  git_buf buf = {};
  git_config_find_global(&buf);
  SET_VECTOR_ELT(out, 4, safe_string(buf.ptr));
  git_buf_free(&buf);
  git_config_find_system(&buf);
  SET_VECTOR_ELT(out, 5, safe_string(buf.ptr));
  git_buf_free(&buf);
  UNPROTECT(1);
  return out;
}
