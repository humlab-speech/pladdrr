# Create Harmonicity from Sound directly (cross-correlation)

Create Harmonicity from Sound directly (cross-correlation)

## Usage

``` r
sound_to_harmonicity_direct(
  sound_xptr,
  time_step = 0.01,
  minimum_pitch = 75,
  silence_threshold = 0.1,
  periods_per_window = 1
)
```

## Arguments

- sound_xptr:

  External pointer to Sound

- time_step:

  Time step

- minimum_pitch:

  Minimum pitch (Hz)

- silence_threshold:

  Silence threshold

- periods_per_window:

  Periods per window

## Value

External pointer to Harmonicity

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
harm_xptr <- pladdrr:::sound_to_harmonicity_direct(sound$.xptr)
harmonicity <- Harmonicity(.xptr = harm_xptr)
```
