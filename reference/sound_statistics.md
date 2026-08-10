# Compute comprehensive sound statistics

Calculates a comprehensive set of statistics for a sound object,
including amplitude statistics and metadata. Works with both S3
praat_sound objects and R6 Sound objects.

## Usage

``` r
sound_statistics(sound)
```

## Arguments

- sound:

  A praat_sound (S3) or Sound (R6) object

## Value

A named list containing:

- mean:

  Mean amplitude

- min:

  Minimum amplitude

- max:

  Maximum amplitude

- rms:

  RMS amplitude

- duration:

  Duration in seconds

- n_samples:

  Number of samples

- sampling_rate:

  Sampling rate in Hz

## Examples

``` r
sound <- generate_sine_wave(440, 0.5)
#> Warning: create_sound() is deprecated and will be removed in v5.0.0. Use Sound$from_values(values, sampling_rate) instead. The R6 interface provides better performance and more features.
stats <- sound_statistics(sound)
print(stats)
#> $mean
#> [1] -3.972481e-17
#> 
#> $min
#> [1] -0.9999997
#> 
#> $max
#> [1] 0.9999997
#> 
#> $rms
#> [1] 0.7071068
#> 
#> $duration
#> [1] 0.5
#> 
#> $n_samples
#> [1] 22050
#> 
#> $sampling_rate
#> [1] 44100
#> 
```
