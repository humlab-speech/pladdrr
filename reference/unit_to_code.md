# Convert Unit Name to Praat Unit Code

Standardized mapping from unit names to Praat integer codes. Ensures
consistency across all APIs (Tier 1, 2, and 3).

## Usage

``` r
unit_to_code(unit, type = "pitch")
```

## Arguments

- unit:

  Character. Unit name

- type:

  Character. Type of unit: "pitch", "formant", or "intensity"

## Value

Integer unit code for Praat C++ layer

## Examples

``` r
pladdrr:::unit_to_code("semitones", type = "pitch")
#> [1] 1
pladdrr:::unit_to_code("bark", type = "formant")
#> [1] 1
```
