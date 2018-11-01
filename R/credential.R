#' Lookup passwords from the git credential store
#'
#' If you have the `git` command line program installed, this function
#' tries to lookup cached authentication keys from the `git-credential`
#' store.
#'
#' @export
#' @rdname credentials
#' @family git
#' @param host hostname to authenticate with
#' @param git path of the `git` command line program
git_credentials <- function(host = "github.com", git = "git"){
  git <- find_git_cmd(git)
  input <- tempfile()
  on.exit(unlink(input))
  writeBin(charToRaw(sprintf("protocol=https\nhost=%s\n", host)), con = input)
  if(is_windows() || !interactive()){
    Sys.setenv(GIT_TERMINAL_PROMPT=0)
  }
  out <- git_credential_exec(input, git)
  data <- strsplit(out, "=", fixed = TRUE)
  key <- vapply(data, `[`, character(1), 1)
  val <- vapply(data, `[`, character(1), 2)
  c(as.list(structure(val, names = key)), list(git=git))
}

git_credential_exec <- function(input, git, verbose = TRUE){
  rs_path <- Sys.getenv('RS_RPOSTBACK_PATH')
  if(nchar(rs_path)){
    old_path <- Sys.getenv("PATH")
    on.exit(Sys.setenv(PATH = old_path))
    rs_path <- sub("rpostback", 'postback', rs_path)
    Sys.setenv(PATH = paste(old_path, rs_path, sep = .Platform$path.sep))
  }
  outcon <- rawConnection(raw(0), "r+")
  on.exit(close(outcon), add = TRUE)
  status <- sys::exec_wait(git, c("credential", "fill"),
                           std_out = outcon, std_err = verbose, std_in = input)
  if(!identical(status, 0L)){
    stop(sprintf("Failed to call 'git credential'"))
  }
  strsplit(rawToChar(rawConnectionValue(outcon)), "\n", fixed = TRUE)[[1]]
}

exec_git <- function (cmd, args = NULL, input) {
  outcon <- rawConnection(raw(0), "r+")
  on.exit(close(outcon), add = TRUE)
  status <- sys::exec_wait(cmd, args, std_out = outcon, std_err = stderr(), std_in = input)
  list(status = status, stdout = rawConnectionValue(outcon), stderr = raw(0))
}

find_git_cmd <- function(git = "git"){
  if(cmd_exists(git)){
    return(git)
  }
  if(is_windows()){
    locations <- c("C:\\PROGRA~1\\Git\\cmd\\git.exe",
      "C:\\Program Files\\Git\\cmd\\git.exe")
    for(i in locations){
      if(cmd_exists(i)){
        return(i)
      }
    }
  }
  stop(sprintf("Could not find the '%s' command line util", git))
}

cmd_exists <- function(cmd){
  nchar(Sys.which(cmd)) > 0
}

is_windows <- function(){
  identical(.Platform$OS.type, "windows")
}
