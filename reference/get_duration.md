# Get duration of sound object (DEPRECATED)

\*\*DEPRECATED:\*\* Use `sound$get_duration()` instead.

## Usage

``` r
get_duration(sound)
```

## Arguments

- sound:

  A Sound R6 object

## Value

Duration in seconds

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
suppressWarnings(get_duration(sound))
#> [1] 0.5
```
