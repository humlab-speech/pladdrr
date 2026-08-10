# Direct Function Dispatch API

These functions provide direct access to Praat operations without R6
class dispatch overhead — no R6 environment lookup, no named parameter
matching, no result wrapping. Use them in tight loops where you are
comfortable working with external pointers instead of R6 objects.

\*\*Output:\*\* Numerically identical to R6 methods.

## Value

This is a documentation-only overview; see the individual functions
(e.g.
[`to_point_process_direct`](https://humlab-speech.github.io/pladdrr/reference/to_point_process_direct.md),
[`pp_get_mean_period_direct`](https://humlab-speech.github.io/pladdrr/reference/pp_get_mean_period_direct.md))
for their return values.

## When to Use

\- Processing many files in a batch loop - Latency-sensitive analysis
pipelines - Tight loops with many queries - When profiling shows R6
dispatch overhead as a bottleneck

## When NOT to Use

\- Interactive exploration (use R6 for convenience) - Small datasets
(overhead is negligible) - When you need method chaining

## Examples

``` r
# See individual functions, e.g. ?pp_get_mean_period_direct
```
