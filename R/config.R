#' Get or set Git configuration
#'
#' @description
#' Get, set, or unset Git options, as `git config` does on the command line.
#' **Global** settings affect all of a user's Git operations
#' (`git config --global`), whereas **local** settings are scoped to a specific
#' repository (`git config --local`). When both exist, local options always win.
#'
#' ```{r echo = FALSE, results = "asis"}
#' dat <- data.frame(
#'   local = c("`git_config()`", "`git_config_get()`", "`git_config_local_get()`", "`git_config_set()`", "`git_config_unset()`"),
#'   global = c("`git_config_global()`", "`git_config_get()`", "`git_config_global_get()`", "`git_config_global_set()`", "`git_config_global_unset()`"),
#'   row.names = c("get all", "get one (local+global)", "get one (local or global only)", "set", "unset")
#' )
#' knitr::kable(dat, col.names = paste0("**", colnames(dat), "**"))
#' ```
#' @return
#' * `git_config()`: a `data.frame` of the Git options "in force" in the context
#'   of `repo`, one row per option. The `level` column reveals whether the
#'   option is determined from global or local config.
#' * `git_config_global()`: a `data.frame`, as for `git_config()`, except only
#'   for global Git options.
#' * `git_config_get()`: the value of the named option considering both local and
#'   global config (local wins), or `NULL` if unset.
#' * `git_config_local_get()`: as for `git_config_get()`, but restricted to
#'   local (repository-level) config only.
#' * `git_config_global_get()`: as for `git_config_get()`, but for global config only.
#' * `git_config_set()`, `git_config_global_set()`: The previous value(s) of
#'   `name` in local or global config, respectively. If this option was
#'   previously unset, returns `NULL`. Returns invisibly.
#' * `git_config_unset()`, `git_config_global_unset()`: The previous value(s) of
#'   `name` that were unset. Returns invisibly.
#'
#' @note All entries in the `name` column are automatically normalised to
#'   lowercase (see
#'   <https://libgit2.org/libgit2/#HEAD/type/git_config_entry> for details).
#'
#' @examples
#' # Set and inspect a local, custom Git option
#' r <- file.path(tempdir(), "gert-demo")
#' git_init(r)
#'
#' previous <- git_config_set("aaa.bbb", "ccc", repo = r)
#' previous
#' git_config_local_get("aaa.bbb", repo = r)
#'
#' previous <- git_config_set("aaa.bbb", NULL, repo = r)
#' previous
#' git_config_local_get("aaa.bbb", repo = r)
#'
#' # Get a single named option (returns NULL if unset)
#' git_config_get("aaa.bbb", repo = r)
#' git_config_set("aaa.bbb", "ccc", repo = r)
#' git_config_get("aaa.bbb", repo = r)
#'
#' unlink(r, recursive = TRUE)
#'
#' \dontrun{
#' # Set global Git options
#' git_config_global_set("user.name", "Your Name")
#' git_config_global_set("user.email", "your@email.com")
#' git_config_global()
#'
#' # Get a single global option (returns NULL if unset)
#' git_config_global_get("user.name")
#' git_config_global_get("gert.nonexistent")
#' }
#' @export
#' @family git
#' @inheritParams git_open
#' @useDynLib gert R_git_config_list
#' @git config
git_config <- function(repo = '.') {
  repo <- git_open(repo)
  .Call(R_git_config_list, repo)
}

#' @export
#' @rdname git_config
git_config_global <- function() {
  .Call(R_git_config_list, NULL)
}

#' @export
#' @rdname git_config
#' @param name Name of the option to get or set
git_config_get <- function(name, repo = '.') {
  cfg <- git_config(repo = repo)
  if (!name %in% cfg$name) {
    return(NULL)
  }
  cfg$value[cfg$name == name]
}

#' @export
#' @rdname git_config
git_config_local_get <- function(name, repo = '.') {
  cfg <- git_config(repo = repo)
  cfg <- cfg[cfg$level == "local", ]
  if (!name %in% cfg$name) {
    return(NULL)
  }
  cfg$value[cfg$name == name]
}

#' @export
#' @rdname git_config
git_config_global_get <- function(name) {
  cfg <- git_config_global()
  if (!name %in% cfg$name) {
    return(NULL)
  }
  cfg$value[cfg$name == name]
}

#' @export
#' @rdname git_config
#' @useDynLib gert R_git_config_set
#' @param value Value to set. Must be a string, logical, number or `NULL` (to
#'   unset).
#' @param add if `TRUE`, append a new entry for `name` instead of replacing
#'   existing one(s). Equivalent to `git config --add`. Only supported for
#'   string values.
git_config_set <- function(name, value, add = FALSE, repo = '.') {
  if (!is.logical(add) || length(add) != 1) {
    stop("Argument add must be a logical of length 1.", call. = FALSE)
  }
  repo <- git_open(repo)
  name <- as.character(name)
  out <- git_config_local_get(name, repo = repo)
  .Call(R_git_config_set, repo, name, value, add)
  if (length(out) > 0) {
    invisible(out)
  } else {
    invisible(NULL)
  }
}

#' @export
#' @rdname git_config
git_config_global_set <- function(name, value, add = FALSE) {
  out <- git_config_global_get(name)
  .Call(R_git_config_set, NULL, name, value, add)
  if (length(out) > 0) {
    invisible(out)
  } else {
    invisible(NULL)
  }
}

#' @export
#' @rdname git_config
#' @useDynLib gert R_git_config_unset
#' @param pattern Regular expression matching values to unset. Note: the regular
#'   expressions engine used depends on the libgit2 installation; you can check
#'   this using `libgit2_config()$regex_backend`.
#' @param fixed If `TRUE`, only unset values that match `pattern` entirely and
#'   as-is.
git_config_unset <- function(name, pattern, fixed = FALSE, repo = '.')
{
  if (fixed) pattern <- fixed_regex(pattern)
  repo <- git_open(repo)
  prev <- git_config_local_get(name, repo = repo)
  .Call(R_git_config_unset, repo, name, pattern)
  post <- git_config_local_get(name, repo = repo)
  out <- setdiff(prev, post)
  invisible(out)
}

#' @export
#' @rdname git_config
git_config_global_unset <- function(name, pattern, fixed = FALSE)
{
  if (fixed) pattern <- fixed_regex(pattern)
  prev <- git_config_global_get(name)
  .Call(R_git_config_unset, NULL, name, pattern)
  post <- git_config_global_get(name)
  out <- setdiff(prev, post)
  invisible(out)
}

#' Show libgit2 version and capabilities
#'
#' `libgit2_config()` reveals which version of libgit2 gert is using and which
#' features are supported, such whether you are able to use ssh remotes.
#'
#' @export
#' @useDynLib gert R_libgit2_config
#' @examples
#' libgit2_config()
libgit2_config <- function() {
  res <- .Call(R_libgit2_config)
  res$version <- as.numeric_version(res$version)
  res
}

# helper used in git_config_unset()
fixed_regex <- function(string) {
  metachars <- c(".", "\\", "|", "(", ")", "[", "]", "{", "}", "^", "$", "*", "+", "?")
  for (metachar in metachars) {
    string <- gsub(metachar, paste0("\\", metachar), string, fixed = TRUE)
  }
  paste0("^", string, "$")
}

# helpers used in tests
configure_local_user <- function(repo = ".") {
  git_config_set('user.name', "Jerry Johnson", repo = repo)
  git_config_set('user.email', "jerry@gmail.com", repo = repo)
}

local_author <- function(repo = ".") {
  user <- git_signature_parse(git_signature_default(repo))
  sprintf("%s <%s>", user$name, user$email)
}

# helpers used in pkgdown setup
configure_global_user <- function() {
  git_config_global_set('user.name', "Jerry Johnson")
  git_config_global_set('user.email', "jerry@gmail.com")
}

global_user_is_configured <- function() {
  user_name_exists <- !is.null(git_config_global_get("user.name"))
  user_email_exists <- !is.null(git_config_global_get("user.email"))
  user_name_exists && user_email_exists
}

# helpers used in examples

#' Test if a Git user is configured
#'
#' This function exists mostly to guard examples that rely on having a user
#' configured, in order to make commits. `user_is_configured()` makes no
#' distinction between local or global user config.
#'
#' @param repo An optional `repo`, in the sense of [git_open()].
#'
#' @return `TRUE` if `user.name` and `user.email` are set locally or globally,
#'   `FALSE` otherwise.
#'
#' @export
#' @examplesIf interactive()
#' user_is_configured()
user_is_configured <- function(repo = ".") {
  user_name_exists <- !is.null(git_config_get("user.name", repo = repo))
  user_email_exists <- !is.null(git_config_get("user.email", repo = repo))
  user_name_exists && user_email_exists
}
