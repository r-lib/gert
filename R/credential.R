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
  git <- find_git_cmd(git)
  input <- tempfile()
  on.exit(unlink(input))
  writeBin(charToRaw(sprintf("protocol=https\nhost=%s\n", host)), con = input)
  out <- git_credential_exec(input, git)
  data <- strsplit(out, "=", fixed = TRUE)
  key <- vapply(data, `[`, character(1), 1)
  val <- vapply(data, `[`, character(1), 2)
  c(as.list(structure(val, names = key)), list(git=git))
}

git_credential_exec <- function(input, git){
  rs_path <- Sys.getenv('RS_RPOSTBACK_PATH')
  if(nchar(rs_path)){
    old_path <- Sys.getenv("PATH")
    on.exit(Sys.setenv(PATH = old_path))
    rs_path <- sub("rpostback", 'postback', rs_path)
    Sys.setenv(PATH = paste(old_path, rs_path, sep = .Platform$path.sep))
  }
  out <- if(.Platform$OS.type == "windows"){
    exec_git("cmd", c("/C", git, "credential", "fill", "<", input))
  } else {
    exec_git("sh", c("-c", paste(git, "credential", "fill", "<", input)))
  }
  if(!identical(out$status, 0L)){
    stop(sprintf("Failure in 'git credential' %s", rawToChar(out$stderr)))
  }
  strsplit(rawToChar(out$stdout), "\n", fixed = TRUE)[[1]]
}

exec_git <- function (cmd, args = NULL) {
  outcon <- rawConnection(raw(0), "r+")
  on.exit(close(outcon), add = TRUE)
  status <- sys::exec_wait(cmd, args, std_out = outcon, std_err = stderr())
  list(status = status, stdout = rawConnectionValue(outcon), stderr = raw(0))
}

find_git_cmd <- function(git = "git"){
  if(cmd_exists(git)){
    return(git)
  }
  if(.Platform$OS.type == "windows"){
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
