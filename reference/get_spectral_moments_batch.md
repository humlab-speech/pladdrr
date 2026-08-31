# Get spectral moments for all frames of a Spectrogram

Computes centre of gravity, standard deviation, skewness, and kurtosis
for every frame in a Spectrogram in a single C++ pass, instead of
calling the per-frame Spectrum methods in an R loop.

## Usage

``` r
get_spectral_moments_batch(spectrogram, power = 2)
```

## Arguments

- spectrogram:

  A `Spectrogram` object

- power:

  Numeric. Power for moment weighting (default 2.0, matching Praat)

## Value

`data.frame` with columns `time`, `cog`, `sd`, `skewness`, `kurtosis`
(one row per frame; `NA` where undefined)

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
spectrogram <- sound$to_spectrogram()
moments <- get_spectral_moments_batch(spectrogram)
head(moments)
#>    time      cog        sd  skewness    kurtosis
#> 1 0.005 225.2336 106.16677 0.1344785 -0.21281033
#> 2 0.007 239.5842  97.96335 0.2588535 -0.09750666
#> 3 0.009 242.1882  96.17069 0.3087649 -0.10693416
#> 4 0.011 230.6530 103.37986 0.1586444 -0.15103524
#> 5 0.013 214.6224 110.65591 0.1352604 -0.34129887
#> 6 0.015 203.3188 114.16597 0.1794434 -0.45276189
```
