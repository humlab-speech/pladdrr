# Summary method for praat_pitch objects

Provides a detailed statistical summary of a pitch contour.

## Usage

``` r
# S3 method for class 'praat_pitch'
summary(object, ...)
```

## Arguments

- object:

  A praat_pitch object

## Value

The object, invisibly

## Examples

``` r
x <- data.frame(time = c(0.1, 0.2, 0.3), frequency = c(120, 125, NA))
class(x) <- c("praat_pitch", "data.frame")
summary(x)
#> Praat Pitch Object - Summary
#> ============================
#> 
#> Frame Information:
#>   Total frames:  3
#>   Voiced:        2 (66.7%)
#>   Unvoiced:      1 (33.3%)
#> 
#> Time Range:
#>   Start:         0.100 seconds
#>   End:           0.300 seconds
#>   Duration:      0.200 seconds
#> 
#> Pitch Statistics (voiced frames, Hz):
#>   Mean:          122.50
#>   Median:        122.50
#>   Min:           120.00
#>   Max:           125.00
#>   Range:         5.00
#>   Std Dev:       3.54
#>   Quantiles:
#>     25%:          121.25
#>     50%:          122.50
#>     75%:          123.75
```
