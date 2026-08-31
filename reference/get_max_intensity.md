# Get maximum intensity (DEPRECATED)

\*\*DEPRECATED:\*\* Use `intensity$get_maximum()` instead.

## Usage

``` r
get_max_intensity(intensity, time_range = NULL)
```

## Arguments

- intensity:

  An Intensity R6 object

- time_range:

  Optional time range c(start, end)

## Value

Maximum intensity in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
intensity <- sound$to_intensity()
suppressWarnings(get_max_intensity(intensity))
#> [1] 90.88218
```
