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
  out <- tempfile()
  on.exit(unlink(out))
  status <- suppressWarnings({
    system2(git, c("credential", "fill"), input =
              c("protocol=https", paste0("host=", host), ""), stdout = out, stderr = FALSE)
  })
  if(status != 0)
    return(NULL)
  data <- strsplit(readLines(out), "=", fixed = TRUE)
  key <- vapply(data, `[`, character(1), 1)
  val <- vapply(data, `[`, character(1), 2)
  as.list(structure(val, names = key))
}
