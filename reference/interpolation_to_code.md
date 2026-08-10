# Convert Interpolation Name to Praat Code

Maps interpolation method names to integer codes.

## Usage

``` r
interpolation_to_code(interpolation)
```

## Arguments

- interpolation:

  Character. Interpolation method name

## Value

Integer interpolation code

## Examples

``` r
pladdrr:::interpolation_to_code("cubic")
#> [1] 2
pladdrr:::interpolation_to_code("linear")
#> [1] 1
```
