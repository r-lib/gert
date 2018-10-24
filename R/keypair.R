#' Setup SSH Keypair
#'
#' Generates a RSA public/private keypair if needed, and then automatically
#' opens the Github page to add it. Defaults to the same deafult path as the git
#' command line tool.
#'
#' @export
#' @rdname ssh_keys
#' @param file destination path of the private key. For the public key, `.pub`
#' is appended to the filename.
#' @param open_github automatically open a browser window to let the user
#' add the key to Github.
#' @importFrom openssl write_ssh write_pem read_key
setup_ssh_key <- function(file = "~/.ssh/id_rsa", open_github = TRUE){
  private_key <- normalizePath(file, mustWork = FALSE)
  if(file.exists(private_key)){
    cat(sprintf("Found existing RSA keyspair at: %s\n", private_key))
    key <- read_key(file)
  } else {
    cat(sprintf("Generating new RSA keyspair at: %s\n", private_key))
    key <- openssl::rsa_keygen()
    write_pkcs1(key, private_key)
    write_ssh(key$pubkey, paste0(private_key, '.pub'))
  }

  # See https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/
  conf_file <- file.path(dirname(private_key), 'config')
  if(!file.exists(conf_file)){
    writeLines(c('Host *', '  AddKeysToAgent yes', '  UseKeychain yes',
                 paste('  IdentityFile ', private_key)), con = conf_file)
  }

  cat(sprintf("Below your public key to share (%s):\n\n", paste0(private_key, '.pub')))
  cat(write_ssh(key$pubkey), "\n\n")
  if(isTRUE(open_github)){
    cat("Opening browser to add your key: https://github.com/settings/ssh/new\n")
    utils::browseURL('https://github.com/settings/ssh/new')
  }
}

#' @importFrom openssl write_ssh write_pem read_key write_pkcs1
make_key_cb <- function(file, password){
  function(){
    key <- read_key(file, password = password)
    tmp_pub <- write_ssh(key$pubkey, tempfile())
    tmp_key <- write_pkcs1(key, tempfile())
    if(.Platform$OS.type == "unix"){
      Sys.chmod(tmp_pub, '0644')
      Sys.chmod(tmp_key, '0400')
    }
    c(tmp_pub, tmp_key, "")
  }
}

#' @useDynLib gert R_set_session_keyphrase
set_session_pass <- function(key){
  .Call(R_set_session_keyphrase, key)
}

#' @importFrom openssl askpass
#' @export
openssl::askpass

#' @importFrom openssl my_key
#' @export
openssl::my_key
