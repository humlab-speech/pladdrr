# Extract TextGrid Intervals Using Custom XPtr Predicate

Filter intervals using a user-compiled C++ predicate function. The
predicate executes entirely in C++ without any R boundary crossings.

## Usage

``` r
textgrid_filter_xptr(
  textgrid_xptr,
  tier_number,
  predicate_xptr,
  sound_xptr = NULL,
  extract_sounds = FALSE
)
```

## Arguments

- textgrid_xptr:

  External pointer to TextGrid object

- tier_number:

  Tier number (1-based)

- predicate_xptr:

  External pointer to compiled predicate function created with
  \`RcppXPtrUtils::cppXPtr()\`. Signature must be: \`bool(const char\*
  label, double start, double end)\`

- sound_xptr:

  Optional external pointer to Sound for extraction

- extract_sounds:

  If TRUE and sound_xptr provided, extract Sound parts

## Value

List with components: - indices: Integer vector of matching interval
indices - labels: Character vector of matching labels - start_times:
Numeric vector of start times - end_times: Numeric vector of end times -
sounds: List of Sound xptrs (if extract_sounds = TRUE)

## Details

\*\*Compiling a custom predicate (requires RcppXPtrUtils):\*\*

“\`r \# Example: Filter intervals with duration \> 0.1s and label
starting with 'V' my_pred \<- RcppXPtrUtils::cppXPtr( "bool pred(cstr
label, double start, double end) { double dur = end - start; return dur
\> 0.1 && label\[0\] == 'V'; }", includes = "typedef const char\* cstr;"
)

result \<- textgrid_filter_xptr( textgrid\$.xptr, tier = 1,
predicate_xptr = my_pred ) “\`

## See also

\[textgrid_extract_intervals_batch()\] for simpler string matching

## Examples

``` r
# \donttest{
if (requireNamespace("RcppXPtrUtils", quietly = TRUE)) {
  tg <- textgrid_create(0, 1, "phones")
  tg$insert_boundary("phones", 0.4)
  tg$insert_boundary("phones", 0.7)
  tg$set_interval_text("phones", 1, "sil")
  tg$set_interval_text("phones", 2, "V")
  tg$set_interval_text("phones", 3, "sil")

  my_pred <- RcppXPtrUtils::cppXPtr(
    "bool pred(cstr label, double start, double end) {
       double dur = end - start;
       return dur > 0.1 && label[0] == 'V';
     }",
    includes = "typedef const char* cstr;"
  )

  result <- textgrid_filter_xptr(tg$.xptr, 1, my_pred)
}
# }
```
