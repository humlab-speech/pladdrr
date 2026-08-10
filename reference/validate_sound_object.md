# Validate praat_sound object

Ensures an object is a valid praat_sound, throwing an error if not

## Usage

``` r
validate_sound_object(x, name = deparse(substitute(x)))
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
pladdrr:::validate_sound_object(sound)
```
