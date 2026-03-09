#' Create or discover a local Git repository
#'
#' Use `git_init()` to create a new repository or `git_find()` to discover an
#' existing local repository. `git_info()` shows basic information about a
#' repository, such as the SHA and branch of the current HEAD.
#'
#' For `git_init()` the `path` parameter sets the directory of the git repository
#' to create. If this directory already exists, it must be empty. If it does
#' not exist, it is created, along with any intermediate directories that don't
#' yet exist. For `git_find()` the `path` arguments specifies the directory at
#' which to start the search for a git repository. If it is not a git repository
#' itself, then its parent directory is consulted, then the parent's parent, and
#' so on.
#'
#' @export
#' @rdname git_repo
#' @name git_repo
#' @family git
#' @useDynLib gert R_git_repository_init
#' @inheritParams git_open
#' @param path the location of the git repository, see details.
#' @param bare if true, a Git repository without a working directory is created
#' @return The path to the Git repository.
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
git_init <- function(path = '.', bare = FALSE) {
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  repo <- .Call(R_git_repository_init, path, as.logical(bare))
  git_repo_path(repo)
}

#' @export
#' @rdname git_repo
#' @useDynLib gert R_git_repository_find
git_find <- function(path = '.') {
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  out <- .Call(R_git_repository_find, path)
  dirname(out)
}

#' @export
#' @rdname git_repo
#' @useDynLib gert R_git_repository_info
git_info <- function(repo = '.') {
  repo <- git_open(repo)
  .Call(R_git_repository_info, repo)
}
