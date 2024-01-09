
# Contributing to tidypolars

This outlines how to propose a change to **tidypolars**.

## Fixing typos

Small typos or grammatical errors in vignettes can be fixed directly on
the Github interface since vignettes are automatically rendered by
`pkgdown`.

Fixing typos in the documentation of functions (those in the “Reference”
page) requires editing the source in the corresponding `.R` file and
then run `devtools::document()`. *Do not edit an `.Rd` file in `man/`*.

## Filing an issue

The easiest way to propose a change or new feature is to file an issue.
If you’ve found a bug, you may also create an associated issue. If
possible, try to illustrate your proposal or the bug with a minimal
[reproducible example](https://www.tidyverse.org/help/#reprex).

## Pull requests

### General information

- Please create a Git branch for each pull request (PR).
- tidypolars uses
  [roxygen2](https://cran.r-project.org/package=roxygen2), with
  [Markdown
  syntax](https://cran.r-project.org/web/packages/roxygen2/vignettes/markdown.html),
  for documentation.
- If your PR is a user-visible change, you may add a bullet point in
  `NEWS.md` describing the changes made. You may optionally add your
  GitHub username, and links to relevant issue(s)/PR(s).

### How to add support for an R function in `tidypolars`?

If you use a function that is not supported, `tidypolars` will throw an
error. This doesn’t mean that `tidypolars` cannot support it, simply
that it is not implemented yet. `tidypolars` can technically support
hundreds of functions that manipulate numbers, strings, or dates, and
those are not limited to the `tidyverse`.

The first step when you come across an unsupported function is to find
the corresponding syntax in `polars`. Just for the example, suppose that
`stringr::str_ends()` is not yet supported (it actually is). We first
define a simple test `data.frame` and its `DataFrame` counterpart in
`polars`:

``` r
library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(polars)

test <- tibble(x = c("abc", "a1", "dac"))
test_pl <- pl$DataFrame(x = c("abc", "a1", "dac"))
```

Then, find the `polars` syntax that gives the same output as
`stringr::str_ends()`. In this case, `polars` has a string methods
`$ends_with()`:

``` r
test |> 
  mutate(ends_with_c = str_ends(x, "c"))
```

    ## # A tibble: 3 × 2
    ##   x     ends_with_c
    ##   <chr> <lgl>      
    ## 1 abc   TRUE       
    ## 2 a1    FALSE      
    ## 3 dac   TRUE

``` r
test_pl$with_columns(
  ends_with_c = pl$col("x")$str$ends_with("c")
)
```

    ## shape: (3, 2)
    ## ┌─────┬─────────────┐
    ## │ x   ┆ ends_with_c │
    ## │ --- ┆ ---         │
    ## │ str ┆ bool        │
    ## ╞═════╪═════════════╡
    ## │ abc ┆ true        │
    ## │ a1  ┆ false       │
    ## │ dac ┆ true        │
    ## └─────┴─────────────┘

What interests us is the expression inside the `$with_columns()` call.
Now that we know the `polars` translation, let’s put this in a function
that `tidypolars` will know. Internally, `tidypolars` will prefix the
function name (`str_ends`) with `pl_` and look for it in the translated
functions.

Depending on the function we translate, it can be stored in different
places. This function only works on strings, we can store it in
[`R/funs-string.R`](https://github.com/etiennebacher/tidypolars/blob/main/R/funs-string.R).
Once we add support for the `negate` argument, this is what it will look
like:

``` r
pl_str_ends <- function(string, pattern, negate = FALSE, ...) {
  check_empty_dots(...)
  out <- string$str$ends_with(pattern)
  if (isTRUE(negate)) {
    out$not()
  } else {
    out
  }
}
```

The `check_empty_dots(...)` is here to grab all additional arguments
that `stringr::str_ends()` might have and ignore them because they have
no counterparts in `polars` (it also adds a message warning the user
that these arguments are not used).

Once the package is reloaded, we can use this function in a `tidypolars`
workflow:

``` r
library(tidypolars, warn.conflicts = FALSE)
```

    ## Registered S3 method overwritten by 'tidypolars':
    ##   method          from  
    ##   print.DataFrame polars

``` r
test_pl |> 
  mutate(ends_with_c = str_ends(x, "c"))
```

    ## shape: (3, 2)
    ## ┌─────┬─────────────┐
    ## │ x   ┆ ends_with_c │
    ## │ --- ┆ ---         │
    ## │ str ┆ bool        │
    ## ╞═════╪═════════════╡
    ## │ abc ┆ true        │
    ## │ a1  ┆ false       │
    ## │ dac ┆ true        │
    ## └─────┴─────────────┘

Finally, the only thing left to do is to add some tests in the
`tests/tinytest` folder.