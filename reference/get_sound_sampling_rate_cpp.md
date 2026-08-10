# Get sound sampling rate

Extract the sampling rate of a sound object

## Usage

``` r
get_sound_sampling_rate_cpp(sound_obj)
```

## Arguments

- sound_obj:

  List representing a praat_sound object

## Value

Numeric value representing sampling rate in Hz

## Examples

``` r
values <- sin(2 * pi * 220 * seq(0, 0.1, length.out = 1000))
snd <- create_sound_from_values(values, sampling_rate = 10000)
pladdrr:::get_sound_sampling_rate_cpp(snd)
#> [1] 10000
```
