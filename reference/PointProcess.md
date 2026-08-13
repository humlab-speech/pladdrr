# Praat PointProcess object

A PointProcess is a sequence of time points, typically representing
glottal pulse boundaries (moments of vocal fold closure). Used for voice
quality analysis: jitter (period perturbation) and shimmer (amplitude
perturbation).

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++
  PointProcess object; set internally when a method returns a new
  PointProcess.

## Value

A `PointProcess` object with methods for glottal pulse analysis,
including jitter and shimmer.

## Query methods

- `get_number_of_points()` - total number of time points

- `get_time(index)` - time of point at index

- `get_nearest_index(time)` - index of point nearest to a given time

- `get_low_index(time)`, `get_high_index(time)` - index bounding a time

- `get_interval(time)` - time between surrounding points

- `get_mean_period(from_time, to_time, ...)` - mean glottal period

- `get_stdev_period(from_time, to_time, ...)` - SD of glottal period

- `get_number_of_periods(from_time, to_time, ...)` - number of periods
  in range

- `get_voice_breaks(from_time, to_time, ...)` - number of voice breaks

## Jitter methods

Period perturbation measures. See the Note section for units.

- `get_jitter_local(from_time, to_time, ...)` - local jitter (Jloc)

- `get_jitter_local_absolute(from_time, to_time, ...)` - local absolute
  jitter

- `get_jitter_rap(from_time, to_time, ...)` - relative average
  perturbation

- `get_jitter_ppq5(from_time, to_time, ...)` - 5-period perturbation
  quotient

- `get_jitter_ddp(from_time, to_time, ...)` - difference of differences
  of periods

## Shimmer methods

Amplitude perturbation measures; each takes a Sound. See the Note
section for units.

- `get_shimmer_local(sound, from_time, to_time, ...)` - local shimmer
  (Shim)

- `get_shimmer_local_db(sound, from_time, to_time, ...)` - local shimmer
  in dB

- `get_shimmer_apq3(sound, from_time, to_time, ...)` - 3-period
  amplitude perturbation quotient

- `get_shimmer_apq5(sound, from_time, to_time, ...)` - 5-period APQ

- `get_shimmer_apq11(sound, from_time, to_time, ...)` - 11-period APQ

- `get_shimmer_dda(sound, from_time, to_time, ...)` - difference of
  differences of amplitude

## Batch and report methods

- `get_jitter_shimmer_batch(pointprocess, sound, ...)` - all jitter and
  shimmer values as a named list, computed in one C++ call. Cache-aware:
  later calls with the same parameters return instantly.

- `voice_report(sound, pitch, ...)` - combined voice report (jitter,
  shimmer, HNR)

## Export and conversion methods

- `as_vector()`, `as_data_frame()` - export as a vector or data.frame

- `to_textgrid_vuv(max_voiced_period, ...)` - create a voiced/unvoiced
  TextGrid

- `to_pitch_tier()` - convert to a PitchTier

- `to_sound_pulse_train(...)` - create a pulse train Sound

## Note

Jitter and shimmer values are returned as decimals (0-1), not
percentages. Multiply by 100 for percentage display. The first shimmer
call caches all 11 metrics; later jitter or shimmer calls with matching
parameters return from cache (no additional C++ call).

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md),
[`AmplitudeTier`](https://humlab-speech.github.io/pladdrr/reference/AmplitudeTier.md)

## Examples

``` r
sound <- Sound$create_tone(duration = 1.0, frequency = 150, sampling_rate = 44100)
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)
jitter <- pp$get_jitter_local()
shimmer <- pp$get_shimmer_local(sound)
```
