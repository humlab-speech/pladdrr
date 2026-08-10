# Get F1-F4 at single time point

Get F1-F4 at single time point

## Usage

``` r
formant_get_f1_f4_direct(formant_xptr, time, unit = 0L)
```

## Arguments

- formant_xptr:

  External pointer to Formant

- time:

  Time in seconds

- unit:

  Unit code (0=Hertz, 1=Bark)

## Value

NumericVector with F1, F2, F3, F4

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
formant <- sound$to_formant_burg()
pladdrr:::formant_get_f1_f4_direct(formant$.xptr, 0.15, 0)
#>        F1        F2        F3        F4 
#>  187.7834  225.4681  263.2265 4777.8419 
```
