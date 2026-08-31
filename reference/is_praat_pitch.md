# Check if object is a valid Pitch (R6 or legacy S3)

Validates that an object is a Pitch R6 object or legacy praat_pitch

## Usage

``` r
is_praat_pitch(x)
```

## Arguments

- x:

  Object to check

## Value

Logical indicating validity

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
pitch <- sound$to_pitch()
is_praat_pitch(pitch)
#> [1] TRUE
is_praat_pitch(42)
#> [1] FALSE
```
