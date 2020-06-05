#include <git2.h>
#include <Rinternals.h>
#include "utils.h"

SEXP R_libgit2_config(){
  char buffer[100];
  snprintf(buffer, 99, "%d.%d.%d", LIBGIT2_VER_MAJOR, LIBGIT2_VER_MINOR, LIBGIT2_VER_REVISION);
  SEXP version = PROTECT(Rf_mkString(buffer));
#if AT_LEAST_LIBGIT2(0, 21)
  int features = git_libgit2_features();
  SEXP ssh = PROTECT(Rf_ScalarLogical(features & GIT_FEATURE_SSH));
  SEXP https = PROTECT(Rf_ScalarLogical(features & GIT_FEATURE_HTTPS));
  SEXP threads = PROTECT(Rf_ScalarLogical(features & GIT_FEATURE_THREADS));
#else
  SEXP ssh = PROTECT(Rf_ScalarLogical(NA_LOGICAL));
  SEXP https = PROTECT(Rf_ScalarLogical(NA_LOGICAL));
  SEXP threads = PROTECT(Rf_ScalarLogical(NA_LOGICAL));
#endif
  git_buf buf = {0};
  git_config_find_global(&buf);
  SEXP config_global = PROTECT(safe_string(buf.ptr));
  git_buf_free(&buf);
  git_config_find_system(&buf);
  SEXP config_system = PROTECT(safe_string(buf.ptr));
  git_buf_free(&buf);
  return build_list(6, "version", version, "ssh", ssh, "https", https, "threads", threads,
                    "config.global", config_global, "config.system", config_system);
}
