#' Version info
#'
#' Shows the version of libgit2 and which features have been enabled.
#'
#' @export
#' @family git
#' @rdname git_config
#' @name git_config
#' @useDynLib gert R_libgit2_config
libgit2_config <- function(){
  res <- .Call(R_libgit2_config)
  names(res) <- c("version", "ssh", "https", "threads")
  res$version <- as.numeric_version(res$version)
  res
}

#' @export
#' @rdname git_config
#' @inheritParams repository
#' @useDynLib gert R_git_config_list
git_config_local <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_config_list, repo)
}

#' @export
#' @rdname git_config
#' @useDynLib gert R_git_config_set
#' @param name setting name
#' @param value setting value, must be string, bool, number or NULL
git_config_local_set <- function(name, value, repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  name <- as.character(name)
  .Call(R_git_config_set, repo, name, value)
}

#' @export
#' @rdname git_config
git_config_global <- function(){
  git_config_local(repo = NULL)
}

#' @export
#' @rdname git_config
git_config_global_set <- function(name, value){
  git_config_local_set(name = name, value = value, repo = NULL)
}
