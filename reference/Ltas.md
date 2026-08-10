# Praat Ltas (Long-term Average Spectrum) Object

Praat Ltas object for long-term spectral analysis. Uses shared dispatch
table for minimal memory per object.

## Value

An `Ltas` object with methods for long-term average spectrum analysis.

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Spectrum`](https://humlab-speech.github.io/pladdrr/reference/Spectrum.md),
[`Spectrogram`](https://humlab-speech.github.io/pladdrr/reference/Spectrogram.md)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
ltas <- sound$to_ltas(bandwidth = 100)
ltas$get_mean()
#> [1] -29.29521
ltas$get_number_of_bins()
#> [1] 221
```
