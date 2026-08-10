# Get pitch maximum directly

Get pitch maximum directly

## Usage

``` r
pitch_get_maximum_direct(
  pitch_xptr,
  from_time = 0,
  to_time = 0,
  unit = 0L,
  interpolate = FALSE
)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch

- from_time:

  Start time

- to_time:

  End time

- unit:

  Unit code

- interpolate:

  Whether to interpolate

## Value

Maximum pitch

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pladdrr:::pitch_get_maximum_direct(pitch$.xptr)
#> [1] 150.0017
```
