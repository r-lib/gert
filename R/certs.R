# This is only used for static builds and on Solaris.
# It is not needed if you're using a system libgit2.
#' @useDynLib gert R_static_libgit2
have_static_libgit2 <- function(){
  .Call(R_static_libgit2)
}

#' @useDynLib gert R_set_cert_locations
set_cert_locations <- function(file, path){
  file <- as.character(file)
  path <- as.character(path)
  .Call(R_set_cert_locations, file, path)
}

file_exists <- function(x){
  length(x) && file.exists(x)
}

find_cert_dir <- function(){
  if(nchar(Sys.which('openssl')) > 0){
    out <- sys::exec_internal('openssl', c('version', '-d'), error = FALSE)
    if(out$status == 0){
      txt <- sys::as_text(out$stdout)
      path <- utils::tail(strsplit(txt, ' ', fixed = TRUE)[[1]], 1)
      path <- gsub('"', "", path, fixed = TRUE)
      path <- file.path(path, 'certs')
      if(file_exists(path)){
        return(path)
      }
    }
  }
  default_paths <- c('/etc/pki/tls/certs', '/etc/ssl/certs/', '/etc/opt/csw/ssl/certs')
  for(x in default_paths){
    if(file_exists(x)){
      return(x)
    }
  }
  return(NULL)
}
