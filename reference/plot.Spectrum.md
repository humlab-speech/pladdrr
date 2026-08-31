# Plot Spectrum

Creates a frequency spectrum visualization.

## Usage

``` r
# S3 method for class 'Spectrum'
plot(
  x,
  from_freq = NULL,
  to_freq = NULL,
  log_freq = FALSE,
  garnish = TRUE,
  title = "Spectrum",
  color = "navy",
  ...
)
```

## Arguments

- x:

  Spectrum object

- from_freq:

  Start frequency in Hz (NULL = from 0)

- to_freq:

  End frequency in Hz (NULL = to Nyquist)

- log_freq:

  Logical. Use logarithmic frequency scale (default: FALSE)

- garnish:

  Logical. Add axis labels and title (default: TRUE)

- title:

  Character. Plot title (default: "Spectrum")

- color:

  Character. Line color (default: "navy")

## Value

A ggplot2 object

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)
spectrum <- sound$to_spectrum()

# Basic plot
plot(spectrum)


# Logarithmic frequency
plot(spectrum, log_freq = TRUE)
#> Warning: log-10 transformation introduced infinite values.

```
