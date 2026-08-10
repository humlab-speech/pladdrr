# Praat AmplitudeTier Object

Praat AmplitudeTier object with direct C++ module binding for amplitude
analysis.

## Value

An `AmplitudeTier` object with methods for amplitude-over-time
manipulation via time-value points.

## Details

AmplitudeTier represents sound pressure amplitude in Pascals as a
function of time, stored as a sequence of (time, value) points with
interpolation between points.

## Examples

``` r
tier <- amplitude_tier_create(0, 1)
tier$add_point(0.25, 0.5)
tier$add_point(0.75, 0.8)
tier$get_number_of_points()
#> [1] 2
tier$get_value_at_time(0.5)
#> [1] 0.65
```
