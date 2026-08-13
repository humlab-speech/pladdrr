# Autoplot and Autolayer Methods for pladdrr Objects

ggplot2-style autoplot() and autolayer() methods for Praat objects.
These provide a tidyverse-idiomatic interface for plotting, allowing
flexible composition of multi-object visualizations.

## Usage

``` r
# S3 method for class 'Sound'
autoplot(object, from_time = NULL, to_time = NULL, color = "steelblue", ...)

# S3 method for class 'Sound'
autolayer(object, from_time = NULL, to_time = NULL, color = "steelblue", ...)

# S3 method for class 'Pitch'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  color = "darkgreen",
  show_voicing = FALSE,
  ...
)

# S3 method for class 'Pitch'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  color = "darkgreen",
  geom = c("line", "point"),
  ...
)

# S3 method for class 'Formant'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3,
  colors = NULL,
  ...
)

# S3 method for class 'Formant'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3,
  colors = NULL,
  ...
)

# S3 method for class 'Intensity'
autoplot(object, from_time = NULL, to_time = NULL, color = "darkorange", ...)

# S3 method for class 'Intensity'
autolayer(object, from_time = NULL, to_time = NULL, color = "darkorange", ...)

# S3 method for class 'Spectrogram'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  from_freq = NULL,
  to_freq = NULL,
  dynamic_range = 70,
  ...
)

# S3 method for class 'Spectrogram'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  from_freq = NULL,
  to_freq = NULL,
  dynamic_range = 70,
  ...
)

# S3 method for class 'Spectrum'
autoplot(
  object,
  from_freq = NULL,
  to_freq = NULL,
  log_freq = FALSE,
  color = "navy",
  ...
)

# S3 method for class 'Spectrum'
autolayer(object, from_freq = NULL, to_freq = NULL, color = "navy", ...)

# S3 method for class 'Ltas'
autoplot(
  object,
  from_freq = NULL,
  to_freq = NULL,
  log_freq = FALSE,
  color = "darkred",
  ...
)

# S3 method for class 'Ltas'
autolayer(object, from_freq = NULL, to_freq = NULL, color = "darkred", ...)

# S3 method for class 'Harmonicity'
autoplot(object, from_time = NULL, to_time = NULL, color = "darkviolet", ...)

# S3 method for class 'Harmonicity'
autolayer(object, from_time = NULL, to_time = NULL, color = "darkviolet", ...)

# S3 method for class 'PointProcess'
autoplot(object, from_time = NULL, to_time = NULL, color = "black", ...)

# S3 method for class 'PointProcess'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  color = "black",
  ymin = 0,
  ymax = 1,
  ...
)

# S3 method for class 'PowerCepstrum'
autoplot(
  object,
  from_quefrency = NULL,
  to_quefrency = NULL,
  color = "darkblue",
  mark_peak = TRUE,
  ...
)

# S3 method for class 'PowerCepstrum'
autolayer(
  object,
  from_quefrency = NULL,
  to_quefrency = NULL,
  color = "darkblue",
  ...
)

# S3 method for class 'TextGrid'
autoplot(object, ...)

# S3 method for class 'TextGrid'
autolayer(
  object,
  tier = 1,
  from_time = NULL,
  to_time = NULL,
  color = "steelblue",
  alpha = 0.3,
  ...
)

# S3 method for class 'AmplitudeTier'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  color = "darkred",
  garnish = TRUE,
  ...
)

# S3 method for class 'AmplitudeTier'
autolayer(object, from_time = NULL, to_time = NULL, color = "darkred", ...)

# S3 method for class 'DurationTier'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  color = "steelblue",
  garnish = TRUE,
  ...
)

# S3 method for class 'DurationTier'
autolayer(object, from_time = NULL, to_time = NULL, color = "steelblue", ...)

# S3 method for class 'IntensityTier'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  color = "darkgreen",
  garnish = TRUE,
  ...
)

# S3 method for class 'IntensityTier'
autolayer(object, from_time = NULL, to_time = NULL, color = "darkgreen", ...)

# S3 method for class 'PitchTier'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  color = "blue",
  garnish = TRUE,
  ...
)

# S3 method for class 'PitchTier'
autolayer(object, from_time = NULL, to_time = NULL, color = "blue", ...)

# S3 method for class 'FormantTier'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3L,
  colors = NULL,
  time_step = 0.005,
  style = c("speckle", "line"),
  garnish = TRUE,
  ...
)

# S3 method for class 'FormantTier'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3L,
  colors = NULL,
  time_step = 0.005,
  style = c("speckle", "line"),
  ...
)

# S3 method for class 'FormantGrid'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3L,
  colors = NULL,
  garnish = TRUE,
  ...
)

# S3 method for class 'FormantGrid'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3L,
  colors = NULL,
  ...
)

# S3 method for class 'FormantPath'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3L,
  colors = NULL,
  show_candidates = TRUE,
  garnish = TRUE,
  ...
)

# S3 method for class 'FormantPath'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  max_formant = 3L,
  colors = NULL,
  show_candidates = FALSE,
  ...
)

# S3 method for class 'Excitation'
autoplot(object, garnish = TRUE, color = "darkred", ...)

# S3 method for class 'Excitation'
autolayer(object, color = "darkred", ...)

# S3 method for class 'ComplexSpectrogram'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  from_freq = NULL,
  to_freq = NULL,
  dynamic_range = 70,
  garnish = TRUE,
  show_phase = FALSE,
  ...
)

# S3 method for class 'ComplexSpectrogram'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  from_freq = NULL,
  to_freq = NULL,
  dynamic_range = 70,
  ...
)

# S3 method for class 'Cepstrum'
autoplot(object, power = FALSE, garnish = TRUE, color = "darkblue", ...)

# S3 method for class 'Cepstrum'
autolayer(object, power = FALSE, color = "darkblue", ...)

# S3 method for class 'Cochleagram'
autoplot(object, from_time = NULL, to_time = NULL, garnish = TRUE, ...)

# S3 method for class 'Cochleagram'
autolayer(object, from_time = NULL, to_time = NULL, ...)

# S3 method for class 'PowerCepstrogram'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  quefrency_range = NULL,
  garnish = TRUE,
  ...
)

# S3 method for class 'PowerCepstrogram'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  quefrency_range = NULL,
  ...
)

# S3 method for class 'MFCC'
autoplot(object, coefficient_range = NULL, garnish = TRUE, ...)

# S3 method for class 'MFCC'
autolayer(object, coefficient_range = NULL, ...)

# S3 method for class 'LFCC'
autoplot(object, coefficient_range = NULL, garnish = TRUE, ...)

# S3 method for class 'LFCC'
autolayer(object, coefficient_range = NULL, ...)

# S3 method for class 'BarkSpectrogram'
autoplot(object, garnish = TRUE, ...)

# S3 method for class 'BarkSpectrogram'
autolayer(object, ...)

# S3 method for class 'MelSpectrogram'
autoplot(object, garnish = TRUE, ...)

# S3 method for class 'MelSpectrogram'
autolayer(object, ...)

# S3 method for class 'Matrix'
autoplot(
  object,
  x_col = NULL,
  y_col = NULL,
  fill_col = NULL,
  garnish = TRUE,
  ...
)

# S3 method for class 'Matrix'
autolayer(object, x_col = NULL, y_col = NULL, fill_col = NULL, ...)

# S3 method for class 'PCA'
autoplot(object, type = c("scree", "scores", "both"), garnish = TRUE, ...)

# S3 method for class 'PCA'
autolayer(object, ...)

# S3 method for class 'Discriminant'
autoplot(object, type = c("scree", "scores", "both"), garnish = TRUE, ...)

# S3 method for class 'Discriminant'
autolayer(object, ...)

# S3 method for class 'FormantModeler'
autoplot(object, from_track = 1L, to_track = 0L, garnish = TRUE, ...)

# S3 method for class 'FormantModeler'
autolayer(object, from_track = 1L, to_track = 0L, ...)

# S3 method for class 'Electroglottogram'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  color = "black",
  garnish = TRUE,
  ...
)

# S3 method for class 'Electroglottogram'
autolayer(object, from_time = NULL, to_time = NULL, color = "black", ...)

# S3 method for class 'LongSound'
autoplot(
  object,
  from_time = 0,
  to_time = 2,
  color = "black",
  garnish = TRUE,
  ...
)

# S3 method for class 'LongSound'
autolayer(object, from_time = 0, to_time = 2, color = "black", ...)

# S3 method for class 'DTW'
autoplot(object, garnish = TRUE, alpha_path = 0.8, ...)

# S3 method for class 'DTW'
autolayer(object, alpha_path = 0.8, ...)

# S3 method for class 'Polygon'
autoplot(
  object,
  garnish = TRUE,
  fill_polygon = FALSE,
  color = "black",
  fill_color = "grey80",
  ...
)

# S3 method for class 'Polygon'
autolayer(object, color = "black", ...)

# S3 method for class 'VocalTract'
autoplot(object, garnish = TRUE, plot_type = c("area", "line"), ...)

# S3 method for class 'VocalTract'
autolayer(object, ...)

# S3 method for class 'LPC'
autoplot(object, frame = 1L, garnish = TRUE, color = "darkred", ...)

# S3 method for class 'LPC'
autolayer(object, frame = 1L, color = "darkred", ...)

# S3 method for class 'KlattGrid'
autoplot(
  object,
  from_time = NULL,
  to_time = NULL,
  formant_type = c("all", "oral", "nasal", "frication", "tracheal", "delta"),
  max_formant = 6L,
  garnish = TRUE,
  ...
)

# S3 method for class 'KlattGrid'
autolayer(
  object,
  from_time = NULL,
  to_time = NULL,
  formant_type = c("oral", "nasal", "frication", "tracheal", "delta"),
  max_formant = 6L,
  ...
)
```

## Arguments

- object:

  TextGrid object

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- color:

  Line color (default: "steelblue")

- ...:

  Additional arguments passed to geom_line

- show_voicing:

  Color by voicing strength (default: FALSE)

- geom:

  For Pitch: type of geometry ("line" or "point")

- max_formant:

  Maximum formant number to display (default: 3).

- colors:

  Colors for each formant track (default: auto).

- from_freq:

  Start frequency in Hz

- to_freq:

  End frequency in Hz

- dynamic_range:

  Dynamic range in dB (default: 70)

- log_freq:

  Use logarithmic frequency scale (default: FALSE)

- ymin:

  For PointProcess: minimum y value for vertical lines (default: 0)

- ymax:

  For PointProcess: maximum y value for vertical lines (default: 1)

- from_quefrency:

  Start quefrency in seconds

- to_quefrency:

  End quefrency in seconds

- mark_peak:

  Mark the cepstral peak (default: TRUE)

- tier:

  Tier number or name to display (default: 1)

- alpha:

  Fill transparency (default: 0.3)

- garnish:

  Whether to add a title and axis labels (default TRUE).

- time_step:

  Sampling interval in seconds, only used when style="line" (default:
  0.005).

- style:

  "speckle" (default, matches Praat's FormantTier_speckle: plots the
  tier's own stored points, unconnected) or "line" (interpolates on a
  time_step grid and connects with a line — not Praat's default view).

- show_candidates:

  Logical. Overlay candidate paths (default: TRUE).

- show_phase:

  Include phase as separate panel (default: FALSE).

- power:

  If TRUE, plot as PowerCepstrum (dB). Default FALSE matches Praat's
  default \`Cepstrum_drawLinear\` (raw signed cepstrum, linear scale).

- quefrency_range:

  Optional \`c(min, max)\` quefrency range to display
  (PowerCepstrogram); NULL shows the full range.

- coefficient_range:

  Range of coefficients to display (e.g. 1:12).

- x_col:

  Column name for x-axis (default: auto-detect).

- y_col:

  Column name for y-axis (default: auto-detect).

- fill_col:

  Column name for fill (default: auto-detect).

- type:

  For PCA: "scree" (variance explained), "scores" (component scores), or
  "both" (combined via patchwork).

- from_track, to_track:

  Track index range to display (FormantModeler).

- alpha_path:

  Alpha for warping path line (default: 0.8).

- fill_polygon:

  Fill the polygon interior (default: FALSE).

- fill_color:

  Fill color for closed shapes (Polygon); distinct from \`fill_col\`,
  which selects a data column to map to a continuous fill scale.

- plot_type:

  Plot style selector (VocalTract).

- frame:

  Time or frame index to extract LPC spectrum at.

- formant_type:

  Type of formant to plot: "oral", "nasal", "frication", "tracheal",
  "delta", or (autoplot.KlattGrid only) "all".

## Value

A ggplot2 object

## Details

The autoplot/autolayer pattern enables flexible plot composition:

- `autoplot(object)` - Creates a complete ggplot

- `autolayer(object)` - Returns a layer to add to existing plots

This allows combining multiple objects:


    autoplot(spectrogram) +
      autolayer(formant, max_formant = 3) +
      autolayer(pitch, color = "blue")

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
p <- ggplot2::autoplot(sound)

pitch <- sound$to_pitch()
p2 <- ggplot2::autoplot(pitch)
```
