#' Git Remotes
#'
#' First create a repository object via [git_clone], [git_open], or [git_init].
#' Then read data with [git_info] or [git_ls].
#'
#' @export
#' @family git
#' @name remotes
#' @rdname remotes
#' @inheritParams repository
#' @useDynLib gert R_git_remote_fetch
#' @param remote name of a remote listed in [git_remotes()]
#' @param refspec string with mapping between remote and local refs
git_fetch <- function(remote = NULL, refspec = NULL, password = askpass,
                      ssh_key = NULL, verbose = interactive(), repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  if(!length(remote))
    remote <- info$remote
  remote <- as.character(remote)
  if(!length(remote) || is.na(remote))
    stop("No remote is set for this branch")
  if(!length(refspec))
    refspec <- info$head
  refspec <- as.character(refspec)
  verbose <- as.logical(verbose)
  host <- remote_to_host(repo, info$remote)
  key_cb <- make_key_cb(ssh_key, host = host, password = password)
  cred_cb <- make_cred_cb(password = password, verbose = verbose)
  .Call(R_git_remote_fetch, repo, remote, refspec, key_cb, cred_cb, verbose)
}

#' @export
#' @rdname remotes
#' @useDynLib gert R_git_remote_push
git_push <- function(remote = NULL, refspec = NULL, password = askpass,
                     ssh_key = NULL, verbose = interactive(), repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  if(!length(remote))
    remote <- info$remote
  remote <- as.character(remote)
  if(!length(remote) || is.na(remote))
    stop("No remote is set for this branch")
  if(!length(refspec))
    refspec <- info$head
  refspec <- as.character(refspec)
  verbose <- as.logical(verbose)
  host <- remote_to_host(repo, info$remote)
  key_cb <- make_key_cb(ssh_key, host = host, password = password)
  cred_cb <- make_cred_cb(password = password, verbose = verbose)
  .Call(R_git_remote_push, repo, remote, refspec, key_cb, cred_cb, verbose)
}

#' @export
#' @rdname remotes
#' @param ... arguments passed to [git_fetch]
git_pull <- function(repo = '.', ...){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  if(!length(info$upstream) || is.na(info$upstream) || !nchar(info$upstream))
    stop("No upstream configured for current HEAD")
  git_fetch(info$remote, repo = repo, ...)
  git_fast_forward(info$upstream, repo = repo)
}

#' @export
#' @rdname remotes
#' @useDynLib gert R_git_remotes_list
git_remotes <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_remotes_list, repo)
}

#' @export
#' @rdname remotes
#' @useDynLib gert R_git_remote_add
git_remote_add <- function(name, url, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  name <- as.character(name)
  url <- as.character(url)
  .Call(R_git_remote_add, repo, name, url)
}

#' @export
#' @rdname remotes
git_refspecs <- function(repo = '.'){
  remotes <- git_remotes()
  lens <- vapply(remotes$refspecs, length, numeric(1))
  indexes <- rep(seq_len(nrow(remotes)), lens)
  out <- remotes[indexes,]
  out$refspecs <- unlist(remotes$refspecs)
  names(out) <- c("remote", "url", "refspec")
  out
}
