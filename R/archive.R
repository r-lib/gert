#' Git Archive
#'
#' Exports the files in your repository to a zip file.
#'
#' @export
#' @rdname archive
#' @name archive
#' @family git
#' @inheritParams git_open
#' @param file name of the output zip file
git_archive <- function(file = "archive.zip", repo = "."){
  repo <- git_open(repo = repo)
  tmp <- tempfile(fileext = '.zip')
  on.exit(unlink(tmp))
  git_archive_internal(tmp, repo = repo)
  file.copy(tmp, file, overwrite = TRUE)
  return(file)
}

git_archive_internal <- function(outfile, repo){
  tryCatch({
    git_stash_save(repo = repo)
    on.exit(git_stash_pop(repo = repo))
  }, GIT_ENOTFOUND = function(e){})
  files <- git_ls(repo = repo)$path
  wd <- getwd()
  on.exit(setwd(wd), add = TRUE)
  setwd(git_info(repo = repo)$path)
  suppressMessages(zip::zip(outfile, files = files, recurse = FALSE), "deprecated")
}
