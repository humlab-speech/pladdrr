# Polygon Object

2D polygon for geometric operations and spatial analysis.

## Arguments

- x:

  Numeric vector of x coordinates. Required unless `.xptr` is given.

- y:

  Numeric vector of y coordinates. Required unless `.xptr` is given.

- .xptr:

  Not for direct use. External pointer to the underlying C++ Polygon
  object; set internally when a method returns a new Polygon.

## Value

A Polygon object with methods for geometry operations.

## Details

Uses Rcpp Modules for high-performance access to Praat's Polygon object.

## Common uses

- Vowel space boundaries

- Formant space visualization

- Acoustic space analysis

- Convex hull computation

## Examples

``` r
# Create polygon from formant data
poly <- Polygon(x = c(730, 1090, 2440), y = c(1090, 1220, 2440))

# Geometry queries
perimeter <- poly$get_perimeter()
n_points <- poly$n_points()

# Optimize path (traveling salesman)
poly$optimize_salesperson(iterations = 100)

# Export
df <- as.data.frame(poly)
```
