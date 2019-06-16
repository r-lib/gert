#include <Rinternals.h>
#include <git2.h>

SEXP R_init_gert(DllInfo *info){
  #if LIBGIT2_VER_MAJOR == 0 && LIBGIT2_VER_MINOR < 22
  git_threads_init();
  #else
  git_libgit2_init();
  #endif
  R_registerRoutines(info, NULL, NULL, NULL, NULL);
  R_useDynamicSymbols(info, TRUE);
  return R_NilValue;
}
