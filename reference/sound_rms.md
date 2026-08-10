# Compute RMS (root mean square) amplitude

Calculates the RMS amplitude of a sound object. RMS is a measure of the
signal's power and is computed as sqrt(mean(x^2)).

## Usage

``` r
sound_rms(sound)
```

## Arguments

- sound:

  A praat_sound object

## Value

RMS amplitude (numeric scalar)

## Details

For a sine wave with amplitude A, the RMS value is A/sqrt(2) ~ 0.707\*A.
RMS is useful for comparing signal levels and measuring acoustic
intensity.

## Examples

``` r
# RMS of a sine wave
sine <- generate_sine_wave(440, 1.0, amplitude = 1.0)
#> Warning: create_sound() is deprecated and will be removed in v5.0.0. Use Sound$from_values(values, sampling_rate) instead. The R6 interface provides better performance and more features.
sound_rms(sine)  # Approximately 0.707
#> [1] 0.7071068
```
