# Spectrum

Praat Spectrum object with direct C++ module binding (complex FFT
spectrum). Spectrum objects represent frequency-domain representations
of sounds. Uses a shared dispatch table for minimal memory per object.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ Spectrum
  object; set internally when a method returns a new Spectrum.

## Value

A `Spectrum` object with methods for frequency-domain spectral analysis.

## Query methods

- `get_lowest_frequency()` - lowest frequency (Hz)

- `get_highest_frequency()` - highest frequency (Hz)

- `get_number_of_bins()` - number of frequency bins

- `get_frequency_step()` - frequency step (Hz)

- `get_real_value_in_bin(bin)` - real part at a bin

- `get_imaginary_value_in_bin(bin)` - imaginary part at a bin

- `get_frequency_from_bin(bin)` - frequency for a bin number

- `get_bin_from_frequency(freq)` - bin number for a frequency

- `get_band_density(fmin, fmax)` - power density in a band (Pa²/Hz²)

- `get_band_energy(fmin, fmax)` - energy in a band (Pa²·s)

- `get_centre_of_gravity(power = 2.0)` - spectral center of gravity

- `get_standard_deviation(power = 2.0)` - spectral standard deviation

- `get_skewness(power = 2.0)` - spectral skewness

- `get_kurtosis(power = 2.0)` - spectral kurtosis

- `get_central_moment(moment, power = 2.0)` - central moment

## Modification methods

- `pass_hann_band(fmin, fmax, smooth = 100)` - apply a Hann band-pass
  filter

- `stop_hann_band(fmin, fmax, smooth = 100)` - apply a Hann band-stop
  filter

- `cepstral_smoothing(bandwidth)` - smooth using the cepstral method

## Transform methods

- `to_sound()` - convert to Sound (inverse FFT)

- `to_ltas(bandwidth)` - convert to long-term average spectrum

- `to_spectrogram(...)` - convert to Spectrogram

- `to_excitation(erb_density)` - convert to Excitation (auditory
  representation)

## Export methods

- `as_matrix()` - export as a numeric matrix (real + imaginary)

- `as_data_frame()` - export as a data.frame (freq, real, imag, power)

- `save(path)` - save to a file

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Spectrogram`](https://humlab-speech.github.io/pladdrr/reference/Spectrogram.md),
[`Ltas`](https://humlab-speech.github.io/pladdrr/reference/Ltas.md),
[`PowerCepstrum`](https://humlab-speech.github.io/pladdrr/reference/PowerCepstrum.md)

## Examples

``` r
sound <- Sound$create_tone(duration = 0.5, frequency = 440, sampling_rate =
 44100)
spectrum <- sound$to_spectrum(fast = FALSE)
cog <- spectrum$get_centre_of_gravity(power = 2.0)
energy <- spectrum$get_band_energy(fmin = 400, fmax = 500)

# Create a spectrum from a recording read from disk
sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
spectrum <- sound$to_spectrum(fast = TRUE)
spec_df <- spectrum$as_data_frame()
```
