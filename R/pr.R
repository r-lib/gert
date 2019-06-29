#' GitHub Wrappers
#'
#' Some wrappers for working with Github.
#'
#' @export
#' @inheritParams fetch
#' @param pr number with PR to check out
git_checkout_pull_request <- function(pr = 1, remote = 'origin', repo = '.'){
  local_branch <- sprintf('pr/%d', pr)
  remote_head <- sprintf('pull/%d/head', pr)
  refspec <- paste0(remote_head, ":", local_branch)
  git_fetch(remote = remote, refspec, repo = repo)
  pr_branch <- sprintf('pull/%d/headrefs/heads/%s', pr, local_branch)
  # Todo: set upstream so that we can push?
  git_branch_create(local_branch, pr_branch, repo = repo)
}
