# Calculate Interval Midpoints with SIMD

Calculate Interval Midpoints with SIMD

## Usage

``` r
calculate_midpoints_simd_bridge(start_times, end_times)
```

## Arguments

- start_times:

  Numeric vector of start times

- end_times:

  Numeric vector of end times

## Value

Numeric vector of midpoints

## Examples

``` r
calculate_midpoints_simd_bridge(c(0, 1, 2.5), c(0.8, 2, 3.2))
#> [1] 0.40 1.50 2.85
```
