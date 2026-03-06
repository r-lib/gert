#' Stage and commit changes
#'
#' @description
#' To commit changes, start by *staging* the files to be included in the commit
#' using `git_add()` or `git_rm()`. Use `git_status()` to see an overview of
#' staged and unstaged changes, and finally `git_commit()` creates a new commit
#' with currently staged files.
#'
#' `git_commit_all()` is a convenience function that automatically stages and
#' commits all modified files. Note that `git_commit_all()` does **not** add
#' new, untracked files to the repository. You need to make an explicit call to
#' `git_add()` to start tracking new files.
#'
#' `git_log()` shows the most recent commits and `git_ls()` lists all the files
#' that are being tracked in the repository. `git_stat_files()`
#'
#' @export
#' @rdname git_commit
#' @name git_commit
#' @family git
#' @inheritParams git_open
#' @param message a commit message
#' @param author A [git_signature] value, default is [git_signature_default()].
#' @param committer A [git_signature] value, default is same as `author`
#' @return
#' * `git_status()`, `git_ls()`: A data frame with one row per file
#' * `git_log()`: A data frame with one row per commit
#' * `git_commit()`, `git_commit_all()`: A SHA
#' @useDynLib gert R_git_commit_create
#' @examples
#' oldwd <- getwd()
#' repo <- file.path(tempdir(), "myrepo")
#' git_init(repo)
#' setwd(repo)
#'
#' # Set a user if no default
#' if(!user_is_configured()){
#'   git_config_set("user.name", "Jerry")
#'   git_config_set("user.email", "jerry@gmail.com")
#' }
#'
#' writeLines(letters[1:6], "alphabet.txt")
#' git_status()
#'
#' git_add("alphabet.txt")
#' git_status()
#'
#' git_commit("Start alphabet file")
#' git_status()
#'
#' git_ls()
#'
#' git_log()
#'
#' cat(letters[7:9], file = "alphabet.txt", sep = "\n", append = TRUE)
#' git_status()
#'
#' git_commit_all("Add more letters")
#'
#' # cleanup
#' setwd(oldwd)
#' unlink(repo, recursive = TRUE)
git_commit <- function(message, author = NULL, committer = NULL, repo = '.') {
  repo <- git_open(repo)
  if (!length(author)) {
    author <- git_signature_default(repo = repo)
  } else {
    git_signature_parse(author) #validate
  }
  if (!length(committer)) {
    committer <- author
  } else {
    git_signature_parse(committer) #validate
  }
  stopifnot(is.character(message), length(message) == 1)
  status <- git_status(repo = repo)
  if (!any(status$staged)) {
    stop("No staged files to commit. Run git_add() to select files.")
  }
  merge_parents <- git_merge_parent_heads(repo = repo)
  .Call(R_git_commit_create, repo, message, author, committer, merge_parents)
}

#' @export
#' @rdname git_commit
git_commit_all <- function(
  message,
  author = NULL,
  committer = NULL,
  repo = '.'
) {
  repo <- git_open(repo)
  unstaged <- git_status(staged = FALSE, repo = repo)

  changes <- unstaged$file[
    unstaged$status %in% c("modified", "renamed", "typechange")
  ]
  if (length(changes)) {
    git_add(changes, repo = repo)
  }

  deleted <- unstaged$file[unstaged$status == "deleted"]
  if (length(deleted)) {
    git_rm(deleted, repo = repo)
  }

  git_commit(
    message = message,
    author = author,
    committer = committer,
    repo = repo
  )
}

#' @export
#' @rdname git_commit
#' @useDynLib gert R_git_commit_info
git_commit_info <- function(ref = "HEAD", repo = '.') {
  repo <- git_open(repo)
  .Call(R_git_commit_info, repo, ref)
}

#' @export
#' @rdname git_commit
#' @useDynLib gert R_git_commit_id
git_commit_id <- function(ref = "HEAD", repo = '.') {
  repo <- git_open(repo)
  .Call(R_git_commit_id, repo, ref)
}

#' @export
#' @rdname git_commit
#' @useDynLib gert R_git_commit_stats
git_commit_stats <- function(ref = "HEAD", repo = '.') {
  repo <- git_open(repo)
  .Call(R_git_commit_stats, repo, ref)
}

#' @export
#' @rdname git_commit
#' @param ancestor a reference to a potential ancestor commit
#' @useDynLib gert R_git_commit_descendant
git_commit_descendant_of <- function(ancestor, ref = 'HEAD', repo = '.') {
  repo <- git_open(repo)
  .Call(R_git_commit_descendant, repo, ref, ancestor)
}

#' @export
#' @rdname git_commit
#' @param files vector of paths relative to the git root directory.
#' Use `"."` to stage all changed files.
#' @param force add files even if in gitignore
#' @useDynLib gert R_git_repository_add
git_add <- function(files, force = FALSE, repo = '.') {
  repo <- git_open(repo)
  info <- git_info(repo)
  normalizePath(file.path(info$path, files), mustWork = FALSE)
  force <- as.logical(force)
  .Call(R_git_repository_add, repo, files, force)
  git_status(repo = repo)
}

#' @export
#' @rdname git_commit
#' @useDynLib gert R_git_repository_rm
git_rm <- function(files, repo = '.') {
  repo <- git_open(repo)
  info <- git_info(repo)
  normalizePath(file.path(info$path, files), mustWork = FALSE)
  .Call(R_git_repository_rm, repo, files)
  git_status(repo = repo)
}

#' @export
#' @rdname git_commit
#' @useDynLib gert R_git_status_list
#' @param staged return only staged (TRUE) or unstaged files (FALSE).
#' Use `NULL` or `NA` to show both (default).
#' @param pathspec character vector with paths to match
git_status <- function(staged = NULL, pathspec = NULL, repo = '.') {
  repo <- git_open(repo)
  staged <- as.logical(staged)
  pathspec <- as.character(pathspec)
  df <- .Call(R_git_status_list, repo, staged, pathspec)
  df[order(df$file), , drop = FALSE]
}

#' @export
#' @rdname git_commit
#' @useDynLib gert R_git_conflict_list
git_conflicts <- function(repo = '.') {
  repo <- git_open(repo)
  .Call(R_git_conflict_list, repo)
}

#' @export
#' @rdname git_commit
#' @useDynLib gert R_git_repository_ls
git_ls <- function(repo = '.', ref = NULL) {
  repo <- git_open(repo)
  if (!length(ref) && isTRUE(git_info(repo = repo)$bare)) {
    ref <- 'HEAD'
  }
  .Call(R_git_repository_ls, repo, ref = ref)
}

#' @export
#' @rdname git_commit
#' @useDynLib gert R_git_commit_log
#' @param ref revision string with a branch/tag/commit value
#' @param max lookup at most latest n parent commits
#' @param after date or timestamp: only include commits starting this date
#' @param path character vector with paths to filter on; only commits that
#' touch these paths are included
git_log <- function(
  ref = "HEAD",
  max = 100,
  after = NULL,
  path = NULL,
  repo = "."
) {
  repo <- git_open(repo)
  ref <- as.character(ref)
  max <- as.integer(max)
  if (length(after)) {
    after <- as.POSIXct(after)
  }
  path <- as.character(path)
  .Call(R_git_commit_log, repo, ref, max, after, path)
}

#' @export
#' @rdname git_commit
#' @useDynLib gert R_git_stat_files
git_stat_files <- function(files, ref = "HEAD", max = NULL, repo = '.') {
  repo <- git_open(repo)
  files <- as.character(files)
  max <- as.integer(max)
  .Call(R_git_stat_files, repo, files, ref, max)
}

#' Revert a commit
#'
#' Applies the inverse of the changes introduced by a given commit, equivalent
#' to `git revert <commit>`. The commit must be reachable from the current HEAD.
#'
#' By default, a new revert commit is created immediately. Set `no_commit = TRUE`
#' to only stage the reverted changes without committing, leaving you free to
#' amend or combine them before calling [git_commit()].
#'
#' @export
#' @name git_revert
#' @rdname git_revert
#' @family git
#' @inheritParams git_open
#' @inheritParams git_commit
#' @inheritParams git_commit_info
#' @param commit a commit reference (SHA, branch name, or revision expression
#'   such as `HEAD~1`) identifying the commit to revert. Must be an ancestor of
#'   the current HEAD.
#' @param no_commit if `TRUE`, stage the reverted changes without creating a
#'   commit. Default is `FALSE`, that is to say, by default a commit is made.
#' @param message a commit message. Similar default to `git revert`.
#' @return The SHA of the new revert commit (invisibly), or `NULL` when
#'   `no_commit = TRUE`.
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
#' writeLines("world", file.path(repo, "hello.txt"))
#' git_add("hello.txt", repo = repo)
#' bad_commit <- git_commit("Second commit", repo = repo)
#'
#' # Default: revert and commit with an auto-generated message
#' git_revert(bad_commit, repo = repo)
#' git_log(repo = repo)
#'
#' # Revert with a custom message
#' writeLines("oops", file.path(repo, "hello.txt"))
#' git_add("hello.txt", repo = repo)
#' bad_commit2 <- git_commit("Third commit", repo = repo)
#' git_revert(bad_commit2, message = "Undo third commit\n", repo = repo)
#' git_log(repo = repo)
#'
#' # Stage the revert without committing
#' writeLines("again", file.path(repo, "hello.txt"))
#' git_add("hello.txt", repo = repo)
#' bad_commit3 <- git_commit("Fourth commit", repo = repo)
#' git_revert(bad_commit3, no_commit = TRUE, repo = repo)
#' git_status(repo = repo)
#'
#' unlink(repo, recursive = TRUE)
#' @useDynLib gert R_git_revert
git_revert <- function(
  ref,
  message = NULL,
  author = NULL,
  committer = NULL,
  no_commit = FALSE,
  repo = '.'
) {
  repo <- git_open(repo)
  assert_string(ref)
  stopifnot(is.logical(no_commit), length(no_commit) == 1)

  sha <- try(git_commit_id(ref, repo = repo), silent = TRUE)
  if (inherits(sha, "try-error")) {
    stop(sprintf(
      "Can't find reference/commit '%s' in the current branch history",
      ref
    ))
  }

  head_sha <- git_commit_id("HEAD", repo = repo)
  sha_descends_from_head <- git_commit_descendant_of(
    ancestor = sha,
    ref = "HEAD",
    repo = repo
  )
  if (sha != head_sha && !sha_descends_from_head) {
    stop(sprintf("commit '%s' is not in the current branch history", commit))
  }

  .Call(R_git_revert, repo, sha)

  if (no_commit) {
    return(NULL)
  }

  if (is.null(message)) {
    message <- revert_message(sha, repo)
  }

  invisible(git_commit(
    message,
    author = author,
    committer = committer,
    repo = repo
  ))
}

assert_string <- function(x) {
  if (!is.character(x) || !length(x)) {
    stop("Argument must be a string of length 1")
  }
}

revert_message <- function(sha, repo) {
  info <- git_commit_info(sha, repo = repo)
  subject <- strsplit(info$message, "\n")[[1]][1]
  subject <- sub("\\s+$", "", subject)

  sprintf(
    'Revert "%s"\n\nThis reverts commit %s.\n',
    subject,
    info$id
  )
}
