# Classed error handling
# Todo: kclass is ignored right now, would this be useful to report?
raise_libgit2_error <- function(code, message, kclass = 0){
  e <- structure(
    class = c(libgit2_error_name(code), "libgit2_error", "error", "condition"),
    list(message = message, call = substitute(gert/libgit2)) #call must be an R expression
  )
  stop(e)
}

libgit2_error_name <- function(x){
  out <- which(libgit2_error_codes == x)
  if(length(out))
    return(names(out))
  return("UNKNOWN_ERROR_CODE")
}

# Eror codes copied from https://github.com/libgit2/libgit2/blame/master/include/git2/errors.h
# We don't do this in C because the list of error codes changes from version to version
libgit2_error_codes <- c(
  GIT_OK         =  0,
  GIT_ERROR      = -1,
  GIT_ENOTFOUND  = -3,
  GIT_EEXISTS    = -4,
  GIT_EAMBIGUOUS = -5,
  GIT_EBUFS      = -6,
  GIT_EUSER      = -7,
  GIT_EBAREREPO       =  -8,
  GIT_EUNBORNBRANCH   =  -9,
  GIT_EUNMERGED       = -10,
  GIT_ENONFASTFORWARD = -11,
  GIT_EINVALIDSPEC    = -12,
  GIT_ECONFLICT       = -13,
  GIT_ELOCKED         = -14,
  GIT_EMODIFIED       = -15,
  GIT_EAUTH           = -16,
  GIT_ECERTIFICATE    = -17,
  GIT_EAPPLIED        = -18,
  GIT_EPEEL           = -19,
  GIT_EEOF            = -20,
  GIT_EINVALID        = -21,
  GIT_EUNCOMMITTED    = -22,
  GIT_EDIRECTORY      = -23,
  GIT_EMERGECONFLICT  = -24,
  GIT_PASSTHROUGH     = -30,
  GIT_ITEROVER        = -31,
  GIT_RETRY           = -32,
  GIT_EMISMATCH       = -33,
  GIT_EINDEXDIRTY     = -34,
  GIT_EAPPLYFAIL      = -35
)
