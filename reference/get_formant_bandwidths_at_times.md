# Batch Query Formant Bandwidths at Multiple Times

Query formant bandwidths at multiple time points in a single function
call.

## Usage

``` r
get_formant_bandwidths_at_times(
  formant,
  times,
  formant_numbers = 1:4,
  unit = "hertz"
)
```

## Arguments

- formant:

  A Formant object

- times:

  Numeric vector of time points (in seconds)

- formant_numbers:

  Integer vector specifying which formants (default \`1:4\`)

- unit:

  Unit for bandwidth values: "hertz" (default) or "bark"

## Value

A list with one element per formant number (e.g., \`B1\`, \`B2\`, ...),
each containing a numeric vector of bandwidths.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate =
 16000)
formant <- sound$to_formant_burg()
times <- seq(0.1, 0.4, length.out = 5)
bandwidths <- get_formant_bandwidths_at_times(formant, times, 1:4)
```
