#' Git Remotes
#'
#' Add, remove and list remotes.
#'
#' @export
#' @rdname remotes
#' @name remotes
#' @inheritParams repository
#' @param name unique name of the remote
#' @param url server url (https or ssh)
#' @useDynLib gert R_git_remote_list
git_remote_list <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_remote_list, repo)
}

#' @export
#' @rdname remotes
#' @param refspec optional string with the remote fetch value
#' @useDynLib gert R_git_remote_add
git_remote_add <- function(name, url, refspec = NULL, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  url <- as.character(url)
  refspec <- as.character(refspec)
  .Call(R_git_remote_add, repo, name, url, refspec)
}

#' @export
#' @rdname remotes
#' @useDynLib gert R_git_remote_remove
git_remote_remove <- function(name, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_remote_remove, repo, name)
  invisible()
}

#' @export
#' @rdname remotes
git_refspecs <- function(repo = '.'){
  remotes <- git_remote_list()
  lens <- vapply(remotes$refspecs, length, numeric(1))
  indexes <- rep(seq_len(nrow(remotes)), lens)
  out <- remotes[indexes,]
  out$refspecs <- unlist(remotes$refspecs)
  names(out) <- c("remote", "url", "refspec")
  out
}
