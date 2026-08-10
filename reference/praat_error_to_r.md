# Convert Praat errors to R exceptions

Wraps Praat function calls and converts Praat's error system to R
exceptions

## Usage

``` r
praat_error_to_r(error_msg)
```

## Arguments

- error_msg:

  Error message from Praat

## Value

This function never returns; it always raises an R error via
[`stop()`](https://rdrr.io/r/base/stop.html).

## Examples

``` r
result <- tryCatch(
  pladdrr:::praat_error_to_r("example failure"),
  error = function(e) conditionMessage(e)
)
result
#> [1] "Praat error: example failure"
```
