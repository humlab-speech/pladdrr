# Get Pitch Mean Directly (Bypass R6)

Get mean pitch value without R6 wrapper overhead.

## Usage

``` r
get_pitch_mean_direct(
  pitch,
  from_time = 0,
  to_time = 0,
  unit = c("hertz", "semitones", "mel", "erb", "loghertz")
)
```

## Arguments

- pitch:

  Pitch object or external pointer

- from_time:

  Start time (0 = beginning)

- to_time:

  End time (0 = end)

- unit:

  Pitch unit

## Value

Mean pitch value

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pitch_ptr <- to_pitch_cc_direct(sound)
get_pitch_mean_direct(pitch_ptr)
#> [1] 149.9998
```
