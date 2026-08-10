# Get sampling rate of sound object (DEPRECATED)

\*\*DEPRECATED:\*\* Use `sound$get_sampling_frequency()` instead.

## Usage

``` r
get_sampling_rate(sound)
```

## Arguments

- sound:

  A Sound R6 object

## Value

Sampling rate in Hz

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
get_sampling_rate(sound)
#> Warning: 'get_sampling_rate' is deprecated.
#> Use 'sound$get_sampling_frequency()' instead.
#> See help("Deprecated") and help("pladdrr-deprecated").
#> [1] 16000
```
