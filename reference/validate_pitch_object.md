# Validate praat_pitch object

Ensures an object is a valid praat_pitch, throwing an error if not

## Usage

``` r
validate_pitch_object(x, name = deparse(substitute(x)))
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
pitch_df <- data.frame(time = c(0.1, 0.2), frequency = c(120, 130))
class(pitch_df) <- c("praat_pitch", "data.frame")
pladdrr:::validate_pitch_object(pitch_df)
```
