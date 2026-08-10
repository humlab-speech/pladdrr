# Load PitchTier from file

Static method to load PitchTier from file

## Usage

``` r
pitchtier_from_file(path)
```

## Arguments

- path:

  Path to PitchTier file

## Value

PitchTier object

## Examples

``` r
tier <- PitchTier(0, 1)
tier$add_point(0.5, 150)
tmp <- tempfile(fileext = ".PitchTier")
tier$save(tmp)
loaded <- pladdrr:::pitchtier_from_file(tmp)
unlink(tmp)
```
