# Create a simple Praat Matrix

Creates a new Matrix object with given dimensions. Domain defaults to
\[0,1\] for both axes.

## Usage

``` r
matrix_create_simple(numberOfRows, numberOfColumns)
```

## Arguments

- numberOfRows:

  Number of rows

- numberOfColumns:

  Number of columns

## Value

A Matrix object

## See also

\[matrix_create()\] for full parameter control, \[Matrix\] for object
methods

## Examples

``` r
m <- matrix_create_simple(3, 4)
m$set_value(1, 1, 5.0)
m$get_value(1, 1)
#> [1] 5
```
