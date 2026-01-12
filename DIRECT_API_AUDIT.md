# Direct API Parameter Audit Results

**Date:** 2026-01-12  
**Version:** pladdrr v4.0.2 (UPDATED)  
**Purpose:** Verify parameter completeness across Tier 1 (Standard), Tier 2 (Direct), and Tier 3 (Batch) APIs

---

## Summary

**Result:** ✅ **All Direct APIs now have complete parameter support** (as of v4.0.2)

**Update:** New full-parameter pitch Direct API functions (`to_pitch_ac_direct()`, `to_pitch_cc_direct()`) added in v4.0.2.

---

## Detailed Comparison

### 1. Pitch Analysis

| API Tier | Function | Parameters | Status |
|----------|----------|------------|--------|
| **Tier 1** (Standard) | `sound$to_pitch_cc()` | 10 params (all) | ✅ Full |
| **Tier 2** (Direct - NEW) | `to_pitch_cc_direct()` | **10 params (all)** | ✅ **FULL** ⭐ |
| **Tier 2** (Direct - Legacy) | `to_pitch_direct()` | 4 params (basic) | ⚠️ Limited |
| **Tier 3** (Batch) | `sound_to_pitch_cc_batch()` | 10 params (all) | ✅ Full |

**NEW in v4.0.2:** Full-parameter Direct API functions
- `to_pitch_ac_direct()` - Autocorrelation with all 10 parameters ✅
- `to_pitch_cc_direct()` - Cross-correlation with all 10 parameters ✅

**All Parameters Now Available in Direct API:**
- ✅ `time_step`
- ✅ `pitch_floor`
- ✅ `pitch_ceiling`
- ✅ `max_candidates` (NEW)
- ✅ `very_accurate` (NEW)
- ✅ `silence_threshold` (NEW)
- ✅ `voicing_threshold` (NEW)
- ✅ `octave_cost` (NEW)
- ✅ `octave_jump_cost` (NEW)
- ✅ `voiced_unvoiced_cost` (NEW)

**Performance:** 2x faster than Tier 1, same parameter coverage

**Legacy Function:** `to_pitch_direct()` kept for backward compatibility (basic params only)

**Status:** ✅ **RESOLVED** - Full parameter support available

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

### ✅ All Direct APIs Complete (v4.0.2)

- ✅ **Pitch Direct API** - Complete (NEW: `to_pitch_ac_direct()`, `to_pitch_cc_direct()`)
- ✅ **Formant Direct API** - Complete
- ✅ **Intensity Direct API** - Complete  
- ✅ **Harmonicity Direct API** - Complete

### Documentation Updated

- ✅ Updated `agents/AGENT_GUIDE.md` (v4.0.2)
- ✅ Updated `DIRECT_API_AUDIT.md` (this file)
- ✅ Benchmark available (`inst/benchmarks/17_pitch_api_tier_comparison.R`)
- ✅ Assessment complete (`DIRECT_API_PITCH_ASSESSMENT.md`)

---

## Conclusion

✅ **ALL Direct APIs now have complete parameter coverage** as of v4.0.2.

The new full-parameter pitch functions (`to_pitch_ac_direct()`, `to_pitch_cc_direct()`) fill the gap between Tier 1 and Tier 3, providing Direct API performance (2x faster than Tier 1) with full parameter control.

**API Landscape (v4.0.2):**
- **Tier 1:** Full features, R6 objects, good for interactive work
- **Tier 2:** Full features, external pointers, 2x faster, good for performance loops
- **Tier 3:** Full features, batch processing, fastest for >10 files

No limitations remain.

---

## Verification Details

**Verified:**
- ✅ R/praat-direct.R - Direct API wrappers
- ✅ R/RcppExports.R - C++ exports  
- ✅ R/sound-r6-new.R - Tier 1 (Standard) API
- ✅ R/batch-ops.R - Tier 3 (Batch) API
- ✅ src/sound_wrappers.cpp - C++ implementation

**Functional Testing:**
- ✅ `to_pitch_ac_direct()` tested with real audio files
- ✅ `to_pitch_cc_direct()` tested with real audio files
- ✅ Custom parameters verified to affect results
- ✅ External pointers successfully wrap in R6 Pitch objects

**Method:** Manual signature comparison + functional testing across all API tiers
