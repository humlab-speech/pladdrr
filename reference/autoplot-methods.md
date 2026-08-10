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

  Maximum formant number to display (default: 3)

- colors:

  Colors for each formant track

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
