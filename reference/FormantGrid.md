# Praat FormantGrid Object

Praat FormantGrid object with direct C++ module binding for formant
manipulation.

## Value

A `FormantGrid` object with methods for formant frequency and bandwidth
manipulation.

## Details

FormantGrid objects allow manipulation of formant frequencies and
bandwidths over time for voice transformation and synthesis. This is the
editable counterpart to the read-only Formant object.

## Examples

``` r
fg <- FormantGrid(0, 1, number_of_formants = 3)
fg$add_formant_point(1, 0.5, 700)
fg$get_formant_at_time(1, 0.5)
#> [1] 550
fg$get_number_of_formants()
#> [1] 3
```
