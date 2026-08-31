# Get All Point Times from PointProcess

Extract all point times from a PointProcess object as a numeric vector,
in a single call instead of calling \`get_time(i)\` in a loop.

## Usage

``` r
get_pointprocess_times(pointprocess)
```

## Arguments

- pointprocess:

  A PointProcess object

## Value

Numeric vector of all point times (in seconds)

## Performance

Reduces R\<-\>C++ calls from \`n\` to 1.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
pp <- sound$to_point_process_periodic_cc(75, 600)
times <- get_pointprocess_times(pp)
```
