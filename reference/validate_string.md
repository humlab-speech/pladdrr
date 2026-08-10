# Validate string parameter

Ensures a parameter is a non-empty character string

## Usage

``` r
validate_string(x, name = deparse(substitute(x)), allow_na = FALSE)
```

## Arguments

- x:

  Value to validate

- name:

  Parameter name for error messages

- allow_na:

  Allow NA values (default: FALSE)

## Value

The validated value (invisibly)

## Examples

``` r
pladdrr:::validate_string("hello")
```
