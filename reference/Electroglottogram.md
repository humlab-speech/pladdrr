# Electroglottogram

Praat Electroglottogram (EGG) object. Measures electrical impedance
across the larynx, varying with vocal fold contact during phonation.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++
  Electroglottogram object; set internally when a method returns a new
  Electroglottogram.

## Value

An `Electroglottogram` object (triple-class
`c("Electroglottogram", "Sound", "PraatObject")`) that inherits Sound's
methods in addition to its own.

## Details

Electroglottogram inherits from Sound and represents a specialized
single-channel sound that records vocal fold contact area.

## Examples

``` r
egg <- electroglottogram_create(xmin = 0, xmax = 1, nx = 16000, dx = 1 /
 16000, x1 = 0)
egg$get_duration()
#> [1] 1
egg$get_number_of_samples()
#> [1] 16000
egg$is_valid()
#> [1] TRUE
```
