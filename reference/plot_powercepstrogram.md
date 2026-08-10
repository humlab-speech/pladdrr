# Plot PowerCepstrogram

Creates a heatmap visualization of a power cepstrogram showing how the
cepstral spectrum varies over time, similar to a spectrogram.

## Usage

``` r
plot_powercepstrogram(
  cepstrogram,
  time_range = NULL,
  quefrency_range = c(0, 0.05),
  db_range = NULL,
  color_scale = c("viridis", "inferno", "magma", "plasma"),
  show_cpp_contour = FALSE,
  contour_color = "white",
  title = NULL,
  theme = c("minimal", "bw", "classic")
)
```

## Arguments

- cepstrogram:

  PowerCepstrogram object

- time_range:

  Numeric vector. c(start, end) time range to display (default: NULL =
  auto)

- quefrency_range:

  Numeric vector. c(min, max) quefrency range to display (default: c(0,
  0.05))

- db_range:

  Numeric vector. c(min, max) dB range for color scale (default: NULL =
  auto)

- color_scale:

  Character. Color palette: "viridis", "inferno", "magma", "plasma"
  (default: "viridis")

- show_cpp_contour:

  Logical. Overlay CPP contour over time (default: FALSE)

- contour_color:

  Character. Color for CPP contour line (default: "white")

- title:

  Character. Plot title (default: auto-generated)

- theme:

  Character. ggplot2 theme (default: "minimal")

## Value

A ggplot2 object

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)
cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)

# Basic plot
plot_powercepstrogram(cepstrogram)


# With CPP contour
plot_powercepstrogram(cepstrogram,
                     show_cpp_contour = TRUE,
                     quefrency_range = c(0.001, 0.02))

```
