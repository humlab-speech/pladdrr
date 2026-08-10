# Validate praat_formant object

Ensures an object is a valid praat_formant, throwing an error if not

## Usage

``` r
validate_formant_object(x, name = deparse(substitute(x)))
```

## Arguments

- x:

  Object to validate

- name:

  Parameter name for error messages

## Value

The validated object (invisibly)

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 16000)
formant <- sound$to_formant_burg()
pladdrr:::validate_formant_object(formant)
```
