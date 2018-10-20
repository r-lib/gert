#include <git2.h>
#include <Rinternals.h>

SEXP R_libgit2_config(){
  char buffer[100];
  int features = git_libgit2_features();
  snprintf(buffer, 99, "%d.%d.%d", LIBGIT2_VER_MAJOR, LIBGIT2_VER_MINOR, LIBGIT2_VER_REVISION);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 4));
  SET_VECTOR_ELT(out, 0, Rf_mkString(buffer));
  SET_VECTOR_ELT(out, 1, Rf_ScalarLogical(features & GIT_FEATURE_SSH));
  SET_VECTOR_ELT(out, 2, Rf_ScalarLogical(features & GIT_FEATURE_HTTPS));
  SET_VECTOR_ELT(out, 3, Rf_ScalarLogical(features & GIT_FEATURE_THREADS));
  UNPROTECT(1);
  return out;
}
