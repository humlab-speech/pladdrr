# BarkSpectrogram

A Bark-scale spectrogram, used in psychoacoustic and perceptual analysis
of speech.

## Usage

``` r
BarkSpectrogram(.xptr = NULL)
```

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++
  BarkSpectrogram object; set internally by
  `Sound$to_bark_spectrogram()`.

## Value

A BarkSpectrogram object.

## Examples

``` r
snd <- Sound$create_tone(frequency = 150, duration = 0.3)
bark <- snd$to_bark_spectrogram()

# Export as matrix
mat <- bark$as_matrix()
```
