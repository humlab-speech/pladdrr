# Summary method for praat_sound objects

Provides a statistical summary of a praat_sound object, including
amplitude statistics and metadata.

## Usage

``` r
# S3 method for class 'praat_sound'
summary(object, ...)
```

## Arguments

- object:

  A praat_sound object

- ...:

  Additional arguments (currently unused)

## Value

The object, invisibly

## Examples

``` r
sound <- list(
  duration = 0.5, sampling_rate = 8000, n_samples = 4000, n_channels = 1,
  start_time = 0, end_time = 0.5,
  values = sin(2 * pi * 150 * seq(0, 0.5, length.out = 4000))
)
class(sound) <- "praat_sound"
summary(sound)
#> Praat Sound Object - Summary
#> ============================
#> 
#> Metadata:
#>   Duration:      0.500000 seconds
#>   Sampling rate: 8000 Hz
#>   Samples:       4000
#>   Channels:      1
#>   Time range:    [0.000000, 0.500000] seconds
#> 
#> Amplitude Statistics:
#>   Mean:          0.000000
#>   Min:           -0.999999
#>   Max:           0.999999
#>   RMS:           0.707018
#>   Std Dev:       0.707107
```
