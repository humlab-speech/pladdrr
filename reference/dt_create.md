# Create data.table from named vectors

Convenience function similar to data.frame() but returns data.table.
Automatically sets appropriate key columns.

## Usage

``` r
dt_create(..., key = NULL)
```

## Arguments

- ...:

  Named vectors

- key:

  Character vector of key column names (optional)

## Value

data.table

## Examples

``` r
pladdrr:::dt_create(time = 1:3, value = c(1.1, 2.2, 3.3), key = "time")
#> Key: <time>
#>     time value
#>    <int> <num>
#> 1:     1   1.1
#> 2:     2   2.2
#> 3:     3   3.3
```
