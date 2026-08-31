# Batch Query Pitch Strengths at Multiple Times

Query pitch strength (voicing confidence) at multiple time points.

## Usage

``` r
get_pitch_strengths_at_times(pitch, times, unit = "hertz", interpolate = TRUE)
```

## Arguments

- pitch:

  A Pitch object

- times:

  Numeric vector of time points (in seconds)

- unit:

  Unit for pitch (used internally by Praat)

- interpolate:

  Logical; whether to interpolate (default TRUE)

## Value

Numeric vector of pitch strengths (0-1) at the specified times

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
pitch <- sound$to_pitch()
times <- seq(0.05, 0.45, length.out = 10)
strengths <- get_pitch_strengths_at_times(pitch, times)
```
