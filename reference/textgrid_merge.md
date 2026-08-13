# Merge Multiple TextGrid Objects

Batch merging using Praat's O(n) algorithm instead of O(n²) manual tier
copying. Manual merge requires save/reload + insert_boundary for each
interval (each insert shifts all later intervals). Batch merge is
single-pass.

## Usage

``` r
textgrid_merge(textgrids, equalize_domains = FALSE)
```

## Arguments

- textgrids:

  List of TextGrid objects (external pointers or R6 objects with .xptr)

- equalize_domains:

  If TRUE, all tiers extended to same domain with empty intervals at
  edges if needed (default: FALSE)

## Value

TextGrid object (external pointer)

## Details

Manual merge requires save/reload plus an O(n²) sequence of
\`insert_boundary\` calls (each insert shifts all later intervals);
batch merge does a single O(n) pass with proper interval handling.

\*\*Domain handling:\*\* - If \`equalize_domains = FALSE\` (default): \*
New domain runs from min(xmin) to max(xmax) of all input TextGrids \*
Tiers retain their original domains

\- If \`equalize_domains = TRUE\`: \* All tiers extended to the new
domain \* Empty intervals added at edges if needed

\*\*Use cases:\*\* - VUV analysis: Merging original TextGrid with VUV
tier - Multi-annotator: Combining annotations from different
annotators - Workflow: Adding automatic tiers to manual annotations

## See also

[`TextGrid`](https://humlab-speech.github.io/pladdrr/reference/TextGrid.md)
for TextGrid object creation

Other batch-ops:
[`sound_load_window()`](https://humlab-speech.github.io/pladdrr/reference/sound_load_window.md)

## Examples

``` r
# Create test TextGrids
tg1 <- textgrid_create(0, 1, "words")
tg1$insert_boundary(1, 0.5)
tg1$set_interval_text(1, 1, "hello")
tg1$set_interval_text(1, 2, "world")

tg2 <- textgrid_create(0, 1, "events", "events")
tg2$insert_point(1, 0.25, "click")

# Batch merge
merged <- textgrid_merge(list(tg1, tg2))
# Result has 2 tiers: "words" (interval) + "events" (point)

# With domain equalization
merged_eq <- textgrid_merge(list(tg1, tg2), equalize_domains = TRUE)
```
