#' Version info and configurations
#'
#' Get and set git configurations like the `'git config'` command line.
#'
#' The `git_config` and `git_config_set` functions get/set options for
#' a given git repository, whereas `git_config_global` and `git_config_global_set`
#' are for global (user level) git settings, such as your username.
#'
#' Use `libgit2_config()` to show the version of libgit2 and which features
#' are supported in your version of gert (such as ssh remotes).
#'
#' @examples
#' \dontrun{
#' # Set global git settings
#' git_config_global_set("user.name", "Your Name")
#' git_config_global_set("user.email", "your@email.com")
#' git_config_global()
#' }
#' # Show your libgit2 configuration:
#' libgit2_config()
#' @export
#' @rdname git_config
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
#' @param name setting name
#' @param value setting value, must be string, bool, number or NULL
git_config_set <- function(name, value, repo = '.'){
  repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_config_set, repo, name, value)
}

#' @export
#' @rdname git_config
git_config_global_set <- function(name, value){
  .Call(R_git_config_set, NULL, name, value)
}

#' @export
#' @family git
#' @rdname git_config
#' @name git_config
#' @useDynLib gert R_libgit2_config
libgit2_config <- function(){
  res <- .Call(R_libgit2_config)
  names(res) <- c("version", "ssh", "https", "threads", "config.global", "config.system")
  res$version <- as.numeric_version(res$version)
  res
}
