#' Restore working tree files
#'
#' Restores specified paths in the working tree from a given ref, equivalent
#' to `git restore --source=<ref> <path>` (or the older
#' `git checkout <ref> -- <path>`). The ref must be reachable from the
#' current HEAD. By default restores from HEAD, discarding any local
#' modifications.
#'
#' @export
#' @name git_restore
#' @rdname git_restore
#' @family git
#' @inheritParams git_open
#' @param path character vector with file paths to restore, relative to the
#'   repository root. Use `"."` to restore all tracked files.
#' @param ref revision string with a branch/tag/commit to restore from.
#'   Defaults to `"HEAD"`.
#' @return Invisibly, the [git_status()] after restoring.
#' @examplesIf interactive()
#' repo <- file.path(tempdir(), "myrepo")
#' git_init(repo)
#'
#' # Set a user if no default
#' if (!user_is_configured()) {
#'   git_config_set("user.name", "Jerry")
#'   git_config_set("user.email", "jerry@gmail.com")
#' }
#'
#' writeLines("hello", file.path(repo, "hello.txt"))
#' git_add("hello.txt", repo = repo)
#' git_commit("First commit", repo = repo)
#'
#' # Modify the file, then restore it from HEAD
#' writeLines("oops", file.path(repo, "hello.txt"))
#' git_restore("hello.txt", repo = repo)
#' readLines(file.path(repo, "hello.txt"))  # "hello"
#'
#' unlink(repo, recursive = TRUE)
#' @useDynLib gert R_git_restore
git_restore <- function(path, ref = "HEAD", repo = ".") {
  repo <- git_open(repo)
  path <- check_path_tracked(as.character(path), repo)
  ref <- check_ref_in_history(ref, repo)
  .Call(R_git_restore, repo, path, ref)
  invisible(git_status(repo = repo))
}

check_path_tracked <- function(path, repo) {
  if (identical(path, ".")) {
    return(character(0))
  }
  tracked <- git_ls(repo = repo)$path
  untracked <- setdiff(path, tracked)
  if (length(untracked) > 0) {
    stop("Path(s) not tracked by git: ", toString(untracked))
  }
  path
}
