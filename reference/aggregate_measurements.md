# Aggregate Measurements by Label

Aggregate extracted measurements by interval label (e.g., phoneme,
word). Common workflow after extract_measurements().

## Usage

``` r
aggregate_measurements(
  measurements,
  by = "label",
  stats = c("mean", "sd", "n")
)
```

## Arguments

- measurements:

  Data frame from extract_measurements().

- by:

  Character. Column to group by (default: "label").

- stats:

  Character vector. Statistics to compute: "mean", "sd", "median",
  "min", "max", "n".

## Value

Data frame with aggregated statistics.

## Examples

``` r
results <- data.frame(
  label = c("a", "a", "e", "e"),
  f0 = c(150, 155, 210, 205)
)
vowel_stats <- aggregate_measurements(
  measurements = results,
  by = "label",
  stats = c("mean", "sd", "n")
)
```
