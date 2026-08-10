# Set key columns on data.table

Sets key for fast operations (modifies in place).

## Usage

``` r
dt_setkey(dt, ...)
```

## Arguments

- dt:

  A data.table

- ...:

  Column names to use as key

## Value

data.table (invisibly, modified by reference)

## Examples

``` r
dt <- data.table::data.table(time = 1:100, formant = rep(1:4, 25), freq = rnorm(100))
pladdrr:::dt_setkey(dt, time, formant)  # sorted/indexed lookups on time+formant
```
