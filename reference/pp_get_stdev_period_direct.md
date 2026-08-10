# Get PointProcess Period Standard Deviation Directly (Bypass R6)

Get standard deviation of periods from PointProcess without R6 wrapper
overhead.

## Usage

``` r
pp_get_stdev_period_direct(
  pointprocess,
  from_time = 0,
  to_time = 0,
  period_floor = 1e-04,
  period_ceiling = 0.02,
  max_period_factor = 1.3
)
```

## Arguments

- pointprocess:

  PointProcess object or external pointer

- from_time:

  Start time (0 = beginning)

- to_time:

  End time (0 = end)

- period_floor:

  Minimum period

- period_ceiling:

  Maximum period

- max_period_factor:

  Maximum period factor

## Value

Standard deviation of periods

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pp_ptr <- to_point_process_from_sound_and_pitch(sound, pitch)
sd_period <- pp_get_stdev_period_direct(pp_ptr)
```
