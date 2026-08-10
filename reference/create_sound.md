# Create a sound object from numeric values (DEPRECATED)

\*\*DEPRECATED:\*\* This S3 function is deprecated. Use the R6 interface
instead: `Sound$from_values(values, sampling_rate)`

## Usage

``` r
create_sound(values, sampling_rate = 44100, start_time = 0)
```

## Arguments

- values:

  Numeric vector of amplitude values

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- start_time:

  Start time in seconds (default: 0.0)

## Value

Sound R6 object

## Examples

``` r
# Old S3 approach (DEPRECATED, shown for reference)
sound <- create_sound(c(0.1, 0.2), sampling_rate = 1000)
#> Warning: create_sound() is deprecated and will be removed in v5.0.0. Use Sound$from_values(values, sampling_rate) instead. The R6 interface provides better performance and more features.

# New R6 approach (RECOMMENDED)
sound2 <- Sound$from_values(c(0.1, 0.2), sampling_rate = 1000)
```
