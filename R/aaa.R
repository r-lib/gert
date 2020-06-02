.onLoad <- function(libname, pkgname) {

  if (identical(Sys.getenv("IN_PKGDOWN"), "true") &&
      !global_user_is_configured()) {
    configure_global_user()
  }

  invisible()
}
