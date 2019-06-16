#' Author Signature
#'
#' A signature contains the author and timestamp of a commit.
#' This is needed by the [git_commit] function.
#'
#' @export
#' @rdname signature
#' @name signature
#' @family git
#' @inheritParams repository
#' @useDynLib gert R_git_signature_default
git_signature_default <- function(repo = '.'){
  if(is.character(repo))
    repo <- git_open(repo)
  .Call(R_git_signature_default, repo)
}

#' @export
#' @rdname signature
#' @useDynLib gert R_git_signature_create
#' @param name Real name of the committer
#' @param email Email address of the commmitter
#' @param time timestamp of class POSIXt or NULL
git_signature <- function(name, email, time = NULL){
  assert_string(name)
  assert_string(email)
  if(length(time)){
    time <- as.POSIXct(time)
    tz <- format(time, "%z")
    minutes <- as.integer(substring(tz, 4))
    hours <- as.integer(substring(tz, 1, 3))
    offset <- hours * 60 + minutes
  }
  .Call(R_git_signature_create, name, email, time, offset)
}
