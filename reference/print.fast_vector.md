# Print Method for Fast-Access Vectors

Print Method for Fast-Access Vectors

## Usage

``` r
# S3 method for class 'fast_vector'
print(x, ...)
```

## Arguments

- x:

  A fast_vector

- ...:

  Additional arguments passed to print

## Value

`x`, invisibly.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 16000)
samples <- get_sound_values_fast(sound, channel = 1)
print(samples)
#> Fast-Access Vector
#> Length: 3200 
#> Range: [ -0.9899924 , 0.9899924 ]
#> 
#> First 10 values:
#>  [1] 0.04275163 0.12793600 0.21216606 0.29481352 0.37526190 0.45291110
#>  [7] 0.52718193 0.59752038 0.66340178 0.72433470
#> ... (3190 more values)
```
