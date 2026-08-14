# Ltas

Represents a long-term average spectrum (LTAS): the frequency spectrum
of a sound averaged over its whole duration.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ object; set
  internally when a method returns a new Ltas.

## Value

An Ltas object with methods for long-term average spectrum analysis.

## Details

An Ltas collapses a recording into a single spectral shape: how much
energy sits in each frequency band once the moment-to-moment detail is
averaged out. It's the standard tool for describing overall spectral
shape (tilt, resonance pattern, noise floor), useful for comparing voice
quality across speakers or checking a recording's frequency balance.

## Usage


    ltas <- sound$to_ltas(bandwidth = 100)
    ltas <- sound$to_ltas_pitch_corrected(pitch_floor = 75, pitch_ceiling = 600)

## Units and interpolation

Power values default to decibels (`unit = "dB"`); pass `"energy"` or
`"sones"` for Praat's other two averaging units. Methods that locate a
peak or trough take an `interpolation` of `"none"`, `"parabolic"` (the
default), `"cubic"`, `"sinc70"`, or `"sinc700"` - parabolic and cubic
refine the peak's position between bins instead of snapping to the
nearest one. `get_value_at_frequency()` takes a plain `interpolate` flag
(`TRUE`/`FALSE`) rather than a named method.

## Frequency domain

- `get_lowest_frequency()`, `get_highest_frequency()` - the frequency
  range, in Hz

- `get_frequency_range()` - the width of that range, in Hz

- `get_number_of_bins()` - number of frequency bins

- `get_bin_width()` - width of each bin, in Hz

- `get_frequency_from_bin(bin)` - centre frequency of a bin

- `get_bin_from_frequency(frequency)` - the bin nearest a frequency

## Query values

- `get_value_at_frequency(frequency, unit, interpolate)` - power at a
  given frequency

- `get_value_in_bin(bin)` - power in one bin, read directly with no
  interpolation

- `get_minimum(fmin, fmax, unit, interpolation)`,
  `get_maximum(fmin, fmax, unit, interpolation)` - lowest/highest power
  in a frequency range

- `get_frequency_of_minimum(fmin, fmax, interpolation)`,
  `get_frequency_of_maximum(fmin, fmax, interpolation)` - where those
  extremes occur

- `get_mean(fmin, fmax, unit)` - average power across a frequency range

- `get_standard_deviation(fmin, fmax, unit)` - how much the power varies
  across a frequency range

- `get_slope(f1min, f1max, f2min, f2max, unit)` - the difference in
  average power between two bands, e.g. spectral tilt (high-frequency
  band minus low-frequency band)

- `get_local_peak_height(environment_min, environment_max, peak_min, peak_max, unit)` -
  how far a peak rises above its surrounding band, e.g.
  harmonic-to-noise prominence

## Batch queries

Faster than calling the single-value methods in a loop, since each call
crosses into C++ once for the whole set of frequencies or ranges.

- `get_values_at_frequencies(frequencies, interpolation)` - values at
  many frequencies at once

- `get_means_batch(fmins, fmaxs, unit)` - means for many frequency
  ranges at once

- `get_peaks_batch(fmins, fmaxs, interpolation)`,
  `get_minima_batch(fmins, fmaxs, interpolation)` - peaks or troughs for
  many ranges at once, returned as a data frame

## Trend and peaks

- `compute_trend_line(fmin, fmax)` - the fitted trend line, as its own
  Ltas

- `subtract_trend_line(fmin, fmax)` - the spectrum with that trend
  removed, e.g. to flatten spectral tilt before comparing bands

- `report_spectral_trend(fmin, fmax, frequency_scale, fit_method)` -
  slope, intercept, and fit quality (R-squared, residual error) as a
  structured result; print it directly or read `$fitted_values` for the
  per-point predictions

- `get_spectral_slope(fmin, fmax, frequency_scale, fit_method)` - just
  the slope from the above, when that's all you need

- `to_spectrum_tier_peaks()` - the local maxima across the whole
  spectrum, as a
  [SpectrumTier](https://humlab-speech.github.io/pladdrr/reference/SpectrumTier.md)

## Export

- `as_data_frame()` - frequency and power as a data frame

- `as_matrix()` - frequency and power as a plain matrix

- `to_matrix()` - the Ltas converted to a full
  [Matrix](https://humlab-speech.github.io/pladdrr/reference/Matrix.md)
  object

- `save(path)` - write to a Praat text file

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Spectrum`](https://humlab-speech.github.io/pladdrr/reference/Spectrum.md),
[`Spectrogram`](https://humlab-speech.github.io/pladdrr/reference/Spectrogram.md),
[`SpectrumTier`](https://humlab-speech.github.io/pladdrr/reference/SpectrumTier.md)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
ltas <- sound$to_ltas(bandwidth = 100)
ltas$get_mean()
#> [1] -29.29521
ltas$get_number_of_bins()
#> [1] 221
```
