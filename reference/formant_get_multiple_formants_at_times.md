# Batch query MULTIPLE formant frequencies at multiple time points

Batch query MULTIPLE formant frequencies at multiple time points

## Usage

``` r
formant_get_multiple_formants_at_times(
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

  Integer vector of formant numbers (1=F1, 2=F2, etc)

- unit:

  Integer code for unit (0=HERTZ, 1=BARK)

## Value

List with one element per formant number, each containing a numeric
vector

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
formant <- sound$to_formant_burg()
pladdrr:::formant_get_multiple_formants_at_times(
  formant$.xptr, c(0.1, 0.15, 0.2), c(1L, 2L), 0L
)
#> $F1
#> [1] 187.7926 187.7834 187.6655
#> 
#> $F2
#> [1] 225.4686 225.4681 225.4587
#> 
```
