# Sound

Represents a digitized acoustic signal (Praat Sound object).

## Arguments

- path:

  Path to an audio file. Read natively for WAV/AIFF/AIFC/NIST/NeXT;
  FLAC, MP3 and other formats are read through the suggested \`av\`
  package.

- .xptr:

  Internal use only - external pointer to C++ Sound object

## Value

A Sound object (function wrapper with methods)

## Details

A Sound contains one or more channels of audio sampled at regular
intervals. This is the entry point for most acoustic analyses in
pladdrr.

## File I/O

The Sound constructor tries two readers in order:

1\. \*\*Native Praat reader\*\* — WAV, AIFF, AIFC, NIST, NeXT/Sun. No
extra packages needed, and the fastest path. 2. \*\*\`av\` package
fallback\*\* — everything else, including \*\*FLAC, MP3\*\* and OGG
Vorbis. The FLAC and MP3 decoder sources were dropped from the vendored
Praat tree in v4.9.5 to keep the CRAN tarball within limits, so those
formats need \`av\` installed (\`install.packages("av")\`). Without it,
reading a FLAC or MP3 file raises an error naming the missing package.

Convert to WAV up front if you want to avoid the dependency entirely.

## Usage

“\`r \# From file sound \<- Sound(path = "audio.wav")

\# From numeric data sound \<- Sound\$from_values(values, sampling_rate
= 44100)

\# Create synthetic tone sound \<- Sound\$create_tone(frequency = 440,
duration = 1.0) “\`

## Query Methods

\- \`get_duration()\` - Duration in seconds -
\`get_sampling_frequency()\` - Sampling rate in Hz -
\`get_number_of_samples()\` - Number of samples -
\`get_number_of_channels()\` - Number of channels -
\`get_value_at_time()\` - Amplitude at specific time - \`get_rms()\`,
\`get_energy()\`, \`get_power()\` - Energy measures -
\`get_intensity_db()\` - Intensity in dB - \`get_minimum()\`,
\`get_maximum()\`, \`get_mean()\` - Amplitude statistics -
\`get_values(channel)\` - \*\*NEW\*\*: Get sample values as numeric
vector (fast, no data frame) - \`get_sample_times()\` - \*\*NEW\*\*: Get
sample times as numeric vector (fast, no data frame)

## Analysis Methods

\- \`to_pitch()\` - Extract pitch contour (F0) - \`to_formant_burg()\` -
Extract formants (F1, F2, F3, ...) - \`to_intensity()\` - Extract
intensity contour - \`to_harmonicity_cc()\` - Harmonics-to-noise ratio -
\`to_harmonicity_gne()\` - Glottal-to-Noise Excitation ratio (GNE) -
\`to_spectrum()\` - Frequency spectrum - \`to_spectrogram()\` -
Time-frequency representation - \`to_ltas()\` - Long-term average
spectrum - \`to_ltas_pitch_corrected()\` - Pitch-corrected LTAS (voice
quality) - \`to_formant_robust()\` - Outlier-resistant formant
tracking - \`to_mel_spectrogram()\` - Mel-scale spectrogram -
\`to_bark_spectrogram()\` - Bark-scale spectrogram -
\`to_point_process_periodic_cc()\` - Extract glottal pulses

## Signal Processing

\- \`lengthen()\` - Time-stretch using overlap-add -
\`autocorrelate()\` - Autocorrelation function - \`convolve()\` -
Convolve with another sound - \`cross_correlate()\` - Cross-correlate
with another sound - \`deepen_band_modulation()\` - Hearing
enhancement - \`filter_by_formant()\` - Filter with Formant object -
\`filter_by_formant_noscale()\` - Filter without scaling

## Extraction

\- \`extract_channel()\` - Extract single channel - \`extract_part(from,
to, window_shape, relative_width, preserve_times)\` - Extract time range
with optional windowing \* Supports 12 window shapes: rectangular,
triangular, parabolic, hanning, hamming, gaussian1-5, kaiser1-2 \* See
<https://www.fon.hum.uva.nl/praat/manual/Sound__Extract_part___.html>

## Modification

\- \`scale_intensity()\` - Scale to target dB level (in-place) -
\`scale_peak()\` - Scale peak amplitude (in-place) -
\`pre_emphasize()\` - High-pass filter (in-place) - \`de_emphasize()\` -
Low-pass filter (in-place) - \`resample()\` - Resample to different rate
(new object) - \`convert_to_mono()\` - Average channels to mono (new
object) - \`concatenate()\` - Append another sound (new object) -
\`mix()\` - Mix with another sound (new object)

## Export

\- \`as_matrix()\` - Export as numeric matrix - \`as_data_frame()\` -
Export as data.frame - \`save()\` - Save to audio file

## See also

\[Pitch\], \[Formant\], \[Intensity\], \[Spectrum\]

## Examples

``` r
# Basic workflow (synthetic tone, no external file needed)
sound <- Sound$create_tone(frequency = 440, duration = 1.0)
pitch <- sound$to_pitch()
formants <- sound$to_formant_burg()

# Query properties
cat("Duration:", sound$get_duration(), "s\n")
#> Duration: 1 s
cat("Sample rate:", sound$get_sampling_frequency(), "Hz\n")
#> Sample rate: 44100 Hz

# Extract portion
part <- sound$extract_part(0.2, 0.5)

# Sound(path = "audio.wav") reads from a WAV/AIFF/etc. file the same way
```
