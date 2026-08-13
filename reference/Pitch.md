# Pitch

Fundamental frequency (F0) contour of a sound (a Praat Pitch object).

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ Pitch
  object; set internally when a method returns a new Pitch.

## Value

A Pitch object.

## Details

Created from a Sound via autocorrelation or cross-correlation pitch
tracking. Supports multiple unit systems: hertz, semitones (re 1 Hz, 100
Hz, or custom), mel, and erb; see the Units section for the full set of
codes.

## Information

- `get_number_of_frames()` - number of analysis frames

- `get_time_step()` - time step between frames, in seconds

- `count_voiced_frames()` - number of frames with voiced (non-zero)
  pitch

## Point queries

- `get_value_at_time(time, unit, interpolate)` - F0 at a time point

- `get_values_at_times(times, unit, interpolate)` - F0 at a vector of
  times (batch)

- `get_strength_at_time(time)` - strength (voicing likelihood) at a time

- `get_strengths_at_times(times)` - strengths at a vector of times
  (batch)

## Statistics

Computed over a time range.

- `get_mean(from_time, to_time, unit)` - mean F0

- `get_standard_deviation(from_time, to_time, unit)` - standard
  deviation

- `get_minimum(from_time, to_time, unit, interpolate)` - minimum F0

- `get_maximum(from_time, to_time, unit, interpolate)` - maximum F0

- `get_quantile(quantile, from_time, to_time, unit)` - quantile of F0

- `get_time_of_minimum(...)`, `get_time_of_maximum(...)` - time of
  extremum

## Export

- `as_vector()`, `as_data_frame()` - export as vector or data.frame

- `get_times_vector()` - frame time points

- `as_matrix()` - F0 values as a matrix (frames by candidates)

## Transform

- `to_point_process(voicing_threshold, octave_cost, ...)` - convert to a
  PointProcess (glottal pulses)

- `down_to_pitch_tier()` - convert to a PitchTier (editable pitch
  contour)

## Units

F0 unit codes: `"hertz"` (0), `"semitones re 1 Hz"` (1),
`"semitones re 100 Hz"` (2), `"semitones re 200 Hz"` (3),
`"semitones re 440 Hz"` (4), `"mel"` (5), `"log hertz"` (6), `"erb"`
(7). Default is `"hertz"`.

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`PointProcess`](https://humlab-speech.github.io/pladdrr/reference/PointProcess.md),
[`PitchTier`](https://humlab-speech.github.io/pladdrr/reference/PitchTier.md)

## Examples

``` r
sound <- Sound$create_tone(duration = 1.0, frequency = 200, sampling_rate = 44100)
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
min_f0 <- pitch$get_minimum(from_time = 0, to_time = 0, unit = "hertz")
df <- as.data.frame(pitch)

# The same analysis on a recording read from disk
sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
n_voiced <- pitch$count_voiced_frames()
```
