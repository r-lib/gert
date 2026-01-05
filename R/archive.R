#' Git Archive
#'
#' Exports the files in your repository to a zip file that
#' is returned by the function.
#'
#' @export
#' @rdname git_archive
#' @name git_archive
#' @family git
#' @inheritParams git_open
#' @param file name of the output zip file. Default is returned
#' by the function
#' @return path to the zip file that was created
git_archive_zip <- function(file = NULL, repo = ".") {
  repo <- git_open(repo = repo)
  tmp <- tempfile(fileext = '.zip')
  git_archive_internal(tmp, repo = repo)
  if (!length(file)) {
    file <- paste0(basename(git_info(repo)$path), ".zip")
  }
  file.copy(tmp, file, overwrite = TRUE)
  return(file)
}

git_archive_internal <- function(outfile, repo) {
  tryCatch(
    {
      git_stash_save(repo = repo)
      on.exit(git_stash_pop(repo = repo))
    },
    GIT_ENOTFOUND = function(e) {
    }
  )
  files <- git_ls(repo = repo)$path
  wd <- getwd()
  on.exit(setwd(wd), add = TRUE)
  setwd(git_info(repo = repo)$path)
  zip::zip(outfile, files = files, recurse = FALSE)
}
