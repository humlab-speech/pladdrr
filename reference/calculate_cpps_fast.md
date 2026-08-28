# Smoothed Cepstral Peak Prominence (CPPS) in one call

Computes the smoothed cepstral peak prominence (CPPS, in dB) of a
\`Sound\` — a widely used acoustic measure of voice quality/breathiness.
It performs the whole PowerCepstrogram-then-CPPS pipeline in a single
call and returns the same value as
\`sound\$to_powercepstrogram(...)\$get_cpps(...)\` with matching
parameters. You supply the analysis parameters directly and are
responsible for passing valid values (see the arguments below).

## Usage

``` r
calculate_cpps_fast(
  sound,
  subtract_tilt = TRUE,
  time_averaging_window = 0.001,
  quefrency_averaging_window = 5e-04,
  pitch_floor = 60,
  pitch_ceiling = 333.3,
  delta_f0 = 0.05,
  interpolation = "parabolic",
  qstart_fit = 0.003,
  qend_fit = 0.04,
  trend_line_type = "straight",
  fit_method = "robust",
  cepstrogram_pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,
  pre_emphasis_from = 50
)
```

## Arguments

- sound:

  Sound object or external pointer

- subtract_tilt:

  Logical, subtract tilt before calculating CPPS (default TRUE)

- time_averaging_window:

  Numeric, time averaging window in seconds (default 0.001)

- quefrency_averaging_window:

  Numeric, quefrency averaging window in seconds (default 0.0005)

- pitch_floor:

  Numeric, minimum F0 in Hz (default 60)

- pitch_ceiling:

  Numeric, maximum F0 in Hz (default 333.3)

- delta_f0:

  Numeric, F0 fractional precision (default 0.05)

- interpolation:

  Character, one of "parabolic", "none", "cubic", "sinc70", "sinc700"
  (default "parabolic")

- qstart_fit:

  Numeric, quefrency range start for fitting in seconds (default 0.003)

- qend_fit:

  Numeric, quefrency range end in seconds (default 0.04)

- trend_line_type:

  Character, "straight" or "exponential" (default "straight")

- fit_method:

  Character, "robust" (Siegel repeated median), "least_squares", or
  "robust slow" (Theil-Sen). Default "robust". \*\*"robust slow" is not
  reproducible\*\*: it samples randomly inside Praat's slope selection,
  so repeated runs on the same input differ (~0.8 dB observed) and can
  return values on the order of 1e290. That is an upstream Praat defect,
  reproduced faithfully here; pladdrr warns once per session when you
  select it.

- cepstrogram_pitch_floor:

  Numeric, pitch floor for cepstrogram creation (default 60)

- time_step:

  Numeric, time step for cepstrogram in seconds (default 0.002)

- max_frequency:

  Numeric, max frequency for cepstrogram in Hz (default 5000)

- pre_emphasis_from:

  Numeric, pre-emphasis frequency in Hz (default 50)

## Value

A single numeric CPPS value in dB.

## Details

Use this when analysing many files in a loop. For interactive or one-off
use, the object API (\`sound\$to_powercepstrogram(...)\$get_cpps(...)\`)
is equivalent and validates its inputs more forgivingly; this function
skips that validation, so pass well-formed parameters.

This is a \*\*CPPS\*\* helper: it builds a whole-sound PowerCepstrogram
and then computes a smoothed peak-prominence summary. If you need a
single-interval \*\*CPP\*\* value that matches Praat's \`To
PowerCepstrum\` workflow, extract the interval, convert it to a
Spectrum, and call \`to_power_cepstrum()\$get_peak_prominence()\`
instead. That path is much cheaper and is not the same metric.

## Defaults differ from Praat's

These defaults follow the AVQI/clinical convention, \*\*not\*\* the
defaults of Praat's \`PowerCepstrogram: Get CPPS...\` dialog. On a 1 s
test signal the two parameter sets give 9.92 dB and 4.82 dB respectively
— a different measurement, not a rounding difference. Pass the Praat
values explicitly to reproduce a Praat run:

\| parameter \| Praat default \| pladdrr default \| \|—\|—\|—\| \|
\`time_averaging_window\` \| 0.02 \| 0.001 \| \|
\`quefrency_averaging_window\` \| 0.0005 \| 0.0005 \| \| \`pitch_floor\`
\| 60 \| 60 \| \| \`pitch_ceiling\` \| 330 \| 333.3 \| \| \`qstart_fit\`
\| 0.001 \| 0.003 \| \| \`qend_fit\` \| 0.05 \| 0.04 \| \|
\`trend_line_type\` \| \`"exponential"\` \| \`"straight"\` \| \|
\`fit_method\` \| \`"robust slow"\` \| \`"robust"\` \|

The \`fit_method\` difference is deliberate beyond convention: Praat's
\`"robust slow"\` (Theil-Sen) is not reproducible — see the
\`fit_method\` argument.

## Examples

``` r
sound <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))

# Full-file CPPS calls on the 60 s demo file are CPU-heavy (> 5 s under
# R CMD check), so they live in \donttest{} (still run under
# --run-donttest).
# \donttest{
# One-call CPPS with the default (AVQI-convention) parameters
calculate_cpps_fast(sound)
#> [1] 9.920529

# The object API gives the identical value
pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
pcep$get_cpps()
#> [1] 9.920529

# Reproduce Praat's own "Get CPPS..." defaults
calculate_cpps_fast(sound,
  time_averaging_window = 0.02, pitch_ceiling = 330,
  qstart_fit = 0.001, qend_fit = 0.05,
  trend_line_type = "exponential", fit_method = "least_squares"
)
#> [1] 5.671056
# }
# Single-interval CPP is a different, cheaper path
segment <- sound$extract_part(0, 0.5)
cpp <- segment$to_spectrum()$to_power_cepstrum()$get_peak_prominence(
  60, 333.3, "parabolic", 0.001, 0.05, "exponential decay", "robust slow"
)
```
