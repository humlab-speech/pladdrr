# Intensity

Intensity objects represent sound power (loudness) over time, measured
in decibels (dB) relative to the auditory threshold.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ Intensity
  object; set internally when a method returns a new Intensity.

## Value

An `Intensity` object with methods for querying intensity values (in dB)
at time points or across the full contour.

## Details

Created from a Sound using intensity contour extraction.

## Information methods

- [`get_duration()`](https://humlab-speech.github.io/pladdrr/reference/get_duration.md) -
  duration of the intensity contour (s)

- `get_time_step()` - time step between frames (s)

## Point query methods

- `get_value_at_time(time, interpolation)` - intensity at a time point
  (dB)

- `get_values_at_times(times, interpolation)` - intensity at a vector of
  times (batch)

## Statistics methods (over a time range)

- `get_mean(from_time, to_time, averaging_method)` - mean intensity (dB)

- `get_standard_deviation(from_time, to_time)` - standard deviation (dB)

- `get_minimum(from_time, to_time, interpolation)` - minimum intensity

- `get_maximum(from_time, to_time, interpolation)` - maximum intensity

- `get_quantile(quantile, from_time, to_time)` - quantile

- `get_time_of_minimum(...)`, `get_time_of_maximum(...)` - time of
  extremum

## Export methods

- `as_vector()` - raw intensity values (dB)

- `as_data_frame()` - export as a data.frame (time, intensity)

- `save(filepath)` - save to a Praat binary file

## Interpolation

Codes: `"nearest"` (0), `"linear"` (1), `"cubic"` (2, default),
`"sinc70"` (3), `"sinc700"` (4). Averaging methods: `"energy"` (0,
default), `"sones"` (1), `"db"` (2).

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md),
[`IntensityTier`](https://humlab-speech.github.io/pladdrr/reference/IntensityTier.md)

## Examples

``` r
sound <- Sound$create_tone(duration = 1.0, frequency = 200, sampling_rate =
 44100)
intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.0)
mean_int <- intensity$get_mean()
df <- intensity$as_data_frame()

# The same analysis on a recording read from disk
sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
intensity <- sound$to_intensity(minimum_pitch = 100, time_step = 0.0)
int_at_02s <- intensity$get_value_at_time(0.2)
```
