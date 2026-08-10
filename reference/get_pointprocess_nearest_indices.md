# Query PointProcess Nearest Indices at Multiple Times

Find the nearest point index for each of multiple query times.

## Usage

``` r
get_pointprocess_nearest_indices(pointprocess, times)
```

## Arguments

- pointprocess:

  A PointProcess object

- times:

  Numeric vector of query times (in seconds)

## Value

Integer vector of nearest point indices (1-based)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
pp <- sound$to_point_process_periodic_cc(75, 600)
query_times <- seq(0.1, 0.4, by = 0.05)
indices <- get_pointprocess_nearest_indices(pp, query_times)
```
