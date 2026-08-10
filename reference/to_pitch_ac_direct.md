# Create Pitch from Sound Directly (Autocorrelation) - Full Parameters

Create Pitch analysis using autocorrelation method with full control
over all voicing parameters. Returns a raw external pointer instead of
an R6 object.

\*\*NEW in v4.0.1:\*\* Exposes all voicing parameters that were
previously only available in Tier 1 (Standard) API.

## Usage

``` r
to_pitch_ac_direct(
  sound,
  time_step = 0,
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_candidates = 15,
  very_accurate = FALSE,
  silence_threshold = 0.03,
  voicing_threshold = 0.45,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14,
  max_number_of_candidates = NULL
)
```

## Arguments

- sound:

  Sound object or external pointer

- time_step:

  Time step (0 = auto, typically 0.75/pitch_floor)

- pitch_floor:

  Minimum pitch (Hz, default 75)

- pitch_ceiling:

  Maximum pitch (Hz, default 600)

- max_candidates:

  Maximum number of pitch candidates (default 15)

- very_accurate:

  Use accurate but slower method (default FALSE)

- silence_threshold:

  Frames below this relative intensity are unvoiced (default 0.03)

- voicing_threshold:

  Strength required for voiced decision (default 0.45)

- octave_cost:

  Cost per octave in path finding (default 0.01)

- octave_jump_cost:

  Cost for octave jumps (default 0.35)

- voiced_unvoiced_cost:

  Cost for voicing transitions (default 0.14)

- max_number_of_candidates:

  Maximum number of pitch candidates per frame

## Value

External pointer to Pitch (NOT R6 object)

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)

# With custom voicing threshold (stricter voicing detection)
pitch_ptr <- to_pitch_ac_direct(sound, voicing_threshold = 0.6)

# Use with query functions
f0 <- get_pitch_value_direct(pitch_ptr, 0.25, "hertz", TRUE)
```
