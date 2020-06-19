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
#' @rdname git_signature
#' @name git_signature
#' @family git
#' @inheritParams git_open
#' @useDynLib gert R_git_signature_default
#' @examples # Your default user
#' try(git_signature_default())
#'
#' # Specify explicit name and email
#' git_signature("Some committer", "sarah@gmail.com")
#'
#' # Create signature for an hour ago
#' (sig <- git_signature("Han", "han@company.com", Sys.time() - 3600))
#'
#' # Parse a signature
#' git_signature_parse(sig)
#' git_signature_parse("Emma <emma@mu.edu>")
git_signature_default <- function(repo = '.'){
  repo <- git_open(repo)
  sig <- .Call(R_git_signature_default, repo)
  sprintf("%s <%s>", sig$name, sig$email)
}

#' @export
#' @rdname git_signature
#' @useDynLib gert R_git_signature_create
#' @param name Real name of the committer
#' @param email Email address of the committer
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
  sig <- .Call(R_git_signature_create, name, email, time, offset)
  if(length(time)){
    sig_data_to_string(sig)
  } else {
    sig_data_to_string(list(name = sig$name, email = sig$email))
  }
}

#' @export
#' @rdname git_signature
#' @param sig string in proper `"First Last <your@email.com>"` format, see details.
#' @useDynLib gert R_git_signature_parse
git_signature_parse <- function(sig){
  assert_string(sig)
  .Call(R_git_signature_parse, sig)
}

offset_to_string <- function(offset){
  if(length(offset) && is.numeric(offset)){
    hours <- as.integer(offset %/% 60)
    mins <- as.integer(offset %% 60)
    sprintf('%+03d%02d', hours, mins)
  } else ""
}

sig_data_to_string <- function(x){
  sig <- sprintf("%s <%s>", x$name, x$email)
  if(length(x$time)){
    sig <- paste(sig, unclass(x$time), offset_to_string(x$offset))
  }
  structure(trimws(sig), class = "gert_signature")
}

#' @export
print.gert_signature <- function(x, ...){
  sig <- git_signature_parse(x)
  name <- sig$name
  email <- sig$email
  time <- format(sig$time, "%a %b %d %H:%M:%S %Y") #print as user local time
  offset <- offset_to_string(sig$offset)
  cat(sprintf('[git signature]\nAuthor: %s <%s>\nDate: %s %s\n', name, email, time, offset))
}
