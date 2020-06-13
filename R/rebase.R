#' Cherry-Pick and Rebase
#'
#' A cherry-pick applies the changes from a given commit (from another branch)
#' onto the current branch. A rebase resets the target branch to another branch
#' (usually the remote upstream) and then re-applies the local changes by
#' cherry-picking each of the local commits that was not yet in the upstream.
#'
#' `git_rebase_list` shows the commits that need to be cherry-picked to rebase
#' `branch` onto `upstream`, including which of these commits will conflict. It
#' does so by performing a dry-run, without saving any actual changes.
#'
#' @export
#' @rdname git_rebase
#' @param upstream branch to which you want to rewind and re-apply your
#' local commits. The default uses the remote upstream branch with the
#' current state on the git server, simulating [git_pull].
#' @param branch target branch containing the commits you want sync with
#' upstream. Defaults to current branch.
#' @inheritParams git_open
#' @useDynLib gert R_git_rebase_list
git_rebase_list <- function(upstream = NULL, branch = "HEAD", repo = '.'){
  repo <- git_open(repo)
  assert_string(branch)
  if(!length(upstream)){
    info <- git_info(repo = repo)
    if(!length(info$upstream) || is.na(info$upstream) || !nchar(info$upstream))
      stop("No upstream configured for current HEAD")
    git_fetch(info$remote, repo = repo)
    upstream <- info$upstream
  }
  .Call(R_git_rebase_list, repo, branch, upstream)
}

#' @export
#' @rdname git_rebase
#' @useDynLib gert R_git_cherry_pick
#' @param commit id of the commit to cherry pick
git_cherry_pick <- function(commit, repo = '.'){
  repo <- git_open(repo)
  assert_string(commit)
  .Call(R_git_cherry_pick, repo, commit)
}
