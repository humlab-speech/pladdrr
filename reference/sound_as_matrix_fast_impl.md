# Get Sound Data as Matrix (Fast Copy)

Copies Sound data into a matrix (samples x channels) via direct pointer
access.

## Usage

``` r
sound_as_matrix_fast_impl(sound_xptr, zerocopy = FALSE)
```

## Arguments

- sound_xptr:

  External pointer to Sound object

- zerocopy:

  Ignored (kept for backward compatibility). All paths copy.

## Value

Numeric matrix with dimensions (n_samples x n_channels)

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 16000)
mat <- pladdrr:::sound_as_matrix_fast_impl(sound$get_xptr())
```
