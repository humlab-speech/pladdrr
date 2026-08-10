# Get pitch quantile directly

Get pitch quantile directly

## Usage

``` r
pitch_get_quantile_direct(
  pitch_xptr,
  quantile,
  from_time = 0,
  to_time = 0,
  unit = 0L
)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch

- quantile:

  Quantile (0-1, 0.5 = median)

- from_time:

  Start time

- to_time:

  End time

- unit:

  Unit code

## Value

Quantile value

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pladdrr:::pitch_get_quantile_direct(pitch$.xptr, 0.5)
#> [1] 150.0017
```
