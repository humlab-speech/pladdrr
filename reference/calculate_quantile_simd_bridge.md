# Calculate quantile with SIMD-optimized sorting

Internal SIMD dispatch helper; not part of the public API.

## Usage

``` r
calculate_quantile_simd_bridge(values, quantile)
```

## Arguments

- values:

  NumericVector

- quantile:

  Quantile value (0.0 to 1.0)

## Value

Quantile value

## Examples

``` r
calculate_quantile_simd_bridge(c(1, 2, 3, 4, 5), 0.5)
#> [1] 3
```
