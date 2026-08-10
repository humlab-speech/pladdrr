# Check if object is a valid Sound (R6 or legacy S3)

Validates that an object is a Sound R6 object or legacy praat_sound

## Usage

``` r
is_praat_sound(x)
```

## Arguments

- x:

  Object to check

## Value

Logical indicating validity

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
is_praat_sound(sound)
#> [1] TRUE
is_praat_sound(42)
#> [1] FALSE
```
