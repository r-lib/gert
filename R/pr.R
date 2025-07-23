#' GitHub Wrappers
#'
#' Fetch and checkout pull requests.
#'
#' By default `git_fetch_pull_requests` will download all PR branches. To
#' remove these again simply use `git_fetch(prune = TRUE)`.
#'
#' @export
#' @rdname github
#' @inheritParams git_fetch
#' @param pr number with PR to fetch or check out. Use `"*"` to fetch all
#' pull requests.
git_checkout_pull_request <- function(pr = 1, remote = NULL, repo = '.'){
  pr <- as.character(pr)
  if(!length(remote))
    remote <- git_info(repo)$remote
  local_branch <- sprintf("pr/%s", pr)
  remote_branch <- sprintf("%s/pr/%s", remote, pr)
  git_fetch_pull_requests(pr = pr, remote = remote, repo = repo)
  if(git_branch_exists(local_branch, repo = repo)){
    inform("Continuing on existing pr branch: %s", local_branch)
    git_branch_checkout(local_branch, repo = repo)
    git_pull(repo = repo)
  } else {
    inform("Creating new branch: %s", local_branch)
    git_branch_create(local_branch, remote_branch, checkout = TRUE, repo = repo)
  }
}

#' @export
#' @rdname github
git_fetch_pull_requests <- function(pr = '*', remote = NULL, repo = '.'){
  pr <- as.character(pr)
  if(!length(remote))
    remote <- git_info(repo)$remote
  refspec <- sprintf('+refs/pull/%s/head:refs/remotes/%s/pr/%s', pr, remote, pr)
  git_fetch(remote = remote, refspec = refspec, repo = repo)
  invisible(refspec)
}
