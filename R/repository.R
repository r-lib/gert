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
#' @useDynLib gert R_git_repository_clone
#' @param url remote url. Typically starts with `https://github.com/` for public
#' repositories, and `https://yourname@github.com/` or `git@github.com/` for
#' private repos. You will be prompted for a password or pat when needed.
#' @param ssh_key path or object containing your ssh private key
#' @param branch name of branch to check out locally
#' @param password a string or a callback function to get passwords for authentication
#' or password proctected ssh keys.
#' @param verbose display some progress info while downloading
git_clone <- function(url, path = NULL, branch = NULL, password = askpass, ssh_key = my_key(), verbose = interactive()){
  stopifnot(is.character(url))
  if(!length(path))
    path <- file.path(getwd(), basename(url))
  stopifnot(is.character(path))
  stopifnot(is.null(branch) || is.character(branch))
  verbose <- as.logical(verbose)
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  key_cb <- make_key_cb(ssh_key, password = password)
  .Call(R_git_repository_clone, url, path, branch, key_cb, password, verbose)
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
