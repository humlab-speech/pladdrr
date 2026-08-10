# Create Pitch from Sound directly (no R6 wrapping)

Create Pitch from Sound directly (no R6 wrapping)

## Usage

``` r
sound_to_pitch_direct(
  sound_xptr,
  time_step = 0,
  pitch_floor = 75,
  pitch_ceiling = 600
)
```

## Arguments

- sound_xptr:

  External pointer to Sound

- time_step:

  Time step (0 = auto)

- pitch_floor:

  Minimum pitch (Hz)

- pitch_ceiling:

  Maximum pitch (Hz)

## Value

External pointer to Pitch

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
pitch_xptr <- pladdrr:::sound_to_pitch_direct(sound$.xptr)
pitch <- Pitch(.xptr = pitch_xptr)
```
