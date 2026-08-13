# PowerCepstrogram

Represents a time-varying power cepstrum (PowerCepstrogram) from Praat.

## Value

A PowerCepstrogram object.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60)
mean_cpp <- cepstrogram$get_mean_cpp()
```
