# Plot Harmonicity (HNR) Contour

Creates a harmonics-to-noise ratio contour visualization.

## Usage

``` r
# S3 method for class 'Harmonicity'
plot(
  x,
  from_time = NULL,
  to_time = NULL,
  garnish = TRUE,
  title = "Harmonicity (HNR)",
  color = "darkviolet",
  ...
)
```

## Arguments

- x:

  Harmonicity object

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- garnish:

  Logical. Add axis labels and title (default: TRUE)

- title:

  Character. Plot title (default: "Harmonicity")

- color:

  Character. Line color (default: "darkviolet")

## Value

A ggplot2 object

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 1.0)
harmonicity <- sound$to_harmonicity_cc()

# Basic plot
plot(harmonicity)


# Time range
plot(harmonicity, from_time = 0.2, to_time = 0.8)

```
