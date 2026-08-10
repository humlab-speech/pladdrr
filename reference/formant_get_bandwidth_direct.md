# Get formant bandwidth at time directly

Get formant bandwidth at time directly

## Usage

``` r
formant_get_bandwidth_direct(formant_xptr, formant_number, time, unit = 0L)
```

## Arguments

- formant_xptr:

  External pointer to Formant

- formant_number:

  Formant number

- time:

  Time in seconds

- unit:

  Unit code

## Value

Bandwidth

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
formant <- sound$to_formant_burg()
pladdrr:::formant_get_bandwidth_direct(formant$.xptr, 1, 0.15, 0)
#> [1] 5.757599
```
