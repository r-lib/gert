#include <git2.h>
#include <Rinternals.h>
#include "utils.h"

SEXP R_static_libgit2(){
#ifdef STATIC_LIBGIT2
  return Rf_ScalarLogical(1);
#else
  return Rf_ScalarLogical(0);
#endif
}

SEXP R_set_cert_locations(SEXP file, SEXP path){
  const char *cafile = Rf_length(file) ? CHAR(STRING_ELT(file, 0)) : NULL;
  const char *capath = Rf_length(path) ? CHAR(STRING_ELT(path, 0)) : NULL;
  git_libgit2_opts(GIT_OPT_SET_SSL_CERT_LOCATIONS, cafile, capath);
  return R_NilValue;
}

SEXP R_libgit2_config(){
  char buffer[100];
  snprintf(buffer, 99, "%d.%d.%d", LIBGIT2_VER_MAJOR, LIBGIT2_VER_MINOR, LIBGIT2_VER_REVISION);
  SEXP version = PROTECT(Rf_mkString(buffer));
  int features = git_libgit2_features();
  SEXP ssh = PROTECT(Rf_ScalarLogical(features & GIT_FEATURE_SSH));
  SEXP https = PROTECT(Rf_ScalarLogical(features & GIT_FEATURE_HTTPS));
  SEXP threads = PROTECT(Rf_ScalarLogical(features & GIT_FEATURE_THREADS));
  git_buf buf = {0};
  git_config_find_global(&buf);
  SEXP config_global = PROTECT(safe_string(buf.ptr));
  git_buf_free(&buf);
  git_config_find_system(&buf);
  SEXP config_system = PROTECT(safe_string(buf.ptr));
  git_buf_free(&buf);
  git_libgit2_opts(GIT_OPT_GET_SEARCH_PATH, GIT_CONFIG_LEVEL_GLOBAL, &buf);
  SEXP config_search_path = PROTECT(Rf_ScalarString(Rf_mkCharLen(buf.ptr, buf.size)));
  git_buf_free(&buf);
  SEXP out = build_list(7, "version", version, "ssh", ssh, "https", https, "threads", threads,
                    "config.global", config_global, "config.system", config_system,
                    "config.home", config_search_path);
  UNPROTECT(7);
  return out;
}
