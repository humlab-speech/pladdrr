# Direct API Parameter Audit Results

**Date:** 2026-01-12  
**Version:** pladdrr v4.0.1  
**Purpose:** Verify parameter completeness across Tier 1 (Standard), Tier 2 (Direct), and Tier 3 (Batch) APIs

---

## Summary

**Result:** Formant, Intensity, and Harmonicity Direct APIs have **complete parameter support**. Only Pitch Direct API has limitations.

---

## Detailed Comparison

### 1. Pitch Analysis

| API Tier | Function | Parameters | Status |
|----------|----------|------------|--------|
| **Tier 1** (Standard) | `sound$to_pitch_cc()` | 10 params (all) | ✅ Full |
| **Tier 2** (Direct) | `to_pitch_direct()` | **4 params** (basic only) | ⚠️ **LIMITED** |
| **Tier 3** (Batch) | `sound_to_pitch_cc_batch()` | 10 params (all) | ✅ Full |

**Missing in Direct API:**
- `max_candidates`
- `very_accurate`
- `silence_threshold` ⚠️
- `voicing_threshold` ⚠️
- `octave_cost` ⚠️
- `octave_jump_cost` ⚠️
- `voiced_unvoiced_cost` ⚠️

**Impact:** High - Voicing parameters commonly needed for custom pitch detection

**Status:** Documented in `agents/AGENT_GUIDE.md` with workarounds

---

### 2. Formant Analysis

| API Tier | Function | Parameters | Status |
|----------|----------|------------|--------|
| **Tier 1** (Standard) | `sound$to_formant_burg()` | 5 params | ✅ Full |
| **Tier 2** (Direct) | `to_formant_direct()` | 5 params | ✅ **FULL** |
| **Tier 3** (Batch) | `.sound_to_formant_batch()` | 5 params | ✅ Full |

**Parameters:**
```r
time_step, max_formants, max_frequency (max_formant), 
window_length, pre_emphasis_from (pre_emphasis)
```

**Status:** ✅ No limitations - Direct API has complete parameter support

---

### 3. Intensity Analysis

| API Tier | Function | Parameters | Status |
|----------|----------|------------|--------|
| **Tier 1** (Standard) | `sound$to_intensity()` | 3 params | ✅ Full |
| **Tier 2** (Direct) | `to_intensity_direct()` | 3 params | ✅ **FULL** |
| **Tier 3** (Batch) | `.sound_to_intensity_batch()` | 3 params | ✅ Full |

**Parameters:**
```r
minimum_pitch, time_step, subtract_mean
```

**Status:** ✅ No limitations - Direct API has complete parameter support

---

### 4. Harmonicity Analysis

| API Tier | Function | Parameters | Status |
|----------|----------|------------|--------|
| **Tier 1** (Standard) | `sound$to_harmonicity_cc()` | 4 params | ✅ Full |
| **Tier 2** (Direct) | `to_harmonicity_direct()` | 4 params | ✅ **FULL** |
| **Tier 3** (Batch) | *Not implemented* | N/A | N/A |

**Parameters:**
```r
time_step, minimum_pitch (min_pitch), silence_threshold, periods_per_window
```

**Status:** ✅ No limitations - Direct API has complete parameter support

---

## Recommendations

### 1. No Action Needed for:
- ✅ Formant Direct API - Complete
- ✅ Intensity Direct API - Complete  
- ✅ Harmonicity Direct API - Complete

### 2. Pitch Direct API (Already Addressed):
- ✅ Documented in `agents/AGENT_GUIDE.md` (lines ~495, ~981, ~1055)
- ✅ Workarounds provided (use Tier 1 or Tier 3)
- ✅ Stub functions created for future enhancement (`to_pitch_ac_direct()`, `to_pitch_cc_direct()`)
- ✅ Benchmark created (`inst/benchmarks/17_pitch_api_tier_comparison.R`)

---

## Conclusion

**Only Pitch Direct API has parameter limitations.** All other Direct APIs (Formant, Intensity, Harmonicity) have complete parameter coverage matching their Tier 1 counterparts.

The Pitch limitation is well-documented and workarounds are provided. No further action required.

---

## Verification Details

**Verified:**
- ✅ R/praat-direct.R - Direct API wrappers
- ✅ R/RcppExports.R - C++ exports
- ✅ R/sound-r6-new.R - Tier 1 (Standard) API
- ✅ R/batch-ops.R - Tier 3 (Batch) API

**Method:** Manual signature comparison across all three API tiers for pitch, formant, intensity, and harmonicity functions.
