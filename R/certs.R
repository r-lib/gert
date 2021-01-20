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

has_files <- function(x){
  isTRUE(file.exists(x) && length(list.files(x)) > 0)
}

find_cert_dir <- function(){
  if(nchar(Sys.which('openssl')) > 0){
    out <- sys::exec_internal('openssl', c('version', '-d'), error = FALSE)
    if(out$status == 0){
      txt <- sys::as_text(out$stdout)
      path <- utils::tail(strsplit(txt, ' ', fixed = TRUE)[[1]], 1)
      path <- gsub('"', "", path, fixed = TRUE)
      path <- file.path(path, 'certs')
      if(has_files(path)){
        return(path)
      }
    }
  }
  default_paths <- c('/etc/pki/tls/certs', '/etc/ssl/certs/', '/etc/opt/csw/ssl/certs')
  for(x in default_paths){
    if(has_files(x)){
      return(x)
    }
  }
  return(NULL)
}
