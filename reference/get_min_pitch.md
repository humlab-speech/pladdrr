# Get minimum pitch (DEPRECATED)

\*\*DEPRECATED:\*\* Use `pitch$get_minimum(unit)` instead.

## Usage

``` r
get_min_pitch(pitch, unit = "Hz", time_range = NULL)
```

## Arguments

- pitch:

  A Pitch R6 object

- unit:

  Unit: "Hz" or "semitones"

- time_range:

  Optional time range c(start, end)

## Value

Minimum pitch value

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
pitch <- sound$to_pitch()
suppressWarnings(get_min_pitch(pitch))
#> [1] 150.0017
```
