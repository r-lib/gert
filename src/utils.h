#include <git2.h>
#include <Rinternals.h>

void warn_last_msg();
void bail_if(int err, const char *what);
void bail_if_null(void * ptr, const char * what);
SEXP safe_string(const char *x);
SEXP safe_char(const char *x);
SEXP make_strvec(int n, ...);
SEXP make_tibble_and_unprotect(int n, ...);
git_repository *get_git_repository(SEXP ptr);

#define AT_LEAST_LIBGIT2(x,y) (LIBGIT2_VER_MAJOR > x || LIBGIT2_VER_MINOR >= y)

/* Some compatibility macros */
#if !AT_LEAST_LIBGIT2(0, 22)
#define git_remote_lookup(a,b,c) git_remote_load(a,b,c)
#endif
