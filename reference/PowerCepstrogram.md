# PowerCepstrogram Class

Represents a time-varying power cepstrum (PowerCepstrogram) from Praat.
Uses shared dispatch table for minimal memory per object. Note: No Rcpp
module — uses direct Rcpp function calls.

## Value

A `PowerCepstrogram` object with methods for time-varying power cepstrum
analysis.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60)
mean_cpp <- cepstrogram$get_mean_cpp()
```
