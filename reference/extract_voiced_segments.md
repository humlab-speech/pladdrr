# Extract Voiced Segments from Speech

Voice activity detection combining intensity-based detection with
optional Zero Crossing Rate (ZCR) filtering. Returns concatenated voiced
segments as a Sound object. This matches the AVQI v2.03/v3.01 voiced
extraction.

## Usage

``` r
extract_voiced_segments(
  sound,
  minimum_pitch = 50,
  time_step = 0.003,
  silence_threshold = -25,
  min_silent_interval = 0.1,
  min_sounding_interval = 0.1,
  zcr_threshold = 3000,
  zcr_window = 0.03,
  use_zcr = TRUE,
  return_textgrid = FALSE
)
```

## Arguments

- sound:

  Sound object (continuous speech)

- minimum_pitch:

  Numeric. Minimum pitch for intensity detection (Hz, default: 50)

- time_step:

  Numeric. Time step for intensity analysis (s, default: 0.003)

- silence_threshold:

  Numeric. Silence threshold in dB below max (default: -25)

- min_silent_interval:

  Numeric. Minimum silence duration (s, default: 0.1)

- min_sounding_interval:

  Numeric. Minimum voiced duration (s, default: 0.1)

- zcr_threshold:

  Numeric. Maximum ZCR for voiced speech (Hz, default: 3000)

- zcr_window:

  Numeric. ZCR analysis window duration (s, default: 0.03)

- use_zcr:

  Logical. Apply ZCR filtering (default: TRUE)

- return_textgrid:

  Logical. Also return VAD TextGrid (default: FALSE)

## Value

If \`return_textgrid = FALSE\`: Sound object with concatenated voiced
segments. If \`return_textgrid = TRUE\`: List with \`sound\` and
\`textgrid\` elements.

## Details

The detection pipeline: 1. Intensity-based: Find segments above silence
threshold 2. ZCR filtering (if \`use_zcr = TRUE\`): Reject high-ZCR
segments (unvoiced)

AVQI uses both intensity AND ZCR filtering. Set \`use_zcr = FALSE\` for
intensity-only detection.

## Examples

``` r
# \donttest{
sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate =
 16000)

# Full AVQI-compatible extraction (default)
voiced <- extract_voiced_segments(sound)

# Intensity-only (no ZCR filtering)
voiced_no_zcr <- extract_voiced_segments(sound, use_zcr = FALSE)

# With TextGrid output
result <- extract_voiced_segments(sound, return_textgrid = TRUE)
cat("Duration:", result$sound$get_duration(), "s\n")
#> Duration: 1 s
# }
```
