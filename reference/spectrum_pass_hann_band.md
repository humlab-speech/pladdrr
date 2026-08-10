# Apply Hann band-pass filter to spectrum (in-place)

Apply Hann band-pass filter to spectrum (in-place)

## Usage

``` r
spectrum_pass_hann_band(spectrum, fmin, fmax, smooth = 100)
```

## Arguments

- spectrum:

  Spectrum object (will be modified)

- fmin:

  Low frequency cutoff (Hz)

- fmax:

  High frequency cutoff (Hz)

- smooth:

  Smoothing bandwidth (Hz)

## Value

NULL (modifies spectrum in place)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
spectrum <- sound$to_spectrum()
spectrum_pass_hann_band(spectrum, fmin = 300, fmax = 3000, smooth = 100)
# spectrum is now modified
```
