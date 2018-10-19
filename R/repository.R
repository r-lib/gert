#' Git Repository
#' 
#' Init, clone or open a repository.
#' 
#' @export
#' @family git
#' @name repository
#' @rdname repository
#' @useDynLib gert R_git_repository_clone
#' @param url remote url
#' @param path local path, must be a non-existing or empty directory
#' @param branch which branch to clone
git_clone <- function(url, path = NULL, branch = NULL){
  stopifnot(is.character(url))
  if(!length(path))
    path <- file.path(getwd(), basename(url))
  stopifnot(is.character(path))
  stopifnot(is.null(branch) || is.character(branch))
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  .Call(R_git_repository_clone, url, path, branch)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_init
git_init <- function(path){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  .Call(R_git_repository_init, path)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_open
git_open <- function(path){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  .Call(R_git_repository_open, path)
}

#' @export
#' @rdname repository
#' @param git_repository a `git_repository` object as returned by [git_open] or 
#' [git_init] or [git_clone]
#' @useDynLib gert R_git_repository_info
git_repository_info <- function(git_repository){
  .Call(R_git_repository_info, git_repository)
}

#' @export
print.git_repository <- function(x, ...){
  info <- git_repository_info(x)
  utils::str(info)
}
