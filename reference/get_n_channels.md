# Get number of channels in sound object (DEPRECATED)

\*\*DEPRECATED:\*\* Use `sound$get_number_of_channels()` instead.

## Usage

``` r
get_n_channels(sound)
```

## Arguments

- sound:

  A Sound R6 object

## Value

Number of channels

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
suppressWarnings(get_n_channels(sound))
#> [1] 1
```
