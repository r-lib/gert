#' Get or set Git configuration
#'
#' @description
#' Get or set Git options, as `git config` does on the command line. **Global**
#' settings affect all of a user's Git operations (`git config --global`),
#' whereas **local** settings are scoped to a specific repository (`git config
#' --local`). When both exist, local options always win. Four functions address
#' the four possible combinations of getting vs setting and global vs. local.
#'
#' ```{r echo = FALSE, results = "asis"}
#' dat <- data.frame(
#'   local = c("`git_config()`", "`git_config_set()`"),
#'   global = c("`git_config_global()`", "`git_config_global_set()`"),
#'   row.names = c("get", "set")
#' )
#' knitr::kable(dat, col.names = paste0("**", colnames(dat), "**"))
#' ```
#' @return
#' * `git_config()`: a `data.frame` of the Git options "in force" in the context
#'   of `repo`, one row per option. The `level` column reveals whether the
#'   option is determined from global or local config.
#' * `git_config_global()`: a `data.frame`, as for `git_config()`, except only
#'   for global Git options.
#' * `git_config_set()`, `git_config_global_set()`: The previous value of
#'   `name` in local or global config, respectively. If this option was
#'   previously unset, returns `NULL`. Returns invisibly.
#'
#' @examples
#' # Set and inspect a local, custom Git option
#' r <- file.path(tempdir(), "gert-demo")
#' git_init(r)
#'
#' previous <- git_config_set("aaa.bbb", "ccc", repo = r)
#' previous
#' cfg <- git_config(repo = r)
#' subset(cfg, level == "local")
#' cfg$value[cfg$name == "aaa.bbb"]
#'
#' previous <- git_config_set("aaa.bbb", NULL, repo = r)
#' previous
#' cfg <- git_config(repo = r)
#' subset(cfg, level == "local")
#' cfg$value[cfg$name == "aaa.bbb"]
#'
#' unlink(r, recursive = TRUE)
#'
#' \dontrun{
#' # Set global Git options
#' git_config_global_set("user.name", "Your Name")
#' git_config_global_set("user.email", "your@email.com")
#' git_config_global()
#' }
#' @export
#' @family git
#' @inheritParams git_open
#' @useDynLib gert R_git_config_list
git_config <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_config_list, repo)
}

#' @export
#' @rdname git_config
git_config_global <- function(){
  .Call(R_git_config_list, NULL)
}

#' @export
#' @rdname git_config
#' @useDynLib gert R_git_config_set
#' @param name Name of the option to set
#' @param value Value to set. Must be a string, logical, number or `NULL` (to
#'   unset).
git_config_set <- function(name, value, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  orig_cfg <- git_config(repo = repo)
  out <- orig_cfg$value[orig_cfg$name == name & orig_cfg$level == "local"]
  .Call(R_git_config_set, repo, name, value)
  if (length(out) > 0) {
    invisible(out)
  } else {
    invisible(NULL)
  }
}

#' @export
#' @rdname git_config
git_config_global_set <- function(name, value){
  orig_cfg <- git_config_global()
  out <- orig_cfg$value[orig_cfg$name == name]
  .Call(R_git_config_set, NULL, name, value)
  if (length(out) > 0) {
    invisible(out)
  } else {
    invisible(NULL)
  }
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
libgit2_config <- function(){
  res <- .Call(R_libgit2_config)
  res$version <- as.numeric_version(res$version)
  res
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
  cfg <- git_config_global()
  user_name_exists <- any(cfg$name == "user.name")
  user_email_exists <- any(cfg$name == "user.email")
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
#' @examples
#' user_is_configured()
user_is_configured <- function(repo = ".") {
  cfg <- tryCatch(
    git_config(repo),
    error = function(e) git_config_global()
  )
  user_name_exists <- any(cfg$name == "user.name")
  user_email_exists <- any(cfg$name == "user.email")
  user_name_exists && user_email_exists
}
