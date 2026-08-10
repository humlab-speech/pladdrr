# Get pitch mean directly

Get pitch mean directly

## Usage

``` r
pitch_get_mean_direct(pitch_xptr, from_time = 0, to_time = 0, unit = 0L)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch

- from_time:

  Start time (0 = start)

- to_time:

  End time (0 = end)

- unit:

  Unit code

## Value

Mean pitch

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pladdrr:::pitch_get_mean_direct(pitch$.xptr)
#> [1] 150.0017
```
