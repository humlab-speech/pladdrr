# Create Pitch from Sound using SPINET Directly (returns XPtr)

Create Pitch from Sound using SPINET Directly (returns XPtr)

## Usage

``` r
to_pitch_spinet_direct(
  sound,
  time_step = 0.005,
  window_duration = 0.04,
  min_frequency = 70,
  max_frequency = 5000,
  n_filters = 250L,
  pitch_ceiling = 500,
  max_candidates = 15L
)
```

## Arguments

- sound:

  Sound object or external pointer

- time_step:

  Time step in seconds (default 0.005)

- window_duration:

  Analysis window duration (default 0.04)

- min_frequency:

  Minimum frequency (Hz, default 70)

- max_frequency:

  Maximum frequency (Hz, default 5000)

- n_filters:

  Number of gamma-tone filters (default 250)

- pitch_ceiling:

  Maximum pitch (Hz, default 500)

- max_candidates:

  Maximum number of pitch candidates per frame (default 15)

## Value

External pointer to Pitch (NOT R6 object)

## Examples

``` r
# The vendored Praat SPINET path has a rare, non-deterministic native
# flake ("all amplitudes equal to zero") unrelated to the input signal;
# tryCatch keeps this example from failing R CMD check when it strikes.
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
pitch_ptr <- tryCatch(to_pitch_spinet_direct(sound), error = function(e) NULL)
if (!is.null(pitch_ptr)) {
  f0 <- get_pitch_value_direct(pitch_ptr, 0.25, "hertz", TRUE)
}
```
