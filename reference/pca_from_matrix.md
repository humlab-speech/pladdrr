# Create PCA from data matrix

Performs Principal Component Analysis on a numeric matrix.

## Usage

``` r
pca_from_matrix(data)
```

## Arguments

- data:

  Numeric matrix where rows are observations and columns are variables

## Value

A PCA object

## Examples

``` r
set.seed(1)
data <- matrix(rnorm(50), nrow = 10, ncol = 5)
pca <- pca_from_matrix(data)
print(pca)
#> <PCA>
#>   Components: 5, Dimension: 5
#>   Observations: 10
#>   Variance explained:
#>     PC1: 54.9% (cumulative: 54.9%)
#>     PC2: 20.4% (cumulative: 75.2%)
#>     PC3: 15.4% (cumulative: 90.6%)
#>     PC4: 5.3% (cumulative: 95.9%)
#>     PC5: 4.1% (cumulative: 100.0%)
```
