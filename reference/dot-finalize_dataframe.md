# Conditionally return data.table or data.frame

For backward compatibility, allows users to opt into data.frame returns.
This is deprecated and will be removed in v5.0.

## Usage

``` r
.finalize_dataframe(dt)
```

## Arguments

- dt:

  A data.table

## Value

data.table or data.frame depending on options

## Examples

``` r
dt <- data.table::data.table(x = 1:3)
pladdrr:::.finalize_dataframe(dt)
#>        x
#>    <int>
#> 1:     1
#> 2:     2
#> 3:     3
```
