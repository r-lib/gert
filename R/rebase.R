#' Cherry-Pick and Rebase
#'
#' @description
#' * `git_cherry_pick()` applies the changes from a given commit (from another branch)
#' onto the current branch.
#'
#' * `git_rebase_commit()` resets the branch to the state of another branch (upstream)
#' and then re-applies your local changes by cherry-picking each of your local
#' commits onto the upstream commit history.
#'
#' * `git_rebase_list()` shows your local commits that are missing from the `upstream`
#' history, and if they conflict with upstream changes.
#'
#' * `git_ahead_behind()` returns a list containing the number of commits ahead and behind
#' comparing `upstream` to `ref`,
#' and the HEAD for respectively the `ref` and `upstream`.
#'
#'
#' @details
#' To find if your local commits are missing from `upstream`,
#' `git_rebase_list()` first performs a rebase dry-run, without committing
#' anything. If there are no conflicts, you can use `git_rebase_commit()`
#' to rewind and rebase your branch onto `upstream`.
#'
#' Gert only support a clean rebase; it never leaves the repository in unfinished
#' "rebasing" state. If conflicts arise, `git_rebase_commit()` will raise an error
#' without making changes.
#'
#' @examplesIf interactive()
#' # Cherry-picking
#' repo <- tempfile()
#' gert::git_init(path = repo)
#' writeLines("hello", file.path(repo, 'hello.txt'))
#' git_add('hello.txt', repo = repo)
#' first_commit <- git_commit(
#'     "First commit",
#'     author = "Jane Doe <jane@example.com>",
#'     repo = repo
#'  )
#' # Create a feature branch with a new commit
#' mainbranch <- gert::git_branch(repo = repo)
#' git_branch_create('feature', repo = repo)
#' write.csv(mtcars, file.path(repo, 'mtcars.csv'))
#' git_add('mtcars.csv', repo = repo)
#' commit <- git_commit(
#'   "Added mtcars.csv file",
#'   author = "Jane Doe <jane@example.com>",
#'   repo = repo
#' )
#' # Cherry pick the commit onto main
#' git_branch_switch(mainbranch, repo = repo)
#' git_log(repo = repo)
#' git_cherry_pick(commit, repo = repo)
#' git_log(repo = repo)
#'
#' # Clean up
#' unlink(repo, recursive = TRUE)
#'
#' # git ahead/behind and git_rebase_list
#' repo <- file.path(tempdir(), 'gert')
#' if (!file.exists(repo)) {
#'  git_clone('https://github.com/r-lib/gert', path = repo)
#'}
#' # Drop some commits, and fast-forward them back
#' git_reset_hard('HEAD~5', repo = repo)
#' file.create(file.path(repo, "bla"))
#' git_add("bla", repo = repo)
#' git_commit("add bla", repo = repo)
#' git_ahead_behind(repo = repo)
#' git_rebase_list(repo = repo)
#'
#' # Clean up
#' unlink(repo, recursive = TRUE)
#' @export
#' @rdname git_rebase
#' @name git_rebase
#' @family git
#' @param upstream branch to which you want to rewind and re-apply your
#' local commits. The default uses the remote upstream branch with the
#' current state on the git server, simulating [git_pull()].
#' @inheritParams git_open
#' @inheritParams git_branch
#' @git rebase
git_rebase_list <- function(upstream = NULL, repo = '.') {
  git_rebase(upstream = upstream, commit_changes = FALSE, repo = repo)
}

#' @export
#' @rdname git_rebase
git_rebase_commit <- function(upstream = NULL, repo = '.') {
  git_rebase(upstream = upstream, commit_changes = TRUE, repo = repo)
}

#' @useDynLib gert R_git_rebase
git_rebase <- function(upstream, commit_changes, repo) {
  repo <- git_open(repo)
  info <- git_info(repo = repo)
  if (!length(upstream)) {
    if (
      !length(info$upstream) || is.na(info$upstream) || !nchar(info$upstream)
    ) {
      stop("No upstream configured for current HEAD")
    }
    git_fetch(info$remote, repo = repo)
    upstream <- info$upstream
  }
  df <- .Call(R_git_rebase, repo, upstream, commit_changes)
  if (commit_changes) {
    new_head <- ifelse(nrow(df) > 0, utils::tail(df$commit, 1), upstream[1])
    git_branch_set_target(ref = new_head, repo = repo)
    inform("Resetting %s to %s", info$shorthand, new_head)
  }
  return(df)
}

#' Reset your repo to a previous state
#'
#' * `git_reset_hard()` resets the index and working tree
#' * `git_reset_soft()` does not touch the index file or the working tree
#' * `git_reset_mixed()` resets the index but not the working tree.
#'
#' @family git
#' @inheritParams git_rebase
#'
#' @export
#' @name git_reset
#' @rdname git_reset
#' @git reset
git_reset_hard <- function(ref = "HEAD", repo = ".") {
  git_reset("hard", ref = ref, repo = repo)
}

#' @export
#' @rdname git_reset
git_reset_soft <- function(ref = "HEAD", repo = ".") {
  git_reset("soft", ref = ref, repo = repo)
}

#' @export
#' @rdname git_reset
git_reset_mixed <- function(ref = "HEAD", repo = ".") {
  git_reset("mixed", ref = ref, repo = repo)
}

#' @useDynLib gert R_git_reset
git_reset <- function(
  type = c("soft", "hard", "mixed"),
  ref = "HEAD",
  repo = "."
) {
  typenum <- switch(match.arg(type), soft = 1L, mixed = 2L, hard = 3L)
  repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_reset, repo, ref, typenum)
  git_status(repo = repo)
}

#' @export
#' @rdname git_rebase
#' @useDynLib gert R_git_cherry_pick
#' @param commit id of the commit to cherry pick
#' @git cherrypick
git_cherry_pick <- function(commit, repo = '.') {
  repo <- git_open(repo)
  assert_string(commit)
  .Call(R_git_cherry_pick, repo, commit)
}

#' @export
#' @rdname git_rebase
#' @useDynLib gert R_git_ahead_behind
#' @git graph
git_ahead_behind <- function(upstream = NULL, ref = 'HEAD', repo = '.') {
  repo <- git_open(repo)
  if (!length(upstream)) {
    upstream <- git_info(repo = repo)$upstream
  }
  if (!length(upstream)) {
    stop("No upstream set or specified")
  }
  .Call(R_git_ahead_behind, repo, ref, upstream)
}
