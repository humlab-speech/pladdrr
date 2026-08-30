# Plot Pitch and Intensity Together

Creates a dual-axis visualization showing pitch and intensity contours
together. This replicates Praat's Pitch_Intensity_draw() function.

## Usage

``` r
plot_pitch_intensity(
  pitch,
  intensity,
  from_time = NULL,
  to_time = NULL,
  pitch_color = "darkgreen",
  intensity_color = "darkorange",
  title = "Pitch and Intensity",
  ...
)
```

## Arguments

- pitch:

  Pitch object

- intensity:

  Intensity object

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- pitch_color:

  Character. Pitch line color (default: "darkgreen")

- intensity_color:

  Character. Intensity line color (default: "darkorange")

- title:

  Character. Plot title (default: "Pitch and Intensity")

- ...:

  Additional arguments (currently unused)

## Value

A ggplot object with dual y-axes

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 1.0)
pitch <- sound$to_pitch()
intensity <- sound$to_intensity()

# Combined plot
plot_pitch_intensity(pitch, intensity)

# Time range
plot_pitch_intensity(pitch, intensity,
                    from_time = 0.2, to_time = 0.8)
```
