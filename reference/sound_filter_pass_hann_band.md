# Apply Hann band-pass filter

Apply Hann band-pass filter

## Usage

``` r
sound_filter_pass_hann_band(sound, fmin, fmax, smooth = 100)
```

## Arguments

- sound:

  Sound object

- fmin:

  Low frequency cutoff (Hz)

- fmax:

  High frequency cutoff (Hz)

- smooth:

  Smoothing bandwidth (Hz)

## Value

New Sound object

## Examples

``` r
sound <- Sound$create_tone(frequency = 1000, duration = 0.5)
filtered <- sound_filter_pass_hann_band(sound, fmin = 300, fmax = 3000,
 smooth = 100)
```
