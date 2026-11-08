# Sound

Represents a digitized acoustic signal (a Praat Sound object).

## Arguments

- path:

  Path to an audio file. See the File I/O section for supported formats.

- .xptr:

  Not for direct use. External pointer to the underlying C++ Sound
  object; set internally when a method returns a new Sound.

## Value

A Sound object.

## Details

A Sound holds one or more channels of audio sampled at regular
intervals. It is the starting point for most acoustic analyses in
pladdrr: pitch, formants, intensity, and spectral measures all begin
from a Sound.

## File I/O

The constructor tries two readers in order:

1.  The native Praat reader, which handles WAV, AIFF, AIFC, NIST, and
    NeXT/Sun files without extra packages, and is the fastest path.

2.  The `av` package, used as a fallback for everything else, including
    FLAC, MP3, and OGG Vorbis. The FLAC and MP3 decoder sources were
    dropped from the vendored Praat tree in v4.9.5 to keep the CRAN
    tarball within limits, so those formats need `av` installed
    (`install.packages("av")`). Without it, reading a FLAC or MP3 file
    raises an error naming the missing package. The fallback announces
    itself once per file read with a `pladdrr_decoder_fallback` warning
    (a warning rather than a console message, so a caller can catch it,
    filter it or turn it into an error); sample values, channel count
    and duration are then those of the file (a multichannel file comes
    back as a multichannel Sound), so a lossless FLAC reads like the WAV
    it came from. AAC/MP4 containers carry an encoder delay that libav
    does not trim, so such a file comes back a few milliseconds longer
    than what was written (the 2026-11 audit measured 8000 samples
    written, 8192 read at 8 kHz): trim with `Sound$extract()` when you
    need sample-exact alignment.

Convert to WAV up front if you want to avoid the `av` dependency
entirely.

## Usage

    # From file
    sound <- Sound(path = "audio.wav")

    # From numeric data
    sound <- Sound$from_values(values, sampling_rate = 44100)

    # Synthetic tone
    sound <- Sound$create_tone(frequency = 440, duration = 1.0)

## Query methods

- [`get_duration()`](https://humlab-speech.github.io/pladdrr/reference/get_duration.md) -
  duration in seconds

- `get_sampling_frequency()` - sampling rate in Hz

- `get_number_of_samples()` - number of samples

- `get_number_of_channels()` - number of channels

- `get_value_at_time()` - amplitude at a given time

- `get_rms()`, `get_energy()`, `get_power()` - energy measures

- `get_intensity_db()` - intensity in dB

- `get_minimum(from_time, to_time, channel)`,
  `get_maximum(from_time, to_time, channel)`,
  `get_mean(from_time, to_time, channel)` - amplitude statistics on one
  channel, or on all of them when `channel = 0`

- `get_values(channel)` - sample values as a numeric vector

- `get_sample_times()` - sample times as a numeric vector

## Analysis methods

- `to_pitch()` - extract pitch contour (F0)

- `to_formant_burg()` - extract formants (F1, F2, F3, ...)

- `to_intensity()` - extract intensity contour

- `to_harmonicity_cc()` - harmonics-to-noise ratio

- `to_harmonicity_gne()` - glottal-to-noise excitation ratio (GNE)

- `extract_electroglottogram(channel, invert)` - extract an
  electroglottogram (EGG) from a channel

- `to_spectrum()` - frequency spectrum

- `to_spectrogram()` - time-frequency representation

- `to_ltas()` - long-term average spectrum

- `to_ltas_pitch_corrected()` - pitch-corrected LTAS (voice quality)

- `to_formant_robust()` - outlier-resistant formant tracking

- `to_mel_spectrogram()` - mel-scale spectrogram

- `to_bark_spectrogram()` - Bark-scale spectrogram

- `to_point_process_periodic_cc()` - extract glottal pulses

## Signal processing

- `lengthen()` - time-stretch using overlap-add

- `autocorrelate()` - autocorrelation function

- [`convolve()`](https://rdrr.io/r/stats/convolve.html) - convolve with
  another sound

- `cross_correlate()` - cross-correlate with another sound

- `deepen_band_modulation()` - hearing enhancement

- `filter_by_formant()` - filter with a Formant object

- `filter_by_formant_noscale()` - filter without scaling

## Extraction

- `extract_channel()` - extract a single channel

- `extract_part(from, to, window_shape, relative_width, preserve_times)` -
  extract a time range, with optional windowing. Supports 12 window
  shapes (rectangular, triangular, parabolic, hanning, hamming,
  gaussian1-5, kaiser1-2); see
  <https://www.fon.hum.uva.nl/praat/manual/Sound__Extract_part___.html>.

## Modification

- `scale_intensity()` - scale to a target dB level (in place)

- `scale_peak()` - scale peak amplitude (in place)

- `pre_emphasize()` - high-pass filter (in place)

- `de_emphasize()` - low-pass filter (in place)

- `resample()` - resample to a different rate (returns a new object)

- `convert_to_mono()` - average channels to mono (returns a new object)

- `concatenate()` - append another sound (returns a new object)

- `mix()` - mix with another sound (returns a new object)

## Export

- `as_matrix()` - export as a numeric matrix

- `as_data_frame()` - export as a data.frame

- [`save()`](https://rdrr.io/r/base/save.html) - save to an audio file

## See also

[`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md),
[`Formant`](https://humlab-speech.github.io/pladdrr/reference/Formant.md),
[`Intensity`](https://humlab-speech.github.io/pladdrr/reference/Intensity.md),
[`Spectrum`](https://humlab-speech.github.io/pladdrr/reference/Spectrum.md)

## Examples

``` r
# Synthetic tone, no external file needed
sound <- Sound$create_tone(frequency = 440, duration = 1.0)
pitch <- sound$to_pitch()
formants <- sound$to_formant_burg()

cat("Duration:", sound$get_duration(), "s\n")
#> Duration: 1 s
cat("Sample rate:", sound$get_sampling_frequency(), "Hz\n")
#> Sample rate: 44100 Hz

part <- sound$extract_part(0.2, 0.5)
```
