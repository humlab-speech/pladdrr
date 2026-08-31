# Cochleagram

A Praat Cochleagram: the output of a bank of auditory filters modeling
the basilar membrane, over time.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ Cochleagram
  object; set internally when a method returns a new Cochleagram.

## Value

A `Cochleagram` object.

## Details

Frequency runs along the Bark scale (0-25.6 Bark) rather than Hertz,
matching the perceptual frequency resolution of the ear. Create one from
a Sound with `sound$to_cochleagram()` or `sound$to_cochleagram_edb()`;
slice it at a time point to get an Excitation pattern, from which
loudness can be read off.

## Usage


    cochleagram <- sound$to_cochleagram()

## Query methods

- `get_start_time()`, `get_end_time()`,
  [`get_duration()`](https://humlab-speech.github.io/pladdrr/reference/get_duration.md) -
  time domain in seconds

- `get_number_of_frames()`, `get_time_step()` - time sampling

- `get_time_from_column(i_col)` - time at a 1-based frame index

- `get_lowest_frequency()`, `get_highest_frequency()` - frequency range
  in Bark

- `get_number_of_frequency_bands()`, `get_frequency_step()` - frequency
  sampling

- `get_frequency_from_row()` - frequency at a 1-based band index

- `get_value_at_time_and_frequency(time, freq_bark)` - excitation level
  at a point

- `get_loudness_at_time(time)` - loudness (sone) at a time

## Transformation and export

- `to_excitation(time)` - excitation pattern (Excitation object) at a
  time

- `get_difference(other, tmin, tmax)` - distance between two
  cochleagrams

- `as_matrix()` - values as a numeric matrix (frequency bands x frames)

## See also

\[Excitation\], \[Sound\]

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate =
 44100)
cochleagram <- sound$to_cochleagram()
cochleagram$get_duration()
#> [1] 0.3
cochleagram$get_loudness_at_time(0.15)
#> [1] 46.78787
```
