# Get formant mean directly

Get formant mean directly

## Usage

``` r
formant_get_mean_direct(
  formant_xptr,
  formant_number,
  from_time = 0,
  to_time = 0,
  unit = 0L
)
```

## Arguments

- formant_xptr:

  External pointer to Formant

- formant_number:

  Formant number

- from_time:

  Start time

- to_time:

  End time

- unit:

  Unit code

## Value

Mean formant frequency

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
formant <- sound$to_formant_burg()
pladdrr:::formant_get_mean_direct(formant$.xptr, 1)
#> [1] 187.7632
```
