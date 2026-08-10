# Extract Formant Statistics for All TextGrid Intervals (Batch, SIMD)

Computes formant statistics for all intervals using SIMD.

## Usage

``` r
textgrid_interval_formant_batch(
  textgrid_xptr,
  formant_xptr,
  tier_number,
  formant_number = 1L
)
```

## Arguments

- textgrid_xptr:

  External pointer to TextGrid

- formant_xptr:

  External pointer to Formant object

- tier_number:

  Tier number (1-based)

- formant_number:

  Formant number to extract (1 = F1, 2 = F2, etc.)

## Value

Data frame with interval info and formant statistics

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 1.0)
formant <- sound$to_formant_burg()
tg <- textgrid_create(0, 1, "phones")
tg$insert_boundary("phones", 0.5)
tg$set_interval_text("phones", 1, "a")
tg$set_interval_text("phones", 2, "b")

stats <- textgrid_interval_formant_batch(tg$.xptr, formant$.xptr,
  tier_number = 1, formant_number = 1)
```
