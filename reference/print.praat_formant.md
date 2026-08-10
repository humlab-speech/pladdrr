# Print method for praat_formant objects

Print method for praat_formant objects

## Usage

``` r
# S3 method for class 'praat_formant'
print(x, ...)
```

## Arguments

- x:

  A praat_formant object

- ...:

  Additional arguments (unused)

## Value

`x`, invisibly.

## Examples

``` r
x <- list(
  n_frames = 2, n_formants = 1, time_step = 0.01,
  max_formant = 5000, window_length = 0.025,
  values = data.frame(
    time = c(0.1, 0.2), formant_number = c(1, 1),
    frequency = c(500, 520), bandwidth = c(80, 82)
  )
)
class(x) <- "praat_formant"
print(x)
#> Praat Formant Object
#> ====================
#> Number of frames: 2
#> Number of formants tracked: 1
#> Time step: 0.010000 s
#> Maximum formant: 5000 Hz
#> Window length: 0.0250 s
#> 
#> First few measurements:
#>   time formant_number frequency bandwidth
#> 1  0.1              1       500        80
#> 2  0.2              1       520        82
```
