# Get pitch standard deviation directly

Get pitch standard deviation directly

## Usage

``` r
pitch_get_stdev_direct(pitch_xptr, from_time = 0, to_time = 0, unit = 0L)
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

## Value

Standard deviation

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pladdrr:::pitch_get_stdev_direct(pitch$.xptr)
#> [1] 2.967089e-09
```
