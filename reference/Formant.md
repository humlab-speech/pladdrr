# Formant

Formant objects represent vocal tract resonance frequencies over time.
Created from a Sound via formant tracking algorithms (Burg,
Split-Levinson, or Willems). Formant frequencies and bandwidths are the
primary acoustic correlates of vowel quality in speech.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ Formant
  object; set internally when a method returns a new Formant.

## Value

A `Formant` object with methods for querying formant frequencies and
bandwidths at time points or across the full contour.

## Information

- `get_number_of_frames()` - number of analysis frames

- `get_time_step()` - time step between frames (s)

- `get_min_num_formants()`, `get_max_num_formants()` - formant count
  range per frame

## Point queries (single time)

- `get_value_at_time(formant_number, time, unit)` - formant frequency at
  time

- `get_bandwidth_at_time(formant_number, time, unit)` - formant
  bandwidth at time

- `get_all_values_at_time(time, max_formants, unit)` - all formant
  values at a time point

## Statistics (over time range)

- `get_mean(formant_number, from_time, to_time, unit)` - mean formant
  frequency

- `get_standard_deviation(formant_number, from_time, to_time, unit)` -
  standard deviation

- `get_minimum(formant_number, from_time, to_time, unit)` - minimum
  value

- `get_maximum(formant_number, from_time, to_time, unit)` - maximum
  value

- `get_quantile(formant_number, quantile, from_time, to_time, unit)` -
  quantile

- `get_time_of_minimum(...)`, `get_time_of_maximum(...)` - time of
  extremum

## Batch and vectorized

- `get_formant_track(formant_number, unit)` - full track for one formant

- `get_bandwidth_track(formant_number, unit)` - full bandwidth track

- `get_values_at_times(formant_number, times, unit)` - values at an
  arbitrary vector of times

- `get_all_formant_tracks(max_formants, unit)` - all formants as a
  matrix

## Export

- `as_data_frame(max_formants)` - export as a data.frame, long format:
  one row per (frame, formant number), with columns `time`, `formant`,
  `frequency` (Hz), and `bandwidth` (Hz). Matches
  `FormantPath$as_data_frame()`.

- `save(filepath)` - save to a Praat binary file

## Transform

- `to_formant_tier(formant_number)` - extract one formant as a
  FormantTier

- `to_formant_modeler()` - create a polynomial trajectory model

- `down_to_formant_tier()` - extract all formants as a FormantTier

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`LPC`](https://humlab-speech.github.io/pladdrr/reference/LPC.md),
[`FormantPath`](https://humlab-speech.github.io/pladdrr/reference/FormantPath.md),
[`FormantModeler`](https://humlab-speech.github.io/pladdrr/reference/FormantModeler.md)

## Examples

``` r
# Self-contained example with generated tone
sound <- Sound$create_tone(duration = 1.0, frequency = 150, sampling_rate = 44100)
formant <- sound$to_formant_burg(
  time_step = 0.01, max_number_of_formants = 5,
  maximum_formant = 5500, window_length = 0.025, pre_emphasis_from = 50
)
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5, unit = "hertz")

# The same analysis on a recording read from disk
sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
formant <- sound$to_formant_burg(
  time_step = 0.01, max_number_of_formants = 5,
  maximum_formant = 5500, window_length = 0.025, pre_emphasis_from = 50
)
f1_at_02s <- formant$get_value_at_time(formant_number = 1, time = 0.2, unit = "hertz")
mean_f1 <- formant$get_mean(formant_number = 1, from_time = 0, to_time = 0, unit = "hertz")
```
