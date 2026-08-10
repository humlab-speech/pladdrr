# Calculate all basic statistics in one pass with SIMD

Internal SIMD dispatch helper; not part of the public API.

## Usage

``` r
calculate_batch_statistics_simd_bridge(values)
```

## Arguments

- values:

  NumericVector

## Value

List with mean, stdev, min, max

## Examples

``` r
calculate_batch_statistics_simd_bridge(c(1, 2, 3, 4, 5))
#> $mean
#> [1] 3
#> 
#> $stdev
#> [1] 1.581139
#> 
#> $min
#> [1] 1
#> 
#> $max
#> [1] 5
#> 
```
