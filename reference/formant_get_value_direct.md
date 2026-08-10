# Get formant value at time directly

Get formant value at time directly

## Usage

``` r
formant_get_value_direct(formant_xptr, formant_number, time, unit = 0L)
```

## Arguments

- formant_xptr:

  External pointer to Formant

- formant_number:

  Formant number (1=F1, 2=F2, etc)

- time:

  Time in seconds

- unit:

  0=Hertz, 1=Bark

## Value

Formant frequency

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
formant <- sound$to_formant_burg()
pladdrr:::formant_get_value_direct(formant$.xptr, 1, 0.15, 0)
#> [1] 187.7834
```
