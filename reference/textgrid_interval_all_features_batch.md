# Extract All Acoustic Features for TextGrid Intervals (Batch, SIMD)

Comprehensive batch extraction of pitch, formant F1/F2, and intensity
statistics for all intervals in a single call, as an alternative to
calling \`textgrid_interval_pitch_batch()\`,
\`textgrid_interval_formant_batch()\`, and
\`textgrid_interval_intensity_batch()\` separately.

## Usage

``` r
textgrid_interval_all_features_batch(
  textgrid_xptr,
  pitch_xptr = NULL,
  formant_xptr = NULL,
  intensity_xptr = NULL,
  tier_number = 1L
)
```

## Arguments

- textgrid_xptr:

  External pointer to TextGrid

- pitch_xptr:

  External pointer to Pitch (optional)

- formant_xptr:

  External pointer to Formant (optional)

- intensity_xptr:

  External pointer to Intensity (optional)

- tier_number:

  Tier number (1-based)

## Value

Data frame with all available features per interval

## Details

Duration calculation and statistics aggregation use SIMD where
applicable.

## Examples

``` r
sound <- Sound$create_tone(frequency = 180, duration = 1.0)
pitch <- sound$to_pitch()
formant <- sound$to_formant_burg()
intensity <- sound$to_intensity()
tg <- textgrid_create(0, 1, "phones")
tg$insert_boundary("phones", 0.5)
tg$set_interval_text("phones", 1, "a")
tg$set_interval_text("phones", 2, "b")

stats <- textgrid_interval_all_features_batch(
  tg$.xptr, pitch$.xptr, formant$.xptr, intensity$.xptr, tier_number = 1
)
```
