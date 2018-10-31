#' Lookup passwords from the git credential store
#'
#' If you have the `git` command line program installed, this function
#' tries to lookup cached authentication keys from the `git-credential`
#' store.
#'
#' @export
#' @param host hostname to authenticate with
#' @param git path of the `git` command line program
get_git_credential <- function(host = "github.com", git = "git"){
  input <- tempfile()
  on.exit(unlink(input))
  writeBin(charToRaw(sprintf("protocol=https\nhost=%s\n", host)), con = input)
  out <- system2(git, c("credential", "fill"), stdin = input, stdout = TRUE)
  if(length(attr(out, "status")))
    stop(out)
  data <- strsplit(out, "=", fixed = TRUE)
  key <- vapply(data, `[`, character(1), 1)
  val <- vapply(data, `[`, character(1), 2)
  as.list(structure(val, names = key))
}
