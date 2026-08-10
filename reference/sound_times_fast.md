# Fast Sound Time Vector

Returns time values for each sample via optimized computation.

## Usage

``` r
sound_times_fast(sound_xptr)
```

## Arguments

- sound_xptr:

  External pointer to Sound object

## Value

Numeric vector of sample times

## Details

Computes sample times directly from Sound metadata (t0 + i\*dt) rather
than going through Praat's accessor functions.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.1)
times <- sound_times_fast(sound$.xptr)
head(times)
#> [1] 1.133787e-05 3.401361e-05 5.668934e-05 7.936508e-05 1.020408e-04
#> [6] 1.247166e-04
```
