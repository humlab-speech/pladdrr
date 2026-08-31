# Get intensity at a specific time (DEPRECATED)

\*\*DEPRECATED:\*\* Use `intensity$get_value_at_time(time)` instead.

## Usage

``` r
get_intensity_at_time(intensity, time, interpolate = FALSE)
```

## Arguments

- intensity:

  An Intensity R6 object

- time:

  Time in seconds

- interpolate:

  Whether to interpolate

## Value

Intensity in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
intensity <- sound$to_intensity()
suppressWarnings(get_intensity_at_time(intensity, 0.25))
#> [1] 90.8818
```
