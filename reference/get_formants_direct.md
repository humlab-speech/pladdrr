# Get Formant F1-F4 at Time Directly

Get F1, F2, F3, F4 at a single time point in one call.

## Usage

``` r
get_formants_direct(formant, time, unit = c("hertz", "bark"))
```

## Arguments

- formant:

  Formant object or external pointer

- time:

  Time in seconds

- unit:

  Character: "hertz" or "bark"

## Value

Named numeric vector: F1, F2, F3, F4

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
formant <- sound$to_formant_burg()

# Get all 4 formants in one call
f1_f4 <- get_formants_direct(formant, time = 0.25)

# Equivalent R6 calls, one boundary crossing per formant:
f1 <- formant$get_value_at_time(1, 0.25, "hertz")
f2 <- formant$get_value_at_time(2, 0.25, "hertz")
```
