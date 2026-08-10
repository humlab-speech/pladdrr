# Get multiple pitch quantiles in a single call (used by VUV analysis)

Get multiple pitch quantiles in a single call (used by VUV analysis)

## Usage

``` r
pitch_get_quantiles_batch(
  pitch_xptr,
  quantiles,
  from_time = 0,
  to_time = 0,
  unit = 0L
)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch object

- quantiles:

  Numeric vector of quantile values (e.g., c(0.25, 0.75))

- from_time:

  Start time (0 = beginning)

- to_time:

  End time (0 = end)

- unit:

  Integer code for unit (0=HERTZ, etc)

## Value

Named numeric vector with quantile values

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pladdrr:::pitch_get_quantiles_batch(pitch$.xptr, c(0.25, 0.5, 0.75))
#>    q0.25     q0.5    q0.75 
#> 150.0017 150.0017 150.0017 
```
