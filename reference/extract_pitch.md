# Extract pitch contour from sound (DEPRECATED)

\*\*DEPRECATED:\*\* This S3 function is deprecated. Use the R6 interface
instead: `sound$to_pitch(time_step, pitch_floor, pitch_ceiling)`

## Usage

``` r
extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 600, time_step = 0.01)
```

## Arguments

- sound:

  A Sound R6 object

- pitch_floor:

  Minimum pitch in Hz (default: 75)

- pitch_ceiling:

  Maximum pitch in Hz (default: 600)

- time_step:

  Time step in seconds (default: 0.01)

## Value

Pitch R6 object

## Examples

``` r
# Old S3 approach (DEPRECATED, shown for reference)
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 300)
#> Warning: extract_pitch() is deprecated and will be removed in v6.0.0. Use sound$to_pitch(time_step, pitch_floor, pitch_ceiling) instead.

# New R6 approach (RECOMMENDED)
pitch2 <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 300)
mean_f0 <- pitch2$get_mean()
```
