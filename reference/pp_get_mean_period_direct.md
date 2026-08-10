# Get PointProcess Mean Period Directly (Bypass R6)

Get mean period from PointProcess without R6 wrapper overhead. Critical
for VUV analysis workflows.

## Usage

``` r
pp_get_mean_period_direct(
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

  Minimum period (default: 0.0001)

- period_ceiling:

  Maximum period (default: 0.02)

- max_period_factor:

  Maximum period factor (default: 1.3)

## Value

Mean period in seconds

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pp_ptr <- to_point_process_from_sound_and_pitch(sound, pitch)
mean_period <- pp_get_mean_period_direct(pp_ptr)
```
