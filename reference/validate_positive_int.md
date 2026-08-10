# Validate positive integer parameter

Ensures an integer parameter is positive (\> 0)

## Usage

``` r
validate_positive_int(x, name = deparse(substitute(x)))
```

## Arguments

- x:

  Value to validate

- name:

  Parameter name for error messages

## Value

The validated value (invisibly)

## Examples

``` r
pladdrr:::validate_positive_int(3)
```
