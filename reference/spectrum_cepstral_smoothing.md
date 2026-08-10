# Apply cepstral smoothing to spectrum

Apply cepstral smoothing to spectrum

## Usage

``` r
spectrum_cepstral_smoothing(spectrum, bandwidth = 500)
```

## Arguments

- spectrum:

  Spectrum object

- bandwidth:

  Smoothing bandwidth (Hz)

## Value

New Spectrum object with smoothing applied

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
spectrum <- sound$to_spectrum()
smoothed <- spectrum_cepstral_smoothing(spectrum, bandwidth = 500)
```
