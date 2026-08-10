# Batch Query Formant Frequencies at Multiple Times

Query formant frequencies (F1, F2, F3, F4, etc.) at multiple time points
in a single function call, instead of calling \`get_value_at_time()\`
repeatedly in a loop.

## Usage

``` r
get_formants_at_times(formant, times, formant_numbers = 1:4, unit = "hertz")
```

## Arguments

- formant:

  A Formant object

- times:

  Numeric vector of time points (in seconds)

- formant_numbers:

  Integer vector specifying which formants to extract (e.g., \`1:4\` for
  F1-F4). Default is \`1:4\`.

- unit:

  Unit for formant values: "hertz" (default) or "bark"

## Value

A list with one element per formant number (e.g., \`F1\`, \`F2\`, ...),
each containing a numeric vector of formant frequencies at the specified
times.

## Performance

This function reduces R\<-\>C++ boundary crossings from \`4n\` calls
(for 4 formants at n times) to just 1 call.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
formant <- sound$to_formant_burg()

# Extract F1-F4 at 5 time points
times <- seq(0.1, 0.4, length.out = 5)
result <- get_formants_at_times(formant, times, formant_numbers = 1:4)

# Access individual formants
f1_vals <- result$F1
f2_vals <- result$F2
```
