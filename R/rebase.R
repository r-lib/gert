#' Cherry-Pick and Rebase
#'
#' @description
#' * `git_cherry_pick()` applies the changes from a given commit (from another branch)
#' onto the current branch.
#' *`git_rebase_commit()` resets the branch to the state of another branch (upstream)
#' and then re-applies your local changes by cherry-picking each of your local
#' commits onto the upstream commit history.
#' *`git_rebase_list()` shows your local commits that are missing from the `upstream`
#' history, and if they conflict with upstream changes.
#'
#'
#' @details
#' To find if your local commits are missing from `upstream`,
#' `git_rebase_list()` first performs a rebase dry-run, without committing
#' anything. If there are no conflicts, you can use `git_rebase_commit()`
#' to rewind and rebase your branch onto `upstream`.
#'
#' Gert only support a clean rebase; it never leaves the repository in unfinished
#' "rebasing" state. If conflicts arise, `git_rebase_commit()` will raise an error
#' without making changes.
#'
#' @export
#' @rdname git_rebase
#' @name git_rebase
#' @family git
#' @param upstream branch to which you want to rewind and re-apply your
#' local commits. The default uses the remote upstream branch with the
#' current state on the git server, simulating [git_pull()].
#' @inheritParams git_open
#' @inheritParams git_branch
git_rebase_list <- function(upstream = NULL, repo = '.'){
  git_rebase(upstream = upstream, commit_changes = FALSE, repo = repo)
}

#' @export
#' @rdname git_rebase
git_rebase_commit <- function(upstream = NULL, repo = '.'){
  git_rebase(upstream = upstream, commit_changes = TRUE, repo = repo)
}

#' @useDynLib gert R_git_rebase
git_rebase <- function(upstream, commit_changes, repo){
  repo <- git_open(repo)
  info <- git_info(repo = repo)
  if(!length(upstream)){
    if(!length(info$upstream) || is.na(info$upstream) || !nchar(info$upstream))
      stop("No upstream configured for current HEAD")
    git_fetch(info$remote, repo = repo)
    upstream <- info$upstream
  }
  df <- .Call(R_git_rebase, repo, upstream, commit_changes)
  if(commit_changes){
    new_head <- ifelse(nrow(df) > 0, utils::tail(df$commit, 1), upstream[1])
    git_branch_set_target(ref = new_head, repo = repo)
    inform("Resetting %s to %s", info$shorthand, new_head)
  }
  return(df)
}

#' Reset your repo to a previous state
#'
#' * `git_reset_hard()` resets the index and working tree
#' * `git_reset_soft()` does not touch the index file or the working tree
#' * `git_reset_mixed()` resets the index but not the working tree.
#'
#' @family git
#' @inheritParams git_rebase
#'
#' @export
#' @name git_reset
#' @rdname git_reset
git_reset_hard <- function(ref = "HEAD", repo = "."){
  git_reset("hard", ref = ref, repo = repo)
}

#' @export
#' @rdname git_reset
git_reset_soft <- function(ref = "HEAD", repo = "."){
  git_reset("soft", ref = ref, repo = repo)
}

#' @export
#' @rdname git_reset
git_reset_mixed <- function(ref = "HEAD", repo = "."){
  git_reset("mixed", ref = ref, repo = repo)
}

#' @useDynLib gert R_git_reset
git_reset <- function(type = c("soft", "hard", "mixed"), ref = "HEAD", repo = "."){
  typenum <- switch(match.arg(type), soft = 1L, mixed = 2L, hard = 3L)
  repo <- git_open(repo)
  ref <- as.character(ref)
  .Call(R_git_reset, repo, ref, typenum)
  git_status(repo = repo)
}

#' @export
#' @rdname git_rebase
#' @useDynLib gert R_git_cherry_pick
#' @param commit id of the commit to cherry pick
git_cherry_pick <- function(commit, repo = '.'){
  repo <- git_open(repo)
  assert_string(commit)
  .Call(R_git_cherry_pick, repo, commit)
}

#' @export
#' @rdname git_rebase
#' @useDynLib gert R_git_ahead_behind
git_ahead_behind <- function(upstream = NULL, ref = 'HEAD', repo = '.'){
  repo <- git_open(repo)
  if(!length(upstream))
    upstream <- git_info(repo = repo)$upstream
  if(!length(upstream))
    stop("No upstream set or specified")
  .Call(R_git_ahead_behind, repo, ref, upstream)
}
