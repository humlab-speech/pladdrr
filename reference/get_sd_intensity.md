# Get standard deviation of intensity (DEPRECATED)

\*\*DEPRECATED:\*\* Use `intensity$get_standard_deviation()` instead.

## Usage

``` r
get_sd_intensity(intensity, time_range = NULL)
```

## Arguments

- intensity:

  An Intensity R6 object

- time_range:

  Optional time range

## Value

Standard deviation in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
intensity <- sound$to_intensity()
suppressWarnings(get_sd_intensity(intensity))
#> [1] 0.0001379489
```
