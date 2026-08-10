# Compute maximum amplitude

Finds the maximum amplitude value in a sound object. Works with both S3
praat_sound objects and R6 Sound objects.

## Usage

``` r
sound_max(sound)
```

## Arguments

- sound:

  A praat_sound (S3) or Sound (R6) object

## Value

Maximum amplitude (numeric scalar)

## Examples

``` r
sound <- Sound$from_values(c(0.5, -0.8, 1.0), sampling_rate = 1000)
sound_max(sound)  # Returns 1.0
#> [1] 1
```
