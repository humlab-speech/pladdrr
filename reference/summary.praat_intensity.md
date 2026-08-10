# Summary method for praat_intensity objects

Summary method for praat_intensity objects

## Usage

``` r
# S3 method for class 'praat_intensity'
summary(object, ...)
```

## Arguments

- object:

  A praat_intensity object

- ...:

  Additional arguments (unused)

## Value

`object`, invisibly.

## Examples

``` r
x <- list(
  n_frames = 2, time_step = 0.01, minimum_pitch = 100,
  values = data.frame(time = c(0.1, 0.2), intensity_db = c(65.2, 66.1))
)
class(x) <- "praat_intensity"
summary(x)
#> Praat Intensity Object
#> ======================
#> Number of frames: 2
#> Time step: 0.010000 s
#> Minimum pitch: 100 Hz
#> 
#> Intensity statistics:
#>   Valid frames: 2 (100.0%)
#>   Mean: 65.65 dB
#>   SD: 0.64 dB
#>   Range: 65.20 - 66.10 dB
```
