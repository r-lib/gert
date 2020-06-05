#' Diff and patch
#'
#' A diff is a list of changes between two trees.
#'
#' @export
#' @rdname diff
#' @name diff
#' @family git
#' @inheritParams git_open
#' @inheritParams commit
#' @param parent the commit to compare with
#' @useDynLib gert R_git_diff_patch
git_diff_patch <- function(ref = "HEAD", parent = paste0(ref, '^'), repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_diff_patch, repo, ref, parent)
}
