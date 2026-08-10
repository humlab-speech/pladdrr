# Check if object is a valid Formant (R6 or legacy S3)

Validates that an object is a Formant R6 object or legacy praat_formant

## Usage

``` r
is_praat_formant(x)
```

## Arguments

- x:

  Object to check

## Value

Logical indicating validity

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
formant <- sound$to_formant_burg()
is_praat_formant(formant)
#> [1] TRUE
is_praat_formant(42)
#> [1] FALSE
```
