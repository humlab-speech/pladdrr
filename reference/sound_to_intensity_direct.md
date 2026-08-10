# Create Intensity from Sound directly

Create Intensity from Sound directly

## Usage

``` r
sound_to_intensity_direct(
  sound_xptr,
  minimum_pitch = 100,
  time_step = 0,
  subtract_mean = TRUE
)
```

## Arguments

- sound_xptr:

  External pointer to Sound

- minimum_pitch:

  Minimum pitch for analysis (Hz)

- time_step:

  Time step (0 = auto)

- subtract_mean:

  Whether to subtract mean

## Value

External pointer to Intensity

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
intensity_xptr <- pladdrr:::sound_to_intensity_direct(sound$.xptr)
intensity <- Intensity(.xptr = intensity_xptr)
```
