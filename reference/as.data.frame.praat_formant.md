# Convert praat_formant to data.frame

Convert praat_formant to data.frame

## Usage

``` r
# S3 method for class 'praat_formant'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A praat_formant object

- row.names:

  Not used

- optional:

  Not used

- ...:

  Additional arguments (unused)

## Value

The values data.table (inherits from data.frame) from the formant object

## Examples

``` r
x <- list(values = data.frame(
  time = c(0.1, 0.2), formant_number = c(1, 1),
  frequency = c(500, 520), bandwidth = c(80, 82)
))
class(x) <- "praat_formant"
as.data.frame(x)
#>   time formant_number frequency bandwidth
#> 1  0.1              1       500        80
#> 2  0.2              1       520        82
```
