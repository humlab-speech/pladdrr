# Plot Formant Tracks

Creates a formant trajectory visualization showing F1, F2, F3, etc.

## Usage

``` r
# S3 method for class 'Formant'
plot(
  x,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3,
  garnish = TRUE,
  title = "Formant",
  colors = NULL,
  ...
)
```

## Arguments

- x:

  Formant object

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- max_formant:

  Maximum formant number to display (default: 3)

- garnish:

  Logical. Add axis labels and title (default: TRUE)

- title:

  Character. Plot title (default: "Formant")

- colors:

  Character vector. Colors for each formant (default: auto)

- ...:

  Additional arguments (currently unused)

## Value

A ggplot2 object

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)
formant <- sound$to_formant_burg()

# Basic plot
plot(formant)


# Show first 5 formants
plot(formant, max_formant = 5)


# Customize
plot(formant, max_formant = 2,
     colors = c("red", "blue"))

```
