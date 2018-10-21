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

.onAttach <- function(libname, pkgname){
  config <- git_libgit2_config()
  ssh <- ifelse(config$ssh, "YES", "NO")
  https <- ifelse(config$https, "YES", "NO")
  packageStartupMessage(sprintf(
    "Linking to libgit2 v%s, ssh support: %s, https support: %s",
    as.character(config$version), ssh, https))
}
