# Praat Matrix Object

Praat Matrix object with direct C++ module binding for matrix
operations.

## Value

A `Matrix` object with methods for two-dimensional sampled data access.

## Details

Matrix objects represent two-dimensional sampled data with x and y axes.

## Examples

``` r
m <- Matrix(numberOfRows = 3, numberOfColumns = 4)
m$set_value(1, 1, 5.0)
m$get_value(1, 1)
#> [1] 5
m$get_number_of_rows()
#> [1] 3
as.matrix(m)
#>      [,1] [,2] [,3] [,4]
#> [1,]    5    0    0    0
#> [2,]    0    0    0    0
#> [3,]    0    0    0    0

# Save and read back
mat_file <- tempfile(fileext = ".Matrix")
m$save(mat_file)
m2 <- matrix_read(mat_file)
m2$get_value(1, 1)
#> [1] 5
```
