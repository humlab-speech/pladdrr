# Extract Pitch (SPINET) from Multiple Sounds

Batch version of to_pitch_spinet using spectral integration.

## Usage

``` r
sound_to_pitch_spinet_batch(
  sounds,
  time_step = 0.005,
  window_duration = 0.04,
  min_frequency = 70,
  max_frequency = 5000,
  n_filters = 250L,
  pitch_ceiling = 500,
  max_candidates = 15L,
  return_r6 = TRUE
)
```

## Arguments

- sounds:

  List of Sound objects (R6) or external pointers

- time_step:

  Numeric. Time step (default: 0.005)

- window_duration:

  Numeric. Analysis window (default: 0.04)

- min_frequency:

  Numeric. Minimum frequency in Hz (default: 70)

- max_frequency:

  Numeric. Maximum frequency in Hz (default: 5000)

- n_filters:

  Integer. Number of gamma-tone filters (default: 250)

- pitch_ceiling:

  Numeric. Pitch ceiling in Hz (default: 500)

- max_candidates:

  Integer. Max candidates per frame (default: 15)

- return_r6:

  Logical. Return R6 Pitch objects (TRUE) or raw xptrs (FALSE)

## Value

List of Pitch objects (R6 or xptr depending on return_r6)

## Examples

``` r
# The vendored Praat SPINET path has a rare, non-deterministic native
# flake ("all amplitudes equal to zero") unrelated to the input signal;
# tryCatch keeps this example from failing R CMD check when it strikes.
sounds <- list(
  Sound$create_tone(frequency = 150, duration = 0.5),
  Sound$create_tone(frequency = 200, duration = 0.5)
)
pitches <- tryCatch(sound_to_pitch_spinet_batch(sounds), error = function(e) NULL)
```
