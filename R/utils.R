# Internal
make_tibble <- function(x, col_names = names(x)){
  stopifnot(is.list(x) || is.data.frame(x))
  stopifnot(length(x) == length(col_names))
  structure(x, class = c("tbl_df", "tbl", "data.frame"),
            names = col_names, row.names = seq_along(x[[1]]))
}
