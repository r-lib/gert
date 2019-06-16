#' Stage and commit changes
#'
#' @description To commit changes, start with *staging* the files to be included
#' in the commit using [git_add()] or [git_rm()]. Use [git_status()] to see an
#' overview of staged and unstaged changes, and finally [git_commit()] creates
#' a new commit with currently staged files.
#'
#' [git_commit_all] is a shorthand that will automatically stage all new and
#' modified files and then commit.
#'
#' Also [git_log()] shows the most recent commits and [git_ls()] lists
#' all the files that are being tracked in the repository.
#' @export
#' @rdname commit
#' @name commit
#' @family git
#' @inheritParams repository
#' @param message a commit message
#' @param author A [git_signature] value, default is [git_signature_default].
#' @param committer A [git_signature] value.
#' @useDynLib gert R_git_commit_create
git_commit <- function(message, author = NULL, committer = author, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  if(!length(author))
    author <- git_signature_default()
  stopifnot(is.character(message), length(message) == 1)
  status <- git_status(repo)
  if(!any(status$staged))
    stop("No staged files to commit. Run git_add() to select files.")
  .Call(R_git_commit_create, repo, message, author, committer)
}

#' @export
#' @rdname commit
git_commit_all <- function(message, author = NULL, committer = author, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  stat <- git_status(repo)
  changes <- stat$file[!stat$staged && stat$status %in% c("modified", "renamed", "typechange")]
  if(length(changes))
    git_add(changes, repo = repo)
  deleted <- stat$file[!stat$staged && stat$status == "deleted"]
  if(length(deleted))
    git_rm(deleted, repo = repo)
  git_commit(message = message, author = author, committer = committer, repo = repo)
}

#' @export
#' @rdname commit
#' @param files vector of paths relative to the git root directory.
#' Use `"."` to stage all changed files.
#' @param force add files even if in gitignore
#' @useDynLib gert R_git_repository_add
git_add <- function(files, force = FALSE, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  normalizePath(file.path(info$path, files), mustWork = FALSE)
  force <- as.logical(force)
  .Call(R_git_repository_add, repo, files, force)
}

#' @export
#' @rdname commit
#' @useDynLib gert R_git_repository_rm
git_rm <- function(files, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  normalizePath(file.path(info$path, files), mustWork = FALSE)
  .Call(R_git_repository_rm, repo, files)
}

#' @export
#' @rdname commit
#' @useDynLib gert R_git_status_list
git_status <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_status_list, repo)
}

#' @export
#' @rdname commit
#' @useDynLib gert R_git_repository_ls
git_ls <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_repository_ls, repo)
}

#' @export
#' @rdname commit
#' @useDynLib gert R_git_commit_log
#' @param ref string with a branch/tag/commit
#' @param max lookup at most latest n parent commits
git_log <- function(ref = "HEAD", max = 100, repo = "."){
  if(is.character(repo))
    repo <- git_open(repo)
  ref <- as.character(ref)
  max <- as.integer(max)
  .Call(R_git_commit_log, repo, ref, max)
}

#' @export
#' @rdname commit
#' @useDynLib gert R_git_reset
#' @param type must be one of `"soft"`, `"hard"`, or `"mixed"`
git_reset <- function(type = c("soft", "hard", "mixed"), ref = "HEAD", repo = "."){
  typenum <- switch(match.arg(type), soft = 1L, mixed = 2L, hard = 3L)
  if(is.character(repo))
    repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_reset, repo, ref, typenum)
}

#' @export
#' @useDynLib gert R_git_signature_info
print.git_sig_ptr <- function(x, ...){
  info <- git_signature_info(x)
  cat(sprintf("<git signature>: %s at %s\n", info$author, as.character(info$time)))
}

git_signature_info <- function(signature){
  stopifnot(inherits(signature, 'git_sig_ptr'))
  .Call(R_git_signature_info, signature)
}

assert_string <- function(x){
  if(!is.character(x) || !length(x))
    stop("Argument must be a string of length 1")
}
