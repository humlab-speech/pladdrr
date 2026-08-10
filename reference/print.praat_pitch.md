# Print method for praat_pitch objects

Provides a concise display of a pitch contour.

## Usage

``` r
# S3 method for class 'praat_pitch'
print(x, ...)
```

## Arguments

- x:

  A praat_pitch object

- ...:

  Additional arguments (currently unused)

## Value

The object x, invisibly

## Examples

``` r
x <- data.frame(time = c(0.1, 0.2, 0.3), frequency = c(120, 125, NA))
class(x) <- c("praat_pitch", "data.frame")
print(x)
#> Praat Pitch Object
#> ==================
#> Frames:        3
#> Voiced:        2 (66.7%)
#> Unvoiced:      1 (33.3%)
#> Time range:    [0.100, 0.300] seconds
#> 
#> Pitch Statistics (Hz):
#>   Mean:        122.5
#>   Median:      122.5
#>   Min:         120.0
#>   Max:         125.0
#>   Std Dev:     3.5
```
