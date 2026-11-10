# Create Sound from numeric values

Factory function to create a Sound object from a numeric vector or
matrix. Use \`Sound\$from_values()\` for backward compatibility (calls
this function).

## Usage

``` r
sound_from_values(values, sampling_rate = 44100, start_time = 0)
```

## Arguments

- values:

  Numeric matrix with channels as rows, samples as columns (or vector
  for mono). Integer vectors, `units` vectors (units are dropped) and
  [`ts`](https://rdrr.io/r/stats/ts.html) series are accepted. For a
  `ts`, a `sampling_rate` or `start_time` you leave out is taken from
  the series' `frequency` and start, which are then read as samples per
  second and seconds. NA, NaN, Inf and non-numeric input are an error.

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- start_time:

  Start time of the sound in seconds (default: 0.0)

## Value

A Sound object

## Examples

``` r
# Create from vector (mono)
values <- sin(2 * pi * 440 * seq(0, 1, length.out = 4410))
sound <- sound_from_values(values, 4410)

# Or using Sound$from_values() (same thing)
sound <- Sound$from_values(values, 4410)

# A ts supplies the sampling rate and start time
series <- ts(values, start = 0.5, frequency = 4410)
sound <- Sound$from_values(series)
sound$get_start_time()
#> [1] 0.5
```
