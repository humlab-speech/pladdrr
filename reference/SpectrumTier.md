# SpectrumTier

Holds the frequency peaks picked out of a long-term average spectrum.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ object; set
  internally by `ltas$to_spectrum_tier_peaks()`.

## Value

A SpectrumTier object with methods for reading its frequency/power
points.

## Details

A SpectrumTier is the result of peak-picking an
[Ltas](https://humlab-speech.github.io/pladdrr/reference/Ltas.md): each
point is one local maximum, recorded as a frequency and its power in dB.
Use it to pull out harmonic or formant-like peaks from a spectral
average without scanning the raw values by hand. It's read-only: build
one with `ltas$to_spectrum_tier_peaks()`, then inspect or export it.

## Usage


    peaks <- ltas$to_spectrum_tier_peaks()

## Query methods

- `get_lowest_frequency()`, `get_highest_frequency()` - the frequency
  range the peaks were picked from, in Hz

- `get_number_of_points()` - number of peaks found

- `get_frequency_from_index(index)` - frequency of one peak

- `get_value_at_index(index)` - power of one peak, in dB

## Export

- `as_data_frame()` - all peaks as a data frame, with `frequency` and
  `power_db` columns

- `as_matrix()` - the same data as a plain matrix

- `save(path)` - write to a Praat text file

## See also

[`Ltas`](https://humlab-speech.github.io/pladdrr/reference/Ltas.md)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
ltas <- sound$to_ltas(bandwidth = 100)
peaks <- ltas$to_spectrum_tier_peaks()
peaks$get_number_of_points()
#> [1] 1
peaks$as_data_frame()
#>   frequency power_db
#> 1  145.5093 70.92279
```
