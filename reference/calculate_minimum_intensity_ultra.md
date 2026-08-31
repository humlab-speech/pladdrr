# Calculate Minimum Intensity in Voiced Regions (Tier 4 Ultra)

Complete intensity pipeline in C++: Sound -\> Pitch -\> PointProcess -\>
TextGrid (VUV) -\> Intensity -\> Minimum in voiced regions, in one call
instead of the equivalent Tier 2/3 workflow.

This is a \*\*Tier 4 "Ultra"\*\* function for batch DSI (Dysphonia
Severity Index) calculations where minimum intensity is the IM
(Intensity Minimum) component.

## Usage

``` r
calculate_minimum_intensity_ultra(
  sound,
  min_pitch = 75,
  max_pitch = 600,
  time_step = 0,
  subtract_mean = TRUE
)
```

## Arguments

- sound:

  A Sound object

- min_pitch:

  Pitch floor in Hz (default: 75)

- max_pitch:

  Pitch ceiling in Hz (default: 600)

- time_step:

  Time step for analysis (0 = auto)

- subtract_mean:

  Whether to subtract mean for intensity calculation (default: TRUE)

## Value

Minimum intensity in dB (in voiced regions only). Returns \`NA\` if no
voiced regions are detected.

## API Tier

This is a \*\*Tier 4 "Ultra"\*\* function. The entire workflow (pitch
extraction, PointProcess creation, VUV segmentation, intensity
calculation, and minimum finding in voiced regions) happens in C++ with
no intermediate R objects.

## Algorithm choice

Pitch is always extracted with \`Sound_to_Pitch_rawCc()\`,
\`veryAccurate = FALSE\`, \`silenceThreshold = 0.03\`,
\`voicingThreshold = 0.8\` — matching DSI201.praat's IM component, which
uses a stricter voicing threshold than the jitter block. None of these
are exposed as parameters (including \`voicing_threshold\`, unlike
\`calculate_f0_stats_ultra()\`). See the Tier 4 Ultra algorithm table in
\`inst/agents/AGENT_GUIDE.md\`.

## See also

\[Sound\] for creating Sound objects \[calculate_f0_stats_ultra()\] for
FH component of DSI

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate =
 16000)

# Get minimum intensity in voiced regions (DSI IM component)
min_int <- calculate_minimum_intensity_ultra(sound, min_pitch = 75)
```
