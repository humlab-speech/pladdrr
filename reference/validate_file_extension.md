# Validate file has expected extension

Ensures a file path has one of the expected extensions

## Usage

``` r
validate_file_extension(path, extensions, name = deparse(substitute(path)))
```

## Arguments

- path:

  File path to validate

- extensions:

  Character vector of allowed extensions (e.g., c("wav", "WAV"))

- name:

  Parameter name for error messages

## Value

The validated path (invisibly)

## Examples

``` r
pladdrr:::validate_file_extension("speech.wav", c("wav", "WAV"))
```
