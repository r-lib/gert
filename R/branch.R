#' Git Branch
#'
#' Create, and checkout branches.
#'
#' @export
#' @rdname branch
#' @name branch
#' @family git
#' @inheritParams repository
#' @useDynLib gert R_git_branch_list
git_branches <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_branch_list, repo)
}

#' @export
#' @rdname branch
#' @param match pattern to filter tags (use `*` for wildcard)
#' @useDynLib gert R_git_tag_list
git_tags <- function(match = "*", repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  match <- as.character(match)
  .Call(R_git_tag_list, repo, match)
}

#' @export
#' @rdname branch
#' @param branch name of branch to check out
#' @param force ignore conflicts and overwrite modified files
#' @useDynLib gert R_git_checkout_branch
git_checkout <- function(branch, force = FALSE, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  branch <- as.character(branch)
  force <- as.logical(force)
  .Call(R_git_checkout_branch, repo, branch, force)
}

#' @export
#' @rdname branch
#' @useDynLib gert R_git_create_branch
#' @param name string with name of the branch / tag / etc
#' @param ref string with a branch/tag/commit
#' @param checkout move HEAD to the newly created branch
git_branch <- function(name, ref = "HEAD", checkout = TRUE, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  name <- as.character(name)
  ref <- as.character(ref)
  checkout <- as.logical(checkout)
  .Call(R_git_create_branch,repo, name, ref, checkout)
}

#' @export
#' @rdname branch
#' @useDynLib gert R_git_merge_fast_forward
git_fast_forward <- function(ref, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_merge_fast_forward, repo, ref)
}
