# Plot Spectrogram Heatmap

Creates a time-frequency heatmap visualization of a Spectrogram.

## Usage

``` r
# S3 method for class 'Spectrogram'
plot(
  x,
  from_time = NULL,
  to_time = NULL,
  from_freq = NULL,
  to_freq = NULL,
  garnish = TRUE,
  title = "Spectrogram",
  dynamic_range = 70,
  ...
)
```

## Arguments

- x:

  Spectrogram object

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- from_freq:

  Start frequency in Hz (NULL = from 0)

- to_freq:

  End frequency in Hz (NULL = to Nyquist)

- garnish:

  Logical. Add axis labels and title (default: TRUE)

- title:

  Character. Plot title (default: "Spectrogram")

- dynamic_range:

  Numeric. Dynamic range in dB (default: 70)

## Value

A ggplot2 object

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)
spectrogram <- sound$to_spectrogram()

# Basic plot
plot(spectrogram)


# Focus on speech range
plot(spectrogram, to_freq = 5000)

```
