# Validate logical parameter

Ensures a parameter is a logical value

## Usage

``` r
validate_logical(x, name = deparse(substitute(x)))
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
pladdrr:::validate_logical(TRUE)
```
