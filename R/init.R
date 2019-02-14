.onAttach <- function(libname, pkgname){
  config <- libgit2_config()
  ssh <- ifelse(config$ssh, "YES", "NO")
  https <- ifelse(config$https, "YES", "NO")
  packageStartupMessage(sprintf(
    "Linking to libgit2 v%s, ssh support: %s, https support: %s",
    as.character(config$version), ssh, https))
  try({
    settings <- git_config_default()
    name <- subset(settings, name == 'user.name')$value
    email <- subset(settings, name == 'user.email')$value
    if(length(name) && length(email)){
      packageStartupMessage(sprintf("Default user: %s <%s>", name, email))
    } else {
      packageStartupMessage("No default user configured")
    }
  })

  # Load tibble (if available) for pretty printing
  if(interactive() && is.null(.getNamespace('tibble'))){
    tryCatch({
      getNamespace('tibble')
    }, error = function(e){})
  }
}
