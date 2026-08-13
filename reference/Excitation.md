# Excitation

Represents a Praat auditory excitation pattern.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ Excitation
  object; set internally when a method returns a new Excitation.

## Value

An Excitation object.

## Details

An excitation pattern is the perceptual loudness distribution across the
auditory frequency range, measured on the Bark scale. It is produced
from a Spectrum or a Cochleagram, not created directly.

## Query methods

- `get_loudness()` - total loudness in sones

- `get_value_at_frequency(freq_bark)` - excitation level at a given Bark
  frequency

- `get_distance(other)` - distance to another Excitation object

## Conversion

- `to_formant(max_formants = 20)` - estimate formants from the
  excitation pattern

## Export

- `as_vector()` - export as a numeric vector, one value per Bark bin

- `as_data_frame()` - export as a data.frame of frequency (Bark) and
  excitation

## See also

[`Spectrum`](https://humlab-speech.github.io/pladdrr/reference/Spectrum.md),
[`Formant`](https://humlab-speech.github.io/pladdrr/reference/Formant.md)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
spectrum <- sound$to_spectrum()
excitation <- spectrum$to_excitation()
excitation$get_loudness()
#> [1] 106.3572
```
