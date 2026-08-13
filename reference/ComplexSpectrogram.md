# ComplexSpectrogram

Create a ComplexSpectrogram object from a Sound: a phase-preserving
spectrogram computed with a complex FFT.

## Arguments

- sound:

  Sound object.

- window_length:

  Window length in seconds. Default 0.005.

- maximum_frequency:

  Maximum frequency to analyze, in Hz. Default 5000.

## Value

An object of class `ComplexSpectrogram` (a list with methods, dispatched
via the shared `PraatObject` pattern).

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
cs <- ComplexSpectrogram(sound)
cs$get_amplitude(0.15, 150)
#> [1] 2.40771e-06
```
