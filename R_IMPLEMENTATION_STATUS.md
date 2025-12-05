# R Implementation Status for plabench Benchmarking

**Date:** 2025-12-03
**System:** macOS 25.1.0, R 4.4.2, pladdrr 1.0.7

## Executive Summary

Investigation into using **pladdrr** (R package for Praat functionality) to create R implementations of AVQI, DSI, and tremor for benchmarking against Python (Parselmouth) and Praat scripts.

**Current Status:** ⚠️ **PARTIALLY BLOCKED** - pladdrr has critical bugs in key functions

---

## pladdrr Package Analysis

### Version Information
```
Package: pladdrr
Version: 1.0.7
Date: 2025-11-29
Description: Object-Oriented Interface to Praat Phonetic Analysis
Built: R 4.4.2; aarch64-apple-darwin20; 2025-12-02
```

### What Works ✅

| Feature | Status | Notes |
|---------|--------|-------|
| **Sound loading** | ✓ Works | `Sound$new(file.wav)` |
| **Concatenation** | ✓ Works | `sound$concatenate(other_sound)` |
| **Basic properties** | ✓ Works | Duration, sampling rate, channels |
| **Pitch extraction** | ✓ Works | `sound$to_pitch()` |
| **Intensity** | ✓ Works | `sound$to_intensity()` |
| **Harmonicity** | ✓ Works | `sound$to_harmonicity_ac()` with correct params |
| **LTAS** | ✓ Works | `sound$to_ltas()` |
| **Spectrum** | ✓ Works | `sound$to_spectrum()` |
| **PointProcess** | ✓ Works | `sound$to_pointprocess_periodic_cc()` |
| **Shimmer/Jitter** | ✓ Works | `pointprocess$get_shimmer_local()`, `get_jitter_ppq5()` |

### What Doesn't Work ❌

| Feature | Status | Error | Impact |
|---------|--------|-------|--------|
| **PowerCepstrogram** | ✗ Broken | "Failed to create PowerCepstrogram from Sound" | **Blocks AVQI** (needs CPPS) |
| **compute_avqi()** | ✗ Broken | Same PowerCepstrogram error | High-level AVQI blocked |
| **compute_dsi()** | ✗ Broken | "Expecting an external pointer: [type=NULL]" | High-level DSI blocked |

---

## Implementation Feasibility Assessment

### AVQI Implementation

**Status:** ⚠️ **BLOCKED by PowerCepstrogram bug**

AVQI requires 6 acoustic measures:
1. **CPPS** (Smoothed Cepstral Peak Prominence) - ❌ **BLOCKED** - requires PowerCepstrogram
2. **HNR** (Harmonics-to-Noise Ratio) - ✅ Available via `to_harmonicity_ac()`
3. **Shimmer Local** - ✅ Available via PointProcess `get_shimmer_local()`
4. **Shimmer Local dB** - ✅ Available via PointProcess `get_shimmer_local_db()`
5. **LTAS Slope** - ⚠️ Partial - LTAS works, but slope calculation method unclear
6. **LTAS Tilt** - ⚠️ Partial - Need trend line computation

**Blockers:**
- CPPS calculation requires PowerCepstrogram which fails in pladdrr 1.0.7
- This is a **critical blocker** - AVQI cannot be implemented without CPPS

**Workaround Options:**
1. Wait for pladdrr package fix (requires package maintainer)
2. Use Praat scripts directly from R via `system()` calls
3. Skip R/AVQI benchmarking (only compare Python vs Praat)

### DSI Implementation

**Status:** ✅ **FEASIBLE** - Can be implemented with current pladdrr

DSI requires 4 measurements:
1. **MPT** (Maximum Phonation Time) - ✅ Available via `sound$get_duration()`
2. **F0-high** (Highest F0) - ✅ Available via `pitch$get_maximum()`
3. **I-low** (Minimum Intensity) - ✅ Available via `intensity$get_minimum()`
4. **Jitter ppq5** - ✅ Available via `pointprocess$get_jitter_ppq5()`

**All components available!** DSI can be fully implemented.

### tremor Implementation

**Status:** ✅ **FEASIBLE** - Complex but possible

tremor requires:
- Pitch extraction - ✅ Available
- Amplitude extraction - ✅ Available via Intensity or Spectrum
- Autocorrelation analysis - ⚠️ Need to verify Matrix/Sound conversion
- Tremor frequency/intensity calculations - ✅ Can compute from extracted contours

**Likely feasible** but requires careful implementation of contour-to-signal conversion.

---

## Recommended Path Forward

### Option A: Implement What Works (DSI + tremor)

**Pros:**
- Can benchmark DSI and tremor across all three implementations
- Demonstrates pladdrr capabilities
- Provides useful performance data

**Cons:**
- Missing AVQI comparison (most complex metric)
- Incomplete benchmarking suite

### Option B: Use Praat Console Scripts for All (Python + Praat only)

**Pros:**
- Complete benchmarking of all three tools
- No dependency on buggy pladdrr functions
- Can create console versions of AVQI/DSI Praat scripts

**Cons:**
- Doesn't test R/pladdrr performance
- More work to create console scripts

### Option C: Hybrid Approach (RECOMMENDED)

**Implement:**
1. ✅ **DSI in R** - Fully working, all components available
2. ✅ **tremor in R** - Feasible with current API
3. ✅ **Console Praat scripts** for AVQI and DSI (for Praat benchmarking)
4. ⏸️ **Skip R/AVQI** - Document as blocked by pladdrr bug

**Benchmarking Matrix:**

| Tool | Python/Parselmouth | R/pladdrr | Praat Console |
|------|-------------------|-----------|---------------|
| **AVQI** | ✅ Working | ❌ Blocked | ✅ Create script |
| **DSI** | ✅ Working | ✅ Implement | ✅ Create script |
| **tremor** | ✅ Working | ✅ Implement | ✅ Already exists |

**Result:**
- Full 3-way comparison for DSI and tremor
- 2-way comparison for AVQI (Python + Praat)
- Documents pladdrr limitations for bug report

---

## Next Steps

### Immediate (Today)

1. ✅ Create R implementation of **DSI** using pladdrr low-level API
2. ✅ Create R implementation of **tremor** using pladdrr low-level API
3. ✅ Create console version of **DSI201.praat**
4. ✅ Create console version of **AVQI301.praat**
5. ⚠️ Test R implementations against Python for numerical accuracy
6. 📊 Run comprehensive benchmarks

### Future (After pladdrr Fix)

1. Report PowerCepstrogram bug to pladdrr maintainer (fredrik.nylen@umu.se)
2. Implement R/AVQI once PowerCepstrogram is fixed
3. Re-run benchmarks with complete 3-way comparison

---

## Technical Notes

### pladdrr API Quirks Discovered

1. **Parameter naming differences from Parselmouth:**
   - Parselmouth: `minimum_pitch` → pladdrr: `min_pitch`
   - Parselmouth: `maximum_pitch` → pladdrr: `pitch_ceiling`

2. **Method signatures:**
   ```r
   # Correct pladdrr usage:
   harm <- sound$to_harmonicity_ac(
     time_step = 0.01,
     min_pitch = 75,  # NOT minimum_pitch
     silence_threshold = 0.1,
     periods_per_window = 1.0
   )

   pp <- sound$to_pointprocess_periodic_cc(
     pitch_floor = 75,      # NOT minimum_pitch
     pitch_ceiling = 600    # NOT maximum_pitch
   )
   ```

3. **PointProcess shimmer/jitter methods available:**
   - `get_shimmer_local()` - Returns shimmer as decimal (multiply by 100 for %)
   - `get_shimmer_local_db()` - Returns shimmer in dB
   - `get_jitter_ppq5()` - Returns jitter ppq5 as decimal
   - `get_jitter_local()`, `get_jitter_rap()`, `get_jitter_ddp()` also available

4. **Voice report available:**
   ```r
   report <- pointprocess$voice_report(
     sound = sound,
     pitch = pitch,
     time_range_start = 0,
     time_range_end = 0,
     floor = 75,
     ceiling = 600,
     maximum_period_factor = 1.3,
     maximum_amplitude_factor = 1.6,
     silence_threshold = 0.03,
     voicing_threshold = 0.45
   )
   ```

---

## Files Created

1. **R_implementations/avqi.R** - Skeleton AVQI implementation (blocked by PowerCepstrogram)
2. **R_IMPLEMENTATION_STATUS.md** - This document

---

## Conclusion

**pladdrr version 1.0.7 has critical bugs** that block AVQI implementation but **DSI and tremor are fully feasible**.

**Recommended:** Proceed with hybrid approach - implement DSI and tremor in R, create Praat console scripts for all three tools, and benchmark what's possible while documenting the AVQI blocker.

This provides valuable performance data for 2 out of 3 tools across all implementations, plus Python vs Praat comparison for AVQI.
