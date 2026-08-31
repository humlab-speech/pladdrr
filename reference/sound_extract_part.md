# Extract part of Sound with optional windowing

Extracts time range from Sound, applying optional window function.
Implements Praat's "Sound: Extract part..." with full window shape
support.

## Usage

``` r
sound_extract_part(
  sound,
  t1,
  t2,
  window_shape = 1L,
  relative_width = 1,
  preserve_times = FALSE
)
```

## Arguments

- sound:

  Sound object

- t1:

  Start time (seconds)

- t2:

  End time (seconds)

- window_shape:

  Window shape code or name: \* 0 or "rectangular" - Rectangular (no
  tapering) \* 1 or "triangular" - Triangular (Bartlett) \* 2 or
  "parabolic" - Parabolic (Welch) \* 3 or "hanning" - Hanning \* 4 or
  "hamming" - Hamming \* 5 or "gaussian1" - Gaussian with sd=0.42466
  (relative to duration) \* 6 or "gaussian2" - Gaussian with sd=0.21233
  (narrower, use relative_width=2.0) \* 7 or "gaussian3" - Gaussian with
  sd=0.14155 (use relative_width=3.0) \* 8 or "gaussian4" - Gaussian
  with sd=0.10616 (use relative_width=4.0) \* 9 or "gaussian5" -
  Gaussian with sd=0.08493 (use relative_width=5.0) \* 10 or "kaiser1" -
  Kaiser-Bessel with alpha=20.7 \* 11 or "kaiser2" - Kaiser-Bessel with
  alpha=40.5 (use relative_width=2.0)

- relative_width:

  Relative width for windowing (default: 1.0). For gaussian2/kaiser2,
  use 2.0 to maintain effective window duration. For gaussian3, use 3.0.
  For gaussian4, use 4.0. For gaussian5, use 5.0. This extends physical
  extraction beyond \[t1,t2\] while keeping effective duration.

- preserve_times:

  If TRUE, preserve original time domain (result spans t1 to t2). If
  FALSE, time-shift result to start at 0.

## Value

New Sound object with extracted and windowed portion

## Details

Window shapes with higher numbers (gaussian2-5, kaiser2) have narrower
effective windows. To maintain comparable effective duration to
gaussian1/kaiser1, use relative_width \> 1.0, which extracts a longer
physical segment while applying a more aggressive taper.

For spectral analysis, Kaiser2 and Gaussian2 with relative_width=2.0 are
commonly used (e.g., in Praat's "To Spectrogram..." and "To Pitch
(ac)... Very accurate").

## References

Praat documentation:
<https://www.fon.hum.uva.nl/praat/manual/Sound__Extract_part___.html>

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 3.0)

# Rectangular window (no tapering)
rect <- sound_extract_part(sound, 1.0, 2.0, window_shape = 0L)

# Gaussian1 window (standard)
gauss1 <- sound_extract_part(sound, 1.0, 2.0, window_shape = 5L,
 relative_width = 1.0)

# Gaussian2 with wider physical extraction
gauss2 <- sound_extract_part(sound, 1.0, 2.0, window_shape = 6L,
 relative_width = 2.0)

# Kaiser2 for spectral analysis
kaiser <- sound_extract_part(sound, 1.0, 2.0, window_shape = 11L,
 relative_width = 2.0)
```
