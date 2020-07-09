#' Git Remotes
#'
#' Add, remove and list remotes.
#'
#' @export
#' @rdname git_remote
#' @name git_remote
#' @family git
#' @inheritParams git_open
#' @param name unique name of the remote
#' @param url server url (https or ssh)
#' @useDynLib gert R_git_remote_list
git_remote_list <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_remote_list, repo)
}

#' @export
#' @rdname git_remote
#' @param refspec optional string with the remote fetch value
#' @useDynLib gert R_git_remote_add
git_remote_add <- function(url, name = "origin", refspec = NULL, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  url <- as.character(url)
  refspec <- as.character(refspec)
  .Call(R_git_remote_add, repo, name, url, refspec)
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_remove
git_remote_remove <- function(name, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_remote_remove, repo, name)
  invisible()
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_info
git_remote_info <- function(name = NULL, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  if(!length(name))
    name <- git_info(repo = repo)$remote
  .Call(R_git_remote_info, repo, name)
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_set_url
git_remote_set_url <- function(url, name = NULL, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  if(!length(name))
    name <- git_info(repo = repo)$remote
  url <- as.character(url)
  .Call(R_git_remote_set_url, repo, name, url)
  invisible()
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_set_pushurl
git_remote_set_pushurl <- function(url, name = NULL , repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  if(!length(name))
    name <- git_info(repo = repo)$remote
  url <- as.character(url)
  .Call(R_git_remote_set_pushurl, repo, name, url)
  invisible()
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_refspecs
git_remote_refspecs <- function(name = NULL, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  if(!length(name))
    name <- git_info(repo = repo)$remote
  .Call(R_git_remote_refspecs, repo, name)
}
