#' Get column names of a Polars Data/LazyFrame
#'
#' @param x A Polars Data/LazyFrame
#'
#' @return A character vector with the column names
#' @noRd

pl_colnames <- function(x) {
  if (inherits(x, "RPolarsDataFrame") || inherits(x, "RPolarsLazyFrame")) {
    x$columns
  }
}

check_polars_data <- function(x, env = caller_env()) {
  if (!inherits(x, "RPolarsDataFrame") && !inherits(x, "RPolarsLazyFrame")) {
    rlang::abort(
      "The data must be a Polars DataFrame or LazyFrame.",
      call = env
    )
  }
}

add_tidypolars_class <- function(x) {
  if (!inherits(x, "tidypolars")) {
    class(x) <- c("tidypolars", class(x))
  }
  x
}

check_same_class <- function(x, y, env = caller_env()) {
  if (class(x) != class(y)) {
    rlang::abort(
      c(
        "Both objects must be of the same class.",
        "i" = paste0("Currently, `x` is a ", class(x)[1], " and `y` is a ", class(y)[1], ".")
      ),
      call = env
    )
  }
}
