#' Git Remotes
#'
#' List, add, configure, or remove remotes.
#'
#' @export
#' @rdname git_remote
#' @name git_remote
#' @family git
#' @inheritParams git_open
#' @param remote name of an existing remote. Default `NULL` means the remote
#' from the upstream of the current branch.
#' @param url server url (https or ssh)
#' @useDynLib gert R_git_remote_list
git_remote_list <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_remote_list, repo)
}

#' @export
#' @rdname git_remote
#' @param name unique name for the new remote
#' @param refspec optional string with the remote fetch value
#' @useDynLib gert R_git_remote_add
git_remote_add <- function(url, name = "origin", refspec = NULL, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  url <- as.character(url)
  refspec <- as.character(refspec)
  invisible(.Call(R_git_remote_add, repo, name, url, refspec))
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_remove
git_remote_remove <- function(remote, repo = '.'){
  repo <- git_open(repo)
  remote <- as.character(remote)
  .Call(R_git_remote_remove, repo, remote)
  invisible()
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_info
git_remote_info <- function(remote = NULL, repo = '.'){
  repo <- git_open(repo)
  remote <- as.character(remote)
  if(!length(remote))
    remote <- git_info(repo = repo)$remote
  .Call(R_git_remote_info, repo, remote)
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_set_url
git_remote_set_url <- function(url, remote = NULL, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(remote)
  if(!length(remote))
    remote <- git_info(repo = repo)$remote
  url <- as.character(url)
  .Call(R_git_remote_set_url, repo, remote, url)
  invisible()
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_set_pushurl
git_remote_set_pushurl <- function(url, remote = NULL , repo = '.'){
  repo <- git_open(repo)
  remote <- as.character(remote)
  if(!length(remote))
    remote <- git_info(repo = repo)$remote
  url <- as.character(url)
  .Call(R_git_remote_set_pushurl, repo, remote, url)
  invisible()
}

#' @export
#' @rdname git_remote
#' @useDynLib gert R_git_remote_refspecs
git_remote_refspecs <- function(remote = NULL, repo = '.'){
  repo <- git_open(repo)
  remote <- as.character(remote)
  if(!length(remote))
    remote <- git_info(repo = repo)$remote
  .Call(R_git_remote_refspecs, repo, remote)
}

#' @useDynLib gert R_git_remote_add_fetch
git_remote_add_fetch <- function(refspec, remote = NULL, repo = '.'){
  repo <- git_open(repo)
  remote <- as.character(remote)
  if(!length(remote))
    remote <- git_info(repo = repo)$remote
  refspec <- as.character(refspec)
  .Call(R_git_remote_add_fetch, repo, remote, refspec)
}
