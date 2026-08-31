# Spectrogram

A Spectrogram is a time-frequency representation of sound: a matrix of
power values indexed by time (columns) and frequency (rows). Created
from a Sound via short-time Fourier transform (STFT).

## Value

A Spectrogram object.

## Query methods

- `get_start_time()`, `get_end_time()` - time range (s)

- `get_time_step()` - time between frames (s)

- `get_number_of_time_bins()` - number of time frames

- `get_lowest_frequency()`, `get_highest_frequency()` - frequency range
  (Hz)

- `get_frequency_step()` - frequency resolution (Hz)

- `get_number_of_frequency_bins()` - number of frequency bins

## Index mapping

- `get_time_from_frame(frame)` - time for a frame index

- `get_frame_from_time(time)` - frame index for a time

- `get_frequency_from_bin(bin)` - frequency for a bin index

- `get_bin_from_frequency(freq)` - bin index for a frequency

## Power queries

- `get_power_at(time, frequency)` - power at a time-frequency point

- `get_power_at_points(times, frequencies)` - power at a vector of
  points (batch)

- `get_frame(time)` - full frequency spectrum at one time

- `get_frequency_slice(frequency)` - time series at one frequency

- `get_frames(times)` - matrix of frames at multiple times

- `get_band_power(fmin, fmax)` - integrated power in a frequency band

- `get_spectral_moments_batch(power)` - center of gravity, SD, skewness,
  and kurtosis per frame (single C++ call)

## Export

- `as_matrix(include_dimnames)` - export as a numeric matrix

- `as_data_frame()` - export as a data.frame

## Transform

- `to_spectrum(time)` - extract a spectrum at one time point

- `to_dtw(reference)` - dynamic time warping between spectrograms

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Spectrum`](https://humlab-speech.github.io/pladdrr/reference/Spectrum.md),
[`DTW`](https://humlab-speech.github.io/pladdrr/reference/DTW.md),
[`ComplexSpectrogram`](https://humlab-speech.github.io/pladdrr/reference/ComplexSpectrogram.md)

## Examples

``` r
snd <- Sound$create_tone(duration = 0.5, frequency = 440, sampling_rate =
 44100)
spec <- snd$to_spectrogram(window_length = 0.005, max_frequency = 5000)
power <- spec$get_power_at(time = 0.25, frequency = 440)
```
