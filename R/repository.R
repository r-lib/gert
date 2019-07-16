#' Create or open a git repository
#'
#' Use [git_init()] to start a new repository or [git_clone()] to download a
#' repository from a remote.
#'
#' You may use [git_find()] and [git_open()] to explicitly discover and open
#' existing git repositories, but this is usually not needed because all gert
#' functions also take a path argument which implicitly opens the repo.
#'
#' @export
#' @rdname repository
#' @name repository
#' @family git
#' @param path directory of the git repository. For `git_init` or `git_clone`
#' this must be a non-existing or empty directory.
#' @useDynLib gert R_git_repository_init
git_init <- function(path = '.'){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  .Call(R_git_repository_init, path)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_open
git_open <- function(path = '.'){
  if(inherits(path, 'git_repo_ptr')){
    return(path)
  } else if(!is.character(path)){
    stop("repo argument must be a path or an existing repository object")
  }
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  search <- !inherits(path, 'AsIs')
  .Call(R_git_repository_open, path, search)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_find
git_find <- function(path = '.'){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  out <- .Call(R_git_repository_find, path)
  dirname(out)
}

#' @export
#' @rdname repository
#' @param repo a path to an existing repository, or a `git_repository` object as
#' returned by [git_open],  [git_init] or [git_clone].
#' @useDynLib gert R_git_repository_info
git_info <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_repository_info, repo)
}

#' @export
print.git_repo_ptr <- function(x, ...){
  info <- git_info(x)
  cat(sprintf("<git repository>: %s[@%s]\n", normalizePath(info$path), info$shorthand))
}
