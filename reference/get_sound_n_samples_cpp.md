# Get number of samples in sound

Extract the number of samples in a sound object

## Usage

``` r
get_sound_n_samples_cpp(sound_obj)
```

## Arguments

- sound_obj:

  List representing a praat_sound object

## Value

Integer number of samples

## Examples

``` r
values <- sin(2 * pi * 220 * seq(0, 0.1, length.out = 1000))
snd <- create_sound_from_values(values, sampling_rate = 10000)
pladdrr:::get_sound_n_samples_cpp(snd)
#> [1] 1000
```
