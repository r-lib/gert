#' Stashing changes
#'
#' Temporary stash away changed from the working directory.
#'
#' @export
#' @rdname stash
#' @name stash
#' @inheritParams repository
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
  if(is.character(repo))
    repo <- git_open(repo)
  keep_index <- as.logical(keep_index)
  include_untracked <- as.logical(include_untracked)
  include_ignored <- as.logical(include_ignored)
  .Call(R_git_stash_save, repo, message, keep_index, include_untracked, include_ignored)
}
