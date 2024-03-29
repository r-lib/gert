.onAttach <- function(libname, pkgname){
  config <- libgit2_config()
  ssh <- ifelse(config$ssh, "YES", "NO")
  https <- ifelse(config$https, "YES", "NO")
  packageStartupInform(
    "Linking to libgit2 v%s, ssh support: %s",
    as.character(config$version), ssh)
  user_config <- config$config.global
  if(length(user_config) && nchar(user_config)){
    if(is_windows()){
      user_config <- normalizePath(user_config, mustWork = FALSE)
    }
    packageStartupInform("Global config: %s", user_config)
  } else {
    packageStartupInform("No global .gitconfig found in: %s", config$config.home)
  }
  if(length(config$config.system) && nchar(config$config.system))
    packageStartupInform(paste0("System config: ", config$config.system))
  try({
    settings <- git_config_global()
    name <- subset(settings, name == 'user.name')$value
    email <- subset(settings, name == 'user.email')$value
    if(length(name) || length(email)){
      packageStartupInform("Default user: %s <%s>", as_string(name), as_string(email))
    } else {
      packageStartupInform("No default user configured")
    }
  })
}

.onLoad <- function(libname, pkgname) {
  # This should usually correspond to 'openssl version -d'
  if(isTRUE(have_static_libgit2())){
    certpath <- find_cert_dir()
    if(length(certpath)){
      cafile <- file.path(dirname(certpath), 'cert.pem')
      if(!file.exists(cafile))
        cafile <- NULL
      set_cert_locations(cafile, certpath)
    } else {
      warning("Unable to find directory with certificates", immediate. = TRUE)
    }
  }

  # Load tibble (if available) for pretty printing
  if(interactive() && is.null(.getNamespace('tibble'))){
    tryCatch({
      getNamespace('tibble')
    }, error = function(e){})
  }

  invisible()
}

as_string <- function(x){
  ifelse(length(x) > 0, x[1], NA_character_)
}

is_windows <- function(){
  identical(.Platform$OS.type, "windows")
}

is_solaris <- function(){
  isTRUE(grepl('solaris', R.version$platform, ignore.case = TRUE))
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


inform <- function(...) inform_impl(sprintf(...), subclass = "gertMessage")

packageStartupInform <- function(...) {
  inform_impl(sprintf(...), subclass = c("gertMessage", "packageStartupMessage"))
}

message <- function(...) {
  stop("Internal error: use inform() instead of message()")
}

packageStartupMessage <- function(...) {
  stop("Internal error: use packageStartupInform() instead of packageStartupMessage()")
}

# libgit2 wants all paths utf-8
normalizePath <- function(...){
  enc2utf8(base::normalizePath(...))
}
