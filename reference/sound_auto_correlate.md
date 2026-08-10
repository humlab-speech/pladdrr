# Auto-correlate a sound with itself

Auto-correlate a sound with itself

## Usage

``` r
sound_auto_correlate(sound, scaling = 4L, signal_outside = 1L)
```

## Arguments

- sound:

  Sound object

- scaling:

  Scaling: 1=integral, 2=sum, 3=normalize, 4=peak_0.99

- signal_outside:

  Signal outside time domain: 1=zero, 2=similar

## Value

New Sound object (auto-correlation function)

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)
ac <- sound_auto_correlate(sound)
```
