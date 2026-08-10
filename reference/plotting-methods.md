# S3 Plot Methods for pladdrr Objects

Convenient S3 plot methods for Praat objects. These are ggplot2-based
wrappers that provide sensible defaults while allowing full
customization. All methods return ggplot2 objects that can be further
customized.

## Value

This is a documentation-only overview; see the individual methods (e.g.
[`plot.Sound`](https://humlab-speech.github.io/pladdrr/reference/plot.Sound.md),
[`plot.Pitch`](https://humlab-speech.github.io/pladdrr/reference/plot.Pitch.md))
for their return values.

## Details

These methods follow R's S3 generic dispatch system, allowing you to use
the standard \`plot()\` function with pladdrr objects. Each method
converts the Praat object to a data frame and creates an appropriate
ggplot2 visualization.

All plot methods support: - Time range filtering via \`from_time\` and
\`to_time\` parameters - Axis labels and titles via \`garnish\`
parameter - ggplot2 object return for further customization

## Examples

``` r
# See individual methods, e.g. ?plot.Sound
```
