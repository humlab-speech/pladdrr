# Plot TextGrid with Sound Waveform

Creates a combined visualization showing a waveform with TextGrid
annotation tiers overlaid. This replicates Praat's TextGrid_Sound_draw()
function.

## Usage

``` r
plot_textgrid_sound(
  textgrid,
  sound,
  tier = NULL,
  from_time = NULL,
  to_time = NULL,
  waveform_color = "steelblue",
  tier_colors = NULL,
  title = NULL,
  ...
)
```

## Arguments

- textgrid:

  TextGrid object

- sound:

  Sound object

- tier:

  Integer or character. Tier number or name to display (default: all)

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- waveform_color:

  Character. Waveform color (default: "steelblue")

- tier_colors:

  Character vector. Colors for each tier (default: auto)

- title:

  Character. Plot title (default: NULL)

- ...:

  Additional arguments passed to plot methods

## Value

A combined ggplot object (requires patchwork or gridExtra)

## Examples

``` r
if (requireNamespace("patchwork", quietly = TRUE) ||
    requireNamespace("gridExtra", quietly = TRUE)) {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0)
  textgrid <- TextGrid$create(0, 1, "words")
  textgrid$set_interval_text("words", 1, "tone")

  # Basic combined plot
  plot_textgrid_sound(textgrid, sound)

  # Single tier with time range
  plot_textgrid_sound(textgrid, sound, tier = 1,
                     from_time = 0.2, to_time = 0.8)
}

```
