# Get Pitch Quantile Directly (Bypass R6)

Get a specific quantile of pitch values without R6 wrapper overhead.
Useful for VUV analysis workflows where you need Q1, Q3 for adaptive
pitch range.

## Usage

``` r
get_pitch_quantile_direct(
  pitch,
  quantile,
  from_time = 0,
  to_time = 0,
  unit = c("hertz", "semitones", "mel", "erb", "loghertz")
)
```

## Arguments

- pitch:

  Pitch object or external pointer

- quantile:

  Quantile value (0.25 for Q1, 0.75 for Q3, 0.5 for median)

- from_time:

  Start time (0 = beginning)

- to_time:

  End time (0 = end)

- unit:

  Pitch unit ("hertz", "semitones", "mel", "erb", "loghertz")

## Value

Quantile value in specified unit

## See also

[`get_pitch_quantiles_batch`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_quantiles_batch.md)
for getting multiple quantiles at once

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
pitch_ptr <- to_pitch_cc_direct(sound)
q1 <- get_pitch_quantile_direct(pitch_ptr, 0.25)
q3 <- get_pitch_quantile_direct(pitch_ptr, 0.75)
```
