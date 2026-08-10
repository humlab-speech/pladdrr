# Praat Electroglottogram Object

Praat Electroglottogram (EGG) object. Measures electrical impedance
across the larynx, varying with vocal fold contact during phonation.

Electroglottogram inherits from Sound and represents a specialized
single-channel sound that records vocal fold contact area.

## Value

An `Electroglottogram` object (triple-class
`c("Electroglottogram", "Sound", "PraatObject")`) that inherits Sound's
methods in addition to its own.

## Examples

``` r
egg <- electroglottogram_create(xmin = 0, xmax = 1, nx = 16000, dx = 1 / 16000, x1 = 0)
egg$get_duration()
#> [1] 1
egg$get_number_of_samples()
#> [1] 16000
egg$is_valid()
#> [1] TRUE
```
