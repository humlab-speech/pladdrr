# Check if object is a valid Intensity (R6 or legacy S3)

Validates that an object is an Intensity R6 object or legacy
praat_intensity

## Usage

``` r
is_praat_intensity(x)
```

## Arguments

- x:

  Object to check

## Value

Logical indicating validity

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
intensity <- sound$to_intensity()
is_praat_intensity(intensity)
#> [1] TRUE
is_praat_intensity(42)
#> [1] FALSE
```
