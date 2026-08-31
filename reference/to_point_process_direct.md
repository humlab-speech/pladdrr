# Create PointProcess from Sound Directly (returns XPtr)

Create PointProcess from Sound Directly (returns XPtr)

## Usage

``` r
to_point_process_direct(
  sound,
  pitch_floor = 75,
  pitch_ceiling = 600,
  time_step = 0,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)
```

## Arguments

- sound:

  Sound object or external pointer

- pitch_floor:

  Numeric. Minimum pitch in Hz (default: 75)

- pitch_ceiling:

  Numeric. Maximum pitch in Hz (default: 600)

- time_step:

  Numeric. Time step in seconds (0 = auto)

- max_period_factor:

  Numeric. Max period factor (default: 1.3)

- max_amplitude_factor:

  Numeric. Max amplitude factor (default: 1.6)

## Value

External pointer to PointProcess

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
# Extract glottal pulses
pp_ptr <- to_point_process_direct(sound, pitch_floor = 75, pitch_ceiling =
 300)
pp <- PointProcess(.xptr = pp_ptr)
pp$get_number_of_points()
#> [1] 96
```
