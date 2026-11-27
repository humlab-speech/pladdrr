# Praat Matrix Object (PraatMatrix)

Praat Matrix object with direct C++ module binding for matrix
operations.

## Usage

``` r
PraatMatrix(xmin = NULL, xmax = NULL, nx = NULL, dx = NULL,
  x1 = NULL, ymin = NULL, ymax = NULL, ny = NULL, dy = NULL, y1 = NULL,
  numberOfRows = NULL, numberOfColumns = NULL, .xptr = NULL)
```

## Arguments

- xmin, xmax:

  Start and end of the x axis (s).

- nx:

  Number of x samples.

- dx:

  Sampling interval along x (s).

- x1:

  Value of the first x sample (s).

- ymin, ymax:

  Start and end of the y axis.

- ny:

  Number of y samples.

- dy:

  Sampling interval along y.

- y1:

  Value of the first y sample.

- numberOfRows, numberOfColumns:

  Grid size; an alternative to the ten full-domain parameters above.

- .xptr:

  External pointer to an existing Praat Matrix. When given, all other
  arguments are ignored.

## Value

A `PraatMatrix` object with methods for two-dimensional sampled data
access.

## Details

Matrix objects represent two-dimensional sampled data with x and y axes.
A pointer handed in through `.xptr` must already be a Matrix (or a Praat
Matrix subclass such as `Ltas` or `Sound`); any other object is refused
with the package's `pladdrr_input_error` naming the class found, because
reading a foreign object's fields is layout confusion (the same check
[`matrix_read`](https://humlab-speech.github.io/pladdrr/reference/matrix_read.md)
performs on the class a file names).

## Examples

``` r
m <- PraatMatrix(numberOfRows = 3, numberOfColumns = 4)
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
