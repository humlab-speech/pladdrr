# Get sound duration

Extract the duration of a sound object in seconds

## Usage

``` r
get_sound_duration_cpp(sound_obj)
```

## Arguments

- sound_obj:

  List representing a praat_sound object

## Value

Numeric value representing duration in seconds

## Examples

``` r
values <- sin(2 * pi * 220 * seq(0, 0.1, length.out = 1000))
snd <- create_sound_from_values(values, sampling_rate = 10000)
pladdrr:::get_sound_duration_cpp(snd)
#> [1] 0.1
```
