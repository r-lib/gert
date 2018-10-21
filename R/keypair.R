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
setup_ssh_key <- function(file = "~/.ssh/id_rsa", open_github = TRUE){
  private_key <- normalizePath(file, mustWork = FALSE)
  if(file.exists(private_key)){
    cat(sprintf("Found existing RSA keyspair at: %s\n", private_key))
    key <- openssl::read_key(file)
  } else {
    cat(sprintf("Generating new RSA keyspair at: %s\n", private_key))
    key <- openssl::rsa_keygen()
    openssl::write_pem(key, private_key)
    openssl::write_ssh(key$pubkey, paste0(private_key, '.pub'))
  }
  cat(sprintf("Below your public key to share (%s):\n\n", paste0(private_key, '.pub')))
  cat(openssl::write_ssh(key$pubkey), "\n\n")
  if(isTRUE(open_github)){
    cat("Opening browser to add your key: https://github.com/settings/ssh/new\n")
    utils::browseURL('https://github.com/settings/ssh/new')
  }
}

#' @useDynLib gert R_set_session_keyphrase
set_session_pass <- function(key){
  .Call(R_set_session_keyphrase, key)
}

#' @importFrom openssl askpass
#' @export
openssl::askpass
