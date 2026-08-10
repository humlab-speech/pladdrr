# Validate file path exists

Ensures a file path points to an existing file

## Usage

``` r
validate_file_exists(path, name = deparse(substitute(path)))
```

## Arguments

- path:

  File path to validate

- name:

  Parameter name for error messages

## Value

The validated path (invisibly)

## Examples

``` r
path <- tempfile(fileext = ".wav")
file.create(path)
#> [1] TRUE
pladdrr:::validate_file_exists(path)
unlink(path)
```
