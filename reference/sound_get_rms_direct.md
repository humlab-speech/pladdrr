# Get Sound RMS directly

Get Sound RMS directly

## Usage

``` r
sound_get_rms_direct(sound_xptr, from_time = 0, to_time = 0)
```

## Arguments

- sound_xptr:

  External pointer to Sound

- from_time:

  Start time (0 = start)

- to_time:

  End time (0 = end)

## Value

RMS value

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)
pladdrr:::sound_get_rms_direct(sound$.xptr)
#> [1] 0.7000357
```
