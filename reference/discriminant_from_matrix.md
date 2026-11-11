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
# Two predictor columns: the GSVD path supports any number of predictors.
set.seed(1)
data <- cbind(f1 = c(rnorm(10, 500), rnorm(10, 700)),
              f2 = c(rnorm(10, 800), rnorm(10, 1200)))
labels <- rep(c("a", "i"), each = 10)
disc <- discriminant_from_matrix(data, labels)
disc$get_number_of_groups()
#> [1] 2
```
