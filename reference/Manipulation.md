# Praat Manipulation Object

Praat Manipulation object with direct C++ module binding for PSOLA-based
pitch and duration modification.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++
  Manipulation object; set internally when a method returns a new
  Manipulation, e.g. `sound$to_manipulation()`.

## Value

A `Manipulation` object.

## Details

The Manipulation object is Praat's main tool for modifying pitch and
duration of speech sounds using PSOLA (Pitch-Synchronous Overlap-Add)
resynthesis.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
manip <- sound$to_manipulation(pitch_floor = 75, pitch_ceiling = 300)
manip$has_pitch_tier()
#> [1] TRUE
pt <- manip$extract_pitch_tier()
```
