# Convert Sound to Matrix (Fast Copy)

Copies Sound data into a matrix (samples x channels) via direct pointer
access.

## Usage

``` r
sound_as_matrix_fast(sound, zerocopy = FALSE)

# Deprecated: use sound_as_matrix_fast() instead
```

## Arguments

- sound:

  A Sound object

- zerocopy:

  Ignored (kept for backward compatibility). All paths copy.

## Value

Numeric matrix (samples x channels)

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
mat <- sound_as_matrix_fast(sound)
```
