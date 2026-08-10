# Get PointProcess standard deviation of periods directly

Get PointProcess standard deviation of periods directly

## Usage

``` r
get_point_process_stdev_period_direct(
  pp_xptr,
  from_time = 0,
  to_time = 0,
  period_floor = 1e-04,
  period_ceiling = 0.02,
  max_period_factor = 1.3
)
```

## Arguments

- pp_xptr:

  External pointer to PointProcess

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
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pp <- sound$to_point_process_periodic_cc(75, 600)
pladdrr:::get_point_process_stdev_period_direct(pp$.xptr)
#> [1] 6.403394e-10
```
