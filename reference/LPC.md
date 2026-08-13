# LPC

Praat LPC object for linear predictive coding analysis, created via
direct C++ module binding.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ LPC object;
  set internally when a method returns a new LPC.

## Value

An `LPC` object with methods for linear predictive coding analysis and
inverse filtering.

## Details

LPC (Linear Predictive Coding) estimates the spectral envelope of a
sound by modeling it as an autoregressive process. The LPC coefficients
describe the vocal tract filter and can be converted to formants,
spectra, or other representations.

## Creating LPC objects

LPC objects are created from Sound objects using one of several methods:

- `sound$to_lpc_burg()` - Burg method (fastest, most robust)

- `sound$to_lpc_auto()` - autocorrelation method

- `sound$to_lpc_covariance()` - covariance method

- `sound$to_lpc_marple()` - Marple method (slowest, most accurate)

## Query methods

- `get_number_of_frames()` - number of analysis frames

- `get_time_step()` - time step between frames

- `get_sampling_period()` - sampling period of the original sound

- `get_max_num_coefficients()` - maximum number of LPC coefficients

- `get_gain_at_frame(frame)` - gain value for a specific frame

- `get_coefficients_at_frame(frame)` - LPC coefficients for a specific
  frame

- `get_all_gains()` - vector of all gain values

- `get_all_coefficients()` - matrix of all LPC coefficients

## Conversion methods

- `to_formant(margin)` - not available in this build (requires CLAPACK);
  use `Sound$to_formant_burg()` for formant extraction instead

- `to_spectrum(time, ...)` - convert to a Spectrum at a specific time

- `to_matrix()` - convert to a Matrix object

## Voice source extraction (inverse filtering)

- `filter_inverse(sound)` - extract glottal flow by inverse filtering

- `filter_inverse_at_time(sound, time, channel)` - use the filter from a
  specific time

These methods remove vocal tract resonances to reveal the voice source
(glottal flow waveform), useful for voice quality research and vocal
fold dynamics.

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Formant`](https://humlab-speech.github.io/pladdrr/reference/Formant.md),
[`Spectrum`](https://humlab-speech.github.io/pladdrr/reference/Spectrum.md),
[`LFCC`](https://humlab-speech.github.io/pladdrr/reference/LFCC.md)

## Examples

``` r
# Load sound
sound <- Sound$create_tone(frequency = 150, duration = 0.3)

# Compute LPC (Burg method is recommended)
lpc <- sound$to_lpc_burg(
  prediction_order = 16,
  analysis_width = 0.025,
  time_step = 0.005,
  pre_emphasis_frequency = 50.0
)

# Query properties
n_frames <- lpc$get_number_of_frames()
gains <- lpc$get_all_gains()
coeffs <- lpc$get_all_coefficients()

# Get coefficients for a specific frame
coef_frame1 <- lpc$get_coefficients_at_frame(1)

# Convert to other representations
spectrum <- lpc$to_spectrum(time = 0.15, df_min = 20)

# Extract voice source (glottal flow) via inverse filtering at a given time
midpoint <- sound$get_duration() / 2
glottal_flow <- lpc$filter_inverse_at_time(sound, time = midpoint)
```
