#' Committing
#'
#' Write operations
#'
#' @export
#' @rdname commit
#' @inheritParams repository
#' @useDynLib gert R_git_signature_default
git_signature_default <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_signature_default, repo)
}

#' @export
#' @rdname commit
#' @inheritParams repository
#' @param message a commit message
#' @param all if TRUE automatically adds all modified (but not new) files
#' @useDynLib gert R_git_commit_create
git_commit <- function(message, all = FALSE, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  stopifnot(is.character(message), length(message) == 1)
  if(isTRUE(all)){
    status <- git_status(repo)
    changed_files <- status$file[status$status %in% c("modified", "renamed", "deleted", "typechange")]
    if(length(changed_files))
      git_add(changed_files, repo = repo)
  }
  status <- git_status(repo)
  if(!any(status$staged))
    stop("No staged files to commit. Run git_add() to select files.")
  .Call(R_git_commit_create, repo, message)
}

