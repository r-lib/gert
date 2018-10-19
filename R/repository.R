#' Git Repository
#' 
#' First create a repository object via [git_clone], [git_open], or [git_init]. 
#' Then read data with [git_info] or [git_ls].
#' 
#' @export
#' @family git
#' @name repository
#' @rdname repository
#' @useDynLib gert R_git_repository_clone
#' @param url remote url
#' @param path local path, must be a non-existing or empty directory
#' @param branch which branch to clone
#' @param verbose display some progress info while downloading
git_clone <- function(url, path = NULL, branch = NULL, verbose = interactive()){
  stopifnot(is.character(url))
  if(!length(path))
    path <- file.path(getwd(), basename(url))
  stopifnot(is.character(path))
  stopifnot(is.null(branch) || is.character(branch))
  verbose <- as.logical(verbose)
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  .Call(R_git_repository_clone, url, path, branch, verbose)
}

#' @export
#' @rdname repository
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
#' @param repo a `git_repository` object as returned by [git_open],  [git_init] or [git_clone]. 
#' If you pass a string, this will be passed to [git_open] first.
#' @useDynLib gert R_git_repository_info
git_info <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_repository_info, repo)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_ls
git_ls <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)  
  out <- .Call(R_git_repository_ls, repo)
  names(out) <- c("path", "filesize", "mtime")
  df <- data.frame(out, stringsAsFactors = FALSE)
  class(df$mtime) <- c("POSIXct", "POSIXt")
  class(df) <- c("tbl_df", "tbl", "data.frame")
  df
}

#' @export
#' @rdname repository
#' @param files vector of paths relative to the git root directory
#' @useDynLib gert R_git_repository_add
git_add <- function(files, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  normalizePath(file.path(info$path, files), mustWork = TRUE)
  .Call(R_git_repository_add, repo, files)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_rm
git_rm <- function(files, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  normalizePath(file.path(info$path, files), mustWork = TRUE)
  .Call(R_git_repository_rm, repo, files)
}

#' @export
print.git_repository <- function(x, ...){
  info <- git_info(x)
  cat(sprintf("<git_repository>: %s[@%s]\n", normalizePath(info$path), info$shorthand))
}
