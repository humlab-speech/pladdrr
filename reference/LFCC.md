# Praat LFCC Object

Linear Frequency Cepstral Coefficients for speaker recognition. Uses
shared dispatch table for minimal memory per object.

## Value

An `LFCC` object with methods for linear-frequency cepstral coefficient
analysis.

## Details

LFCCs are similar to MFCCs but use a linear frequency scale instead of
the mel scale. They are derived from LPC analysis and are useful for
speaker recognition tasks.

## See also

[`Sound`](https://humlab-speech.github.io/pladdrr/reference/Sound.md),
[`LPC`](https://humlab-speech.github.io/pladdrr/reference/LPC.md)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3)
lpc <- sound$to_lpc_burg(prediction_order = 16)
lfcc <- lpc$to_lfcc(num_coefficients = 12)
coefs <- lfcc$get_all_coefficients()
lpc2 <- lfcc$to_lpc(num_coefficients = 16)
```
