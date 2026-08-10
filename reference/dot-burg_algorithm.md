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
#> NULL
```
