# Create a sound object from numeric vector

Creates a praat_sound object structure from R numeric data

## Usage

``` r
create_sound_from_values(values, sampling_rate = 44100, start_time = 0)
```

## Arguments

- values:

  Numeric vector of sound amplitude values

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- start_time:

  Start time in seconds (default: 0.0)

## Value

List representing a praat_sound object with values and metadata

## Examples

``` r
values <- sin(2 * pi * 220 * seq(0, 0.1, length.out = 1000))
snd <- create_sound_from_values(values, sampling_rate = 10000)
```
