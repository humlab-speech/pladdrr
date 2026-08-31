# Fast Sound Sample Access

Copies Sound sample data via direct pointer access into Praat's
contiguous sample array, rather than going through the per-sample
accessor in a loop.

## Usage

``` r
sound_values_fast(sound_xptr, channel = 1L)
```

## Arguments

- sound_xptr:

  External pointer to Sound object

- channel:

  Channel number (1-based, default 1)

## Value

Numeric vector (independent copy of sample data). Has class
\`c("fast_vector", "numeric")\` and a \`readonly\` attribute for
backward compatibility with code that checked these.

## Details

The returned vector is an independent R copy — safe to modify, store, or
use after the Sound object is garbage collected.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5)

samples <- sound_values_fast(sound$.xptr, channel = 1)
rms <- sqrt(mean(samples^2))

# Regular copy — equivalent output
samples2 <- sound$get_values(channel = 1)
```
