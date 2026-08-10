# Ensure object is a data.table

Converts to data.table if not already one (modifies in place).

## Usage

``` r
ensure_datatable(df)
```

## Arguments

- df:

  A data.frame or data.table

## Value

data.table (invisibly)

## Examples

``` r
df <- data.frame(x = 1:3, y = c("a", "b", "c"))
pladdrr:::ensure_datatable(df)
```
