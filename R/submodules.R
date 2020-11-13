#' Submodules
#'
#' Interact with submodules
#'
#' @export
#' @inheritParams git_open
#' @useDynLib gert R_git_submodule_list
git_submodule_list <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_submodule_list, repo)
}
