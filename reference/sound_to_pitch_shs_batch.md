# Extract Pitch (SHS) from Multiple Sounds

Batch version of to_pitch_shs using Subharmonic Summation.

## Usage

``` r
sound_to_pitch_shs_batch(
  sounds,
  time_step = 0.01,
  pitch_floor = 50,
  max_frequency = 1250,
  pitch_ceiling = 500,
  max_subharmonics = 15L,
  max_candidates = 15L,
  compression_factor = 0.84,
  n_points_per_octave = 48L,
  return_r6 = TRUE
)
```

## Arguments

- sounds:

  List of Sound objects (R6) or external pointers

- time_step:

  Numeric. Time step (default: 0.01)

- pitch_floor:

  Numeric. Pitch floor in Hz (default: 50)

- max_frequency:

  Numeric. Maximum frequency in Hz (default: 1250)

- pitch_ceiling:

  Numeric. Pitch ceiling in Hz (default: 500)

- max_subharmonics:

  Integer. Number of subharmonics (default: 15)

- max_candidates:

  Integer. Max candidates per frame (default: 15)

- compression_factor:

  Numeric. Compression factor (default: 0.84)

- n_points_per_octave:

  Integer. Points per octave (default: 48)

- return_r6:

  Logical. Return R6 Pitch objects (TRUE) or raw xptrs (FALSE)

## Value

List of Pitch objects (R6 or xptr depending on return_r6)

## Examples

``` r
sounds <- list(
  Sound$create_tone(frequency = 150, duration = 0.5),
  Sound$create_tone(frequency = 200, duration = 0.5)
)
pitches <- sound_to_pitch_shs_batch(sounds)
```
