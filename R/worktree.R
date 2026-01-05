#' Git Worktrees
#'
#' @description
#' Worktrees represent an alternative location to checkout a branch into. Rather
#' than checking out a branch in your main working tree (which changes the
#' branch you are currently on and forces you to stash any existing work), you
#' can instead check that branch out into a separate _linked worktree_ with its
#' own working tree. Practically, a worktree is just a separate folder that a
#' branch is checked out into, with some extra git metadata that links it back
#' to the main working tree.
#'
#' `git_worktree_list()` returns a data frame of information about the worktrees
#' linked to the main working tree.
#'
#' `git_worktree_exists()` lets you check whether or not a worktree by the name
#' of `name` exists for this `repo`.
#'
#' `git_worktree_path()` returns the file path to the worktree.
#'
#' `git_worktree_add()` creates a new worktree called `name` in the folder
#' pointed to by `path`, and checks `branch` out into it.
#'
#' `git_worktree_remove()` removes a worktree. It does so by deleting the folder
#' provided as the `path` to `git_worktree_add()`, and then cleaning up some git
#' metadata in the main working tree that linked the main working tree to the
#' removed worktree. The `branch` checked out by the worktree is not deleted.
#' Note that this is just a wrapper around `git_worktree_prune()` that sets some
#' desirable defaults for aggressive removal.
#'
#' `git_worktree_prune()` is more cautious than `git_worktree_remove()`. It
#' refuses to prune _valid_ or _locked_ worktrees by default, and also refuses
#' the delete the working tree of the worktree by default (i.e. the folder at
#' `path`). It is automatically run by git itself on periodic intervals to prune
#' outdated worktrees. For interactive usage, you typically want
#' `git_worktree_remove()` instead. `git_worktree_is_prunable()` lets you check
#' if a worktree is prunable with the given options.
#'
#' `git_worktree_lock()`, `git_worktree_unlock()`, and
#' `git_worktree_is_locked()` help you manage whether or not a worktree is
#' _locked_. When a worktree is locked, it is not automatically cleaned up by
#' `git_worktree_prune()` (and git itself) on periodic intervals, even when it
#' looks _invalid_. This is typically only useful when your worktree is on a
#' hard drive that isn't always connected (which can make it look _invalid_ when
#' disconnected, typically making it a candidate for automatic pruning).
#'
#' `git_worktree_is_valid()` checks whether a worktree is valid or not. A
#' _valid_ worktree requires both the git data structures inside the main
#' working tree and this worktree to be present.
#'
#' @name git_worktree
#' @family git
#' @inheritParams git_open
#'
#' @param name The name of the worktree.
#'
#' @examples
#' repo <- git_init(tempfile("gert-examples-repo"))
#'
#' writeLines("hello", file.path(repo, 'hello.txt'))
#' git_add('hello.txt', repo = repo)
#' git_commit("First commit", author = "jeroen <jeroen@blabla.nl>", repo = repo)
#'
#' # Create a branch that is going to be used for the worktree,
#' # but don't check it out!
#' git_branch_create(branch = "branch", checkout = FALSE, repo = repo)
#'
#' path <- tempfile("gert-examples-worktree")
#'
#' # Add a worktree for this branch
#' git_worktree_add(
#'   name = "worktree",
#'   path = path,
#'   branch = "branch",
#'   repo = repo
#' )
#'
#' # Worktree info
#' git_worktree_list(repo = repo)
#'
#' # Note how the files are checked out here
#' dir(path, all.files = TRUE)
#'
#' # And the branch that we are on at `path` is `"branch"`
#' git_branch(repo = path)
#'
#' # Cleanup worktree, and the folder at `path`
#' git_worktree_remove("worktree", repo = repo)
#'
#' # Cleanup repo
#' unlink(repo, recursive = TRUE)
NULL

#' @export
#' @rdname git_worktree
#' @useDynLib gert R_git_worktree_list
git_worktree_list <- function(repo = '.') {
  repo <- git_open(repo)
  .Call(R_git_worktree_list, repo)
}

#' @export
#' @rdname git_worktree
#' @useDynLib gert R_git_worktree_exists
git_worktree_exists <- function(name, repo = '.') {
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_worktree_exists, repo, name)
}

#' @export
#' @rdname git_worktree
#' @useDynLib gert R_git_worktree_path
git_worktree_path <- function(name, repo = ".") {
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_worktree_path, repo, name)
}

#' @export
#' @rdname git_worktree
#' @inheritParams git_branch
#' @param path The path to checkout `branch` into. Importantly, the path up to
#'   the folder name must exist, but the folder name itself must not exist yet
#'   and will be created.
#' @param branch The branch to checkout into `path`.
#' @param lock Whether or not to lock the worktree on creation.
#' @useDynLib gert R_git_worktree_add
git_worktree_add <- function(
  name,
  path,
  branch,
  lock = FALSE,
  local = TRUE,
  repo = "."
) {
  repo <- git_open(repo)
  name <- as.character(name)
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  stopifnot(length(path) == 1L)
  # Avoid footguns where worktree metadata can get created, but branch can't be
  # checked out into the worktree, resulting in broken worktree state requiring
  # manual touching of `.git/` files
  if (dir.exists(path)) {
    stop(sprintf("Path at '%s' must not exist.", path))
  }
  if (!dir.exists(dirname(path))) {
    stop(sprintf("Path at '%s' must exist.", dirname(path)))
  }
  branch <- as.character(branch)
  lock <- as.logical(lock)
  if (!is.null(local)) {
    local <- as.logical(local)
  }
  .Call(R_git_worktree_add, repo, name, path, branch, lock, local)
  invisible()
}

#' @export
#' @rdname git_worktree
git_worktree_remove <- function(name, repo = ".") {
  git_worktree_prune(
    name = name,
    repo = repo,
    prune_valid = TRUE,
    prune_locked = TRUE,
    prune_working_tree = TRUE
  )
}

#' @export
#' @rdname git_worktree
#' @param prune_valid Whether or not to forcibly prune a _valid_ worktree.
#' @param prune_locked Whether or not to forcibly prune a _locked_ worktree.
#' @param prune_working_tree Whether or not to also remove the folder that the
#'   worktree was using, i.e. the `path` supplied to `git_worktree_add()`.
#' @useDynLib gert R_git_worktree_prune
git_worktree_prune <- function(
  name,
  prune_valid = FALSE,
  prune_locked = FALSE,
  prune_working_tree = FALSE,
  repo = "."
) {
  repo <- git_open(repo)
  name <- as.character(name)
  prune_valid <- as.logical(prune_valid)
  prune_locked <- as.logical(prune_locked)
  prune_working_tree <- as.logical(prune_working_tree)
  .Call(
    R_git_worktree_prune,
    repo,
    name,
    prune_valid,
    prune_locked,
    prune_working_tree
  )
  invisible()
}

#' @export
#' @rdname git_worktree
#' @useDynLib gert R_git_worktree_is_prunable
git_worktree_is_prunable <- function(
  name,
  prune_valid = FALSE,
  prune_locked = FALSE,
  repo = "."
) {
  repo <- git_open(repo)
  name <- as.character(name)
  prune_valid <- as.logical(prune_valid)
  prune_locked <- as.logical(prune_locked)
  .Call(
    R_git_worktree_is_prunable,
    repo,
    name,
    prune_valid,
    prune_locked
  )
}

#' @export
#' @rdname git_worktree
#' @useDynLib gert R_git_worktree_lock
git_worktree_lock <- function(name, repo = ".") {
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_worktree_lock, repo, name)
  invisible()
}

#' @export
#' @rdname git_worktree
#' @useDynLib gert R_git_worktree_unlock
git_worktree_unlock <- function(name, repo = ".") {
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_worktree_unlock, repo, name)
  invisible()
}

#' @export
#' @rdname git_worktree
#' @useDynLib gert R_git_worktree_is_locked
git_worktree_is_locked <- function(name, repo = ".") {
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_worktree_is_locked, repo, name)
}

#' @export
#' @rdname git_worktree
#' @useDynLib gert R_git_worktree_is_valid
git_worktree_is_valid <- function(name, repo = ".") {
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_worktree_is_valid, repo, name)
}
