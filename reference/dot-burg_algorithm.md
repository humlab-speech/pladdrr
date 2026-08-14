# Burg's algorithm for LPC estimation

Burg's algorithm for LPC estimation

## Usage

``` r
.burg_algorithm(x, order)
```

## Arguments

- x:

  Numeric vector, the input signal frame

- order:

  Integer, the LPC order

## Value

A list with `coefficients` (numeric vector of LPC coefficients) and
`error` (prediction error power), or `NULL` if `x` is too short or has
no variation

## Examples

``` r
set.seed(1)
x <- sin(2 * pi * 5 * seq(0, 1, length.out = 100)) + rnorm(100, sd = 0.01)
pladdrr:::.burg_algorithm(x, order = 8)
#> $coefficients
#> [1] -0.38280637 -0.26011055 -0.12924684 -0.05052718  0.03216793  0.18496016
#> [7]  0.08047252  0.27562348
#> 
#> $error
#> [1] 0.0001139047
#> 
```
