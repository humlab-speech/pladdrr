# Extract Parts and Analyze Pitch in Single C++ Call

Combines interval extraction and pitch analysis in a single C++ call,
avoiding intermediate R6 object creation, as an alternative to
extracting each part and calling \`\$to_pitch()\` on it in a loop.

## Usage

``` r
sound_extract_and_pitch(
  sound,
  from_times,
  to_times,
  time_step = 0,
  pitch_floor = 75,
  pitch_ceiling = 600,
  return_r6 = TRUE
)
```

## Arguments

- sound:

  Sound object (R6) or external pointer

- from_times:

  Numeric vector of start times

- to_times:

  Numeric vector of end times

- time_step:

  Numeric. Pitch time step (0 = automatic)

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
sound <- Sound$create_tone(frequency = 150, duration = 2.0)
from_times <- c(0.2, 1.0)
to_times <- c(0.6, 1.4)
pitches <- sound_extract_and_pitch(sound, from_times, to_times)
```
