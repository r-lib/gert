#' Git Ignore
#'
#' Test if files would be ignored by `.gitignore` rules
#'
#' @export
#' @rdname git_ignore
#' @name git_ignore
#' @family git
#' @inheritParams git_open
#' @param path A character vector of paths to test within the repo
#' @return A logical vector the same length as `path`, indicating if the
#' paths would be ignored.
#' @useDynLib gert R_git_ignore_path_is_ignored
git_ignore_path_is_ignored <- function(path, repo = '.') {
  repo <- git_open(repo)
  path <- as.character(path)
  .Call(R_git_ignore_path_is_ignored, repo, path)
}
