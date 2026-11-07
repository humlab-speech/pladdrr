# Read a Matrix from file

Reads a Praat Matrix object from a matrix text file (Praat's binary
object files are not read - this is Praat's text-file reader). A Praat
file names the class to instantiate; if it names a class other than
Matrix, an error is raised naming the class found (casting blindly used
to give garbage numbers or an uncatchable segfault).

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

[`matrix_create`](https://humlab-speech.github.io/pladdrr/reference/matrix_create.md),
[`matrix_create_simple`](https://humlab-speech.github.io/pladdrr/reference/matrix_create_simple.md)

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
