# Validate non-negative numeric parameter

Ensures a numeric parameter is non-negative (\>= 0)

## Usage

``` r
validate_non_negative(x, name = deparse(substitute(x)))
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
pladdrr:::validate_non_negative(0)
```
