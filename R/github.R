# What: High-level wrapper functions
# Why: To make several common tasks easier for end users
# Who: Caspar J. van Lissa, Utrecht University, dept. Methodology & Statistics
# Context: These functions are implemented in the package
#          https://github.com/cjvanlissa/worcs, but I'd rather import them from
#          gert.

# Check if the user has a working git setup
has_git <- function(){
  config <- libgit2_config()
  settings <- git_config_global()
  name <- subset(settings, name == "user.name")$value
  email <- subset(settings, name == "user.email")$value
  (any(unlist(config[c("ssh", "https")])) & (length(name) && length(email)))
}

# Before first use, must set credentials. This currently requires two function
# calls to git_config_global_set with name / value arguments. Novice users might
# misunderstand the'name' argument to mean the user name. a single unambiguous
# function call is more user friendly.

#' @title Set global 'Git' credentials
#' @description This function is a wrapper for
#' \code{\link[gert]{git_config_global_set}}. It sets two name/value pairs at
#' once: \code{name = "user.name"} is set to the value of the \code{name}
#' argument, and \code{name = "user.email"} is set to the value of the
#' \code{email} argument.
#' @param name Character. The user name you want to use with 'Git'.
#' @param email Character. The email address you want to use with 'Git'.
#' @return No return value. This function is called for its side effects.
#' @examples
#' git_credentials("myname", "my@email.com")
#' @rdname git_credentials
#' @export
git_credentials <- function(name, email){
  invisible(
    tryCatch({
      do.call(git_config_global_set, list(
        name = "user.name",
        value = name
      ))
      do.call(git_config_global_set, list(
        name = "user.email",
        value = email
      ))
      message("'Git' username set to '", name, "' and email set to '", email, "'.")
  }, error = function(e){warning("Could not set 'Git' credentials.", call. = FALSE)})
  )
}

# I find myself doing a "git quicksave" very often, by typing these three
# commands in rapid succession. Would be so nice to have a single call, with
# message as first argument (because you would almost always want to customize
# that), and files as second argument, as you sometimes want to make selective
# commits.

#' @title Add, commit, and push changes.
#' @description This function is a wrapper for
#' \code{\link[gert]{git_add}}, \code{\link[gert]{git_commit}}, and
#' \code{\link[gert]{git_push}}. It adds all locally changed files to the
#' staging area of the local 'Git' repository, then commits these changes
#' (with an optional) \code{message}, and then pushes them to a remote
#' repository. This is used for making a "cloud backup" of local changes.
#' Do not use this function when working with privacy sensitive data,
#' or any other file that should not be pushed to a remote repository.
#' The \code{\link[gert]{git_add}} argument \code{force} is disabled by default,
#' to avoid accidentally committing and pushing a file that is listed in
#' \code{.gitignore}.
#' @param remote name of a remote listed in git_remote_list()
#' @param refspec string with mapping between remote and local refs
#' @param password a string or a callback function to get passwords for authentication or password protected ssh keys. Defaults to askpass which checks getOption('askpass').
#' @param ssh_key	path or object containing your ssh private key. By default we look for keys in ssh-agent and credentials::ssh_key_info.
#' @param verbose display some progress info while downloading
#' @param repo a path to an existing repository, or a git_repository object as returned by git_open, git_init or git_clone.
#' @param mirror use the --mirror flag
#' @param force use the --force flag
#' @param files vector of paths relative to the git root directory. Use "." to stage all changed files.
#' @param message a commit message
#' @param author A git_signature value, default is git_signature_default.
#' @param committer A git_signature value, default is same as author
#' @return No return value. This function is called for its side effects.
#' @examples
#' git_update()
#' @rdname git_update
#' @export
git_update <- function(message = paste0("update ", Sys.time()),
                       files = ".",
                       repo = ".",
                       author,
                       committer,
                       remote,
                       refspec,
                       password,
                       ssh_key,
                       mirror,
                       force,
                       verbose){
  tryCatch({
    git_ls(repo)
    message("Identified local 'Git' repository.")
  }, error = function(e){
    message("Not a 'Git' repository.", success = FALSE)
    message("Could not add files to staging area of 'Git' repository.", success = FALSE)
    message("Could not commit staged files to 'Git' repository.", success = FALSE)
    message("Could not push local commits to remote repository.", success = FALSE)
    return()
    })

  cl <- as.list(match.call()[-1])
  for(this_arg in c("message", "files", "repo")){
    if(is.null(cl[[this_arg]])){
      cl[[this_arg]] <- formals()[[this_arg]]
    }
  }

  Args_add <- cl[names(cl) %in% c("files", "repo")]
  Args_commit <- cl[names(cl) %in% c("message", "author", "committer", "repo")]
  Args_push <- cl[names(cl) %in% c("remote", "refspec", "password", "ssh_key", "mirror", "force", "verbose", "repo")]
  invisible(
    tryCatch({
      do.call(git_add, Args_add)
      message("Added files to staging area of 'Git' repository.")
    }, error = function(e){message("Could not add files to staging area of 'Git' repository.", success = FALSE)})
  )
  invisible(
    tryCatch({
      do.call(git_commit, Args_commit)
      message("Committed staged files to 'Git' repository.")
    }, error = function(e){message("Could not commit staged files to 'Git' repository.", success = FALSE)})
  )
  invisible(
    tryCatch({
      do.call(git_push, Args_push)
      message("Pushed local commits to remote repository.")
    }, error = function(e){message("Could not push local commits to remote repository.", success = FALSE)})
  )
}
