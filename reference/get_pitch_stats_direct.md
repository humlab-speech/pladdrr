# Get Pitch Statistics Directly

Get all common pitch statistics in a single call, bypassing R6 dispatch.

## Usage

``` r
get_pitch_stats_direct(
  pitch,
  from_time = 0,
  to_time = 0,
  unit = c("hertz", "semitones", "mel", "erb", "loghertz")
)
```

## Arguments

- pitch:

  Pitch object or external pointer

- from_time:

  Start time (0 = start of signal)

- to_time:

  End time (0 = end of signal)

- unit:

  Character: "hertz", "semitones", "mel", "erb", "loghertz"

## Value

Named list with: min, max, mean, stdev, median, q25, q75, count_voiced

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pitch <- sound$to_pitch_cc()

# Direct call
stats <- get_pitch_stats_direct(pitch)

# Equivalent R6 calls, one boundary crossing per statistic:
min_val <- pitch$get_minimum(0, 0, "hertz")
max_val <- pitch$get_maximum(0, 0, "hertz")
```
