# Run an expression, reclassifying tagged pladdrr C++ errors/warnings.

Any error or warning whose message matches the
`"[pladdrr_<class>:<routine>:<param>] <message>"` tag is rethrown as a
classed R condition. Untagged conditions pass through unchanged.

## Usage

``` r
with_pladdrr_errors(expr)
```

## Arguments

- expr:

  expression to evaluate

## Value

value of `expr`, possibly with a `pladdrr_data_loss` attribute.

## Details

Class hierarchy:

- `pladdrr_input_error` — invalid argument or precondition failed

- `pladdrr_praat_error` — Praat-internal failure

- `pladdrr_data_loss` — output incomplete vs requested range

All inherit from `pladdrr_error` so a single
`tryCatch(pladdrr_error = ...)` catches them all.

Data-loss warnings additionally attach `attr(., "pladdrr_data_loss")` to
the result, listing every routine that reported missing values during
the call.

The reaction to data loss is controlled by
`options(pladdrr.data_loss = )`: `"warn"` (default) raises a classed
warning per incident, `"error"` stops at the first incident, `"silent"`
only records the attribute.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
formant <- sound$to_formant_burg()
tryCatch(
  with_pladdrr_errors(
    pladdrr:::formant_get_multiple_formants_at_times(
      formant$.xptr, times = c(0.1, 0.2), formant_numbers = 0L
    )
  ),
  pladdrr_input_error = function(e) message("bad input: ", conditionMessage(e))
)
#> bad input: formant index must be >= 1 (F1, F2, ...)
```
