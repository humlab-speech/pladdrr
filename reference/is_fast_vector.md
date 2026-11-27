# Check if Vector is a Fast-Access Vector

Tests whether a numeric vector was created by
\[get_sound_values_fast()\].

## Usage

``` r
is_fast_vector(x)

is_zerocopy_vector(x)
```

## Arguments

- x:

  A vector to test

## Value

Logical. TRUE if vector has fast_vector/zerocopy_vector class.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)

fast_vec <- get_sound_values_fast(sound, 1)
regular_vec <- sound$get_values(1)

is_fast_vector(fast_vec)     # TRUE
#> [1] TRUE
is_fast_vector(regular_vec)  # FALSE
#> [1] FALSE
```
