# Create empty data.table with typed columns

Replacement for data.frame() constructor.

## Usage

``` r
dt_empty(...)
```

## Arguments

- ...:

  Named vectors defining column types (e.g., time=numeric())

## Value

Empty data.table with specified columns

## Examples

``` r
# Before: results <- data.frame(time=numeric(), value=numeric())
# After:  results <- pladdrr:::dt_empty(time=numeric(), value=numeric())
results <- pladdrr:::dt_empty(time=numeric(), formant=integer(), frequency=numeric())
```
