# Validate positive numeric parameter

Ensures a numeric parameter is positive (\> 0)

## Usage

``` r
validate_positive(x, name = deparse(substitute(x)))
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
pladdrr:::validate_positive(2.5)
```
