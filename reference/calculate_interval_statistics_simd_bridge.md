# Calculate statistics for multiple intervals with SIMD

Optimized for batch processing of interval-based metrics. Internal SIMD
dispatch helper; not part of the public API.

## Usage

``` r
calculate_interval_statistics_simd_bridge(intervals_values, metric)
```

## Arguments

- intervals_values:

  List of NumericVectors, one per interval

- metric:

  String: "mean", "stdev", "min", "max", or "all"

## Value

NumericVector or NumericMatrix depending on metric

## Examples

``` r
intervals <- list(c(1, 2, 3), c(4, 5, 6, 7))
calculate_interval_statistics_simd_bridge(intervals, "mean")
#> [1] 2.0 5.5
calculate_interval_statistics_simd_bridge(intervals, "all")
#>      mean    stdev min max
#> [1,]  2.0 1.000000   1   3
#> [2,]  5.5 1.290994   4   7
```
