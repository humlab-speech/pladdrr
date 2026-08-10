# Calculate Duration Statistics with SIMD

Computes mean, standard deviation, min, and max of durations using SIMD.

## Usage

``` r
duration_statistics_simd_bridge(durations)
```

## Arguments

- durations:

  Numeric vector of durations

## Value

List with mean, stdev, min, max

## Examples

``` r
duration_statistics_simd_bridge(c(0.5, 0.8, 1.2, 0.3))
#> $mean
#> [1] 0.7
#> 
#> $stdev
#> [1] 0.391578
#> 
#> $min
#> [1] 0.3
#> 
#> $max
#> [1] 1.2
#> 
```
