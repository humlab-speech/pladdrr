# Get Single Formant Value Directly

Get Single Formant Value Directly

## Usage

``` r
get_formant_value_direct(formant, formant_number, time, unit = "hertz")
```

## Arguments

- formant:

  Formant object or external pointer

- formant_number:

  Formant number (1=F1, etc)

- time:

  Time in seconds

- unit:

  Unit string

## Value

Formant frequency

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
formant_ptr <- to_formant_direct(sound)
get_formant_value_direct(formant_ptr, 1, 0.25)
#> [1] 187.7938
```
