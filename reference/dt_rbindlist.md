# Efficiently bind list of rows into data.table

Replacement for repeated rbind() calls in loops.

## Usage

``` r
dt_rbindlist(l, fill = TRUE)
```

## Arguments

- l:

  List of lists or data.frames to bind

- fill:

  Logical, fill missing columns with NA (default TRUE)

## Value

data.table

## Examples

``` r
results_list <- vector("list", 5)
for (i in 1:5) results_list[[i]] <- list(x = i, y = i^2)
results <- pladdrr:::dt_rbindlist(results_list)
```
