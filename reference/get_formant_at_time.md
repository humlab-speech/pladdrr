# Get formant frequency at a specific time (DEPRECATED)

\*\*DEPRECATED:\*\* Use the R6 interface instead:
\`formant\$get_value_at_time()\`

## Usage

``` r
get_formant_at_time(formant, formant_number, time, interpolate = FALSE)
```

## Arguments

- formant:

  A legacy `praat_formant`-shaped list: a plain list with a `values`
  element (a data.frame with columns `time`, `formant_number`,
  `frequency`, `bandwidth`) and a `class` attribute of
  `"praat_formant"`.
  [`extract_formants()`](https://humlab-speech.github.io/pladdrr/reference/extract_formants.md)
  no longer produces this (it now returns an R6 `Formant` object instead
  — see its
  [`extract_formants`](https://humlab-speech.github.io/pladdrr/reference/extract_formants.md)
  documentation); build one by hand for this legacy function, or use
  `formant$get_value_at_time()` on an R6 `Formant` object directly
  instead of this deprecated wrapper.

- formant_number:

  Which formant (1 = F1, 2 = F2, etc.)

- time:

  Time in seconds

- interpolate:

  Logical; if TRUE, interpolate between frames

## Value

Formant frequency in Hz, or NA if undefined

## Examples

``` r
# A praat_formant-shaped list (see the @param formant description
# above); built directly here for a self-contained example.
formant <- structure(
  list(
    values = data.frame(
      time = c(0.1, 0.1, 0.2, 0.2),
      formant_number = c(1, 2, 1, 2),
      frequency = c(500, 1500, 520, 1480),
      bandwidth = c(80, 120, 85, 110)
    ),
    n_frames = 2,
    n_formants = 2
  ),
  class = "praat_formant"
)
get_formant_at_time(formant, formant_number = 1, time = 0.15)
#> Warning: get_formant_at_time() is deprecated and will be removed in v5.0.0. Use the R6 interface: formant$get_value_at_time(formant_number, time)
#> [1] 500
```
