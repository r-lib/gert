#' Git Diff
#'
#' View changes in a commit or in the current working directory.
#'
#' @export
#' @rdname diff
#' @name diff
#' @family git
#' @param ref a reference such as `"HEAD"`, or a commit id, or `NULL`
#' to the diff the working directory against the repository index.
#' @useDynLib gert R_git_diff_list
git_diff_list <- function(ref = NULL, repo = '.'){
  repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_diff_list, repo, ref)
}

#' @export
#' @rdname diff
git_diff_patch <- function(ref = NULL, repo = '.'){
  git_diff_list(ref = ref, repo = repo)$patch
}
