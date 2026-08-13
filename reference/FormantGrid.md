# FormantGrid

Praat FormantGrid object: formant frequencies and bandwidths over time,
editable at arbitrary time points.

## Arguments

- tmin:

  Start time in seconds.

- tmax:

  End time in seconds.

- number_of_formants:

  Number of formants to track. Default 10.

- initial_first_formant:

  Initial frequency of the first formant, in Hz. Default 550.

- initial_formant_spacing:

  Initial spacing between formants, in Hz. Default 1100.

- initial_first_bandwidth:

  Initial bandwidth of the first formant, in Hz. Default 60.

- initial_bandwidth_spacing:

  Initial spacing between formant bandwidths, in Hz. Default 50.

- .xptr:

  Not for direct use. External pointer to the underlying C++ FormantGrid
  object; set internally when a method returns a new FormantGrid.

## Value

A `FormantGrid` object with methods for formant frequency and bandwidth
manipulation.

## Details

Used for voice transformation and synthesis. This is the editable
counterpart to the read-only Formant object.

## Examples

``` r
fg <- FormantGrid(0, 1, number_of_formants = 3)
fg$add_formant_point(1, 0.5, 700)
fg$get_formant_at_time(1, 0.5)
#> [1] 550
fg$get_number_of_formants()
#> [1] 3
```
