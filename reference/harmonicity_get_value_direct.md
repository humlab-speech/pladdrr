# Get harmonicity value at time directly

Get harmonicity value at time directly

## Usage

``` r
harmonicity_get_value_direct(harmonicity_xptr, time, interpolation = 2L)
```

## Arguments

- harmonicity_xptr:

  External pointer to Harmonicity

- time:

  Time in seconds

- interpolation:

  Interpolation method

## Value

HNR in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
harmonicity <- sound$to_harmonicity_cc()
pladdrr:::harmonicity_get_value_direct(harmonicity$.xptr, 0.25)
#> [1] 77.90722
```
