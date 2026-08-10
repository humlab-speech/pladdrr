# Convert value to NA with warning

Converts undefined analysis values to NA and issues a warning (Per
clarification: return NA for undefined values)

## Usage

``` r
undefined_to_na(message = NULL)
```

## Arguments

- message:

  Reason for NA

## Value

NA_real\_

## Examples

``` r
withCallingHandlers(
  pladdrr:::undefined_to_na("pitch could not be determined"),
  warning = function(w) invokeRestart("muffleWarning")
)
#> [1] NA
```
