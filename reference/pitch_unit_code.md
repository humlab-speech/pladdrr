# Convert unit string to integer code

Convert unit string to integer code

## Usage

``` r
pitch_unit_code(unit)
```

## Arguments

- unit:

  Unit string: "hertz", "hz", "semitones", "mel", "erb"

## Value

Integer unit code for Praat API

## Examples

``` r
pladdrr:::pitch_unit_code("hertz")
#> [1] 0
pladdrr:::pitch_unit_code("semitones")
#> [1] 1
```
