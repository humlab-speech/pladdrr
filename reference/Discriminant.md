# Discriminant

Linear Discriminant Analysis (LDA) for vowel classification, speaker
identification, and other multivariate acoustic classification tasks.

## Arguments

- .xptr:

  Not for direct use. External pointer to the underlying C++
  Discriminant object; set internally when a method returns a new
  Discriminant (for example
  [`discriminant_from_matrix`](https://humlab-speech.github.io/pladdrr/reference/discriminant_from_matrix.md)).

## Value

A `Discriminant` object with methods for querying discriminant
functions, eigenvalues, and group statistics.

## Details

Discriminant analysis is commonly used in phonetics for vowel
classification, speaker identification, dialect/accent classification,
and phoneme recognition.

## See also

[`PCA`](https://humlab-speech.github.io/pladdrr/reference/PCA.md)

## Examples

``` r
set.seed(1)
data <- matrix(c(rnorm(10, 500), rnorm(10, 700)), ncol = 1,
                dimnames = list(NULL, "f1"))
labels <- rep(c("a", "i"), each = 10)
disc <- discriminant_from_matrix(data, labels)
disc$get_number_of_groups()
#> [1] 2
disc$get_eigenvalues()
#> [1] 12690.19
```
