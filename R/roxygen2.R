# nocov start

git_links <- function() {
  rlang::check_installed("tibble")
  tibble::tribble(
    ~command   , ~url                                                          ,
    "checkout" , "https://libgit2.org/docs/reference/main/checkout/index.html"
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
