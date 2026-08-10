# Get pitch at specific time point (DEPRECATED)

\*\*DEPRECATED:\*\* Use `pitch$get_value_at_time(time, unit)` instead.

## Usage

``` r
get_pitch_at_time(pitch, time, unit = "Hz", interpolate = FALSE)
```

## Arguments

- pitch:

  A Pitch R6 object

- time:

  Time in seconds

- unit:

  Unit: "Hz" or "semitones"

- interpolate:

  Whether to interpolate

## Value

Pitch value or NA

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pitch <- sound$to_pitch()
get_pitch_at_time(pitch, 0.25)
#> Warning: 'get_pitch_at_time' is deprecated.
#> Use 'pitch$get_value_at_time()' instead.
#> See help("Deprecated") and help("pladdrr-deprecated").
#> [1] 150.0017
```
