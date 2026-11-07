# Run an expression, reclassifying tagged pladdrr C++ errors and warnings

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

- `pladdrr_data_loss` — output incomplete vs requested range, or input
  shorter than its own header (a WAV read shorter than the length its
  `data` chunk declares)

- `pladdrr_decoder_fallback` — the native reader refused the file and
  the `av` fallback decoded it instead

The error classes inherit from `pladdrr_error` and the warning classes
from `pladdrr_warning`, so `tryCatch(pladdrr_error = ...)` catches the
failures; `pladdrr_data_loss` as a warning and
`pladdrr_decoder_fallback` are caught as warnings.

Only conditions carrying the C++ tag above are reclassified here. The
ones pladdrr raises at R level are already classed and pass through
unchanged: `pladdrr_data_loss` from `.warn_data_loss()` (out-of-range
extraction, and a file read shorter than its own header) and
`pladdrr_decoder_fallback` from the `av` fallback in `Sound(path = )`.
Those two need no `with_pladdrr_errors()`; they carry `$routine` and
`$message` on the condition, and no attribute on the value they
interrupted.

Data loss reported by a tagged C++ routine additionally attaches
`attr(., "pladdrr_data_loss")` to the value `with_pladdrr_errors()`
returns, listing every routine that reported missing values during the
call. Values that take no attributes (an external pointer, an R6 object)
get none.

The reaction to data loss is controlled by
`options(pladdrr.data_loss = )`: `"warn"` (default) raises a classed
warning per incident, `"error"` stops at the first incident, `"silent"`
only records the attribute. It does not govern
`pladdrr_decoder_fallback`: a decode that succeeded lost nothing.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate =
 16000)
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
