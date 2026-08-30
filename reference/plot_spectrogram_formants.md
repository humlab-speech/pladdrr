# Plot Spectrogram with Formant Overlay

Creates a spectrogram heatmap with formant trajectories overlaid. This
is a common visualization pattern in Praat for vowel analysis.

## Usage

``` r
plot_spectrogram_formants(
  spectrogram,
  formant,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3,
  formant_colors = NULL,
  dynamic_range = 70,
  title = "Spectrogram + Formants",
  ...
)
```

## Arguments

- spectrogram:

  Spectrogram object

- formant:

  Formant object

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- max_formant:

  Maximum formant number to display (default: 3)

- formant_colors:

  Character vector. Colors for formants (default: auto)

- dynamic_range:

  Numeric. Spectrogram dynamic range in dB (default: 70)

- title:

  Character. Plot title (default: "Spectrogram + Formants")

- ...:

  Additional arguments passed to plot.Spectrogram

## Value

A ggplot object with formant tracks overlaid on spectrogram

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)
spectrogram <- sound$to_spectrogram()
formant <- sound$to_formant_burg()

# Combined plot
plot_spectrogram_formants(spectrogram, formant)

# Show F1-F5
plot_spectrogram_formants(spectrogram, formant, max_formant = 5)
```
