#' Merging tools
#'
#' Tools for preparing and performing merge operations. Under construction.
#'
#' @export
#' @family git
#' @rdname merge
#' @inheritParams git_open
#' @param ref branch or commit that you want to merge
#' @param target the branch where you want to merge into. Defaults to current `HEAD`.
#' @useDynLib gert R_git_merge_base
git_merge_base <- function(ref, target = "HEAD", repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_base, repo, ref, target)
}

#' @export
#' @rdname merge
#' @useDynLib gert R_git_merge_analysis
git_merge_analysis <- function(ref, repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_analysis, repo, ref)
}
