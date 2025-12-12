# Session Summary: Pitch Strength & Intensity Implementation (2025-12-11)

## Status: ✅ COMPLETE

## What We Accomplished

### 1. Pitch Strength Methods (Commit: d1d132d) ✅
**Files Modified:**
- `src/pitch_wrappers.cpp` - Added 3 C++ wrappers for strength extraction
- `R/pitch-r6.R` - Added 3 R6 methods
- Auto-generated: `R/RcppExports.R`, `src/RcppExports.cpp`

**New Methods:**
```r
pitch$get_strength_at_time(time, unit = "hertz", interpolate = TRUE)
pitch$get_mean_strength(from_time, to_time, unit = "hertz") 
pitch$as_data_frame(include_strength = TRUE)
```

**Purpose:** Extract pitch candidate strength (periodicity/cyclicality) for FTrC and ATrC tremor metrics.

**Status:** Tested and working. Values range 0-1 as expected.

---

### 2. Pitch Frame Intensity Methods (Commit: 50094cf) ✅
**Files Modified:**
- `src/pitch_wrappers.cpp` - Added 2 C++ wrappers for intensity extraction
- `R/pitch-r6.R` - Added 2 R6 methods + updated as_data_frame()
- Auto-generated: `R/RcppExports.R`, `src/RcppExports.cpp`

**New Methods:**
```r
pitch$get_intensity_at_time(time)
pitch$get_mean_intensity(from_time, to_time)
pitch$as_data_frame(include_intensity = TRUE)
```

**Purpose:** Extract pitch frame intensity (acoustic amplitude) for FCoM and ACoM tremor metrics.

**Implementation Details:**
- Direct access to `Pitch_Frame->intensity` field (double)
- Used by Praat for acoustic magnitude measurement
- Distinct from strength (which measures cyclicality)

---

## Critical Discovery: Praat Pitch Frame Structure

### What We Found:
```cpp
// Praat Pitch_Frame structure (from Pitch_def.h)
#define ooSTRUCT Pitch_Frame
oo_DOUBLE (intensity)           // ← Acoustic magnitude (FCoM/ACoM)
oo_INTEGER (nCandidates)
oo_STRUCTVEC (Pitch_Candidate, candidates, nCandidates)
  ├─ frequency
  └─ strength                   // ← Cyclicality (FTrC/ATrC)
```

### Why This Matters:
The external analysis in `/tmp/TREMOR_R_*` revealed:
- **FCoM/ACoM** should use `frame->intensity` (contour magnitude)
- **FTrC/ATrC** should use `candidate[1].strength` (tremor cyclicality)

**Before this fix:**
- Our R/tremor.R was using max(strength) for FCoM ❌
- Missing pitch intensity methods entirely ❌

**After this fix:**
- FCoM/ACoM will use `pitch$get_intensity_at_time()` ✅
- FTrC/ATrC use `pitch$get_strength_at_time()` ✅

---

## Next Steps (IMMEDIATE)

### 1. Update R/tremor.R Implementation
**File:** `R/tremor.R` (uncommitted changes exist)

**Fix FCoM (line ~206):**
```r
# OLD (WRONG):
FCoM <- max(pitch_df$strength[voiced])

# NEW (CORRECT):
pitch_df <- pitch$as_data_frame(include_intensity = TRUE)
FCoM <- max(pitch_df$intensity[voiced])
```

**Fix ACoM (line ~327):**
```r
# OLD (WRONG):
# Using amplitude from intensity object

# NEW (CORRECT):
amp_contour <- pitch$as_data_frame(include_intensity = TRUE)$intensity
ACoM <- (max(amp_contour) - min(amp_contour)) / mean(amp_contour)
```

**Keep FTrC/ATrC (lines ~254, ~367):**
```r
# Already correct - use strength for cyclicality
FTrC <- .compute_tremor_cyclicality(pitch_df$strength)
ATrC <- .compute_tremor_cyclicality(amp_contour)
```

### 2. Test Complete Workflow
**Expected Values (sv1.wav):**
- FCoM ≈ 0.599 (not 0.359)
- FTrC ≈ 0.353
- ACoM ≈ 0.442
- ATrC ≈ varies

**Test Script:**
```r
library(pladdrr)
snd <- Sound$new("inst/signalfiles/AVQI/input/sv1.wav")
pitch <- snd$to_pitch_ac(...)
results <- compute_tremor_metrics(snd, pitch)
```

### 3. Commit All Changes
- Uncomm itted: `R/tremor.R`, test scripts, documentation
- After successful testing

---

## Technical Details

### C++ Implementation Highlights:

**Intensity Extraction:**
```cpp
// Direct field access (no Praat API function exists)
Pitch_Frame frame = &pitch->frames[iframe];
return frame->intensity;  // Raw double value
```

**Mean Intensity Computation:**
```cpp
// Find frame range, iterate, average non-zero values
for (integer i = ifrom; i <= ito; i++) {
    Pitch_Frame frame = &pitch->frames[i];
    if (frame->intensity > 0.0) {
        sum += frame->intensity;
        count++;
    }
}
return (count > 0) ? (sum / count) : NA_REAL;
```

### R6 API Design:

**Consistency with existing methods:**
- `get_*_at_time()` pattern for single point queries
- `get_mean_*()` pattern for range statistics
- `as_data_frame(include_* = TRUE)` for bulk export

**Parameters:**
- Intensity methods don't need `unit` parameter (raw magnitude)
- Strength methods keep `unit` for consistency (though not frequency-dependent)

---

## Package Status

**Version:** pladdrr 1.2.2  
**Branch:** 001-praat-r-access  
**Commits Ahead:** 15 (d1d132d + 50094cf)  
**Build Status:** ✅ Successful (18 warnings, 0 errors)

**Warnings:** Standard Rcpp incomplete type warnings (harmless)

---

## Key Files

### Committed (2 commits):
1. **d1d132d** - Pitch strength methods
   - `src/pitch_wrappers.cpp`
   - `R/pitch-r6.R`
   - Auto-generated exports

2. **50094cf** - Pitch intensity methods
   - `src/pitch_wrappers.cpp`
   - `R/pitch-r6.R`
   - Auto-generated exports

### Uncommitted (needs fixing):
- `R/tremor.R` - Has FCoM/ACoM/FTrC/ATrC implementations (needs intensity fix)
- `test_tremor_fixed.R` - Test script
- `TREMOR_METRICS_FIX.md` - Documentation
- Various session summaries

---

## Conclusion

We successfully implemented BOTH strength and intensity extraction from Praat Pitch objects:

1. ✅ **Strength methods** - For cyclicality measurement (FTrC/ATrC)
2. ✅ **Intensity methods** - For magnitude measurement (FCoM/ACoM)

The R/tremor.R file can now be corrected to use the proper metrics:
- FCoM/ACoM → `pitch$get_intensity_at_time()` (contour magnitude)
- FTrC/ATrC → `pitch$get_strength_at_time()` (tremor cyclicality)

**Next Action:** Update R/tremor.R with correct metric implementations, test, and commit.
