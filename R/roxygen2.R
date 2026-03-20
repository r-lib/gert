# nocov start

git_links <- function() {
  base_url <- "https://libgit2.org/docs/reference/main/%s/index.html"
  dat <- as.data.frame(
    rbind(
      c("branch",     sprintf(base_url, "branch")),
      c("cherrypick", sprintf(base_url, "cherrypick")),
      c("checkout",   sprintf(base_url, "checkout")),
      c("clone",      sprintf(base_url, "clone")),
      c("commit",     sprintf(base_url, "commit")),
      c("config",     sprintf(base_url, "config")),
      c("diff",       sprintf(base_url, "diff")),
      c("graph",      sprintf(base_url, "graph")),
      c("ignore",     sprintf(base_url, "ignore")),
      c("index",      sprintf(base_url, "index")),
      c("merge",      sprintf(base_url, "merge")),
      c("rebase",     sprintf(base_url, "rebase")),
      c("remote",     sprintf(base_url, "remote")),
      c("repository", sprintf(base_url, "repository")),
      c("reset",      sprintf(base_url, "reset")),
      c("revert",     sprintf(base_url, "revert")),
      c("signature",  sprintf(base_url, "signature")),
      c("stash",      sprintf(base_url, "stash")),
      c("status",     sprintf(base_url, "status")),
      c("tag",        sprintf(base_url, "tag")),
      c("worktree",   sprintf(base_url, "worktree"))
    ),
    stringsAsFactors = FALSE
  )
  names(dat) <- c("command", "url")
  dat
}

#' @exportS3Method roxygen2::roxy_tag_parse
roxy_tag_parse.roxy_tag_git <- function(x) {
  roxygen2::tag_words(x)
}

#' @exportS3Method roxygen2::roxy_tag_rd
roxy_tag_rd.roxy_tag_git <- function(x, base_path, env) {
  roxygen2::rd_section("gitcommands", x$val)
}

#' @export
format.rd_section_gitcommands <- function(x, ...) {
  paste0(
    "\\section{Related libgit2 documentation}{",
    present_git_link(x[["value"]]),
    ".}\n"
  )
}

present_git_link <- function(value) {
  links <- git_links()
  format_git_single_link <- function(x) {
    df <- links[links$command == x, ]
    if (nrow(df) == 0) {
      warning(sprintf("Can't find libgit2 entry for %s!", x))
    }
    sprintf("\\href{%s}{\\code{%s}}", df$url, df$command)
  }

  strings <- vapply(unique(value), format_git_single_link, character(1))

  paste(strings, collapse = ", ")
}
# nocov end
