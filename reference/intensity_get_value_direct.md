# Get intensity value at time directly

Get intensity value at time directly

## Usage

``` r
intensity_get_value_direct(intensity_xptr, time, interpolation = 2L)
```

## Arguments

- intensity_xptr:

  External pointer to Intensity

- time:

  Time in seconds

- interpolation:

  0=nearest, 1=linear, 2=cubic, 3=sinc70, 4=sinc700

## Value

Intensity in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
intensity <- sound$to_intensity()
pladdrr:::intensity_get_value_direct(intensity$.xptr, 0.25)
#> [1] 90.88181
```
