# Validate praat_intensity object

Ensures an object is a valid praat_intensity, throwing an error if not

## Usage

``` r
validate_intensity_object(x, name = deparse(substitute(x)))
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
sound <- Sound$create_tone(frequency = 150, duration = 0.2)
intensity <- sound$to_intensity()
pladdrr:::validate_intensity_object(intensity)
```
