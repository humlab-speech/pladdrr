# Convert praat_sound to data frame

Converts a praat_sound object to a data frame with time and amplitude
columns. This is useful for plotting and further analysis in R.

## Usage

``` r
# S3 method for class 'praat_sound'
as.data.frame(x, ...)
```

## Arguments

- x:

  A praat_sound object

- ...:

  Additional arguments (currently unused)

## Value

A data.table (inherits from data.frame) with two columns:

- time:

  Time in seconds

- amplitude:

  Amplitude values

## Examples

``` r
values <- sin(2 * pi * 220 * seq(0, 0.1, length.out = 1000))
snd <- create_sound_from_values(values, sampling_rate = 10000)
df <- as.data.frame(snd)
#> Warning: as.data.frame.praat_sound() is deprecated. Use Sound$as_data_frame() instead.
head(df)
#>    time amplitude
#> 1 0e+00 0.0000000
#> 2 1e-04 0.1379273
#> 3 2e-04 0.2732182
#> 4 3e-04 0.4032863
#> 5 4e-04 0.5256456
#> 6 5e-04 0.6379569
```
