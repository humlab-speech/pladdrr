# Batch query MULTIPLE formant bandwidths at multiple time points

Batch query MULTIPLE formant bandwidths at multiple time points

## Usage

``` r
formant_get_multiple_bandwidths_at_times(
  formant_xptr,
  times,
  formant_numbers,
  unit = 0L
)
```

## Arguments

- formant_xptr:

  External pointer to Formant object

- times:

  Numeric vector of time points

- formant_numbers:

  Integer vector of formant numbers

- unit:

  Integer code for unit

## Value

List with bandwidth vectors for each formant

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
formant <- sound$to_formant_burg()
pladdrr:::formant_get_multiple_bandwidths_at_times(
  formant$.xptr, c(0.1, 0.15, 0.2), c(1L, 2L), 0L
)
#> $B1
#> [1] 5.837749 5.757599 4.643894
#> 
#> $B2
#> [1] 5.454707 5.377291 4.311015
#> 
```
