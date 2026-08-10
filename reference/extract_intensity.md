# Extract intensity from a sound object (DEPRECATED)

\*\*DEPRECATED:\*\* Use `sound$to_intensity()` instead.

## Usage

``` r
extract_intensity(
  sound,
  time_step = 0,
  minimum_pitch = 100,
  subtract_mean = TRUE
)
```

## Arguments

- sound:

  A Sound R6 object

- time_step:

  Time step in seconds

- minimum_pitch:

  Minimum pitch in Hz

- subtract_mean:

  Subtract mean intensity

## Value

Intensity R6 object

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
intensity <- suppressWarnings(extract_intensity(sound))
intensity$get_mean(from_time = 0, to_time = 0)
#> [1] 90.882
```
