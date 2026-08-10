# Calculate standard deviation with SIMD

Internal SIMD dispatch helper; not part of the public API.

## Usage

``` r
calculate_stdev_simd_bridge(values, mean = 0)
```

## Arguments

- values:

  NumericVector

- mean:

  Pre-computed mean (optional, default 0.0 computes it)

## Value

Standard deviation

## Examples

``` r
x <- c(1, 2, 3, 4, 5)
calculate_stdev_simd_bridge(x, mean(x))
#> [1] 1.581139
```
