#' Author Signature
#'
#' A signature contains the author and timestamp of a commit. Each commit
#' includes a signature of the author and committer (which can be identical).
#'
#' A signature string has format `"Real Name <email> timestamp tzoffset"`. The
#' `timestamp tzoffset` piece can be omitted in which case the current local
#' time is used. If not omitted, `timestamp` must contain the number
#' of seconds since the Unix epoch and `tzoffset` is the timezone offset in
#' `hhmm` format (note the lack of a colon separator)
#'
#' @export
#' @rdname signature
#' @name signature
#' @family git
#' @inheritParams git_open
#' @useDynLib gert R_git_signature_default
git_signature_default <- function(repo = '.'){
  repo <- git_open(repo)
  .Call(R_git_signature_default, repo)
}

#' @export
#' @rdname signature
#' @param sig string in proper `"First Last <your@email.com>"` format, see details.
#' @useDynLib gert R_git_signature_parse
git_signature_parse <- function(sig){
  sig <- as.character(sig)
  .Call(R_git_signature_parse, sig)
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
