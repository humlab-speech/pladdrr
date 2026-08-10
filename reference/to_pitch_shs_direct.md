# Create Pitch from Sound using Subharmonic Summation (SHS) Directly (returns XPtr)

Create Pitch from Sound using Subharmonic Summation (SHS) Directly
(returns XPtr)

## Usage

``` r
to_pitch_shs_direct(
  sound,
  time_step = 0.01,
  pitch_floor = 50,
  max_frequency = 1250,
  pitch_ceiling = 500,
  max_subharmonics = 15L,
  max_candidates = 15L,
  compression_factor = 0.84,
  n_points_per_octave = 48L
)
```

## Arguments

- sound:

  Sound object or external pointer

- time_step:

  Time step in seconds (default 0.01)

- pitch_floor:

  Minimum pitch (Hz, default 50)

- max_frequency:

  Maximum frequency for analysis (Hz, default 1250)

- pitch_ceiling:

  Maximum pitch (Hz, default 500)

- max_subharmonics:

  Number of subharmonics to sum (default 15)

- max_candidates:

  Maximum number of pitch candidates per frame (default 15)

- compression_factor:

  Compression factor for subharmonic weighting (default 0.84)

- n_points_per_octave:

  Number of frequency points per octave (default 48)

## Value

External pointer to Pitch (NOT R6 object)

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
pitch_ptr <- to_pitch_shs_direct(sound)
f0 <- get_pitch_value_direct(pitch_ptr, 0.25, "hertz", TRUE)
```
