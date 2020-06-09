#' Create or discover a local Git repository
#'
#' Use `git_init()` to create a new repository or `git_find()` to discover an
#' existing local repository. Each has the ability to recurse down or up, as
#' appropriate.
#'
#' @export
#' @rdname git_repo
#' @name git_repo
#' @family git
#' @useDynLib gert R_git_repository_init
#' @param path
#' * For `git_init()`: directory of the Git repository to create. If
#'   this directory already exists, it must be empty. If it does not exist, it
#'   is created, along with any intermediate directories that don't yet exist.
#' * For `git_find()`: directory at which to start the search for a Git
#'   repository. If it is not a Git repository, then its parent directory is
#'   consulted, then the parent's parent, and so on, similar to [git_open()].
#' @return The path to the Git repository.
#'
#' @examples
#' # directory does not yet exist
#' r <- tempfile(pattern = "gert")
#' git_init(r)
#' git_find(r)
#'
#' # create a child directory, then a grandchild, then search
#' r_grandchild_dir <- file.path(r, "aaa", "bbb")
#' dir.create(r_grandchild_dir, recursive = TRUE)
#' git_find(r_grandchild_dir)
#'
#' # cleanup
#' unlink(r, recursive = TRUE)
#'
#' # directory exists but is empty
#' r <- tempfile(pattern = "gert")
#' dir.create(r)
#' git_init(r)
#' git_find(r)
#'
#' # cleanup
#' unlink(r, recursive = TRUE)
git_init <- function(path = '.'){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  repo <- .Call(R_git_repository_init, path)
  git_info(repo)$path
}

#' @export
#' @rdname git_repo
#' @useDynLib gert R_git_repository_find
git_find <- function(path = '.'){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  out <- .Call(R_git_repository_find, path)
  dirname(out)
}

#' Open or get metadata about a local repository
#'
#' @description
#' `git_open()` returns a reference to a local repository, which is a
#' prerequisite for Git operations. However, most users do not need to make an
#' explicit call to `git_open()` and nor do they need to handle such references.
#' Most gert functions accept the target repo as a path and open it internally,
#' as necessary.
#'
#' `git_info()` reveals information about a repository, such as the SHA of the
#' most recent commit or its refs.
#'
#' @family git
#' @param repo The repository to target, either as a filepath or as an object of
#'   class `git_repo_ptr`. If `repo` is a filepath and is not a repository, then
#'   its parent directory is considered, then the parent's parent, and so on. To
#'   prevent this recursive search, provide a filepath protected with [I()].
#' @return
#' * `git_open()`: An object of class `git_repo_ptr`.
#' * `git_info()`: A named list.
#' @export
#' @useDynLib gert R_git_repository_open
#'
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
  .Call(R_git_repository_open, path, search)
}

#' @export
#' @rdname git_open
#' @useDynLib gert R_git_repository_info
git_info <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_repository_info, repo)
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
