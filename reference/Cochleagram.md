# Cochleagram

Praat Cochleagram object with direct C++ module binding for auditory
modeling.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ Cochleagram
  object; set internally when a method returns a new Cochleagram.

## Value

A `Cochleagram` object with methods for auditory filter-bank analysis in
Bark scale.

## Details

A Cochleagram represents the output of a bank of auditory filters
arranged along the basilar membrane. Frequency is measured in Bark units
(0-25.6 Bark).

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 44100)
cochleagram <- sound$to_cochleagram()
cochleagram$get_duration()
#> [1] 0.3
cochleagram$get_loudness_at_time(0.15)
#> [1] 46.78787
```
