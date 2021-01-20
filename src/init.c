#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>
#include <git2.h>

/* FIXME:
 Check these declarations against the C/Fortran source code.
 */

/* .Call calls */
extern SEXP R_git_ahead_behind(SEXP, SEXP, SEXP);
extern SEXP R_git_branch_current(SEXP);
extern SEXP R_git_branch_exists(SEXP, SEXP, SEXP);
extern SEXP R_git_branch_list(SEXP, SEXP);
extern SEXP R_git_branch_set_target(SEXP, SEXP);
extern SEXP R_git_branch_set_upstream(SEXP, SEXP, SEXP);
extern SEXP R_git_checkout_branch(SEXP, SEXP, SEXP);
extern SEXP R_git_cherry_pick(SEXP, SEXP);
extern SEXP R_git_commit_create(SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_commit_descendant(SEXP, SEXP, SEXP);
extern SEXP R_git_commit_id(SEXP, SEXP);
extern SEXP R_git_commit_info(SEXP, SEXP);
extern SEXP R_git_commit_log(SEXP, SEXP, SEXP);
extern SEXP R_git_config_list(SEXP);
extern SEXP R_git_config_set(SEXP, SEXP, SEXP);
extern SEXP R_git_conflict_list(SEXP);
extern SEXP R_git_create_branch(SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_delete_branch(SEXP, SEXP);
extern SEXP R_git_diff_list(SEXP, SEXP);
extern SEXP R_git_merge_analysis(SEXP, SEXP);
extern SEXP R_git_merge_cleanup(SEXP);
extern SEXP R_git_merge_find_base(SEXP, SEXP, SEXP);
extern SEXP R_git_merge_parent_heads(SEXP);
extern SEXP R_git_merge_stage(SEXP, SEXP);
extern SEXP R_git_rebase(SEXP, SEXP, SEXP);
extern SEXP R_git_remote_add(SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_remote_add_fetch(SEXP, SEXP, SEXP);
extern SEXP R_git_remote_fetch(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_remote_info(SEXP, SEXP);
extern SEXP R_git_remote_list(SEXP);
extern SEXP R_git_remote_ls(SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_remote_push(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_remote_refspecs(SEXP, SEXP);
extern SEXP R_git_remote_remove(SEXP, SEXP);
extern SEXP R_git_remote_set_pushurl(SEXP, SEXP, SEXP);
extern SEXP R_git_remote_set_url(SEXP, SEXP, SEXP);
extern SEXP R_git_repository_add(SEXP, SEXP, SEXP);
extern SEXP R_git_repository_clone(SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_repository_find(SEXP);
extern SEXP R_git_repository_info(SEXP);
extern SEXP R_git_repository_init(SEXP);
extern SEXP R_git_repository_ls(SEXP);
extern SEXP R_git_repository_open(SEXP, SEXP);
extern SEXP R_git_repository_path(SEXP);
extern SEXP R_git_repository_rm(SEXP, SEXP);
extern SEXP R_git_reset(SEXP, SEXP, SEXP);
extern SEXP R_git_signature_create(SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_signature_default(SEXP);
extern SEXP R_git_signature_parse(SEXP);
extern SEXP R_git_stash_drop(SEXP, SEXP);
extern SEXP R_git_stash_list(SEXP);
extern SEXP R_git_stash_pop(SEXP, SEXP);
extern SEXP R_git_stash_save(SEXP, SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_status_list(SEXP, SEXP);
extern SEXP R_git_submodule_info(SEXP, SEXP);
extern SEXP R_git_submodule_init(SEXP, SEXP, SEXP);
extern SEXP R_git_submodule_list(SEXP);
extern SEXP R_git_submodule_save(SEXP, SEXP);
extern SEXP R_git_submodule_set_to(SEXP, SEXP, SEXP);
extern SEXP R_git_submodule_setup(SEXP, SEXP, SEXP);
extern SEXP R_git_submodule_update(SEXP, SEXP, SEXP);
extern SEXP R_git_tag_create(SEXP, SEXP, SEXP, SEXP);
extern SEXP R_git_tag_delete(SEXP, SEXP);
extern SEXP R_git_tag_list(SEXP, SEXP);
extern SEXP R_libgit2_config();
extern SEXP R_set_cert_locations(SEXP, SEXP);
extern SEXP R_static_libgit2();

static const R_CallMethodDef CallEntries[] = {
  {"R_git_ahead_behind",        (DL_FUNC) &R_git_ahead_behind,        3},
  {"R_git_branch_current",      (DL_FUNC) &R_git_branch_current,      1},
  {"R_git_branch_exists",       (DL_FUNC) &R_git_branch_exists,       3},
  {"R_git_branch_list",         (DL_FUNC) &R_git_branch_list,         2},
  {"R_git_branch_set_target",   (DL_FUNC) &R_git_branch_set_target,   2},
  {"R_git_branch_set_upstream", (DL_FUNC) &R_git_branch_set_upstream, 3},
  {"R_git_checkout_branch",     (DL_FUNC) &R_git_checkout_branch,     3},
  {"R_git_cherry_pick",         (DL_FUNC) &R_git_cherry_pick,         2},
  {"R_git_commit_create",       (DL_FUNC) &R_git_commit_create,       5},
  {"R_git_commit_descendant",   (DL_FUNC) &R_git_commit_descendant,   3},
  {"R_git_commit_id",           (DL_FUNC) &R_git_commit_id,           2},
  {"R_git_commit_info",         (DL_FUNC) &R_git_commit_info,         2},
  {"R_git_commit_log",          (DL_FUNC) &R_git_commit_log,          3},
  {"R_git_config_list",         (DL_FUNC) &R_git_config_list,         1},
  {"R_git_config_set",          (DL_FUNC) &R_git_config_set,          3},
  {"R_git_conflict_list",       (DL_FUNC) &R_git_conflict_list,       1},
  {"R_git_create_branch",       (DL_FUNC) &R_git_create_branch,       4},
  {"R_git_delete_branch",       (DL_FUNC) &R_git_delete_branch,       2},
  {"R_git_diff_list",           (DL_FUNC) &R_git_diff_list,           2},
  {"R_git_merge_analysis",      (DL_FUNC) &R_git_merge_analysis,      2},
  {"R_git_merge_cleanup",       (DL_FUNC) &R_git_merge_cleanup,       1},
  {"R_git_merge_find_base",     (DL_FUNC) &R_git_merge_find_base,     3},
  {"R_git_merge_parent_heads",  (DL_FUNC) &R_git_merge_parent_heads,  1},
  {"R_git_merge_stage",         (DL_FUNC) &R_git_merge_stage,         2},
  {"R_git_rebase",              (DL_FUNC) &R_git_rebase,              3},
  {"R_git_remote_add",          (DL_FUNC) &R_git_remote_add,          4},
  {"R_git_remote_add_fetch",    (DL_FUNC) &R_git_remote_add_fetch,    3},
  {"R_git_remote_fetch",        (DL_FUNC) &R_git_remote_fetch,        7},
  {"R_git_remote_info",         (DL_FUNC) &R_git_remote_info,         2},
  {"R_git_remote_list",         (DL_FUNC) &R_git_remote_list,         1},
  {"R_git_remote_ls",           (DL_FUNC) &R_git_remote_ls,           5},
  {"R_git_remote_push",         (DL_FUNC) &R_git_remote_push,         6},
  {"R_git_remote_refspecs",     (DL_FUNC) &R_git_remote_refspecs,     2},
  {"R_git_remote_remove",       (DL_FUNC) &R_git_remote_remove,       2},
  {"R_git_remote_set_pushurl",  (DL_FUNC) &R_git_remote_set_pushurl,  3},
  {"R_git_remote_set_url",      (DL_FUNC) &R_git_remote_set_url,      3},
  {"R_git_repository_add",      (DL_FUNC) &R_git_repository_add,      3},
  {"R_git_repository_clone",    (DL_FUNC) &R_git_repository_clone,    8},
  {"R_git_repository_find",     (DL_FUNC) &R_git_repository_find,     1},
  {"R_git_repository_info",     (DL_FUNC) &R_git_repository_info,     1},
  {"R_git_repository_init",     (DL_FUNC) &R_git_repository_init,     1},
  {"R_git_repository_ls",       (DL_FUNC) &R_git_repository_ls,       1},
  {"R_git_repository_open",     (DL_FUNC) &R_git_repository_open,     2},
  {"R_git_repository_path",     (DL_FUNC) &R_git_repository_path,     1},
  {"R_git_repository_rm",       (DL_FUNC) &R_git_repository_rm,       2},
  {"R_git_reset",               (DL_FUNC) &R_git_reset,               3},
  {"R_git_signature_create",    (DL_FUNC) &R_git_signature_create,    4},
  {"R_git_signature_default",   (DL_FUNC) &R_git_signature_default,   1},
  {"R_git_signature_parse",     (DL_FUNC) &R_git_signature_parse,     1},
  {"R_git_stash_drop",          (DL_FUNC) &R_git_stash_drop,          2},
  {"R_git_stash_list",          (DL_FUNC) &R_git_stash_list,          1},
  {"R_git_stash_pop",           (DL_FUNC) &R_git_stash_pop,           2},
  {"R_git_stash_save",          (DL_FUNC) &R_git_stash_save,          5},
  {"R_git_status_list",         (DL_FUNC) &R_git_status_list,         2},
  {"R_git_submodule_info",      (DL_FUNC) &R_git_submodule_info,      2},
  {"R_git_submodule_init",      (DL_FUNC) &R_git_submodule_init,      3},
  {"R_git_submodule_list",      (DL_FUNC) &R_git_submodule_list,      1},
  {"R_git_submodule_save",      (DL_FUNC) &R_git_submodule_save,      2},
  {"R_git_submodule_set_to",    (DL_FUNC) &R_git_submodule_set_to,    3},
  {"R_git_submodule_setup",     (DL_FUNC) &R_git_submodule_setup,     3},
  {"R_git_submodule_update",    (DL_FUNC) &R_git_submodule_update,    3},
  {"R_git_tag_create",          (DL_FUNC) &R_git_tag_create,          4},
  {"R_git_tag_delete",          (DL_FUNC) &R_git_tag_delete,          2},
  {"R_git_tag_list",            (DL_FUNC) &R_git_tag_list,            2},
  {"R_libgit2_config",          (DL_FUNC) &R_libgit2_config,          0},
  {"R_set_cert_locations",      (DL_FUNC) &R_set_cert_locations,      2},
  {"R_static_libgit2",          (DL_FUNC) &R_static_libgit2,          0},
  {NULL, NULL, 0}
};

attribute_visible void R_init_gert(DllInfo *dll) {
  git_libgit2_init();
#ifdef _WIN32
  const char *userprofile = getenv("USERPROFILE");
  if(userprofile)
    git_libgit2_opts(GIT_OPT_SET_SEARCH_PATH, GIT_CONFIG_LEVEL_GLOBAL, userprofile);
#endif
  R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
