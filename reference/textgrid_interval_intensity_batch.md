# Extract Intensity Statistics for All TextGrid Intervals (Batch, SIMD)

Extract Intensity Statistics for All TextGrid Intervals (Batch, SIMD)

## Usage

``` r
textgrid_interval_intensity_batch(textgrid_xptr, intensity_xptr, tier_number)
```

## Arguments

- textgrid_xptr:

  External pointer to TextGrid

- intensity_xptr:

  External pointer to Intensity object

- tier_number:

  Tier number (1-based)

## Value

Data frame with interval info and intensity statistics

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
intensity <- sound$to_intensity()
tg <- textgrid_create(0, 1, "phones")
tg$insert_boundary("phones", 0.5)
tg$set_interval_text("phones", 1, "a")
tg$set_interval_text("phones", 2, "b")

stats <- textgrid_interval_intensity_batch(tg$.xptr, intensity$.xptr, tier_number = 1)
```
