# Get Single Pitch Value Directly

Get Single Pitch Value Directly

## Usage

``` r
get_pitch_value_direct(pitch, time, unit = "hertz", interpolate = TRUE)
```

## Arguments

- pitch:

  Pitch object or external pointer

- time:

  Time in seconds

- unit:

  Unit string

- interpolate:

  Whether to interpolate

## Value

Pitch value

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pitch_ptr <- to_pitch_cc_direct(sound)
get_pitch_value_direct(pitch_ptr, 0.25)
#> [1] 149.9998
```
