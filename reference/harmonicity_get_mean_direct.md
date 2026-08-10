# Get harmonicity mean directly

Get harmonicity mean directly

## Usage

``` r
harmonicity_get_mean_direct(harmonicity_xptr, from_time = 0, to_time = 0)
```

## Arguments

- harmonicity_xptr:

  External pointer to Harmonicity

- from_time:

  Start time

- to_time:

  End time

## Value

Mean HNR in dB

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
harmonicity <- sound$to_harmonicity_cc()
pladdrr:::harmonicity_get_mean_direct(harmonicity$.xptr)
#> [1] 77.90722
```
