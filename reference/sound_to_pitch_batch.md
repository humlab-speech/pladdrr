# Extract Pitch from Multiple Sounds in Single C++ Call

Processes multiple Sound objects and extracts Pitch at the C++ level,
avoiding O(n) R→C boundary crossings from calling \`\$to_pitch()\` in a
loop.

## Usage

``` r
sound_to_pitch_batch(
  sounds,
  time_step = 0,
  pitch_floor = 75,
  pitch_ceiling = 600,
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
pitches <- sound_to_pitch_batch(sounds)
```
