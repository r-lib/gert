#' Git Repository
#'
#' First create a repository object via [git_clone], [git_open], or [git_init].
#' Then read data with [git_info] or [git_ls].
#'
#' @export
#' @family git
#' @name repository
#' @rdname repository
#' @useDynLib gert R_git_repository_clone
#' @param url remote url. Typically starts with `https://github.com/` for public
#' repositories, and `https://yourname@github.com/` or `git@github.com/` for
#' private repos. You will be prompted for a password or pat when needed.
#' @param path local path, must be a non-existing or empty directory
#' @param ssh_key path or object containing your ssh private key
#' @param password a string or a callback function to get passwords for authentication
#' or password proctected ssh keys.
#' @param verbose display some progress info while downloading
git_clone <- function(url, path = NULL, branch = NULL, password = askpass, ssh_key = my_key(), verbose = interactive()){
  stopifnot(is.character(url))
  if(!length(path))
    path <- file.path(getwd(), basename(url))
  stopifnot(is.character(path))
  stopifnot(is.null(branch) || is.character(branch))
  verbose <- as.logical(verbose)
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  key_cb <- make_key_cb(ssh_key, password = password)
  .Call(R_git_repository_clone, url, path, branch, key_cb, password, verbose)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_init
git_init <- function(path = '.'){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  .Call(R_git_repository_init, path)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_open
git_open <- function(path = '.'){
  path <- normalizePath(path.expand(path), mustWork = FALSE)
  .Call(R_git_repository_open, path)
}

#' @export
#' @rdname repository
#' @param repo a path to an existing repository, or a `git_repository` object as
#' returned by [git_open],  [git_init] or [git_clone].
#' @useDynLib gert R_git_repository_info
git_info <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_repository_info, repo)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_ls
git_ls <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_repository_ls, repo)
}

#' @export
#' @rdname repository
#' @param files vector of paths relative to the git root directory
#' @param force add files even if in gitignore
#' @useDynLib gert R_git_repository_add
git_add <- function(files, force = FALSE, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  normalizePath(file.path(info$path, files), mustWork = TRUE)
  force <- as.logical(force)
  .Call(R_git_repository_add, repo, files, force)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_repository_rm
git_rm <- function(files, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  normalizePath(file.path(info$path, files), mustWork = FALSE)
  .Call(R_git_repository_rm, repo, files)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_status_list
git_status <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_status_list, repo)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_remotes_list
git_remotes <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_remotes_list, repo)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_remote_fetch
#' @param remote name of a remote listed in [git_remotes()]
#' @param refspec string with mapping between remote and local refs
git_fetch <- function(remote = "origin", refspec = NULL, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  remote <- as.character(remote)
  refspec <- as.character(refspec)
  .Call(R_git_remote_fetch, repo, remote, refspec)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_branch_list
git_branches <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_branch_list, repo)
}

#' @export
#' @rdname repository
#' @param match pattern to filter tags (use `*` for wildcard)
#' @useDynLib gert R_git_tag_list
git_tags <- function(match = "*", repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  match <- as.character(match)
  .Call(R_git_tag_list, repo, match)
}

#' @export
#' @rdname repository
#' @param branch name of branch or commit to check out
#' @useDynLib gert R_git_checkout_branch
git_checkout <- function(branch, force = FALSE, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  branch <- as.character(branch)
  force <- as.logical(force)
  .Call(R_git_checkout_branch, repo, branch, force)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_create_branch
#' @param name string with name of the branch / tag / etc
#' @param checkout switch HEAD to the newly created branch
git_branch <- function(name, ref = "HEAD", checkout = TRUE, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  name <- as.character(name)
  ref <- as.character(ref)
  checkout <- as.logical(checkout)
  .Call(R_git_create_branch,repo, name, ref, checkout)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_commit_log
#' @param ref string with a branch/tag/commit
#' @param max lookup at most latest n parent commits
git_log <- function(max = 100, ref = "HEAD", repo = "."){
  if(is.character(repo))
    repo <- git_open(repo)
  ref <- as.character(ref)
  max <- as.integer(max)
  .Call(R_git_commit_log, repo, max, ref)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_reset
#' @param type must be one of `"soft"`, `"hard"`, or `"mixed"`
git_reset <- function(type = c("soft", "hard", "mixed"), ref = "HEAD", repo = "."){
  typenum <- switch(match.arg(type), soft = 1L, mixed = 2L, hard = 3L)
  if(is.character(repo))
    repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_reset, repo, ref, typenum)
}

#' @export
#' @rdname repository
#' @useDynLib gert R_git_merge_fast_forward
git_fast_forward <- function(ref, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_merge_fast_forward, repo, ref)
}

#' @export
#' @rdname repository
git_pull <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  info <- git_info(repo)
  if(!length(info$upstream) || is.na(info$upstream) || !nchar(info$upstream))
    stop("No upstream configured for current HEAD")
  git_fetch(info$remote, repo = repo)
  git_fast_forward(info$upstream, repo = repo)
}

#' @export
print.git_repo_ptr <- function(x, ...){
  info <- git_info(x)
  cat(sprintf("<git repository>: %s[@%s]\n", normalizePath(info$path), info$shorthand))
}
