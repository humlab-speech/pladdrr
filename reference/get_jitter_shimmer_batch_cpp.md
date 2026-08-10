# Get all jitter and shimmer measures in a single C++ call

Returns 11 voice quality measures (5 jitter, 6 shimmer) in a single
call, for when you need multiple measures at once instead of calling
individual methods separately.

## Usage

``` r
get_jitter_shimmer_batch_cpp(
  pp_xptr,
  sound_xptr,
  from_time = 0,
  to_time = 0,
  period_floor = 1e-04,
  period_ceiling = 0.02,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)
```

## Arguments

- pp_xptr:

  External pointer to PointProcess object

- sound_xptr:

  External pointer to Sound object (required for shimmer)

- from_time:

  Start time (0 = beginning)

- to_time:

  End time (0 = end)

- period_floor:

  Minimum period in seconds (default 0.0001)

- period_ceiling:

  Maximum period in seconds (default 0.02)

- max_period_factor:

  Maximum period factor (default 1.3)

- max_amplitude_factor:

  Maximum amplitude factor (default 1.6)

## Value

Named list with 11 voice quality measures

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pp <- sound$to_point_process_periodic_cc(75, 600)
pladdrr:::get_jitter_shimmer_batch_cpp(pp$.xptr, sound$.xptr)
#> $jitter_local
#> [1] 1.226397e-07
#> 
#> $jitter_local_abs
#> [1] 8.175984e-10
#> 
#> $jitter_rap
#> [1] 6.799982e-08
#> 
#> $jitter_ppq5
#> [1] 8.181443e-08
#> 
#> $jitter_ddp
#> [1] 2.039995e-07
#> 
#> $shimmer_local
#> [1] 5.722082e-09
#> 
#> $shimmer_local_db
#> [1] 4.970137e-08
#> 
#> $shimmer_apq3
#> [1] 3.45423e-09
#> 
#> $shimmer_apq5
#> [1] 4.452906e-09
#> 
#> $shimmer_apq11
#> [1] 4.532043e-09
#> 
#> $shimmer_dda
#> [1] 1.036269e-08
#> 
```
