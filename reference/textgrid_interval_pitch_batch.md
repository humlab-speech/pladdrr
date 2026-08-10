# Extract Pitch Statistics for All TextGrid Intervals (Batch, SIMD)

Computes pitch statistics (mean, stdev, min, max) for all intervals in a
TextGrid tier using SIMD-accelerated batch processing.

## Usage

``` r
textgrid_interval_pitch_batch(
  textgrid_xptr,
  pitch_xptr,
  tier_number,
  unit = "HERTZ"
)
```

## Arguments

- textgrid_xptr:

  External pointer to TextGrid

- pitch_xptr:

  External pointer to Pitch object

- tier_number:

  Tier number (1-based)

- unit:

  Pitch unit: "HERTZ" or "SEMITONES"

## Value

Data frame with interval index, label, start, end, duration, pitch_mean,
pitch_stdev, pitch_min, pitch_max

## Details

This function combines: 1. SIMD duration calculation for all intervals
2. SIMD statistics calculation for pitch values in each interval

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
pitch <- sound$to_pitch()
tg <- textgrid_create(0, 1, "phones")
tg$insert_boundary("phones", 0.5)
tg$set_interval_text("phones", 1, "a")
tg$set_interval_text("phones", 2, "b")

stats <- textgrid_interval_pitch_batch(tg$.xptr, pitch$.xptr, tier_number = 1, unit = "HERTZ")
```
