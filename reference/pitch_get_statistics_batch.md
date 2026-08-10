# Batch get pitch statistics over multiple time intervals

Calculate multiple pitch statistics (min, max, mean, stdev, quantiles)
over multiple time intervals in a single C++ call, avoiding repeated R
method calls.

## Usage

``` r
pitch_get_statistics_batch(
  pitch_xptr,
  from_times,
  to_times,
  metrics,
  unit = 0L
)
```

## Arguments

- pitch_xptr:

  External pointer to Pitch object

- from_times:

  Numeric vector of interval start times

- to_times:

  Numeric vector of interval end times

- metrics:

  Character vector of metrics: "min", "max", "mean", "stdev", "q25",
  "q50" (median), "q75", "count_voiced"

- unit:

  Integer code for unit (0=HERTZ, 1=HERTZ_LOGARITHMIC, etc)

## Value

NumericMatrix with intervals as rows, metrics as columns

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
pladdrr:::pitch_get_statistics_batch(
  pitch$.xptr,
  from_times = c(0, 0.5),
  to_times = c(0.5, 1.0),
  metrics = c("min", "max", "mean")
)
#>           min      max     mean
#> [1,] 150.0017 150.0017 150.0017
#> [2,] 150.0017 150.0017 150.0017
```
