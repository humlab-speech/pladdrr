# Get Voice Quality Metrics in Single Call (Tier 4 Ultra)

Complete voice quality pipeline in C++: Sound -\> Pitch -\> PointProcess
-\> Jitter/Shimmer/HNR metrics, in one call instead of the equivalent
Tier 2/3 workflow using separate function calls.

This is a \*\*Tier 4 "Ultra"\*\* function for batch DSI (Dysphonia
Severity Index) calculations where jitter PPQ5 is the PPQ component.

By default, this keeps the existing Tier 4 pitch path (\`pitch_method =
"cc"\`, \`very_accurate = TRUE\`). If your reference workflow uses
Praat's plain \`To Pitch...\` command before \`To PointProcess (cc)\`
(for example the DSI jitter block), call this with \`pitch_method =
"ac", very_accurate = FALSE\` — or the equivalent shorthand
\`pitch_method = "periodic_cc"\` (see below).

## Usage

``` r
get_voice_quality_ultra(
  sound,
  metrics = "all",
  min_pitch = 75,
  max_pitch = 600,
  time_step = 0,
  pitch_method = c("cc", "ac", "periodic_cc"),
  very_accurate = TRUE
)
```

## Arguments

- sound:

  A Sound object

- metrics:

  Character vector of metrics to compute: "jitter", "shimmer", "hnr", or
  "all" for all metrics

- min_pitch:

  Pitch floor in Hz for pitch extraction (default: 75). Note: HNR always
  uses 75 Hz as minimum pitch (Praat's CC harmonicity default),
  independent of this parameter.

- max_pitch:

  Pitch ceiling in Hz (default: 600)

- time_step:

  Time step for pitch/HNR (0 = auto; HNR auto uses 0.01 s)

- pitch_method:

  Pitch algorithm for the jitter/shimmer pitch object: \`"cc"\`
  (default, preserves existing Tier 4 behaviour), \`"ac"\`, or
  \`"periodic_cc"\` — an alias for \`"ac"\` with \`very_accurate\`
  forced to \`FALSE\`, matching Praat's \`To PointProcess (periodic,
  cc)...\` command (see Algorithm choice section below).

- very_accurate:

  Logical; whether to use Praat's very accurate pitch path for
  jitter/shimmer pitch extraction (default: \`TRUE\` to preserve the
  existing Tier 4 output). Use \`FALSE\` with \`pitch_method = "ac"\` to
  match Praat's plain \`To Pitch...\` command. Ignored (forced
  \`FALSE\`) when \`pitch_method = "periodic_cc"\`.

## Value

Named list with requested voice quality metrics:

- jitter_local:

  Local jitter (relative, fraction)

- jitter_local_abs:

  Local absolute jitter (seconds)

- jitter_rap:

  Relative average perturbation

- jitter_ppq5:

  5-point period perturbation quotient (DSI PPQ component)

- jitter_ddp:

  Difference of differences of periods

- shimmer_local:

  Local shimmer (relative, fraction)

- shimmer_local_db:

  Local shimmer (dB)

- shimmer_apq3:

  3-point amplitude perturbation quotient

- shimmer_apq5:

  5-point amplitude perturbation quotient

- shimmer_apq11:

  11-point amplitude perturbation quotient

- shimmer_dda:

  Difference of differences of amplitudes

- hnr_mean:

  Mean harmonics-to-noise ratio (dB)

- hnr_sd:

  Standard deviation of HNR

## Algorithm choice — `pitch_method = "periodic_cc"`

Praat's \`Sound: To PointProcess (periodic, cc)...\` command is, per
Praat's own source (\`Sound_to_PointProcess.cpp\`) and manual, exactly
\`Sound_to_Pitch(sound, 0, floor, ceiling)\` (i.e.
\`Sound_to_Pitch_rawAc\` with \`veryAccurate = FALSE\` and Praat's raw
defaults \`0.03, 0.45, 0.01, 0.35, 0.14\`) followed by
\`Sound_Pitch_to_PointProcess_cc\`. That is byte-for-byte what this
function already computes when called with \`pitch_method = "ac",
very_accurate = FALSE\`. \`pitch_method = "periodic_cc"\` is a pure
alias for that combination (it forces \`very_accurate = FALSE\`
regardless of the \`very_accurate\` argument), so callers porting a
Praat script that uses \`To PointProcess (periodic, cc)...\` can request
the matching Tier 4 path by name instead of having to know the two are
equivalent.

## API Tier

This is a \*\*Tier 4 "Ultra"\*\* function. The entire workflow (pitch
extraction, PointProcess creation, and all voice quality calculations)
happens in C++ with no intermediate R objects.

## See also

\[Sound\] for creating Sound objects \[get_jitter_shimmer_batch()\] for
Tier 2/3 voice quality analysis

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)

# Get all voice quality metrics
vq <- get_voice_quality_ultra(sound, metrics = "all", min_pitch = 75)

# Get only jitter metrics (DSI PPQ component)
vq <- get_voice_quality_ultra(sound, metrics = "jitter")
ppq5 <- vq$jitter_ppq5

# Match a plain pitch extraction + PointProcess (cc) DSI path
vq_ac <- get_voice_quality_ultra(
  sound,
  metrics = "jitter",
  pitch_method = "ac",
  very_accurate = FALSE
)

# Equivalent shorthand for the periodic-cc PointProcess path
vq_periodic_cc <- get_voice_quality_ultra(
  sound,
  metrics = "jitter",
  pitch_method = "periodic_cc"
)
```
