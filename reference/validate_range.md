# Validate numeric parameter is in range

Ensures a numeric parameter falls within a specified range

## Usage

``` r
validate_range(x, min, max, name = deparse(substitute(x)))
```

## Arguments

- x:

  Value to validate

- min:

  Minimum allowed value (inclusive)

- max:

  Maximum allowed value (inclusive)

- name:

  Parameter name for error messages

## Value

The validated value (invisibly)

## Examples

``` r
pladdrr:::validate_range(5, min = 0, max = 10)
```
