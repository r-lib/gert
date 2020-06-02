#' Merging tools
#'
#' @export
#' @useDynLib gert R_git_merge_base
git_merge_base <- function(one, two = "HEAD", repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_merge_base, repo, one, two)
}
