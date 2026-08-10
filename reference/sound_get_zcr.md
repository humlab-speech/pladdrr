# Calculate Zero Crossing Rate for Sound

Calculates Zero Crossing Rate (ZCR) per frame using Praat's built-in
zero crossing detection. ZCR is the rate at which the signal changes
sign, useful for distinguishing voiced (low ZCR) from unvoiced (high
ZCR) speech.

## Usage

``` r
sound_get_zcr(
  sound,
  window_duration = 0.03,
  hop_duration = 0.01,
  channel = 1L,
  avqi_compatible = TRUE
)
```

## Arguments

- sound:

  Sound object

- window_duration:

  Numeric. Window duration in seconds (default: 0.03)

- hop_duration:

  Numeric. Hop between windows in seconds (default: 0.01)

- channel:

  Integer. Channel to analyze for stereo (default: 1)

- avqi_compatible:

  Logical. Use AVQI-compatible analysis window (0.0025-0.0275s within
  each frame) instead of full frame (default: TRUE)

## Value

Named list with: - \`times\`: Numeric vector of frame center times -
\`zcr\`: Numeric vector of zero crossing rates (crossings per second) -
\`window_duration\`: Window duration used - \`hop_duration\`: Hop
duration used

## Details

Uses Praat's \`to_point_process_zeros()\` for accurate zero crossing
detection with interpolation.

When \`avqi_compatible = TRUE\` (default), uses AVQI203.praat's
checkZeros procedure: analyzes zeros within 0.0025-0.0275s of each frame
(25ms analysis window within 30ms frame). This matches Praat's AVQI
implementation.

Typical ZCR values: - Voiced speech: 500-2000 crossings/second -
Unvoiced speech: 3000-6000 crossings/second - Silence: variable, depends
on noise

For AVQI, segments with ZCR \> 3000 Hz are typically rejected as
unvoiced.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1.0)
zcr_data <- sound_get_zcr(sound, window_duration = 0.03)
str(zcr_data)
#> List of 4
#>  $ times          : num [1:98] 0.015 0.025 0.035 0.045 0.055 0.065 0.075 0.085 0.095 0.105 ...
#>  $ zcr            : num [1:98] 343 343 343 343 343 ...
#>  $ window_duration: num 0.03
#>  $ hop_duration   : num 0.01
```
