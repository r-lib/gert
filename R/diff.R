#' Git Diff
#'
#' @description
#' View changes in a commit or in the current working directory.
#'
#' * `git_diff()` returns a data frame with information about a commit patch.
#' * `git_diff_patch()` is shortcode for `git_diff()$patch`.
#'
#' @export
#' @inheritParams git_open
#' @family git
#' @param ref a reference such as `"HEAD"`, or a commit id, or `NULL`
#' to the diff the working directory against the repository index.
#' @returns
#' * `git_diff()` returns a data frame.
#' * `git_diff_patch()` returns a character vector.
#' @useDynLib gert R_git_diff_list
git_diff <- function(ref = NULL, repo = '.'){
  repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_diff_list, repo, ref)
}

#' @export
#' @rdname git_diff
git_diff_patch <- function(ref = NULL, repo = '.'){
  git_diff(ref = ref, repo = repo)$patch
}
