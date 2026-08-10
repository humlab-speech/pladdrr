# Create Spectrum from Sound Directly (returns XPtr)

Create Spectrum from Sound Directly (returns XPtr)

## Usage

``` r
to_spectrum_direct(sound, fast = TRUE)
```

## Arguments

- sound:

  Sound object or external pointer

- fast:

  Logical. Use fast algorithm (default: TRUE)

## Value

External pointer to Spectrum

## Examples

``` r
sound <- Sound$create_tone(frequency = 200, duration = 0.5)
spec_ptr <- to_spectrum_direct(sound)
spec <- Spectrum(.xptr = spec_ptr)
spec$get_number_of_bins()
#> [1] 16385
```
