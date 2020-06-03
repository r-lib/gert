#' Stage and commit changes
#'
#' @description
#' To commit changes, start by *staging* the files to be included in the commit
#' using `git_add()` or `git_rm()`. Use `git_status()` to see an overview of
#' staged and unstaged changes, and finally `git_commit()` creates a new commit
#' with currently staged files.
#'
#' `git_commit_all()` is a convenience function that automatically stages and
#' commits all modified files. Note that `git_commit_all()` does **not** add
#' new, untracked files to the repository. You need to make an explicit call to
#' `git_add()` to start tracking new files.
#'
#' `git_log()` shows the most recent commits and `git_ls()` lists all the files
#' that are being tracked in the repository.
#'
#' @export
#' @rdname commit
#' @name commit
#' @family git
#' @inheritParams git_open
#' @param message a commit message
#' @param author A [git_signature] value, default is [git_signature_default()].
#' @param committer A [git_signature] value, default is same as `author`
#' @return
#' * `git_status()`, `git_ls()`: A data frame with one row per file
#' * `git_log()`: A data frame with one row per commit
#' * `git_add()`, `git_rm()`, `git_reset()`: An object of class `git_repo_ptr`
#' * `git_commit()`, `git_commit_all()`: A SHA
#' @useDynLib gert R_git_commit_create
#'
#' @examples
#' oldwd <- getwd()
#' repo <- file.path(tempdir(), "myrepo")
#' git_init(repo)
#' setwd(repo)
#'
#' # Set a user if no default
#' if(!user_is_configured()){
#'   git_config_set("user.name", "Jerry")
#'   git_config_set("user.email", "jerry@gmail.com")
#' }
#'
#' writeLines(letters[1:6], "alphabet.txt")
#' git_status()
#'
#' git_add("alphabet.txt")
#' git_status()
#'
#' git_commit("Start alphabet file")
#' git_status()
#'
#' git_ls()
#'
#' git_log()
#'
#' cat(letters[7:9], file = "alphabet.txt", sep = "\n", append = TRUE)
#' git_status()
#'
#' git_commit_all("Add more letters")
#'
#' # cleanup
#' setwd(oldwd)
#' unlink(repo, recursive = TRUE)
git_commit <- function(message, author = NULL, committer = NULL, repo = '.'){
  repo <- git_open(repo)
  if(!length(author))
    author <- git_signature_default(repo)
  if(!length(committer))
    committer <- author
  stopifnot(is.character(message), length(message) == 1)
  status <- git_status(repo)
  if(!any(status$staged))
    stop("No staged files to commit. Run git_add() to select files.")
  .Call(R_git_commit_create, repo, message, author, committer)
}

#' @export
#' @rdname commit
git_commit_all <- function(message, author = NULL, committer = NULL, repo = '.'){
  repo <- git_open(repo)
  unstaged <- subset(git_status(repo), subset = !staged)

  changes <- unstaged$file[unstaged$status %in% c("modified", "renamed", "typechange")]
  if(length(changes))
    git_add(changes, repo = repo)

  deleted <- unstaged$file[unstaged$status == "deleted"]
  if(length(deleted))
    git_rm(deleted, repo = repo)

  new <- unstaged$file[unstaged$status == "new"]
  if (length(new)) {
    message("New, untracked files found, which won't be committed. Use git_add() instead.")
  }

  staged <- subset(git_status(repo), subset = staged)
  if (nrow(staged)) {
    git_commit(message = message, author = author, committer = committer, repo = repo)
  }
}

#' @export
#' @rdname commit
#' @param files vector of paths relative to the git root directory.
#' Use `"."` to stage all changed files.
#' @param force add files even if in gitignore
#' @useDynLib gert R_git_repository_add
git_add <- function(files, force = FALSE, repo = '.'){
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
  repo <- git_open(repo)
  info <- git_info(repo)
  normalizePath(file.path(info$path, files), mustWork = FALSE)
  .Call(R_git_repository_rm, repo, files)
}

#' @export
#' @rdname commit
#' @useDynLib gert R_git_status_list
git_status <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_status_list, repo)
}

#' @export
#' @rdname commit
#' @useDynLib gert R_git_repository_ls
git_ls <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_repository_ls, repo)
}

#' @export
#' @rdname commit
#' @useDynLib gert R_git_commit_log
#' @param ref string with a branch/tag/commit
#' @param max lookup at most latest n parent commits
git_log <- function(ref = "HEAD", max = 100, repo = "."){
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
