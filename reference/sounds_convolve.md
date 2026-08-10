# Convolve two sounds

Convolve two sounds

## Usage

``` r
sounds_convolve(sound1, sound2, scaling = 4L, signal_outside = 1L)
```

## Arguments

- sound1:

  First Sound object

- sound2:

  Second Sound object (filter/impulse response)

- scaling:

  Scaling: 1=integral, 2=sum, 3=normalize, 4=peak_0.99

- signal_outside:

  Signal outside time domain: 1=zero, 2=similar

## Value

New Sound object

## Examples

``` r
s1 <- Sound$create_tone(frequency = 220, duration = 0.2)
s2 <- Sound$create_tone(frequency = 440, duration = 0.05)
conv <- sounds_convolve(s1, s2)
```
