# Get minimum intensity (DEPRECATED)

\*\*DEPRECATED:\*\* Use `intensity$get_minimum()` instead.

## Usage

``` r
get_min_intensity(intensity, time_range = NULL)
```

## Arguments

- intensity:

  An Intensity R6 object

- time_range:

  Optional time range

## Value

Minimum intensity in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
intensity <- sound$to_intensity()
suppressWarnings(get_min_intensity(intensity))
#> [1] 90.8818
```
