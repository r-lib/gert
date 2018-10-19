#include <Rinternals.h>
#include <git2.h>

SEXP R_init_gert(){
  #if LIBGIT2_VER_MAJOR == 0 && LIBGIT2_VER_MINOR < 22
  git_threads_init();
  #else
  git_libgit2_init();
  #endif
  return R_NilValue;
}
