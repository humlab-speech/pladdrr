# Calculate basic sound statistics

Calculates basic statistics for a sound vector

## Usage

``` r
sound_stats(sound_data)
```

## Arguments

- sound_data:

  Numeric vector containing sound amplitude values

## Value

List containing mean, min, max, and length statistics

## Examples

``` r
pladdrr:::sound_stats(sin(2 * pi * 150 * seq(0, 1, length.out = 1000)))
#> $mean
#> [1] -1.010015e-16
#> 
#> $min
#> [1] -0.9999889
#> 
#> $max
#> [1] 0.9999889
#> 
#> $length
#> [1] 1000
#> 
```
