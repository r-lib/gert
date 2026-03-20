# nocov start

git_links <- function() {
  rlang::check_installed("tibble")
  tibble::tribble(
    ~command      , ~url                                                             ,
    "branch"      , "https://libgit2.org/docs/reference/main/branch/index.html"     ,
    "cherrypick"  , "https://libgit2.org/docs/reference/main/cherrypick/index.html" ,
    "checkout"    , "https://libgit2.org/docs/reference/main/checkout/index.html"   ,
    "clone"       , "https://libgit2.org/docs/reference/main/clone/index.html"      ,
    "commit"      , "https://libgit2.org/docs/reference/main/commit/index.html"     ,
    "config"      , "https://libgit2.org/docs/reference/main/config/index.html"     ,
    "diff"        , "https://libgit2.org/docs/reference/main/diff/index.html"       ,
    "graph"       , "https://libgit2.org/docs/reference/main/graph/index.html"      ,
    "ignore"      , "https://libgit2.org/docs/reference/main/ignore/index.html"     ,
    "index"       , "https://libgit2.org/docs/reference/main/index/index.html"      ,
    "merge"       , "https://libgit2.org/docs/reference/main/merge/index.html"      ,
    "rebase"      , "https://libgit2.org/docs/reference/main/rebase/index.html"     ,
    "remote"      , "https://libgit2.org/docs/reference/main/remote/index.html"     ,
    "repository"  , "https://libgit2.org/docs/reference/main/repository/index.html" ,
    "reset"       , "https://libgit2.org/docs/reference/main/reset/index.html"      ,
    "revert"      , "https://libgit2.org/docs/reference/main/revert/index.html"     ,
    "signature"   , "https://libgit2.org/docs/reference/main/signature/index.html"  ,
    "stash"       , "https://libgit2.org/docs/reference/main/stash/index.html"      ,
    "status"      , "https://libgit2.org/docs/reference/main/status/index.html"     ,
    "tag"         , "https://libgit2.org/docs/reference/main/tag/index.html"        ,
    "worktree"    , "https://libgit2.org/docs/reference/main/worktree/index.html"   ,
  )
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
  format_git_single_link <- function(x, git_links) {
    df <- git_links[git_links$command == x, ]
    if (nrow(df) == 0) {
      cli::cli_warn("Can't find libgit2 entry for {x}!")
    }
    sprintf("\\href{%s}{\\code{%s}}", df$url, df$command)
  }

  strings <- purrr::map_chr(
    unique(value),
    format_git_single_link,
    git_links = git_links()
  )

  paste(strings, collapse = ", ")
}
# nocov end
