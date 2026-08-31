# Get mean intensity (DEPRECATED)

\*\*DEPRECATED:\*\* Use `intensity$get_mean()` instead.

## Usage

``` r
get_mean_intensity(intensity, time_range = NULL)
```

## Arguments

- intensity:

  An Intensity R6 object

- time_range:

  Optional time range c(start, end)

## Value

Mean intensity in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
intensity <- sound$to_intensity()
suppressWarnings(get_mean_intensity(intensity))
#> [1] 90.882
```
