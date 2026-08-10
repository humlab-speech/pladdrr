# Batch query pitch strengths at multiple time points

Batch query pitch strengths at multiple time points

## Usage

``` r
pitch_get_strengths_at_times(pitch_xptr, times, unit = 0L, interpolate = TRUE)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch object

- times:

  Numeric vector of time points

- unit:

  Integer code for unit

- interpolate:

  Logical, whether to interpolate

## Value

Numeric vector of pitch strengths

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pladdrr:::pitch_get_strengths_at_times(pitch$.xptr, c(0.2, 0.5, 0.8))
#> [1] 0.9999652 0.9999652 0.9999652
```
