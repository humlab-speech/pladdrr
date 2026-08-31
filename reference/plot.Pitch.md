# Plot Pitch Contour

Creates a pitch (F0) contour visualization of a Pitch object.

## Usage

``` r
# S3 method for class 'Pitch'
plot(
  x,
  from_time = NULL,
  to_time = NULL,
  garnish = TRUE,
  title = "Pitch",
  color = "darkgreen",
  show_voicing = TRUE,
  ...
)
```

## Arguments

- x:

  Pitch object

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- garnish:

  Logical. Add axis labels and title (default: TRUE)

- title:

  Character. Plot title (default: "Pitch")

- color:

  Character. Line color (default: "darkgreen")

- show_voicing:

  Logical. Color by voicing (default: TRUE)

## Value

A ggplot2 object

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 1.0)
pitch <- sound$to_pitch()

# Basic plot
plot(pitch)


# Time range
plot(pitch, from_time = 0.2, to_time = 0.8)


# Customize
plot(pitch, show_voicing = FALSE, color = "blue") +
  ggplot2::geom_hline(yintercept = 120, linetype = "dashed")

```
