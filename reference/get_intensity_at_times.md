# Batch Query Intensity Values at Multiple Times

Query intensity (amplitude in dB) at multiple time points in a single
call.

## Usage

``` r
get_intensity_at_times(
  intensity,
  times,
  interpolate = "cubic",
  interpolation = NULL
)
```

## Arguments

- intensity:

  An Intensity object

- times:

  Numeric vector of time points (in seconds)

- interpolate:

  Interpolation method: "nearest", "linear", "cubic" (default), or
  "sinc70". Kept for backward compatibility; prefer \`interpolation\`.

- interpolation:

  Alias for \`interpolate\` (consistent with R6 method naming). When
  provided, supersedes \`interpolate\`.

## Value

Numeric vector of intensity values (in dB) at the specified times

## Performance

Uses existing optimized C++ code.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
intensity <- sound$to_intensity()
times <- seq(0.05, 0.45, length.out = 10)
intensities <- get_intensity_at_times(intensity, times)
```
