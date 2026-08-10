# Create Intensity from Sound Directly (returns XPtr)

Create Intensity from Sound Directly (returns XPtr)

## Usage

``` r
to_intensity_direct(
  sound,
  minimum_pitch = 100,
  time_step = 0,
  subtract_mean = TRUE
)
```

## Arguments

- sound:

  Sound object or external pointer

- minimum_pitch:

  Minimum pitch (Hz)

- time_step:

  Time step (0 = auto)

- subtract_mean:

  Whether to subtract mean

## Value

External pointer to Intensity

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
intensity_ptr <- to_intensity_direct(sound)
db <- get_intensity_value_direct(intensity_ptr, 0.25)
```
