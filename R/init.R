.onAttach <- function(libname, pkgname){
  config <- libgit2_config()
  ssh <- ifelse(config$ssh, "YES", "NO")
  https <- ifelse(config$https, "YES", "NO")
  packageStartupMessage(sprintf(
    "Linking to libgit2 v%s, ssh support: %s, https support: %s",
    as.character(config$version), ssh, https))

  # Show default user / email
  tryCatch({
    user <- git_signature_default()
    packageStartupMessage(paste("Default user:", user))
  }, error = function(e) {
    packageStartupMessage("No default user configured")
  })


  # Load tibble (if available) for pretty printing
  if(interactive() && is.null(.getNamespace('tibble'))){
    tryCatch({
      getNamespace('tibble')
    }, error = function(e){})
  }
}
