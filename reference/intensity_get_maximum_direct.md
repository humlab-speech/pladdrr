# Get intensity maximum directly

Get intensity maximum directly

## Usage

``` r
intensity_get_maximum_direct(intensity_xptr, from_time = 0, to_time = 0)
```

## Arguments

- intensity_xptr:

  External pointer to Intensity

- from_time:

  Start time

- to_time:

  End time

## Value

Maximum intensity in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
intensity <- sound$to_intensity()
pladdrr:::intensity_get_maximum_direct(intensity$.xptr)
#> [1] 90.88958
```
