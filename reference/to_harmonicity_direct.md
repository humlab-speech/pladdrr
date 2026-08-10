# Create Harmonicity from Sound Directly (returns XPtr)

Create Harmonicity from Sound Directly (returns XPtr)

## Usage

``` r
to_harmonicity_direct(
  sound,
  time_step = 0.01,
  minimum_pitch = 75,
  silence_threshold = 0.1,
  periods_per_window = 1
)
```

## Arguments

- sound:

  Sound object or external pointer

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
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
hnr_ptr <- to_harmonicity_direct(sound)
hnr <- Harmonicity(.xptr = hnr_ptr)
hnr$get_mean(0, 0)
#> [1] 113.1902
```
