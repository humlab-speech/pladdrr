# Create Discriminant Analysis from labeled data

Performs Linear Discriminant Analysis on a labeled numeric matrix.

## Usage

``` r
discriminant_from_matrix(data, labels)
```

## Arguments

- data:

  Numeric matrix where rows are observations and columns are variables

- labels:

  Character vector of group labels (one per row in data)

## Value

A Discriminant object

## Examples

``` r
# NOTE: only a single predictor column is used here; multi-column
# matrices are currently unreliable (see Discriminant class docs).
set.seed(1)
data <- matrix(c(rnorm(10, 500), rnorm(10, 700)), ncol = 1,
                dimnames = list(NULL, "f1"))
labels <- rep(c("a", "i"), each = 10)
disc <- discriminant_from_matrix(data, labels)
disc$get_number_of_groups()
#> [1] 2
```
