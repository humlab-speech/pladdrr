# Calculate F0 Statistic in Single Call (Tier 4 Ultra)

Performs pitch extraction AND statistic calculation entirely in C++,
avoiding intermediate R6 object creation and the separate
\`to_pitch_cc()\` and \`get_maximum()\` calls.

This is a \*\*Tier 4 "Ultra"\*\* function for batch DSI (Dysphonia
Severity Index) calculations where maximum F0 is the FH (Highest
Frequency) component.

## Usage

``` r
calculate_f0_stats_ultra(
  sound,
  stat,
  min_pitch = 75,
  max_pitch = 600,
  time_step = 0,
  voicing_threshold = 0.45
)
```

## Arguments

- sound:

  A Sound object

- stat:

  Statistic to compute: "max", "min", "mean", "median", or "sd"

- min_pitch:

  Pitch floor in Hz (default: 75)

- max_pitch:

  Pitch ceiling in Hz (default: 600)

- time_step:

  Time step for pitch extraction (0 = auto)

- voicing_threshold:

  Voicing threshold (default: 0.45)

## Value

Single numeric value of the requested statistic in Hz

## API Tier

This is a \*\*Tier 4 "Ultra"\*\* function. The entire pitch extraction
and statistic computation happens in C++ with no intermediate R6
objects.

## Algorithm choice

Pitch is always extracted with \`Sound_to_Pitch_rawCc()\`,
\`veryAccurate = TRUE\`, \`silenceThreshold = 0.03\` (matching
DSI201.praat's \`To Pitch (cc)...\` step). Only \`voicing_threshold\` is
configurable; the AC/CC choice and \`veryAccurate\` are not. See the
Tier 4 Ultra algorithm table in \`inst/agents/AGENT_GUIDE.md\` for how
this compares to the other Ultra functions.

## See also

\[Sound\] for creating Sound objects \[get_durations_batch()\] for MPT
component of DSI

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate =
 16000)

# Get maximum F0 (DSI FH component)
max_f0 <- calculate_f0_stats_ultra(sound, stat = "max", min_pitch = 75,
 max_pitch = 600)

# Get mean F0
mean_f0 <- calculate_f0_stats_ultra(sound, stat = "mean")
```
