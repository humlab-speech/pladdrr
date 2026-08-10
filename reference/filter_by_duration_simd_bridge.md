# Filter Intervals by Duration Range with SIMD

Returns indices of intervals with duration in \[min_dur, max_dur\]. Uses
SIMD for fast range comparison.

## Usage

``` r
filter_by_duration_simd_bridge(durations, min_dur, max_dur)
```

## Arguments

- durations:

  Numeric vector of durations

- min_dur:

  Minimum duration (inclusive)

- max_dur:

  Maximum duration (inclusive)

## Value

Integer vector of 1-based indices into `durations` whose value falls
within `[min_dur, max_dur]`

## Examples

``` r
filter_by_duration_simd_bridge(c(0.1, 0.5, 1.2, 0.3), 0.2, 0.8)
#> [1] 2 4
```
