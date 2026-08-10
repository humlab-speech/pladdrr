# BarkSpectrogram Object

Praat BarkSpectrogram: Bark-scale spectrogram used in psychoacoustic and
perceptual analysis of speech.

## Usage

``` r
BarkSpectrogram(.xptr = NULL)
```

## Arguments

- .xptr:

  Internal use only - external pointer to C++ BarkSpectrogram object

## Value

A BarkSpectrogram object

## Examples

``` r
snd <- Sound$create_tone(frequency = 150, duration = 0.3)
bark <- snd$to_bark_spectrogram()

# Export as matrix
mat <- bark$as_matrix()
```
