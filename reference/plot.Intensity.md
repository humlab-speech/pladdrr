# Plot Intensity Contour

Creates an intensity (loudness) contour visualization.

## Usage

``` r
# S3 method for class 'Intensity'
plot(
  x,
  from_time = NULL,
  to_time = NULL,
  garnish = TRUE,
  title = "Intensity",
  color = "darkorange",
  ...
)
```

## Arguments

- x:

  Intensity object

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- garnish:

  Logical. Add axis labels and title (default: TRUE)

- title:

  Character. Plot title (default: "Intensity")

- color:

  Character. Line color (default: "darkorange")

- ...:

  Additional arguments (currently unused)

## Value

A ggplot2 object

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 1.0)
intensity <- sound$to_intensity()

# Basic plot
plot(intensity)


# Time range
plot(intensity, from_time = 0.2, to_time = 0.8)

```
