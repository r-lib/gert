#' Push and Pull
#'
#' Use [git_fetch] and [git_push] to sync a local branch with a remote.
#' Here [git_pull] is a wrapper for [git_fetch] which that tries to
#' [fast-forward][git_branch_fast_forward] the local branch after fetching.
#'
#' @export
#' @family git
#' @name fetch
#' @rdname fetch
#' @inheritParams repository
#' @useDynLib gert R_git_remote_fetch
#' @param remote name of a remote listed in [git_remote_list()]
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
#' @rdname fetch
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
#' @rdname fetch
#' @useDynLib gert R_git_repository_clone
#' @param url remote url. Typically starts with `https://github.com/` for public
#' repositories, and `https://yourname@github.com/` or `git@github.com/` for
#' private repos. You will be prompted for a password or pat when needed.
#' @param ssh_key path or object containing your ssh private key. By default we
#' look for keys in `ssh-agent` and [credentials::ssh_key_info].
#' @param branch name of branch to check out locally
#' @param password a string or a callback function to get passwords for authentication
#' or password proctected ssh keys. Defaults to [askpass][askpass::askpass] which
#' checks `getOption('askpass')`.
#' @param verbose display some progress info while downloading
#' @examples {# Clone a small repository
#' git_dir <- file.path(tempdir(), 'antiword')
#' git_clone('https://github.com/ropensci/antiword', git_dir)
#'
#' # Change into the repo directory
#' olddir <- getwd()
#' setwd(git_dir)
#'
#' # Show some stuff
#' git_log()
#' git_branch_list()
#' git_remote_list()
#'
#' # Add a file
#' write.csv(iris, 'iris.csv')
#' git_add('iris.csv')
#'
#' # Commit the change
#' jerry <- git_signature("Jerry", "jerry@hotmail.com")
#' git_commit('added the iris file', author = jerry)
#'
#' # Now in the log:
#' git_log()
#'
#' # Cleanup
#' setwd(olddir)
#' unlink(git_dir, recursive = TRUE)
#' }
git_clone <- function(url, path = NULL, branch = NULL, password = askpass,
                      ssh_key = NULL, verbose = interactive()){
  stopifnot(is.character(url))
  if(!length(path))
    path <- file.path(getwd(), basename(url))
  stopifnot(is.character(path))
  stopifnot(is.null(branch) || is.character(branch))
  verbose <- as.logical(verbose)
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  host <- url_to_host(url)
  key_cb <- make_key_cb(ssh_key, host = host, password = password)
  cred_cb <- make_cred_cb(password = password, verbose = verbose)
  .Call(R_git_repository_clone, url, path, branch, key_cb, cred_cb, verbose)
}

#' @export
#' @rdname fetch
#' @param ... arguments passed to [git_fetch]
git_pull <- function(..., repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  if(!length(info$upstream) || is.na(info$upstream) || !nchar(info$upstream))
    stop("No upstream configured for current HEAD")
  git_fetch(info$remote, ..., repo = repo)
  git_branch_fast_forward(info$upstream, repo = repo)
}
