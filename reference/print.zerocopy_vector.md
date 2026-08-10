# Print method for legacy zerocopy_vector class (deprecated)

Print method for legacy zerocopy_vector class (deprecated)

## Usage

``` r
# S3 method for class 'zerocopy_vector'
print(x, ...)
```

## Arguments

- x:

  A zerocopy_vector

- ...:

  Additional arguments

## Value

`x`, invisibly.

## Examples

``` r
# zerocopy_vector is a deprecated class name; fast_vector is current.
legacy_vec <- structure(c(0.1, 0.2, 0.3), class = c("zerocopy_vector", "numeric"))
print(legacy_vec)
#> Fast-Access Vector
#> Length: 3 
#> Range: [ 0.1 , 0.3 ]
#> 
#> First 10 values:
#> [1] 0.1 0.2 0.3
```
