#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <git2.h>

/* FIXME:
 Check these declarations against the C/Fortran source code.
 */

/* .Call calls */
extern SEXP R_git_branch_list(SEXP);
extern SEXP R_git_branch_set_upsteam(SEXP, SEXP, SEXP);
extern SEXP R_git_checkout_branch(SEXP, SEXP, SEXP);
extern SEXP R_git_commit_create(SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_diff_patch(SEXP, SEXP, SEXP);
extern SEXP R_git_commit_log(SEXP, SEXP, SEXP);
extern SEXP R_git_commit_info(SEXP, SEXP);
extern SEXP R_git_config_list(SEXP);
extern SEXP R_git_config_set(SEXP, SEXP, SEXP);
extern SEXP R_git_create_branch(SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_delete_branch(SEXP, SEXP);
extern SEXP R_git_merge_analysis(SEXP, SEXP);
extern SEXP R_git_merge_base(SEXP, SEXP, SEXP);
extern SEXP R_git_merge_cleanup(SEXP);
extern SEXP R_git_merge_fast_forward(SEXP, SEXP);
extern SEXP R_git_merge_stage(SEXP, SEXP);
extern SEXP R_git_remote_add(SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_remote_fetch(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_remote_list(SEXP);
extern SEXP R_git_remote_push(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_remote_remove(SEXP, SEXP);
extern SEXP R_git_remote_set_url(SEXP, SEXP, SEXP);
extern SEXP R_git_repository_add(SEXP, SEXP, SEXP);
extern SEXP R_git_repository_clone(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_repository_find(SEXP);
extern SEXP R_git_repository_info(SEXP);
extern SEXP R_git_repository_init(SEXP);
extern SEXP R_git_repository_ls(SEXP);
extern SEXP R_git_repository_open(SEXP, SEXP);
extern SEXP R_git_repository_rm(SEXP, SEXP);
extern SEXP R_git_reset(SEXP, SEXP, SEXP);
extern SEXP R_git_signature_create(SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_signature_default(SEXP);
extern SEXP R_git_signature_info(SEXP);
extern SEXP R_git_stash_drop(SEXP, SEXP);
extern SEXP R_git_stash_list(SEXP);
extern SEXP R_git_stash_pop(SEXP, SEXP);
extern SEXP R_git_stash_save(SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_status_list(SEXP, SEXP);
extern SEXP R_git_tag_create(SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_tag_delete(SEXP, SEXP);
extern SEXP R_git_tag_list(SEXP, SEXP);
extern SEXP R_libgit2_config();

static const R_CallMethodDef CallEntries[] = {
  {"R_git_branch_list",        (DL_FUNC) &R_git_branch_list,        1},
  {"R_git_branch_set_upsteam", (DL_FUNC) &R_git_branch_set_upsteam, 3},
  {"R_git_checkout_branch",    (DL_FUNC) &R_git_checkout_branch,    3},
  {"R_git_commit_create",      (DL_FUNC) &R_git_commit_create,      4},
  {"R_git_diff_patch",         (DL_FUNC) &R_git_diff_patch,         3},
  {"R_git_commit_log",         (DL_FUNC) &R_git_commit_log,         3},
  {"R_git_commit_info",        (DL_FUNC) &R_git_commit_info,        2},
  {"R_git_config_list",        (DL_FUNC) &R_git_config_list,        1},
  {"R_git_config_set",         (DL_FUNC) &R_git_config_set,         3},
  {"R_git_create_branch",      (DL_FUNC) &R_git_create_branch,      4},
  {"R_git_delete_branch",      (DL_FUNC) &R_git_delete_branch,      2},
  {"R_git_merge_analysis",     (DL_FUNC) &R_git_merge_analysis,     2},
  {"R_git_merge_base",         (DL_FUNC) &R_git_merge_base,         3},
  {"R_git_merge_cleanup",      (DL_FUNC) &R_git_merge_cleanup,      1},
  {"R_git_merge_fast_forward", (DL_FUNC) &R_git_merge_fast_forward, 2},
  {"R_git_merge_stage",        (DL_FUNC) &R_git_merge_stage,        2},
  {"R_git_remote_add",         (DL_FUNC) &R_git_remote_add,         4},
  {"R_git_remote_fetch",       (DL_FUNC) &R_git_remote_fetch,       6},
  {"R_git_remote_list",        (DL_FUNC) &R_git_remote_list,        1},
  {"R_git_remote_push",        (DL_FUNC) &R_git_remote_push,        6},
  {"R_git_remote_remove",      (DL_FUNC) &R_git_remote_remove,      2},
  {"R_git_remote_set_url",     (DL_FUNC) &R_git_remote_set_url,     3},
  {"R_git_repository_add",     (DL_FUNC) &R_git_repository_add,     3},
  {"R_git_repository_clone",   (DL_FUNC) &R_git_repository_clone,   8},
  {"R_git_repository_find",    (DL_FUNC) &R_git_repository_find,    1},
  {"R_git_repository_info",    (DL_FUNC) &R_git_repository_info,    1},
  {"R_git_repository_init",    (DL_FUNC) &R_git_repository_init,    1},
  {"R_git_repository_ls",      (DL_FUNC) &R_git_repository_ls,      1},
  {"R_git_repository_open",    (DL_FUNC) &R_git_repository_open,    2},
  {"R_git_repository_rm",      (DL_FUNC) &R_git_repository_rm,      2},
  {"R_git_reset",              (DL_FUNC) &R_git_reset,              3},
  {"R_git_signature_create",   (DL_FUNC) &R_git_signature_create,   4},
  {"R_git_signature_default",  (DL_FUNC) &R_git_signature_default,  1},
  {"R_git_signature_info",     (DL_FUNC) &R_git_signature_info,     1},
  {"R_git_stash_drop",         (DL_FUNC) &R_git_stash_drop,         2},
  {"R_git_stash_list",         (DL_FUNC) &R_git_stash_list,         1},
  {"R_git_stash_pop",          (DL_FUNC) &R_git_stash_pop,          2},
  {"R_git_stash_save",         (DL_FUNC) &R_git_stash_save,         5},
  {"R_git_status_list",        (DL_FUNC) &R_git_status_list,        2},
  {"R_git_tag_create",         (DL_FUNC) &R_git_tag_create,         4},
  {"R_git_tag_delete",         (DL_FUNC) &R_git_tag_delete,         2},
  {"R_git_tag_list",           (DL_FUNC) &R_git_tag_list,           2},
  {"R_libgit2_config",         (DL_FUNC) &R_libgit2_config,         0},
  {NULL, NULL, 0}
};

void R_init_gert(DllInfo *dll) {
#if LIBGIT2_VER_MAJOR == 0 && LIBGIT2_VER_MINOR < 22
  git_threads_init();
#else
  git_libgit2_init();
#endif
#ifdef _WIN32
  const char *userprofile = getenv("USERPROFILE");
  if(userprofile)
    git_libgit2_opts(GIT_OPT_SET_SEARCH_PATH, GIT_CONFIG_LEVEL_GLOBAL, userprofile);
#endif
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
