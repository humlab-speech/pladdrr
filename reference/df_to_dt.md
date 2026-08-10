# Convert data.frame to data.table

Creates a copy as data.table (does not modify original).

## Usage

``` r
df_to_dt(df)
```

## Arguments

- df:

  A data.frame

## Value

data.table

## Examples

``` r
df <- data.frame(x = 1:3, y = c("a", "b", "c"))
pladdrr:::df_to_dt(df)
#>        x      y
#>    <int> <char>
#> 1:     1      a
#> 2:     2      b
#> 3:     3      c
```
