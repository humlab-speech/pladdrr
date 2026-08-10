# Praat IntensityTier Object

Praat IntensityTier object with direct C++ module binding for intensity
manipulation.

## Value

An `IntensityTier` object with methods for intensity (dB SPL)
manipulation via time-value points.

## Details

IntensityTiers contain discrete time-value pairs representing intensity
in dB SPL. They can be used to modify the amplitude envelope of sounds.

## Examples

``` r
it <- IntensityTier(0, 1)
it$add_point(0.25, 70)
it$add_point(0.75, 60)
it$get_number_of_points()
#> [1] 2
it$get_value_at_time(0.5)
#> [1] 65
```
