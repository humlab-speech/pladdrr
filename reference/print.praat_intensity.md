# Print method for praat_intensity objects

Print method for praat_intensity objects

## Usage

``` r
# S3 method for class 'praat_intensity'
print(x, ...)
```

## Arguments

- x:

  A praat_intensity object

- ...:

  Additional arguments (unused)

## Value

`x`, invisibly.

## Examples

``` r
x <- list(
  n_frames = 2, time_step = 0.01, minimum_pitch = 100,
  window_length = 0.032, subtract_mean = TRUE,
  values = data.frame(time = c(0.1, 0.2), intensity_db = c(65.2, 66.1))
)
class(x) <- "praat_intensity"
print(x)
#> Praat Intensity Object
#> ======================
#> Number of frames: 2
#> Time step: 0.010000 s
#> Minimum pitch: 100 Hz
#> Window length: 0.0320 s
#> Mean subtracted: yes
#> 
#> First few measurements:
#>   time intensity_db
#> 1  0.1         65.2
#> 2  0.2         66.1
```
