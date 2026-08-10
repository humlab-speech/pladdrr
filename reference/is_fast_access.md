# Check if Vector is a Fast-Access Vector

Check if Vector is a Fast-Access Vector

## Usage

``` r
is_fast_access(x)
```

## Arguments

- x:

  Numeric vector

## Value

TRUE if x has the fast_vector or zerocopy_vector class

## Examples

``` r
is_fast_access(1:10)
#> [1] FALSE
sound <- Sound$create_tone(frequency = 220, duration = 0.1, sampling_rate = 8000)
is_fast_access(get_sound_values_fast(sound))
#> [1] TRUE
```
