# Calculate min and max with SIMD

Internal SIMD dispatch helper; not part of the public API.

## Usage

``` r
calculate_min_max_simd_bridge(values)
```

## Arguments

- values:

  NumericVector

## Value

List with min and max

## Examples

``` r
calculate_min_max_simd_bridge(c(3, 1, 4, 1, 5, 9))
#> $min
#> [1] 1
#> 
#> $max
#> [1] 9
#> 
```
