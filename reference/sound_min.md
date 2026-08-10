# Compute minimum amplitude

Finds the minimum amplitude value in a sound object. Works with both S3
praat_sound objects and R6 Sound objects.

## Usage

``` r
sound_min(sound)
```

## Arguments

- sound:

  A praat_sound (S3) or Sound (R6) object

## Value

Minimum amplitude (numeric scalar)

## Examples

``` r
sound <- Sound$from_values(c(0.5, -0.8, 0.2), sampling_rate = 1000)
sound_min(sound)  # Returns -0.8
#> [1] -0.8
```
