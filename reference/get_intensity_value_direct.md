# Get Single Intensity Value Directly

Get Single Intensity Value Directly

## Usage

``` r
get_intensity_value_direct(intensity, time, interpolation = "cubic")
```

## Arguments

- intensity:

  Intensity object or external pointer

- time:

  Time in seconds

- interpolation:

  Interpolation method

## Value

Intensity in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
intensity_ptr <- to_intensity_direct(sound)
get_intensity_value_direct(intensity_ptr, 0.25)
#> [1] 90.88181
```
