.onAttach <- function(libname, pkgname){
  config <- libgit2_config()
  ssh <- ifelse(config$ssh, "YES", "NO")
  https <- ifelse(config$https, "YES", "NO")
  packageStartupInform(sprintf(
    "Linking to libgit2 v%s, ssh support: %s",
    as.character(config$version), ssh))
  user_config <- config$config.global
  if(length(user_config) && nchar(user_config)){
    if(is_windows()){
      user_config <- normalizePath(user_config, mustWork = FALSE)
    }
    packageStartupInform(paste0("Global config: ", user_config))
  } else {
    packageStartupInform(paste("No global .gitconfig found in:", config$config.home))
  }
  if(length(config$config.system) && nchar(config$config.system))
    packageStartupInform(paste0("System config: ", config$config.system))
  try({
    settings <- git_config_global()
    name <- subset(settings, name == 'user.name')$value
    email <- subset(settings, name == 'user.email')$value
    if(length(name) || length(email)){
      packageStartupInform(sprintf("Default user: %s <%s>", as_string(name), as_string(email)))
    } else {
      packageStartupInform("No default user configured")
    }
  })

  # Load tibble (if available) for pretty printing
  if(interactive() && is.null(.getNamespace('tibble'))){
    tryCatch({
      getNamespace('tibble')
    }, error = function(e){})
  }
}

.onLoad <- function(libname, pkgname) {

  if (identical(Sys.getenv("IN_PKGDOWN"), "true") &&
      !global_user_is_configured()) {
    configure_global_user()
  }

  invisible()
}

as_string <- function(x){
  ifelse(length(x) > 0, x[1], NA_character_)
}

is_windows <- function(){
  identical(.Platform$OS.type, "windows")
}

inform_impl <- function(message, subclass = NULL) {
  cnd <- structure(
    list(message = paste0(message, "\n")),
    class = c(subclass, "simpleMessage", "message", "condition")
  )
  withRestarts(
    muffleMessage = function() NULL,
    {
      signalCondition(cnd)
      cat(
        conditionMessage(cnd),
        file = if (interactive()) stdout() else stderr()
      )
    }
  )
}


inform <- function(message) inform_impl(message)

packageStartupInform <- function(message) {
  inform_impl(message, subclass = "packageStartupMessage")
}

message <- function(...) {
  stop("Internal error: use inform() instead of message()")
}

packageStartupMessage <- function(...) {
  stop("Internal error: use packageStartupInform() instead of packageStartupMessage()")
}
