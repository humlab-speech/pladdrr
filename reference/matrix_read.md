# Read a Matrix from file

Reads a Praat Matrix object from a text or binary file.

## Usage

``` r
matrix_read(path)
```

## Arguments

- path:

  Path to the Matrix file

## Value

A Matrix object

## See also

\[matrix_create()\], \[matrix_create_simple()\]

## Examples

``` r
mat_file <- tempfile(fileext = ".Matrix")
m <- matrix_create_simple(1, 2)
m$set_value(1, 1, 1)
m$set_value(1, 2, 2)
m$save(mat_file)

m2 <- matrix_read(mat_file)
m2$get_number_of_rows()
#> [1] 1
m2$get_value(1, 1)
#> [1] 1
```
