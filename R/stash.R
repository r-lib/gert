#' Stashing changes
#'
#' Temporary stash away changed from the working directory.
#'
#' @export
#' @rdname git_stash
#' @name git_stash
#' @family git
#' @inheritParams git_open
#' @useDynLib gert R_git_stash_save
#' @param message optional message to store the stash
#' @param keep_index changes already added to the index are left intact in
#' the working directory
#' @param include_untracked untracked files are also stashed and then
#' cleaned up from the working directory
#' @param include_ignored ignored files are also stashed and then cleaned
#' up from the working directory
git_stash_save <- function(message = "", keep_index = FALSE, include_untracked = FALSE,
                           include_ignored = FALSE, repo = "."){
  repo <- git_open(repo)
  keep_index <- as.logical(keep_index)
  include_untracked <- as.logical(include_untracked)
  include_ignored <- as.logical(include_ignored)
  .Call(R_git_stash_save, repo, message, keep_index, include_untracked, include_ignored)
}

#' @export
#' @rdname git_stash
#' @useDynLib gert R_git_stash_pop
#' @param index The position within the stash list. 0 points to the
#' most recent stashed state.
git_stash_pop <- function(index = 0, repo = "."){
  repo <- git_open(repo)
  .Call(R_git_stash_pop, repo, index)
}

#' @export
#' @rdname git_stash
#' @useDynLib gert R_git_stash_drop
git_stash_drop <- function(index = 0, repo = "."){
  repo <- git_open(repo)
  .Call(R_git_stash_drop, repo, index)
}

#' @export
#' @rdname git_stash
#' @useDynLib gert R_git_stash_list
git_stash_list <- function(repo = "."){
  repo <- git_open(repo)
  .Call(R_git_stash_list, repo)
}
