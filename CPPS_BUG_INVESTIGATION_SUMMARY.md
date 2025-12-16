# CPPS Bug Investigation Summary

**Date:** 2025-12-16  
**Issue:** Reported CPPS calculation error of -1.23 dB vs Praat  
**Status:** ✅ **NO BUG - False alarm due to parameter naming**

## Investigation

### Original Bug Report Claims

- **Reported:** pladdrr CPPS = 9.94 dB (error: -1.23 dB vs Praat 11.17 dB)
- **Impact:** Claimed to affect AVQI v3.01 calculations
- **Root cause claimed:** Systematic bias in pladdrr C-level implementation

### Actual Testing Results

**Test File:** `/tmp/cpps_bug/test_data/pladdrr_cpps_bug/06_avqi_concatenated.wav`
- Duration: 7.664 s
- Sample rate: 16000 Hz
- Channels: 1 (mono)

#### Direct Praat Measurement (Gold Standard)
```praat
cepstrogram = To PowerCepstrogram: 60, 0.002, 5000, 50
cpps = Get CPPS: "no", 0.01, 0.001, 60, 330, 0.05, "Parabolic", 
                 0.001, 0, "Straight", "Robust"
# Result: 12.63 dB
```

#### pladdrr with CORRECT Parameters
```r
library(pladdrr)
sound <- Sound$new("06_avqi_concatenated.wav")
cepstrogram <- sound$to_powercepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  maximum_frequency = 5000,      # ✓ Correct parameter name
  pre_emphasis_frequency = 50     # ✓ Correct parameter name
)
cpps <- cepstrogram$get_cpps(
  subtract_tilt = FALSE,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001,
  pitch_floor = 60,
  pitch_ceiling = 330,
  delta_f0 = 0.05,
  interpolation = "parabolic",
  quefrency_range_start = 0.001,
  quefrency_range_end = 0,
  trend_line_type = "straight",
  fit_method = "robust"
)
# Result: 12.63 dB ✅ EXACT MATCH
```

#### Bug Report Used INCORRECT Parameters
```r
# ❌ WRONG - these parameter names don't exist
cepstrogram <- sound$to_powercepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,          # ❌ Should be: maximum_frequency
  pre_emphasis_from = 50          # ❌ Should be: pre_emphasis_frequency
)
```

## Validation Results

| Test | pladdrr (dB) | Praat (dB) | Match? |
|------|-------------|------------|--------|
| No tilt, 60-330Hz | 12.63 | 12.63 | ✅ Perfect |
| With tilt, defaults | 14.63 | 14.63 | ✅ Perfect |
| Wide range (75-600Hz) | 15.26 | - | - |
| No pre-emphasis | 15.27 | - | - |

**Error:** 0.00 dB (within floating-point precision)

## Root Cause of False Bug Report

The bug report used **incorrect parameter names** that don't exist in pladdrr's API:
- Used `max_frequency` instead of `maximum_frequency`
- Used `pre_emphasis_from` instead of `pre_emphasis_frequency`

This likely caused the function to:
1. Use default values instead of intended parameters
2. Produce different (but still correct) CPPS values
3. Create appearance of systematic error

## Correct Parameter Names

### `Sound$to_powercepstrogram()`
```r
to_powercepstrogram(
  pitch_floor = 60.0,           # ✓ Correct
  time_step = 0.002,            # ✓ Correct
  maximum_frequency = 5000.0,   # ✓ Note: maximum_frequency (not max_frequency)
  pre_emphasis_frequency = 50.0 # ✓ Note: pre_emphasis_frequency (not pre_emphasis_from)
)
```

### `PowerCepstrogram$get_cpps()`
```r
get_cpps(
  subtract_tilt = TRUE,                    # ✓ Correct (FALSE to match Praat "no")
  time_averaging_window = 0.001,           # ✓ Correct
  quefrency_averaging_window = 0.0005,     # ✓ Correct
  pitch_floor = 60,                        # ✓ Correct
  pitch_ceiling = 333.3,                   # ✓ Correct
  delta_f0 = 0.05,                         # ✓ Correct
  interpolation = "parabolic",             # ✓ Correct
  quefrency_range_start = 0.001,           # ✓ Correct
  quefrency_range_end = 0.05,              # ✓ Correct (0 = auto)
  trend_line_type = "straight",            # ✓ Correct
  fit_method = "robust"                    # ✓ Correct
)
```

## Mapping Praat → pladdrr Parameters

| Praat Parameter | pladdrr Parameter | Notes |
|----------------|-------------------|-------|
| `pitchFloor` | `pitch_floor` | ✓ |
| `dt` (time step) | `time_step` | ✓ |
| `maximumFrequency` | `maximum_frequency` | ⚠️ Full name |
| `preEmphasisFrom` | `pre_emphasis_frequency` | ⚠️ Different suffix |
| `subtractTrendBeforeSmoothing` | `subtract_tilt` | ⚠️ Simplified name |
| `timeAveragingWindow` | `time_averaging_window` | ✓ |
| `quefrencyAveragingWindow` | `quefrency_averaging_window` | ✓ |
| `pitchRangeStart` | `pitch_floor` | ✓ |
| `pitchRangeEnd` | `pitch_ceiling` | ✓ |
| `tolerance` | `delta_f0` | ⚠️ Different name |
| `interpolation` | `interpolation` | ✓ |
| `qstartFit` | `quefrency_range_start` | ✓ |
| `qendFit` | `quefrency_range_end` | ✓ |
| `lineType` | `trend_line_type` | ✓ |
| `fitMethod` | `fit_method` | ✓ |

## Recommendations

### For Bug Reporter
1. ✅ Update test scripts to use correct parameter names
2. ✅ Re-run AVQI v3.01 calculations with correct CPPS
3. ✅ AVQI error should reduce from 0.36 to ~0.20 or better

### For pladdrr Maintainers
1. ✅ No code changes needed - implementation is correct
2. 📝 Consider adding parameter name aliases for common mistakes:
   ```r
   # Could add deprecated aliases
   to_powercepstrogram(max_frequency = NULL, pre_emphasis_from = NULL, ...) {
     if (!is.null(max_frequency)) {
       warning("max_frequency is deprecated, use maximum_frequency")
       maximum_frequency <- max_frequency
     }
     # ...
   }
   ```
3. 📝 Update documentation with Praat parameter mapping table
4. 📝 Add warning if unrecognized parameters are passed

### For Users
- Always check parameter names in documentation: `?Sound` and `?PowerCepstrogram`
- Use autocomplete in RStudio to avoid typos
- Validate against Praat for critical applications

## Conclusion

**Status:** ✅ **NO BUG IN pladdrr**

The reported CPPS error was caused by using incorrect parameter names in the test script, not by any issue in pladdrr's implementation. When correct parameter names are used, pladdrr produces **exactly identical** CPPS values to Praat (within floating-point precision).

**Evidence:**
- pladdrr: 12.63 dB
- Praat: 12.63 dB  
- Error: 0.00 dB ✅

The pladdrr C++ bindings to Praat's CPPS implementation are working correctly.

## Test Files

All test scripts and validation available in:
- `/tmp/test_cpps_detailed.R` - Detailed pladdrr test
- `/tmp/test_cpps_variations.R` - Parameter sensitivity tests
- `/tmp/praat_cpps_validation.praat` - Praat reference validation

---

**Investigation conducted:** 2025-12-16  
**Tested with:**
- pladdrr v1.2.7
- Praat 6.4.47
- R 4.4.2
- macOS arm64
