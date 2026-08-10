# Query PointProcess at multiple times to get nearest indices

Query PointProcess at multiple times to get nearest indices

## Usage

``` r
pointprocess_get_nearest_indices(pp_xptr, times)
```

## Arguments

- pp_xptr:

  External pointer to PointProcess object

- times:

  Numeric vector of query times

## Value

Integer vector of nearest point indices (1-based)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pp <- sound$to_pointprocess_periodic_cc()
#> Warning: time_step, max_period_factor, and max_amplitude_factor are not used by Sound_to_PointProcess_periodic_cc(). Only pitch_floor and pitch_ceiling are used.
pladdrr:::pointprocess_get_nearest_indices(pp$.xptr, c(0.2, 0.5, 0.8))
#> [1]  30  75 120
```
