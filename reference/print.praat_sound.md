# Print method for praat_sound objects

Provides a concise, informative display of a praat_sound object.

## Usage

``` r
# S3 method for class 'praat_sound'
print(x, ...)
```

## Arguments

- x:

  A praat_sound object

- ...:

  Additional arguments passed to the underlying function or ignored.

## Value

The object x, invisibly

## Examples

``` r
sound <- create_sound(rep(0, 1000), sampling_rate = 44100)
#> Warning: create_sound() is deprecated and will be removed in v6.0.0. Use Sound$from_values(values, sampling_rate) instead. The R6 interface provides better performance and more features.
print(sound)
#> <Praat Sound>
#>   Duration: 0.023 s
#>   Sampling frequency: 44100 Hz
#>   Number of samples: 1000
#>   Number of channels: 1
```
