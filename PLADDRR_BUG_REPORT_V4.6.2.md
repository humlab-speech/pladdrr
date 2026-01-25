# pladdrr v4.6.2 Bug Report: Ultra API Issues

**Date**: January 25, 2026  
**Reporter**: plabench project (voice analysis toolkit)  
**pladdrr version tested**: 4.6.2  
**Platform**: macOS (aarch64-apple-darwin20), R 4.4.2

---

## Executive Summary

Testing pladdrr v4.6.2 Ultra API functions for production voice analysis toolkit. Found **2 critical bugs** in AVQI-related functions that prevent using optimized Ultra API, forcing fallback to slower explicit implementations.

**Good news**: DSI intensity bug from v4.4.0 is **FIXED** in v4.6.2! ✅

**Bad news**: AVQI bugs from v4.4.2 are **STILL PRESENT** in v4.6.2. ❌

---

## Bug #1: `extract_voiced_segments_ultra()` Version Parameter Bug

### Severity: **CRITICAL** (Incorrect Results)

### Description

`extract_voiced_segments_ultra(sound, version)` applies **different filtering algorithms** for `version = "v2.03"` vs `version = "v3.01"`, when both should use **IDENTICAL** voiced segment extraction. The only difference between AVQI v2.03 and v3.01 should be the final AVQI equation coefficients, NOT the voiced extraction algorithm.

### Evidence

Using plabench test data (6 concatenated continuous speech files, 37.00s total duration):

| Version | Extracted Duration | Expected | Error | Status |
|---------|-------------------|----------|-------|--------|
| Python reference | 17.73s | - | - | ✓ Baseline |
| v2.03 (v4.6.2) | **27.66s** | 17.73s | **+56%** | ❌ **WRONG** |
| v3.01 (v4.6.2) | 17.97s | 17.73s | +1.4% | ✅ Correct |

### Root Cause (Suspected)

The C++ implementation appears to have conditional logic based on `version` parameter that incorrectly applies more aggressive filtering for v2.03 than v3.01.

### Expected Behavior

Both `extract_voiced_segments_ultra(sound, "v2.03")` and `extract_voiced_segments_ultra(sound, "v3.01")` should:

1. Detect silence/sounding intervals
2. Extract sounding intervals → "onlyLoud"
3. Apply 30ms sliding window with dual filtering:
   - Power > 30% of global power AND
   - Zero-crossing rate < 3000 Hz
4. Concatenate surviving windows → "onlyVoice"

This algorithm is IDENTICAL for both versions per original Praat scripts (AVQI203.praat and AVQI301.praat).

### Test Case

```r
library(pladdrr)

# Load and concatenate CS files
cs_files <- c(
  "signalfiles/AVQI/input/cs1.wav",
  "signalfiles/AVQI/input/cs2.wav",
  "signalfiles/AVQI/input/cs3.wav",
  "signalfiles/AVQI/input/cs4.wav",
  "signalfiles/AVQI/input/cs5.wav",
  "signalfiles/AVQI/input/cs6.wav"
)

cs_sounds <- lapply(cs_files, Sound)
cs_sound <- cs_sounds[[1]]
for (i in 2:length(cs_sounds)) {
  cs_sound <- cs_sound$concatenate(cs_sounds[[i]])
}

# Apply high-pass filter
cs_filtered <- cs_sound$filter_stop_hann_band(0, 34, 0.1)

# Test both versions
voiced_v203 <- extract_voiced_segments_ultra(cs_filtered, "v2.03")
voiced_v301 <- extract_voiced_segments_ultra(cs_filtered, "v3.01")

cat("v2.03 duration:", voiced_v203$.cpp$duration, "s\n")
cat("v3.01 duration:", voiced_v301$.cpp$duration, "s\n")
cat("Expected: ~17.73s for BOTH\n")

# Expected output:
# v2.03 duration: 17.73 s  (currently: 27.66s - WRONG!)
# v3.01 duration: 17.73 s  (currently: 17.97s - correct)
```

### Impact

- **High**: Produces incorrect AVQI v2.03 scores (downstream metrics like CPPS, slope, tilt calculated on 56% too much audio)
- Forces users to implement explicit voiced extraction in R (slower, ~5-10x performance penalty)
- v4.4.2 documentation already warned about this bug, still present in v4.6.2

### Workaround

Implement explicit voiced extraction algorithm in R matching Python/Praat exactly (see plabench `R_implementations/avqi.R` lines 183-302).

---

## Bug #2: `calculate_cpps_ultra()` Returns NA

### Severity: **HIGH** (Function Unusable)

### Description

`calculate_cpps_ultra()` always returns `NA` (not available) instead of numeric CPPS value.

### Test Case

```r
library(pladdrr)

# Load sustained vowel
sv_sound <- Sound("signalfiles/AVQI/input/sv1.wav")
sv_filtered <- sv_sound$filter_stop_hann_band(0, 34, 0.1)

# Test calculate_cpps_ultra
cpps <- calculate_cpps_ultra(
  sv_filtered,
  time_averaging_window = 0.01,
  pitch_floor = 50,
  pitch_ceiling = 350
)

cat("CPPS:", cpps, "dB\n")

# Expected: Numeric value around 12-13 dB
# Actual: NA
```

### Expected Behavior

Should return numeric CPPS (Cepstral Peak Prominence Smoothed) value in dB, matching `calculate_cpps_fast()` output (within reasonable tolerance for algorithm differences).

### Impact

- **Medium**: Forces fallback to `calculate_cpps_fast()` (works correctly but may not benefit from Ultra API optimizations)
- Affects AVQI, VQ, and any custom analysis using CPPS

### Workaround

Use `calculate_cpps_fast()` instead:

```r
cpps <- calculate_cpps_fast(
  sound,
  subtract_tilt = FALSE,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001,
  pitch_floor = 60,
  pitch_ceiling = 330,
  delta_f0 = 0.05,
  interpolation = "parabolic",
  qstart_fit = 0.001,
  qend_fit = 0.05,
  trend_line_type = "straight",
  fit_method = "robust"
)
```

---

## ✅ FIXED: `calculate_minimum_intensity_ultra()` (v4.6.2)

### Great News!

The DSI intensity bug reported in v4.4.0 documentation is **FIXED** in v4.6.2!

### Previous Behavior (v4.4.0)

- Returned 52.87 dB (wrong algorithm - not extracting from voiced regions only)

### Current Behavior (v4.6.2)

- Returns 65.94 dB
- Expected 66.21 dB (before calibration)
- **Within 0.3 dB tolerance** ✅

### Test Case

```r
library(pladdrr)

im_sound <- Sound("signalfiles/DSI/input/im1.wav")

min_intensity <- calculate_minimum_intensity_ultra(
  im_sound,
  min_pitch = 70,
  max_pitch = 600,
  time_step = 0,
  subtract_mean = TRUE
)

cat("Min intensity:", min_intensity, "dB\n")

# v4.4.0: 52.87 dB (WRONG)
# v4.6.2: 65.94 dB (CORRECT!)
# Expected: 66.21 dB
```

### Impact

**Positive**: DSI implementation can now fully use Tier 4 Ultra API for maximum performance!

---

## Additional Observations

### Working Ultra API Functions ✅

These functions work correctly in v4.6.2:

- `get_durations_batch()` - Fast WAV header reading
- `calculate_f0_stats_ultra()` - F0 statistics  
- `get_voice_quality_ultra()` - Jitter/shimmer metrics
- `calculate_minimum_intensity_ultra()` - **Fixed!**

### API Parameter Changes

Some Ultra functions have different parameter names than documented in v4.4.0:

**`calculate_cpps_ultra()` parameters** (v4.6.2):
- `subtract_trend` (not `subtract_tilt`)
- `line_type` (not `trend_line`)
- `max_quefrency` (not `quefrency_ceiling`)

**Note**: Despite correct parameters, function still returns NA.

---

## Testing Environment

### Hardware/OS
- Platform: macOS (aarch64-apple-darwin20)
- R version: 4.4.2 (2024-10-31) "Pile of Leaves"
- pladdrr version: 4.6.2

### Test Data
- Source: plabench voice analysis toolkit
- Files: AVQI continuous speech (6 files, 37s total), DSI intensity measurement
- Reference: Validated against Praat scripts (AVQI203.praat, DSI201.praat) and Python implementations

### Validation Method
- 3-way cross-validation: Praat (reference) vs Python vs R
- Praat scripts: Original validated implementations
- Python: plabench/avqi.py (faithful Praat port using Parselmouth)
- R: pladdrr-based implementations

---

## Requested Actions

### Priority 1: Fix `extract_voiced_segments_ultra()` v2.03 Bug

1. Review C++ implementation for conditional logic based on `version` parameter
2. Ensure both v2.03 and v3.01 use IDENTICAL voiced extraction algorithm
3. Add unit test: both versions should extract ~17.73s from test data (not 27.66s vs 17.97s)

### Priority 2: Fix `calculate_cpps_ultra()` NA Return

1. Investigate why function returns NA instead of numeric value
2. Add unit test with sustained vowel file
3. Compare output with `calculate_cpps_fast()` for algorithm validation

### Priority 3: Documentation

1. Update Ultra API documentation with correct parameter names
2. Add note about v2.03 bug if fix is not backward compatible
3. Document v4.6.2 intensity fix

---

## References

### Test Files Available At

plabench GitHub repository: [specify if public]

Or request test files via:
- 6 CS WAV files (~6.2s each, 37s total concatenated)
- 1 IM WAV file for DSI intensity testing
- 1 SV WAV file for CPPS testing

### Related Documentation

- `AVQI_REMEDIATION_SUMMARY.md` - Original v4.4.2 bug discovery (2026-01-21)
- `SESSION_SUMMARY_2026-01-21.md` - Complete debugging session
- `SESSION_SUMMARY_2026-01-25.md` - v4.6.2 testing and optimization

### Contact

Fredrik Karlsson (plabench maintainer) - [contact info if appropriate]

---

## Appendix: Comparison Table

### Bug Status Across Versions

| Function | v4.4.0 / v4.4.2 | v4.6.2 | Fix Status |
|----------|-----------------|--------|------------|
| `calculate_minimum_intensity_ultra()` | ❌ Wrong algorithm (52.87 dB) | ✅ **FIXED** (65.94 dB) | Fixed |
| `extract_voiced_segments_ultra()` v2.03 | ❌ 28.48s (61% too much) | ❌ 27.66s (56% too much) | **Not fixed** |
| `extract_voiced_segments_ultra()` v3.01 | ✅ 17.88s (correct) | ✅ 17.97s (correct) | Working |
| `calculate_cpps_ultra()` | ❌ Returns NA | ❌ Returns NA | **Not fixed** |
| `get_durations_batch()` | ✅ Working | ✅ Working | N/A |
| `calculate_f0_stats_ultra()` | ✅ Working | ✅ Working | N/A |
| `get_voice_quality_ultra()` | ✅ Working | ✅ Working | N/A |

### Performance Impact

| Implementation | Performance | Accuracy | Status |
|----------------|-------------|----------|--------|
| **AVQI with Ultra API** | Fast (2-4x speedup) | ❌ Incorrect (v2.03) | Cannot use |
| **AVQI explicit R** | Baseline | ✅ Correct | Current workaround |
| **AVQI vectorized explicit** | Medium (3-5x vs explicit) | ✅ Correct | Optimized workaround |
| **DSI with Tier 4 Ultra** | Fast (3-6x speedup) | ✅ Correct | ✅ **Production ready!** |

---

**Thank you for your attention to these issues!** The DSI fix in v4.6.2 is much appreciated. Looking forward to AVQI fixes in a future release so we can leverage the full Ultra API performance benefits.
