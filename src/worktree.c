#include "utils.h"

// Note that `valid` and `locked` only report `TRUE` if the column is known to
// be valid or locked (i.e. unknowable due to an error reports `FALSE`, like
// their `git_worktree_is_valid()` and `git_worktree_is_locked()` counterparts).
SEXP R_git_worktree_list(SEXP ptr) {
  git_strarray worktrees = {0};
  git_repository *repo = get_git_repository(ptr);
  bail_if(git_worktree_list(&worktrees, repo), "git_worktree_list");
  SEXP names = PROTECT(Rf_allocVector(STRSXP, worktrees.count));
  SEXP paths = PROTECT(Rf_allocVector(STRSXP, worktrees.count));
  SEXP valid = PROTECT(Rf_allocVector(LGLSXP, worktrees.count));
  SEXP locked = PROTECT(Rf_allocVector(LGLSXP, worktrees.count));
  for (size_t i = 0; i < worktrees.count; i++) {
    git_worktree *worktree = NULL;
    char* name = worktrees.strings[i];
    SET_STRING_ELT(names, i, safe_char(name));
    if (git_worktree_lookup(&worktree, repo, name) == GIT_OK) {
      SET_STRING_ELT(paths, i, safe_char(git_worktree_path(worktree)));
      SET_LOGICAL_ELT(valid, i, git_worktree_validate(worktree) == GIT_OK);
      SET_LOGICAL_ELT(locked, i, git_worktree_is_locked(NULL, worktree) > 0);
      git_worktree_free(worktree);
    } else {
      SET_STRING_ELT(paths, i, NA_STRING);
      SET_LOGICAL_ELT(valid, i, NA_LOGICAL);
      SET_LOGICAL_ELT(locked, i, NA_LOGICAL);
    }
    free(name);
  }
  SEXP out = build_tibble(
    4,
    "name", names,
    "path", paths,
    "valid", valid,
    "locked", locked
  );
  UNPROTECT(4);
  return out;
}

SEXP R_git_worktree_exists(SEXP ptr, SEXP name) {
  git_repository *repo = get_git_repository(ptr);
  git_worktree *worktree = NULL;
  const int exists = git_worktree_lookup(&worktree, repo, CHAR(STRING_ELT(name, 0))) == GIT_OK;
  git_worktree_free(worktree);
  return Rf_ScalarLogical(exists);
}

SEXP R_git_worktree_path(SEXP ptr, SEXP name) {
  git_repository *repo = get_git_repository(ptr);
  git_worktree *worktree = NULL;
  bail_if(git_worktree_lookup(&worktree, repo, CHAR(STRING_ELT(name, 0))), "git_worktree_lookup");
  SEXP out = PROTECT(safe_string(git_worktree_path(worktree)));
  git_worktree_free(worktree);
  UNPROTECT(1);
  return out;
}

// Throws away reason for why it is not valid. Could add
// `git_worktree_check_valid()` to propagate the reason up.
SEXP R_git_worktree_is_valid(SEXP ptr, SEXP name) {
  git_repository *repo = get_git_repository(ptr);
  git_worktree *worktree = NULL;
  bail_if(git_worktree_lookup(&worktree, repo, CHAR(STRING_ELT(name, 0))), "git_worktree_lookup");
  const int valid = git_worktree_validate(worktree) == GIT_OK;
  git_worktree_free(worktree);
  return Rf_ScalarLogical(valid);
}

// Only `TRUE` if KNOWN to be locked (i.e. both unlocked and unknowable due to
// error return `FALSE`). Throws away reason for why it is not locked. Could add
// the following to round out the family:
// - `git_worktree_is_unlocked()` (only `TRUE` if known to be unlocked)
// - `git_worktree_check_locked()` (errors if unlocked or unknowable due to error)
// - `git_worktree_check_unlocked()` (errors if locked or unknowable due to error)
// Also ignores `reason_for_being_locked`. Could add `git_worktree_locked_reason()`
// if we wanted to expose this.
SEXP R_git_worktree_is_locked(SEXP ptr, SEXP name) {
  git_repository *repo = get_git_repository(ptr);
  git_worktree *worktree = NULL;
  bail_if(git_worktree_lookup(&worktree, repo, CHAR(STRING_ELT(name, 0))), "git_worktree_lookup");
  git_buf *reason_for_being_locked = NULL;
  const int locked = git_worktree_is_locked(reason_for_being_locked, worktree) > 0;
  git_worktree_free(worktree);
  return Rf_ScalarLogical(locked);
}

SEXP R_git_worktree_lock(SEXP ptr, SEXP name) {
  git_repository *repo = get_git_repository(ptr);
  git_worktree *worktree = NULL;
  bail_if(git_worktree_lookup(&worktree, repo, CHAR(STRING_ELT(name, 0))), "git_worktree_lookup");
  const char *reason = NULL;
  const int status = git_worktree_lock(worktree, reason);
  git_worktree_free(worktree);
  bail_if(status, "git_worktree_lock");
  return R_NilValue;
}

SEXP R_git_worktree_unlock(SEXP ptr, SEXP name) {
  git_repository *repo = get_git_repository(ptr);
  git_worktree *worktree = NULL;
  bail_if(git_worktree_lookup(&worktree, repo, CHAR(STRING_ELT(name, 0))), "git_worktree_lookup");
  const int status = git_worktree_unlock(worktree);
  git_worktree_free(worktree);
  if (status == 0) {
    // Success
  } else if (status == 1) {
    // Was already unlocked, treat as success
  } else {
    // Error when trying to unlock
    bail_if(status, "git_worktree_unlock");
  }
  return R_NilValue;
}

// libgit2's `git_worktree_add()` is complicated. It has 3 ways to finalize the
// branch `ref` that is checked out into the worktree. In order of priority:
//
// - If `opts.ref` is set, it must point to an existing branch, and that is
//   checked out.
// - If `opts.checkout_existing` is `1`:
//   - If `name` maps to an existing local branch, then that is checked out.
//   - Otherwise a branch named `name` is created from the repository `HEAD`,
//     and that is checked out.
// - If `opts.checkout_existing` is `0`:
//   - A branch named `name` is created from the repository `HEAD`, and that is
//     checked out. This fails if a pre-existing branch named `name` existed.
//
// https://github.com/libgit2/libgit2/blob/3ac4c0adb1064bad16a7f980d87e7261753fd07e/src/libgit2/worktree.c#L336-L351
//
// Because `git_worktree_prune()` does not delete the branch that
// `git_worktree_add()` might automagically create when `opts.ref` is not
// specified, you can get in very confusing scenarios where `git_worktree_add()`
// creates both a branch and worktree, then you `git_worktree_prune()` that
// worktree, but you can't call `git_worktree_add()` again to re-add that same
// worktree back, because you forgot to delete the existing branch for it and
// you forgot that now you'd need `opts.checkout_existing = 1`. The best
// solution seems to be to only expose the first option from above - i.e.
// require a `branch` name be provided from the user that points to an existing
// branch, and check that out. That way `git_worktree_add()` is solely focused
// on worktree creation, rather than confusingly mixing in branch creation as
// well.
SEXP R_git_worktree_add(
  SEXP ptr,
  SEXP name,
  SEXP path,
  SEXP branch,
  SEXP lock,
  SEXP local
) {
  git_repository *repo = get_git_repository(ptr);
  git_worktree *worktree = NULL;
  git_reference *ref = NULL;
  git_worktree_add_options opts = GIT_WORKTREE_ADD_OPTIONS_INIT;
  opts.lock = LOGICAL_ELT(lock, 0) ? 1 : 0;
  const int status_branch_lookup = git_branch_lookup(
    &ref,
    repo,
    CHAR(STRING_ELT(branch, 0)),
    r_branch_type(local)
  );
  bail_if(status_branch_lookup, "git_branch_lookup");
  opts.ref = ref;
  const int status_worktree_add = git_worktree_add(
    &worktree,
    repo,
    CHAR(STRING_ELT(name, 0)),
    CHAR(STRING_ELT(path, 0)),
    &opts
  );
  // Ensure `ref` is freed if `git_worktree_add()` errors
  git_reference_free(ref);
  git_worktree_free(worktree);
  bail_if(status_worktree_add, "git_worktree_add");
  return R_NilValue;
}

// Only `TRUE` if KNOWN to be prunable (i.e. both unprunable and unknowable due to
// error return `FALSE`). Throws away reason for why it is not prunable. Could add
// `git_worktree_check_prunable()` (errors if unprunable or unknowable due to error)
// to propagate up the error.
//
// Note that the `GIT_WORKTREE_PRUNE_WORKING_TREE` flag is meaningless and unused
// in `git_worktree_is_prunable()`. It is only useful for `git_worktree_prune()`,
// so we don't expose it here.
SEXP R_git_worktree_is_prunable(
  SEXP ptr,
  SEXP name,
  SEXP prune_valid,
  SEXP prune_locked
) {
  git_repository *repo = get_git_repository(ptr);
  git_worktree *worktree = NULL;
  bail_if(git_worktree_lookup(&worktree, repo, CHAR(STRING_ELT(name, 0))), "git_worktree_lookup");
  git_worktree_prune_options opts = GIT_WORKTREE_PRUNE_OPTIONS_INIT;
  if (LOGICAL_ELT(prune_valid, 0)) {
    opts.flags |= GIT_WORKTREE_PRUNE_VALID;
  }
  if (LOGICAL_ELT(prune_locked, 0)) {
    opts.flags |= GIT_WORKTREE_PRUNE_LOCKED;
  }
  const int prunable = git_worktree_is_prunable(worktree, &opts) == 1;
  git_worktree_free(worktree);
  return Rf_ScalarLogical(prunable);
}

SEXP R_git_worktree_prune(
  SEXP ptr,
  SEXP name,
  SEXP prune_valid,
  SEXP prune_locked,
  SEXP prune_working_tree
) {
  git_repository *repo = get_git_repository(ptr);
  git_worktree* worktree = NULL;
  bail_if(git_worktree_lookup(&worktree, repo, CHAR(STRING_ELT(name, 0))), "git_worktree_lookup");
  git_worktree_prune_options opts = GIT_WORKTREE_PRUNE_OPTIONS_INIT;
  if (LOGICAL_ELT(prune_valid, 0)) {
    opts.flags |= GIT_WORKTREE_PRUNE_VALID;
  }
  if (LOGICAL_ELT(prune_locked, 0)) {
    opts.flags |= GIT_WORKTREE_PRUNE_LOCKED;
  }
  if (LOGICAL_ELT(prune_working_tree, 0)) {
    opts.flags |= GIT_WORKTREE_PRUNE_WORKING_TREE;
  }
  const int status = git_worktree_prune(worktree, &opts);
  git_worktree_free(worktree);
  bail_if(status, "git_worktree_prune");
  return R_NilValue;
}
