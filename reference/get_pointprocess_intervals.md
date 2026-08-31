# Get Inter-Point Intervals from PointProcess

Compute the time intervals between consecutive points in a PointProcess.
Useful for jitter analysis and prosody studies.

## Usage

``` r
get_pointprocess_intervals(pointprocess)
```

## Arguments

- pointprocess:

  A PointProcess object

## Value

Numeric vector of intervals (in seconds). Length is \`n_points - 1\`.

## Performance

Computes all intervals in C++ without R\<-\>C++ overhead.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
pp <- sound$to_point_process_periodic_cc(75, 600)
intervals <- get_pointprocess_intervals(pp)
jitter <- sd(intervals) / mean(intervals)
```
