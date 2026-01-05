#include <git2.h>
#include <Rinternals.h>

#ifndef GIT_OBJECT_COMMIT
#define GIT_OBJECT_COMMIT GIT_OBJ_COMMIT
#endif

void warn_last_msg(void);
void bail_if(int err, const char *what);
void bail_if_null(void * ptr, const char * what);
SEXP string_or_null(const char *x);
SEXP safe_string(const char *x);
SEXP safe_char(const char *x);
SEXP make_strvec(int n, ...);
SEXP build_list(int n, ...);
SEXP list_to_tibble(SEXP df);
SEXP new_git_repository(git_repository *repo);
git_repository *get_git_repository(SEXP ptr);
git_object *resolve_refish(SEXP string, git_repository *repo);
git_commit *ref_to_commit(SEXP ref, git_repository *repo);
git_branch_t r_branch_type(SEXP local);

#define build_tibble(...) list_to_tibble(build_list( __VA_ARGS__))

#define AT_LEAST_LIBGIT2(x,y) (LIBGIT2_VER_MAJOR > x || LIBGIT2_VER_MINOR >= y)

/* Workaround for API change in 1.8.0 and 1.8.1 only: https://github.com/libgit2/libgit2/issues/6793 */
#if LIBGIT2_VER_MAJOR == 1 && LIBGIT2_VER_MINOR == 8 && LIBGIT2_VER_REVISION < 2
#define no_const_workaround (git_commit **)
#else
#define no_const_workaround
#endif

void set_checkout_notify_cb(git_checkout_options *opts);
