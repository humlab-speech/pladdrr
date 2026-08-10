# Time-stretch a sound using overlap-add

Time-stretch a sound using overlap-add

## Usage

``` r
sound_lengthen(sound, fmin = 75, fmax = 600, factor = 1.5)
```

## Arguments

- sound:

  Sound object

- fmin:

  Minimum pitch (Hz)

- fmax:

  Maximum pitch (Hz)

- factor:

  Lengthening factor (\>1 = slower, \<1 = faster)

## Value

New Sound object

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
slower <- sound_lengthen(sound, fmin = 75, fmax = 600, factor = 1.5)
faster <- sound_lengthen(sound, fmin = 75, fmax = 600, factor = 0.8)
```
