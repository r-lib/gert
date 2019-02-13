#' Create or open a git repository
#'
#' Use [git_init()] to start a new repository or [git_clone()] to download a
#' repository from a remote.
#'
#' @export
#' @rdname repository
#' @name repository
#' @family git
#' @param path local path, must be a non-existing or empty directory
#' @useDynLib gert R_git_repository_init
git_init <- function(path = '.'){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  .Call(R_git_repository_init, path)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_open
git_open <- function(path = '.'){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  .Call(R_git_repository_open, path)
}

#' @export
#' @rdname repository
#' @param repo a path to an existing repository, or a `git_repository` object as
#' returned by [git_open],  [git_init] or [git_clone].
#' @useDynLib gert R_git_repository_info
git_info <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_repository_info, repo)
}

#' @export
print.git_repo_ptr <- function(x, ...){
  info <- git_info(x)
  cat(sprintf("<git repository>: %s[@%s]\n", normalizePath(info$path), info$shorthand))
}
