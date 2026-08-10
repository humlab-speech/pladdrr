# Extract Voiced Segments with AVQI Filtering (Tier 4 Ultra)

Complete AVQI voiced segment extraction pipeline in a single C++ call.
Supports both AVQI v2.03 (simple intensity-based) and v3.01 (with ZCR
filtering). Performs: Sound -\> TextGrid (silence) -\> Extract sounding
-\> Concatenate -\> \[v3.01: Window power/ZCR filtering\] -\> Final
concatenation, in a single C++ call instead of a multi-step R
implementation.

## Usage

``` r
extract_voiced_segments_ultra(
  sound,
  version = "v3.01",
  min_pitch = 50,
  silence_threshold_db = -25,
  min_silent_duration = 0.1,
  min_sounding_duration = 0.1,
  power_threshold_factor = 0.3,
  max_zcr = 3000,
  window_width = 0.03
)
```

## Arguments

- sound:

  Sound object or external pointer

- version:

  AVQI version: "v2.03" (simple) or "v3.01" (ZCR filtering, default)

- min_pitch:

  Minimum pitch for silence detection in Hz (default 50)

- silence_threshold_db:

  Silence threshold in dB (default -25)

- min_silent_duration:

  Minimum silent interval duration in seconds (default 0.1)

- min_sounding_duration:

  Minimum sounding interval duration in seconds (default 0.1)

- power_threshold_factor:

  Power threshold as fraction of global power (default 0.3)

- max_zcr:

  Maximum zero-crossing rate for voiced segments (default 3000)

- window_width:

  Window width for v3.01 filtering in seconds (default 0.03)

## Value

Sound object containing only voiced segments (concatenated)

## Details

\*\*TIER 4 ULTRA API\*\*

This function implements the exact AVQI voiced extraction algorithm in a
single C++ call. It replaces the R loops and multiple boundary crossings
of the standard multi-step approach.

\*\*Algorithm (AVQI v3.01):\*\* 1. Detect silences using intensity-based
TextGrid creation 2. Extract all "sounding" intervals 3. Concatenate
sounding intervals -\> "loud_sound" 4. Slide 30ms windows through
loud_sound 5. Filter windows by: power \> 30 6. Concatenate passing
windows -\> final voiced sound

\*\*Algorithm (AVQI v2.03):\*\* Steps 1-3 only (no window filtering)

\*\*Version Differences:\*\* - v2.03: Simpler, keeps most voiced content
(~37s from 37s input) - v3.01: Aggressive ZCR filtering, removes
fricatives (~25-30s from 37s input)

## Algorithm choice

No pitch algorithm is used here — voiced/silence segmentation is
Intensity-threshold based (\`Sound_to_Intensity()\` +
\`silence_threshold_db\` relative to the maximum), not derived from a
\`Pitch\` object. \`min_pitch\` only controls the Intensity analysis
window length (via \`Sound_to_Intensity\`'s own floor parameter), not a
pitch-detection algorithm choice. See the Tier 4 Ultra algorithm table
in \`inst/agents/AGENT_GUIDE.md\`.

## References

\- AVQI v3.01: Maryn et al. (2017) - with ZCR filtering - AVQI v2.03:
Original Praat script - intensity-based only

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)

# AVQI v3.01 (default, with ZCR filtering)
voiced_v3 <- extract_voiced_segments_ultra(sound, version = "v3.01")

# AVQI v2.03 (simple intensity-based)
voiced_v2 <- extract_voiced_segments_ultra(sound, version = "v2.03")

voiced_v3$get_total_duration()
#> [1] 0.001
voiced_v2$get_total_duration()
#> [1] 0.001
```
