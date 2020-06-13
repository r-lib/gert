#' Cherry Pick and Rebase
#'
#' Utilities for cherry-picking commits onto another branch. A rebase
#' operation resets the target branch to a given upstream, and then re-applies
#' your local changes by cherry-picking all your commits back onto the
#' rewinded state.
#'
#' @export
#' @rdname git_rebase
#' @param upstream branch to which you want to rewind and re-apply your
#' local commits. The default uses the remote upstream branch with the
#' current state on the git server, simulating [git_pull].
#' @param target branch containing the commits you want to cherry-pick
#' onto upstream. Defaults to current branch.
#' @inheritParams git_open
#' @useDynLib gert R_git_rebase_info
git_rebase_info <- function(upstream = NULL, target = "HEAD", repo = '.'){
  repo <- git_open(repo)
  assert_string(target)
  if(!length(upstream)){
    info <- git_info(repo = repo)
    if(!length(info$upstream) || is.na(info$upstream) || !nchar(info$upstream))
      stop("No upstream configured for current HEAD")
    git_fetch(info$remote, repo = repo)
    upstream <- info$upstream
  }
  .Call(R_git_rebase_info, repo, target, upstream)
}
