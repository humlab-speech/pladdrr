# Batch get intensity statistics over multiple time intervals

Batch get intensity statistics over multiple time intervals

## Usage

``` r
intensity_get_statistics_batch(
  intensity_xptr,
  from_times,
  to_times,
  metrics,
  averaging_method = 0L
)
```

## Arguments

- intensity_xptr:

  External pointer to Intensity object

- from_times:

  Numeric vector of interval start times

- to_times:

  Numeric vector of interval end times

- metrics:

  Character vector: "min", "max", "mean", "stdev", "q25", "q50", "q75"

- averaging_method:

  Integer (0=ENERGY, 1=SONES, 2=DB)

## Value

NumericMatrix with intervals as rows, metrics as columns

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
intensity <- sound$to_intensity()
pladdrr:::intensity_get_statistics_batch(
  intensity$.xptr, c(0.1, 0.3), c(0.2, 0.4), c("mean", "max")
)
#>          mean      max
#> [1,] 90.88496 90.88958
#> [2,] 90.88496 90.88958
```
