# Create a Praat Matrix with full parameters

Creates a new Matrix object with explicit domain and sampling
parameters.

## Usage

``` r
matrix_create(xmin, xmax, nx, dx, x1, ymin, ymax, ny, dy, y1)
```

## Arguments

- xmin:

  Minimum x value (start of x domain)

- xmax:

  Maximum x value (end of x domain)

- nx:

  Number of columns

- dx:

  X sampling period (step between columns)

- x1:

  X value of first column

- ymin:

  Minimum y value (start of y domain)

- ymax:

  Maximum y value (end of y domain)

- ny:

  Number of rows

- dy:

  Y sampling period (step between rows)

- y1:

  Y value of first row

## Value

A Matrix object

## See also

\[matrix_create_simple()\] for simpler creation, \[Matrix\] for object
methods

## Examples

``` r
m <- matrix_create(xmin = 0, xmax = 2, nx = 2, dx = 1, x1 = 0.5,
                    ymin = 0, ymax = 1, ny = 1, dy = 1, y1 = 0.5)
m$get_number_of_rows()
#> [1] 1
m$get_number_of_columns()
#> [1] 2
```
