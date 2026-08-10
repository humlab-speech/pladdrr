# Praat Cepstrum Object

Praat Cepstrum object with direct C++ module binding.

## Value

A `Cepstrum` object with methods for cepstral analysis and
quefrency-domain processing.

## Details

The cepstrum is the inverse Fourier transform of the logarithm of the
spectrum. Unlike PowerCepstrum, it preserves phase information.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
cepstrum <- sound$to_cepstrum()
spectrum <- cepstrum$to_spectrum()
```
