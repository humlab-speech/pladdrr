# Get number of samples in sound object (DEPRECATED)

\*\*DEPRECATED:\*\* Use `sound$get_number_of_samples()` instead.

## Usage

``` r
get_n_samples(sound)
```

## Arguments

- sound:

  A Sound R6 object

## Value

Number of samples

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
suppressWarnings(get_n_samples(sound))
#> [1] 8000
```
