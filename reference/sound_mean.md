# Compute mean amplitude

Calculates the mean (average) of all amplitude values in a sound object.
Works with both S3 praat_sound objects and R6 Sound objects.

## Usage

``` r
sound_mean(sound)
```

## Arguments

- sound:

  A praat_sound (S3) or Sound (R6) object

## Value

Mean amplitude (numeric scalar)

## Examples

``` r
sound <- Sound$from_values(c(-1, 0, 1), sampling_rate = 1000)
sound_mean(sound)  # Returns 0
#> [1] 0
```
