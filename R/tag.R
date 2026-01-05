#' Git Tag
#'
#' Create and list tags.
#'
#' @export
#' @rdname git_tag
#' @name git_tag
#' @family git
#' @inheritParams git_open
#' @param match pattern to filter tags (use `*` for wildcard)
#' @useDynLib gert R_git_tag_list
git_tag_list <- function(match = "*", repo = '.') {
  repo <- git_open(repo)
  match <- as.character(match)
  .Call(R_git_tag_list, repo, match)
}

#' @export
#' @rdname git_tag
#' @param name tag name
#' @param message tag message
#' @param ref target reference to tag
#' @useDynLib gert R_git_tag_create
git_tag_create <- function(name, message, ref = "HEAD", repo = '.') {
  repo <- git_open(repo)
  name <- as.character(name)
  message <- as.character(message)
  .Call(R_git_tag_create, repo, name, message, ref)
}

#' @export
#' @rdname git_tag
#' @useDynLib gert R_git_tag_delete
git_tag_delete <- function(name, repo = '.') {
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_tag_delete, repo, name)
}

#' @export
#' @rdname git_tag
#' @param ... other arguments passed to [git_push]
git_tag_push <- function(name, ..., repo = '.') {
  ref <- paste0('refs/tags/', name)
  git_push(refspec = ref, ..., repo = repo)
}
