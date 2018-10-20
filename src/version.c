#include <git2.h>
#include <Rinternals.h>
#include "utils.h"

SEXP R_libgit2_config(){
  char buffer[100];
  snprintf(buffer, 99, "%d.%d.%d", LIBGIT2_VER_MAJOR, LIBGIT2_VER_MINOR, LIBGIT2_VER_REVISION);
  SEXP out = PROTECT(Rf_allocVector(VECSXP, 4));
  SET_VECTOR_ELT(out, 0, Rf_mkString(buffer));
#if AT_LEAST_LIBGIT2(0, 21)
  int features = git_libgit2_features();
  SET_VECTOR_ELT(out, 1, Rf_ScalarLogical(features & GIT_FEATURE_SSH));
  SET_VECTOR_ELT(out, 2, Rf_ScalarLogical(features & GIT_FEATURE_HTTPS));
  SET_VECTOR_ELT(out, 3, Rf_ScalarLogical(features & GIT_FEATURE_THREADS));
#else //I think these features dit not even exit in super old libgit2 
  SET_VECTOR_ELT(out, 1, Rf_ScalarLogical(0));
  SET_VECTOR_ELT(out, 2, Rf_ScalarLogical(0));
  SET_VECTOR_ELT(out, 3, Rf_ScalarLogical(0));  
#endif
  UNPROTECT(1);
  return out;
}
