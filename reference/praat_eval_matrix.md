# Evaluate a matrix Praat expression

Evaluate a matrix Praat expression

## Usage

``` r
praat_eval_matrix(expression)
```

## Arguments

- expression:

  Character string containing a Praat matrix formula

## Value

Numeric matrix

## Examples

``` r
# Create matrix
mat <- praat_eval_matrix("{{ 1, 2 }, { 3, 4 }}")
```
