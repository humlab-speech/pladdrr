# MFCC

Mel-frequency cepstral coefficients for speech and speaker recognition.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ MFCC
  object; set internally when a method returns a new MFCC.

## Value

An `MFCC` object with methods for Mel-frequency cepstral coefficient
analysis.

## Details

MFCCs are widely used features in speech and speaker recognition
systems. They represent the short-term power spectrum of a sound on a
mel scale, which approximates human auditory perception. Uses a shared
dispatch table for minimal memory per object.

## Creating MFCC objects

- `sound$to_mfcc()` - extract MFCCs with default parameters

## Query methods

- `get_number_of_frames()` - number of analysis frames

- `get_time_step()` - time step between frames

- `get_max_num_coefficients()` - maximum number of coefficients

- `get_fmin()`, `get_fmax()` - frequency range (mel)

- `get_c0_at_frame(frame)` - C0 (energy) for a specific frame

- `get_value_in_frame(frame, coef)` - coefficient value at a frame

- `get_coefficients_at_frame(frame)` - all coefficients for a frame

- `get_all_coefficients()` - matrix of all coefficients

- `get_all_c0()` - vector of all C0 values

## Liftering

- `lifter(L)` - apply cepstral liftering (weighting)

## Export

- `as_data_frame(include_c0)` - convert to a data.frame/data.table

- `to_matrix()` - convert to a Matrix object

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`MelSpectrogram`](https://humlab-speech.github.io/pladdrr/reference/MelSpectrogram.md)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
mfcc <- sound$to_mfcc(
  num_coefficients = 13,
  analysis_width = 0.025,
  time_step = 0.01,
  f1_mel = 100,
  fmax_mel = 7800,
  df_mel = 100
)
n_frames <- mfcc$get_number_of_frames()
coefs <- mfcc$get_all_coefficients()
mfcc$lifter(22)
df <- mfcc$as_data_frame(include_c0 = TRUE)
```
