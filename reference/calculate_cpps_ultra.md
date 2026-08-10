# Calculate CPPS with Optimized Single-Call (Tier 4 Ultra)

Computes CPPS from a \`Sound\` in a single C++ call, building the
PowerCepstrogram internally so no intermediate R object is created.

Returns the same value as
[`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md)
and as `sound$to_powercepstrogram(...)$get_cpps(...)`. The three paths
cost about the same: the R/C++ boundary crossing is negligible next to
the per-frame trend fit, so pick whichever reads best at the call site.

## Usage

``` r
calculate_cpps_ultra(
  sound,
  time_averaging_window = 0.001,
  quefrency_averaging_window = 5e-04,
  pitch_floor = 60,
  pitch_ceiling = 333.3,
  subtract_trend = TRUE,
  time_step = 0.002,
  max_quefrency = 0.04,
  tolerance = 0.05,
  interpolation = "parabolic",
  tilt_line_quefrency = 0.003,
  line_type = "straight",
  fit_method = "robust",
  pre_emphasis_from = 50,
  max_frequency = 5000
)
```

## Arguments

- sound:

  Sound object or external pointer

- time_averaging_window:

  Time averaging window in seconds (default 0.001)

- quefrency_averaging_window:

  Quefrency averaging window in seconds (default 0.0005)

- pitch_floor:

  Minimum F0 in Hz (default 60)

- pitch_ceiling:

  Maximum F0 in Hz (default 333.3)

- subtract_trend:

  Logical, subtract tilt before smoothing (default TRUE)

- time_step:

  Time step for cepstrogram in seconds (default 0.002)

- max_quefrency:

  End of the trend-fit quefrency window in seconds (default 0.04); 0
  means autowindow to the full quefrency range (Praat convention).

- tolerance:

  Tolerance for peak detection (default 0.05)

- interpolation:

  Peak interpolation: "none", "parabolic", "cubic", "sinc70", "sinc700"
  (default "parabolic")

- tilt_line_quefrency:

  Start of the trend-fit quefrency window in seconds (default 0.003).

- line_type:

  Trend line type: "straight" or "exponential" (default "straight")

- fit_method:

  Fitting method: "robust" (Siegel repeated median), "least_squares", or
  "robust slow" (Theil-Sen). Default "robust". \*\*"robust slow" is not
  reproducible\*\* — see \`calculate_cpps_fast()\`.

- pre_emphasis_from:

  Pre-emphasis frequency in Hz for the cepstrogram (default 50).

- max_frequency:

  Maximum frequency in Hz for the cepstrogram (default 5000).

## Value

Numeric CPPS value in dB

## Details

Implements the complete CPPS pipeline in one C++ call, following the
approach used in AVQI v2.03 and v3.01: PowerCepstrogram creation and
CPPS extraction are consolidated, and no intermediate R object is
allocated.

This does \*\*not\*\* make it meaningfully cheaper than the other CPPS
entry points: the per-frame robust trend fit
(\`SlopeSelector::getSlope_Siegel\`) dominates CPPS runtime and is
shared by every path; consolidating the PowerCepstrogram creation only
removes the R/C++ boundary crossing, which is a small fraction of the
total cost. Treat the choice as a matter of call-site convenience, not
performance.

The defaults here match
[`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md)
and therefore also deviate from Praat's dialog defaults — see the
"Defaults differ from Praat's" section of
[`calculate_cpps_fast`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md).

This is still a \*\*CPPS\*\* helper. For a single-interval \*\*CPP\*\*
measurement, use the segment's \`Spectrum -\> PowerCepstrum -\>
get_peak_prominence()\` path instead of \`calculate_cpps_ultra()\`. It
is both cheaper and closer to the Praat workflow used by voice-quality
scripts that query one interval at a time.

\*\*Use Cases:\*\* - AVQI v2.03/v3.01 implementation - High-throughput
voice quality analysis - CPPS monitoring in latency-sensitive pipelines

## Algorithm choice

Not applicable — this function is pitch-independent. It builds a
\`PowerCepstrogram\` directly from the Sound
(\`Sound_to_PowerCepstrogram()\`) and never extracts a \`Pitch\` object,
so there is no AC/CC or \`veryAccurate\` choice to document here. See
the CPPS parameter default table in \`/CLAUDE.md\` for the (non-pitch)
parameters that do vary by caller, and the Tier 4 Ultra algorithm table
in \`inst/agents/AGENT_GUIDE.md\` for how this compares to the
pitch-based Ultra functions.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)

# Tier 4 Ultra (same defaults as calculate_cpps_fast)
cpps <- calculate_cpps_ultra(sound)

# Should match calculate_cpps_fast() within 0.01 dB
cpps_fast <- calculate_cpps_fast(sound)
all.equal(cpps, cpps_fast, tolerance = 0.01)
#> [1] TRUE
```
