# Create TextGrid

Create a new empty TextGrid with specified tiers

## Usage

``` r
textgrid_create(tmin, tmax, tier_names = "", point_tiers = "")
```

## Arguments

- tmin:

  Start time in seconds

- tmax:

  End time in seconds

- tier_names:

  Space-separated tier names (e.g., "phones words syllables")

- point_tiers:

  Space-separated names of tiers that should be PointTiers (default: all
  are IntervalTiers)

## Value

A `TextGrid` object.

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`Pitch`](https://humlab-speech.github.io/pladdrr/reference/Pitch.md),
[`Formant`](https://humlab-speech.github.io/pladdrr/reference/Formant.md),
[`PointProcess`](https://humlab-speech.github.io/pladdrr/reference/PointProcess.md)

## Examples

``` r
# Create TextGrid with 3 interval tiers
tg <- textgrid_create(0, 10, "phones words syllables")

# Create TextGrid with mixed tier types
tg2 <- textgrid_create(0, 10, "phones tones", "tones")  # tones is PointTier
```
