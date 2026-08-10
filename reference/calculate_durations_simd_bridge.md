# Calculate Interval Durations with SIMD

Vectorized calculation of interval durations (end - start). Uses SIMD
instructions on large interval counts.

## Usage

``` r
calculate_durations_simd_bridge(start_times, end_times)
```

## Arguments

- start_times:

  Numeric vector of start times

- end_times:

  Numeric vector of end times

## Value

Numeric vector of durations

## Examples

``` r
starts <- c(0, 1, 2.5)
ends <- c(0.8, 2, 3.2)
calculate_durations_simd_bridge(starts, ends)
#> [1] 0.8 1.0 0.7
```
