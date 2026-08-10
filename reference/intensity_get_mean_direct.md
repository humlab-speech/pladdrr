# Get intensity mean directly

Get intensity mean directly

## Usage

``` r
intensity_get_mean_direct(
  intensity_xptr,
  from_time = 0,
  to_time = 0,
  averaging_method = 0L
)
```

## Arguments

- intensity_xptr:

  External pointer to Intensity

- from_time:

  Start time

- to_time:

  End time

- averaging_method:

  0=energy, 1=sones, 2=dB

## Value

Mean intensity

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
intensity <- sound$to_intensity()
pladdrr:::intensity_get_mean_direct(intensity$.xptr)
#> [1] 90.88496
```
