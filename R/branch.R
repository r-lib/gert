#' Git Branch
#'
#' Create, list, and checkout branches.
#'
#' @export
#' @rdname git_branch
#' @name git_branch
#' @family git
#' @inheritParams git_open
#' @useDynLib gert R_git_branch_list
git_branch_list <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_branch_list, repo)
}

#' @export
#' @rdname git_branch
#' @param branch name of branch to check out
#' @param force ignore conflicts and overwrite modified files
#' @useDynLib gert R_git_checkout_branch
git_branch_checkout <- function(branch, force = FALSE, repo = '.'){
  repo <- git_open(repo)
  branch <- as.character(branch)
  force <- as.logical(force)
  if(!git_branch_exists(branch, repo = repo)){
    all_branches <- git_branch_list(repo = repo)$name
    candidate <- basename(all_branches) == branch
    if(sum(candidate) > 1){
      stop(sprintf("Local branch '%s' does not exist and multiple remote candidates found.", branch))
    } else if(sum(candidate) == 0){
      stop(sprintf("No local or remote branch '%s' found.", branch))
    } else {
      remote_branch <- unname(all_branches[candidate])
      message(sprintf("Creating local branch %s from %s", branch, remote_branch))
      git_branch_create(branch, remote_branch, checkout = FALSE, repo = repo)
    }
  }
  .Call(R_git_checkout_branch, repo, branch, force)
}

#' @export
#' @rdname git_branch
#' @useDynLib gert R_git_create_branch
#' @param name string with name of the branch / tag / etc
#' @param ref string with a branch/tag/commit
#' @param checkout move HEAD to the newly created branch
git_branch_create <- function(name, ref = "HEAD", checkout = TRUE, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  ref <- as.character(ref)
  checkout <- as.logical(checkout)
  invisible(.Call(R_git_create_branch, repo, name, ref, checkout))
}

#' @export
#' @rdname git_branch
#' @useDynLib gert R_git_delete_branch
git_branch_delete <- function(name, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_delete_branch, repo, name)
  git_repo_path(repo)
}

#' @export
#' @rdname git_branch
git_branch_fast_forward <- function(ref, repo = '.'){
  analysis <- git_merge_analysis(ref = ref, repo = repo)
  if(analysis != "fastforward")
    stop("Branch cannot be fast-forwarded. Use git_merge() instead")
  git_branch_set_target(ref = ref, repo = repo)
}

#' @export
#' @rdname git_branch
#' @param remote name of existing remote from [git_remote_list]
#' @useDynLib gert R_git_branch_set_upstream
git_branch_set_upstream <- function(remote = "origin", repo = '.'){
  repo <- git_open(repo)
  branch <- NULL
  .Call(R_git_branch_set_upstream, repo, remote, branch)
  git_repo_path(repo)
}

#' @export
#' @rdname git_branch
#' @param local set FALSE to check for remote branch names.
#' @useDynLib gert R_git_branch_exists
git_branch_exists <- function(name, local = TRUE, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  local <- as.logical(local)
  .Call(R_git_branch_exists, repo, name, local)
}

#' @useDynLib gert R_git_branch_set_target
git_branch_set_target <- function(ref, repo = '.'){
  repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_branch_set_target, repo, ref)
  git_repo_path(repo)
}
