#' @importFrom openssl write_ssh write_pem read_key write_pkcs1
#' @importFrom credentials my_ssh_key
make_key_cb <- function(ssh_key = NULL, host = "github.com", password = askpass){
  function(){
    if(is.null(ssh_key)){
      ssh_key <- try(my_ssh_key(host = host, password = password, auto_keygen = FALSE))
      if(inherits(ssh_key, "try-error"))
        return(NULL)
    }
    key <- read_key(ssh_key, password = password)
    tmp_pub <- write_ssh(key$pubkey, tempfile())
    tmp_key <- write_pkcs1(key, tempfile())
    if(.Platform$OS.type == "unix"){
      Sys.chmod(tmp_pub, '0644')
      Sys.chmod(tmp_key, '0400')
    }
    c(tmp_pub, tmp_key, "")
  }
}

#' @export
#' @importFrom credentials git_credential_read
credentials::git_credential_read

#' @export
#' @importFrom credentials git_credential_update
credentials::git_credential_update

#' @export
#' @importFrom credentials my_ssh_key
credentials::my_ssh_key

#' @export
#' @importFrom openssl askpass
openssl::askpass
