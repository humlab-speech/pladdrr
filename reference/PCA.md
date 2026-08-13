# PCA

Principal Component Analysis (PCA) for dimensionality reduction and
analysis of multivariate acoustic data.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++ PCA object;
  set internally when a method returns a new PCA (for example
  [`pca_from_matrix`](https://humlab-speech.github.io/pladdrr/reference/pca_from_matrix.md)).

## Value

A `PCA` object with methods for querying components, eigenvalues, and
projections.

## Details

PCA is commonly used in phonetics for vowel space analysis, speaker
normalization, acoustic feature extraction, and data visualization.

## See also

[`Discriminant`](https://humlab-speech.github.io/pladdrr/reference/Discriminant.md)

## Examples

``` r
set.seed(1)
data <- cbind(f1 = rnorm(20, 500, 50), f2 = rnorm(20, 1500, 100))
pca <- pca_from_matrix(data)
pca$get_number_of_components()
#> [1] 2
pca$get_eigenvalues()
#> [1] 7725.581 1952.273
```
