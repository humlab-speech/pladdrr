# Extract Intensity from Multiple Sounds in Single C++ Call

Extract Intensity from Multiple Sounds in Single C++ Call

## Usage

``` r
sound_to_intensity_batch(
  sounds,
  minimum_pitch = 100,
  time_step = 0,
  subtract_mean = TRUE,
  return_r6 = TRUE
)
```

## Arguments

- sounds:

  List of Sound objects (R6) or external pointers

- minimum_pitch:

  Numeric. Minimum pitch for analysis (default: 100)

- time_step:

  Numeric. Time step (0 = automatic)

- subtract_mean:

  Logical. Subtract mean pressure (default: TRUE)

- return_r6:

  Logical. Return R6 Intensity objects (TRUE) or raw xptrs (FALSE)

## Value

List of Intensity objects (R6 or xptr depending on return_r6)

## Examples

``` r
sounds <- list(
  Sound$create_tone(frequency = 150, duration = 0.5),
  Sound$create_tone(frequency = 200, duration = 0.5)
)
intensities <- sound_to_intensity_batch(sounds)
```
