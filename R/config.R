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
#' @useDynLib gert R_git_config_default
git_config_default <- function(){
  .Call(R_git_config_default)
}

#' @export
#' @rdname git_config
#' @inheritParams repository
#' @useDynLib gert R_git_config_repo
git_config_repo <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_config_repo, repo)
}

#' @export
#' @rdname git_config
#' @useDynLib gert R_git_config_default_set
#' @param name setting name
#' @param value setting value, must be string, bool or number
git_config_default_set <- function(name, value){
  name <- as.character(name)
  .Call(R_git_config_default_set, name, value)
}
