# Batch Query Pitch Values at Multiple Times

Query pitch (F0) values at multiple time points in a single function
call, instead of repeated calls to \`get_value_at_time()\`.

## Usage

``` r
get_pitch_at_times(pitch, times, unit = "hertz", interpolate = TRUE)
```

## Arguments

- pitch:

  A Pitch object

- times:

  Numeric vector of time points (in seconds)

- unit:

  Unit for pitch values: "hertz" (default), "mel", "loghertz",
  "semitones", or "erb"

- interpolate:

  Logical; whether to interpolate between frames (default TRUE)

## Value

Numeric vector of pitch values at the specified times

## Performance

This function uses existing optimized C++ code.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pitch <- sound$to_pitch()
times <- seq(0.05, 0.45, length.out = 10)
f0_contour <- get_pitch_at_times(pitch, times)
```
