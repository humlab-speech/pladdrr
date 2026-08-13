# DurationTier

Praat DurationTier object for duration manipulation, created via direct
C++ module binding.

## Arguments

- tmin:

  Start time in seconds. Used with `tmax` to create a new, empty
  DurationTier.

- tmax:

  End time in seconds. Used with `tmin` to create a new, empty
  DurationTier.

- .xptr:

  Not for direct use. External pointer to the underlying C++
  DurationTier object; set internally when a method returns a new
  DurationTier.

## Value

A `DurationTier` object with methods for duration and tempo manipulation
via time-value points.

## Details

DurationTiers are used together with Manipulation objects to modify the
duration/tempo of sounds. Values represent duration multiplication
factors:

- 1.0 - normal speed

- 2.0 - half speed (doubled duration)

- 0.5 - double speed (halved duration)

## Examples

``` r
dt <- DurationTier(0, 1)
dt$add_point(0.25, 1.0)
dt$add_point(0.75, 1.5)
dt$get_number_of_points()
#> [1] 2
dt$get_value_at_time(0.5)
#> [1] 1.25
```
