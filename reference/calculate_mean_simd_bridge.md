# Calculate mean of NumericVector with SIMD

Internal SIMD dispatch helper; not part of the public API.

## Usage

``` r
calculate_mean_simd_bridge(values)
```

## Arguments

- values:

  NumericVector

## Value

Mean value

## Examples

``` r
calculate_mean_simd_bridge(c(1, 2, 3, 4, 5))
#> [1] 3
```
