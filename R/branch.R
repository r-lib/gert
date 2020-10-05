#' Git Branch
#'
#' Create, list, and checkout branches.
#'
#' @export
#' @rdname git_branch
#' @name git_branch
#' @family git
#' @inheritParams git_open
#' @useDynLib gert R_git_branch_current
git_branch <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_branch_current, repo)
}

#' @export
#' @rdname git_branch
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
    all_branches <- subset(git_branch_list(repo = repo), local == FALSE)$name
    candidate <- sub("^[^/]+/", "", all_branches) == branch
    if(sum(candidate) > 1){
      stop(sprintf("Local branch '%s' does not exist and multiple remote candidates found.", branch))
    } else if(sum(candidate) == 0){
      stop(sprintf("No local or remote branch '%s' found.", branch))
    } else {
      remote_branch <- unname(all_branches[candidate])
      inform("Creating local branch %s from %s", branch, remote_branch)
      git_branch_create(branch, remote_branch, checkout = FALSE, repo = repo)
    }
  }
  .Call(R_git_checkout_branch, repo, branch, force)
}

#' @export
#' @rdname git_branch
#' @useDynLib gert R_git_create_branch
#' @param ref string with a branch/tag/commit
#' @param checkout move HEAD to the newly created branch
git_branch_create <- function(branch, ref = "HEAD", checkout = TRUE, repo = '.'){
  repo <- git_open(repo)
  branch <- as.character(branch)
  ref <- as.character(ref)
  checkout <- as.logical(checkout)
  invisible(.Call(R_git_create_branch, repo, branch, ref, checkout))
}

#' @export
#' @rdname git_branch
#' @useDynLib gert R_git_delete_branch
git_branch_delete <- function(branch, repo = '.'){
  repo <- git_open(repo)
  branch <- as.character(branch)
  .Call(R_git_delete_branch, repo, branch)
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
#' @param upstream remote branch from [git_branch_list], for example `"origin/master"`
#' @useDynLib gert R_git_branch_set_upstream
git_branch_set_upstream <- function(upstream, branch = git_branch(repo), repo = '.'){
  repo <- git_open(repo)
  stopifnot(is.character(upstream))
  if(!git_branch_exists(upstream, local = FALSE))
    stop(sprintf("No remote branch found: %s, maybe fetch first?", upstream))
  .Call(R_git_branch_set_upstream, repo, upstream, branch)
  git_repo_path(repo)
}

#' @export
#' @rdname git_branch
#' @param local set FALSE to check for remote branch names.
#' @useDynLib gert R_git_branch_exists
git_branch_exists <- function(branch, local = TRUE, repo = '.'){
  repo <- git_open(repo)
  branch <- as.character(branch)
  local <- as.logical(local)
  .Call(R_git_branch_exists, repo, branch, local)
}

#' @useDynLib gert R_git_branch_set_target
git_branch_set_target <- function(ref, branch, repo){
  repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_branch_set_target, repo, ref)
  git_repo_path(repo)
}
