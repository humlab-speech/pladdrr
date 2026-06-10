# pladdrr Developer Report — June 2026

**Generated from**: algobench fidelity and performance benchmarks  
**pladdrr version tested**: 4.8.35  
**Praat reference version**: 6.4.47 (November 7 2025)  
**Date**: 2026-06-10

---

## Executive Summary

Systematic benchmarking of R/pladdrr implementations against native Praat reference scripts
across 14 voice analysis algorithms revealed two confirmed bugs, one critical performance gap,
and two API usability issues that require changes inside pladdrr. Three discrepancies were
resolved by correcting R user-code errors; the items below cannot be fixed outside pladdrr.

| ID | Issue | Type | Severity | Key Impact | Status |
|----|-------|------|----------|-----------|--------|
| BUG-1 | `to_formant_burg()` on short windows produces wrong F1/F2/F3 | Bug | CRITICAL | F1 r=0.57, F2 r=0.38 vs Praat | Open |
| BUG-2 | `get_peaks_batch(interpolation="parabolic")` returns physically impossible values | Bug | CRITICAL | pharyngeal harmonics r≈−0.08 vs Praat | Open |
| PERF-1 | No batch spectral moments API forces slow R loop | Perf Gap | HIGH | 14× slower than Praat | Open |
| API-1 | `to_ltas_direct()` returns raw `externalptr`, not wrapped `Ltas` | API | LOW | Developer friction / error-prone | Open |
| INV-1 | `to_intensity_direct()` mean intensity ~1.3 dB below Praat | Investigation | MEDIUM | mean_intensity r=0.61 vs Praat | Needs reproduction |

---

## BUG-1: `to_formant_burg()` — Incorrect Formants on Short Windowed Audio

### Affected API
`sound$to_formant_burg(time_step, num_formants, max_formant, window_length, pre_emphasis_from)`  
Also exposed as `to_formant_direct()`.

### Evidence

Fidelity benchmark: `formant` algorithm, N=166 files, R/pladdrr vs Praat reference.

| Field | N | Mean diff (Hz) | SD (Hz) | r |
|-------|---|---------------|---------|---|
| F1 | 166 | 85.1 | 128.7 | 0.57 |
| F2 | 166 | 481.1 | 452.8 | 0.38 |
| F3 | 166 | 265.4 | 414.6 | 0.36 |
| B1 | 166 | 124.9 | 142.9 | 0.50 |
| B2 | 166 | 433.7 | 276.2 | 0.34 |
| B3 | 166 | 290.4 | 226.7 | 0.53 |

For comparison, Python/Parselmouth running the same algorithm achieves r > 0.9999 for F1/F2/F3.

The bug was independently discovered during pharyngeal analysis and documented in `pharyngeal.R` (added 2026-01-25):

> _"pladdrr has incomplete polynomial root finding in formant extraction. Extracting formants from windows returns incorrect values (F1=570 vs 873 Hz)."_

### Reproduction

```r
library(pladdrr)

# Load any voiced vowel (e.g., sustained /a/)
snd <- Sound("path/to/vowel.wav")

# Extract 40ms window — standard analysis window for formants
window <- snd$extract_part(0.0, 0.04, "rectangular", 1, FALSE)

# Run Burg LPC formant analysis
formant <- window$to_formant_burg(
  time_step    = 0.005,
  num_formants = 5,
  max_formant  = 5500,
  window_length = 0.025,
  pre_emphasis = 50
)

f1 <- formant$get_value_at_time(1, 0.02, "hertz")
f2 <- formant$get_value_at_time(2, 0.02, "hertz")

cat("pladdrr F1:", f1, "Hz\n")  # e.g. 570 Hz (incorrect)
cat("pladdrr F2:", f2, "Hz\n")  # significantly off

# Compare with Praat on same file:
# Praat F1: ~873 Hz, F2: ~1350 Hz (typical adult male /a/)
```

### Root Cause (suspected)

The Burg LPC algorithm computes an all-pole model whose formants are the roots of the
characteristic polynomial. The pladdrr C++ implementation appears to fail to find all roots
for short (40ms) windows, causing some formants to be missed or mis-ordered.

The bug does **not** manifest when the full-length Sound is analysed — extracting formants
from a 1–3 second vowel and querying at a time point returns correct values. The failure is
specific to operating on a short (≤100ms) windowed excerpt.

### Current Workaround

```r
# Analyze full sound, query at absolute time — slower but correct
formant_full <- snd$to_formant_burg(0.005, 5, 5500, 0.025, 50)
f1 <- formant_full$get_value_at_time(1, target_time, "hertz")
```

This is a performance regression (full-sound Burg is significantly more expensive than 40ms
window Burg) and forces all pharyngeal analysis to use the full sound workaround.

### Requested Fix

Correct the polynomial root-finding code in the C++ Burg LPC implementation.
Reference implementation: Praat source `FormantSoundAnalysis.cpp` / `Formant.cpp`.

### Downstream Impact

- `formant.R` — F1/F2/F3 errors up to 481 Hz mean difference
- `pharyngeal.R` — requires full-sound workaround, causing ~6× speed penalty
- Any user code performing Burg formant analysis on audio windows shorter than ~500ms

---

## BUG-2: `get_peaks_batch(interpolation="parabolic")` Returns Physically Impossible Values

### Affected API

`Ltas$get_peaks_batch(fmins, fmaxs, interpolation = "parabolic")`

### Evidence

Fidelity benchmark: `pharyngeal` algorithm, N=152 files, R/pladdrr vs Praat reference.

| Field | N | Mean diff (dB) | SD (dB) | Range (dB) | r |
|-------|---|---------------|---------|-----------|---|
| h1_onset | 152 | 52.9 | 94.1 | [13.4, 1202.9] | −0.078 |
| h2_onset | 152 | 51.4 | 93.2 | [22.8, 1189.9] | 0.050 |
| a1_onset | 152 | 59.8 | 92.3 | [40.2, 1189.9] | −0.007 |
| a2_onset | 152 | 62.7 | 93.7 | [37.1, 1208.7] | −0.151 |
| a3_onset | 152 | 70.9 | 95.0 | [29.9, 1231.3] | −0.154 |

Values up to **1231 dB** are physically impossible for any acoustic spectrum. The near-zero
and negative correlation coefficients confirm the values are noise, not a systematic offset.

**Critical diagnostic**: Python/Parselmouth running the identical algorithm on the same files
produces h1_onset with r=0.949 and SD=2.5 dB — confirming the algorithm is correct. The
failure is isolated to pladdrr's `get_peaks_batch(interpolation="parabolic")`.

**Isolation test**: Switching to `interpolation="none"` in the same R code immediately produces
physically plausible values (~30–55 dB for vocal harmonics with near-zero mean diff). This
confirms the bug is in the parabolic path of `get_peaks_batch`, not in the surrounding code.

### Reproduction

```r
library(pladdrr)

snd <- Sound("path/to/vowel.wav")

# Build LTAS from 40ms Kaiser2 window (standard pharyngeal pipeline)
window <- snd$extract_part(0.0, 0.04, "Kaiser2", 1, FALSE)
spec   <- window$to_spectrum(TRUE)
ltas   <- spec$to_ltas_1to1()

f0 <- 120  # Hz — typical male F0

# --- BUGGY: parabolic interpolation ---
peaks_para <- ltas$get_peaks_batch(
  fmins = c(f0 * 0.9, f0 * 1.8),
  fmaxs = c(f0 * 1.1, f0 * 2.2),
  interpolation = "parabolic"
)
cat("Parabolic H1:", peaks_para$peak_value[1], "dB\n")
# Observed: values routinely in range 500–1200 dB (physically impossible)

# --- CORRECT: no interpolation ---
peaks_none <- ltas$get_peaks_batch(
  fmins = c(f0 * 0.9, f0 * 1.8),
  fmaxs = c(f0 * 1.1, f0 * 2.2),
  interpolation = "none"
)
cat("None H1:", peaks_none$peak_value[1], "dB\n")
# Expected: ~30–55 dB for typical speech LTAS
```

**Expected**: H1 amplitude in range [20, 80] dB for normal speech. No value from any audio
source should exceed 200 dB.

### Suspected Cause

The parabolic interpolation for LTAS peak finding likely has a numerical error — possibly a
division by near-zero denominator when adjacent LTAS bins have nearly equal power, or an
incorrect bin index offset in the batch C++ code path. The non-batch single-call
`ltas$get_maximum(fmin, fmax, "Parabolic")` may work correctly; compare the two code paths.

### Requested Fix

1. Identify why the parabolic interpolation in `get_peaks_batch` produces values >200 dB
2. Add a sanity clamp or assertion: parabolic-interpolated LTAS values must be within ±50 dB
   of the surrounding bin values (a parabolic fit cannot extrapolate more than the bin width)
3. Consider whether the batch code path shares the same interpolation implementation as the
   single-call path, or if it has a separate (buggy) implementation

---

## PERF-1: Missing Batch Spectral Moments API — 14× Performance Gap

### Affected Use Case

Spectral moments analysis: computing per-frame centre of gravity (CoG), standard deviation,
skewness, and kurtosis from a spectrogram.

### Evidence

Performance benchmark: `spectral_moments` algorithm, N=2324 files.

| Implementation | Mean time (s) | Speedup vs Praat |
|---------------|--------------|-----------------|
| Praat 6.4.47 | 0.0365 | 1.00× (reference) |
| R/pladdrr 4.8.35 | 0.5140 | **0.07×** (14× slower) |
| Python/Parselmouth | 0.5026 | 0.07× (same) |

Both R and Python suffer the same penalty. Praat runs identical logic in compiled C++.

### Root Cause

No vectorized API exists. All per-frame work must be done in interpreted R (or Python):

```r
for (frame in seq_len(num_frames)) {
  curr_time <- spectrogram$get_time_from_frame(frame)  # C++ round-trip
  spectrum  <- spectrogram$to_spectrum(curr_time)       # C++ object allocation
  cog <- spectrum$get_centre_of_gravity(power)          # C++ round-trip
  sd  <- spectrum$get_standard_deviation(power)         # C++ round-trip
  sk  <- spectrum$get_skewness(power)                   # C++ round-trip
  ku  <- spectrum$get_kurtosis(power)                   # C++ round-trip
}
# 400 frames → 400 object allocations + 1600 individual C++ calls from R
```

Each `to_spectrum(time)` allocates a new Praat `Spectrum` object in C++ and wraps it in R.
The 4 moment calls each cross the R–C++ boundary. For ~400 frames per file, this is
~1600 R→C++ round-trips per file, each with allocation and GC pressure.

### Requested API Addition

New method on `Spectrogram`:

```r
moments_df <- spectrogram$get_spectral_moments_batch(power = 2.0)
```

**Returns**: `data.frame` with columns `time`, `cog`, `sd`, `skewness`, `kurtosis`  
(one row per frame, `NA` for frames where CoG is undefined/zero-power)

**Implementation note**: The C++ Spectrogram already iterates frames for other batch
operations. This simply adds 4 spectral moment computations inside the existing C++ loop,
returning a matrix. No new algorithmic complexity is needed — this is a direct vectorization
of the existing per-frame approach.

**Expected speedup**: From 14× slower to ≥1× (matching or exceeding Praat), based on
elimination of all R-loop overhead and per-frame object allocation.

---

## API-1: `to_ltas_direct()` Returns Raw `externalptr` Instead of Wrapped `Ltas`

### Affected API

`to_ltas_direct(sound, bandwidth = 100)`

### Evidence

```r
library(pladdrr)
snd  <- Sound("path/to/file.wav")
ltas <- to_ltas_direct(snd, 1)

class(ltas)
# [1] "externalptr"   ← should be c("Ltas", "PraatObject")

ltas$get_slope(0, 1000, 1000, 10000, "energy")
# Error in ltas$get_slope : object of type 'externalptr' is not subsettable
```

Every other pladdrr constructor (`to_pitch_cc_direct()`, `to_formant_burg()`,
`to_intensity_direct()`, etc.) returns a wrapped R object. `to_ltas_direct()` uniquely
returns a raw C++ pointer, making it unusable without manual wrapping.

### Required Workaround

```r
ltas <- Ltas(.xptr = to_ltas_direct(snd, 1))
```

### Requested Fix

Return a wrapped `Ltas` object from `to_ltas_direct()`, consistent with all other pladdrr
constructors:

```r
# Current (broken):
to_ltas_direct <- function(sound, bandwidth = 100) {
  sound_ptr <- extract_xptr(sound, "Sound")
  .sound_to_ltas(sound_ptr, as.numeric(bandwidth))   # returns raw ptr
}

# Fixed:
to_ltas_direct <- function(sound, bandwidth = 100) {
  sound_ptr <- extract_xptr(sound, "Sound")
  Ltas(.xptr = .sound_to_ltas(sound_ptr, as.numeric(bandwidth)))
}
```

---

## INV-1: `to_intensity_direct()` — Mean Intensity ~1.3 dB Below Praat

### Affected API

`sound$to_intensity(min_pitch, time_step, subtract_mean)` / `to_intensity_direct()`

### Evidence

Fidelity benchmark: `intensity` algorithm, N=2324 files.

| Field | N | Mean diff | SD | r |
|-------|---|-----------|----|---|
| mean_intensity | 2324 | −1.30 dB | 3.17 | 0.61 |
| max_intensity | 2324 | −1.24 dB | 2.91 | 0.66 |
| min_intensity | 2324 | +0.95 dB | 5.45 | 0.93 |

Python/Parselmouth shows similar divergence (mean_intensity r=0.80), suggesting this is a
known difference in how pladdrr/Parselmouth implement the Praat intensity algorithm.

The `min_intensity` has higher correlation (r=0.93) than `mean_intensity` (r=0.61), which
suggests the error is not constant — it varies with the signal, pointing to a numerical
integration difference rather than a simple unit offset.

### Suspected Causes

1. **Window length formula**: Praat derives intensity window length as `3.2 / min_pitch`.
   Verify pladdrr uses the same formula when `time_step = 0.0` (automatic).

2. **Mean calculation domain**: Praat's `Intensity: Get mean: 0, 0` averages in the
   **energy domain** (Pa²·s), then converts to dB. If pladdrr averages in dB directly,
   the result will be systematically lower (Jensen's inequality), explaining the −1.3 dB bias.

3. **DC subtraction timing**: `subtract_mean=TRUE` removes the DC component before windowed
   analysis. Verify the subtraction is applied per-window, not globally.

### Requested Action

Compare `to_intensity_direct()` against Praat's `Sound_to_Intensity.cpp`, specifically:
- Window length derivation from `min_pitch`
- The energy integration and dB conversion sequence
- Whether `Get mean` averages in energy or dB domain

---

## What Works Well

The following pladdrr APIs were validated against Praat across large datasets (N=140–2324
files per algorithm) and produce high-fidelity results:

| API | Validated in | r vs Praat | Notes |
|-----|-------------|-----------|-------|
| `two_pass_adaptive_pitch()` | vq, pharyngeal | — | Adaptive pitch range correct |
| `get_jitter_shimmer_batch()` | vq, voice_report | r = 0.97–0.999 | Excellent fidelity for all 11 measures |
| `calculate_multiband_hnr_ultra()` | vq | r ≈ 0.99 | CC method confirmed correct (v4.6.4 fix) |
| `calculate_cpps_ultra()` | avqi_v203, avqi_v301 | r = 0.999 | CPPS matches Praat exactly |
| `to_point_process_from_sound_and_pitch()` | vq, pharyngeal | — | PointProcess creation correct |
| `to_harmonicity_gne()` | vq | — | GNE calculation correct |
| `ltas$get_slope("energy")` | vq | — | Correct when called with "energy" type |
| `ltas$compute_trend_line()` | vq | — | Tilt calculation correct |
| `Ltas$to_ltas_1to1()` (from Spectrum) | vq, pharyngeal | — | 1-to-1 LTAS correct |
| `pitch / vuv / formant` (full sound) | all | r > 0.99 | Correct on full-length sounds |

---

## Verification Checklist

After implementing fixes, run the algobench assessment suite:

```bash
cd /path/to/algobench
algobench assess
```

Target metrics per fix:

| Fix | Algorithm | Field | Current r | Target r |
|-----|-----------|-------|-----------|---------|
| BUG-1 | formant | F1 | 0.57 | > 0.95 |
| BUG-1 | formant | F2 | 0.38 | > 0.90 |
| BUG-1 | pharyngeal | (enables window-based formant) | — | speedup > 1× |
| BUG-2 | pharyngeal | h1_onset | −0.078 | > 0.90 |
| BUG-2 | pharyngeal | h2_onset | 0.050 | > 0.85 |
| BUG-2 | pharyngeal | a1/a2/a3_onset | ~0 | > 0.80 |
| PERF-1 | spectral_moments | speedup | 0.07× | > 0.80× |
| API-1 | any | `to_ltas_direct()` usable without wrapping | — | no error |

Fidelity reports are in `algobench/reports/fidelity.csv` and performance in
`algobench/reports/performance.csv`.

---

## Appendix: Test Environment

```
OS:       macOS Darwin 25.5.0 (arm64)
R:        4.4.x
pladdrr:  4.8.35
Praat:    6.4.47 (November 7 2025)
Dataset:  Kay Elemetrics/MEEI Disordered Voice Database + healthy controls
          50–2324 files per algorithm depending on signal type requirement
Signals:  FLAC, 44100 Hz, mono, sustained vowel /a/ and /i/ + running speech
```
