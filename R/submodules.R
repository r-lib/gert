#' Submodules
#'
#' Interact with submodules in the repository.
#'
#' @export
#' @rdname git_submodule
#' @inheritParams git_open
#' @useDynLib gert R_git_submodule_list
git_submodule_list <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_submodule_list, repo)
}

#' @export
#' @rdname git_submodule
#' @useDynLib gert R_git_submodule_init
#' @param submodule name of the submodule
#' @param overwrite overwrite existing entries
git_submodule_init <- function(submodule, overwrite = FALSE, repo = '.'){
  repo <- git_open(repo)
  submodule <- as.character(submodule)
  overwrite <- as.logical(overwrite)
  .Call(R_git_submodule_init, repo, submodule, overwrite)
}

#' @export
#' @rdname git_submodule
#' @useDynLib gert R_git_submodule_update
#' @param submodule name of the submodule
#' @param init automatically initialize before updating
git_submodule_update <- function(submodule, init = TRUE, repo = '.'){
  repo <- git_open(repo)
  submodule <- as.character(submodule)
  init <- as.logical(init)
  .Call(R_git_submodule_update, repo, submodule, init)
}
