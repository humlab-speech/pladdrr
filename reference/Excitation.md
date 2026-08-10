# Praat Excitation Object

Praat Excitation object with direct C++ module binding for auditory
modeling.

## Value

An `Excitation` object with methods for auditory excitation pattern
analysis.

## Details

An Excitation pattern represents the perceptual loudness distribution
across the auditory frequency range, measured in Bark scale.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
spectrum <- sound$to_spectrum()
excitation <- spectrum$to_excitation()
excitation$get_loudness()
#> [1] 106.3572
```
