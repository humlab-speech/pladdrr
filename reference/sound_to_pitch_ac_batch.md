# Extract Pitch (AC) from Multiple Sounds in Single C++ Call

Batch version of to_pitch_ac with full voicing parameters. Avoids O(n)
R→C boundary crossings for VUV analysis workflows.

## Usage

``` r
sound_to_pitch_ac_batch(
  sounds,
  time_step = 0,
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_candidates = 15L,
  very_accurate = FALSE,
  silence_threshold = 0.03,
  voicing_threshold = 0.45,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14,
  return_r6 = TRUE
)
```

## Arguments

- sounds:

  List of Sound objects (R6) or external pointers

- time_step:

  Numeric. Time step (0 = automatic)

- pitch_floor:

  Numeric. Pitch floor in Hz (default: 75)

- pitch_ceiling:

  Numeric. Pitch ceiling in Hz (default: 600)

- max_candidates:

  Integer. Max candidates per frame (default: 15)

- very_accurate:

  Logical. Use very accurate algorithm (default: FALSE)

- silence_threshold:

  Numeric. Silence threshold (default: 0.03)

- voicing_threshold:

  Numeric. Voicing threshold (default: 0.45)

- octave_cost:

  Numeric. Octave cost (default: 0.01)

- octave_jump_cost:

  Numeric. Octave jump cost (default: 0.35)

- voiced_unvoiced_cost:

  Numeric. Voiced/unvoiced cost (default: 0.14)

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
pitches <- sound_to_pitch_ac_batch(sounds)
```
