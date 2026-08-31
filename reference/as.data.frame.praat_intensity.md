# Convert praat_intensity to data.frame

Convert praat_intensity to data.frame

## Usage

``` r
# S3 method for class 'praat_intensity'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A praat_intensity object

- row.names:

  Not used

- optional:

  Not used

- ...:

  Additional arguments (unused)

## Value

The values data.table (inherits from data.frame) from the intensity
object

## Examples

``` r
x <- list(values = data.frame(time = c(0.1, 0.2), intensity_db = c(65.2,
 66.1)))
class(x) <- "praat_intensity"
as.data.frame(x)
#>   time intensity_db
#> 1  0.1         65.2
#> 2  0.2         66.1
```
