# Convert LPC coefficients to formants

Convert LPC coefficients to formants

## Usage

``` r
.lpc_to_formants(frame, sr, lpc_order, n_formants, max_formant)
```

## Arguments

- frame:

  Numeric vector, one windowed analysis frame

- sr:

  Sampling rate in Hz

- lpc_order:

  LPC order (number of coefficients)

- n_formants:

  Number of formants to return

- max_formant:

  Maximum formant frequency (Hz)

## Value

A data.frame with columns `frequency` and `bandwidth`, one row per
formant, padded with `NA` if fewer roots were found than `n_formants`

## Examples

``` r
set.seed(1)
frame <- sin(2 * pi * 500 * seq(0, 0.025, length.out = 400)) + rnorm(400, sd = 0.01)
pladdrr:::.lpc_to_formants(frame, sr = 16000, lpc_order = 12,
                            n_formants = 4, max_formant = 5500)
#>   frequency bandwidth
#> 1        NA        NA
#> 2        NA        NA
#> 3        NA        NA
#> 4        NA        NA
```
