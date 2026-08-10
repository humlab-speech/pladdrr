# Cross-correlate two sounds

Cross-correlate two sounds

## Usage

``` r
sounds_cross_correlate(sound1, sound2, scaling = 4L, signal_outside = 1L)
```

## Arguments

- sound1:

  First Sound object

- sound2:

  Second Sound object

- scaling:

  Scaling: 1=integral, 2=sum, 3=normalize, 4=peak_0.99

- signal_outside:

  Signal outside time domain: 1=zero, 2=similar

## Value

New Sound object (cross-correlation function)

## Examples

``` r
s1 <- Sound$create_tone(frequency = 220, duration = 0.2)
s2 <- Sound$create_tone(frequency = 220, duration = 0.2)
xcorr <- sounds_cross_correlate(s1, s2)
```
