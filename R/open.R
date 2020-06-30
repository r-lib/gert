#' Open local repository
#'
#' Returns a pointer to a libgit2 repository object.This function is mainly
#' for internal use; users should simply reference a repository in gert by
#' by the path to the directory.
#'
#' @export
#' @param repo The path to the git repository. If the directory is not a
#' repository, parent directories are considered (see [git_find]). To disable
#' this search, provide the filepath protected with [I()].
#' @return an pointer to the libgit2 repository
#' @useDynLib gert R_git_repository_open
#' @examples
#' r <- tempfile(pattern = "gert")
#' git_init(r)
#' r_ptr <- git_open(r)
#' r_ptr
#' git_open(r_ptr)
#' git_info(r)
#'
#' # cleanup
#' unlink(r, recursive = TRUE)
git_open <- function(repo = '.'){
  if(inherits(repo, 'git_repo_ptr')){
    return(repo)
  } else if(!is.character(repo)){
    stop("repo argument must be a filepath or an existing repository object")
  }
  search <- !inherits(repo, 'AsIs')
  path <- normalizePath(path.expand(repo), mustWork = FALSE)
  out <- .Call(R_git_repository_open, path, search)
  do.call(
    on.exit, list(substitute(rstudio_git_tickle()), add = TRUE),
    envir = parent.frame()
  )
  return(out)
}

#' @export
print.git_repo_ptr <- function(x, ...){
  info <- git_info(x)

  type = "git repository"
  if(info$bare){
    type = paste(type, "(bare)")
  }

  cat(sprintf("<%s>: %s[@%s]\n", type, normalizePath(info$path), info$shorthand))
}

#' @useDynLib gert R_git_repository_path
git_repo_path <- function(repo){
  invisible(.Call(R_git_repository_path, repo))
}

rstudio_git_tickle <- function() {
  if(interactive() && identical(Sys.getenv('RSTUDIO'), '1')){
    if (rstudioapi::hasFun("executeCommand")) {
      rstudioapi::executeCommand("vcsRefresh")
    }
  }
  invisible()
}
