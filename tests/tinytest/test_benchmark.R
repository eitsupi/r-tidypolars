source("helpers.R")
using("tidypolars")

exit_if(is_ci(), is_cran())
exit_file("Only for releases")

tmp <- rep(list(mtcars), 4*1e5)

# EAGER

dat <- data.table::rbindlist(tmp) |>
  as_polars_df()

x <- bench::mark(
  polars = dat$
    select(c("mpg", "cyl", "disp", "vs", "am", "gear"))$
    with_columns(
      pl$when(
        (pl$col("cyl") >= 6)
      )$then(pl$lit("large"))$
        otherwise(pl$lit("small"))$
        alias("cyl_type")
    )$
    filter(pl$col("disp") / pl$col("gear") > 40),
  tidypolars = dat |>
    select(c("mpg", "cyl", "disp", "vs", "am", "gear")) |>
    mutate(
      cyl_type = ifelse(cyl >= 6, "large", "small")
    ) |>
    filter(disp / gear > 40),
  iterations = 10
)

times <- as.numeric(x$median)
time_ratio <- times[2] / times[1]

expect_true(
  time_ratio < 1.05
)


# LAZY

dat <- data.table::rbindlist(tmp) |>
  as_polars_lf()

x <- bench::mark(
  polars = dat$
    select(c("mpg", "cyl", "disp", "vs", "am", "gear"))$
    with_columns(
      pl$when(
        (pl$col("cyl") >= 6)
      )$then("large")$
        otherwise("small")$
        alias("cyl_type")
    )$
    filter(pl$col("disp") / pl$col("gear") > 40)$
    collect(),
  tidypolars = dat |>
    select(c("mpg", "cyl", "disp", "vs", "am", "gear")) |>
    mutate(
      cyl_type = ifelse(cyl >= 6, "large", "small")
    ) |>
    filter(disp / gear > 40) |>
    collect(),
  iterations = 5
)

times <- as.numeric(x$median)
time_ratio <- times[2] / times[1]

expect_true(
  time_ratio < 1.05
)
