#' Version info
#' 
#' Shows the version of libgit2 and which features have been enabled.
#' 
#' @export
#' @rdname version
#' @useDynLib gert R_libgit2_config
git_libgit2_config <- function(){
  res <- .Call(R_libgit2_config)
  names(res) <- c("version", "ssh", "https", "threads")
  res$version <- as.numeric_version(res$version)
  res
}
