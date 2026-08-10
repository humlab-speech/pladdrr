# Calculate multiple quantiles for multiple intervals with SIMD

Internal SIMD dispatch helper; not part of the public API.

## Usage

``` r
calculate_interval_quantiles_simd_bridge(intervals_values, quantiles)
```

## Arguments

- intervals_values:

  List of NumericVectors

- quantiles:

  NumericVector of quantile values (e.g., c(0.25, 0.50, 0.75))

## Value

NumericMatrix with intervals as rows, quantiles as columns

## Examples

``` r
intervals <- list(c(1, 2, 3, 4), c(5, 6, 7, 8, 9))
calculate_interval_quantiles_simd_bridge(intervals, c(0.25, 0.5, 0.75))
#>      q0.25 q0.5 q0.75
#> [1,]  1.75  2.5  3.25
#> [2,]  6.00  7.0  8.00
```
