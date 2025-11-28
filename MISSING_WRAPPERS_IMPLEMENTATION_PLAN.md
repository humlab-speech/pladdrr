# Missing Praat Wrappers - Implementation Assessment & Plan

**Date**: 2025-11-28
**Source Documents**:
- MISSING_PRAAT_CPP_WRAPPERS_2025-11-27.md
- COMPREHENSIVE_FINAL_ASSESSMENT_2025-11-27.md
- ADVANCED_PRAAT_FUNCTIONS_ANALYSIS_2025-11-27.md

---

## Executive Summary

After analyzing the assessment documents, the missing Praat wrappers fall into clear categories:

### ✅ Can Implement (Praat C++ Functions Exist)
**Priority**: HIGH - Core voice analysis functions

### ⏸️ Should NOT Implement (User Requirements Violated)
**Reason**: Not direct Praat C++ exposures or interactive/GUI features

### ❌ Cannot Implement (Not in Praat Source)
**Reason**: Third-party algorithms or stubs

---

## Analysis Results

### Category 1: HIGH PRIORITY - Voice Quality Analysis ✅

**Functions from `Sound_to_PointProcess.h`** (Exist in Praat source):

1. `Sound_to_PointProcess_periodic_cc()` - Periodic pulse via cross-correlation
2. `Sound_to_PointProcess_periodic_peaks()` - Periodic pulse via peak finding

**Impact**: 20-25% of archive scripts (jitter, shimmer, voice quality)
**Status**: ✅ EXISTS in `src/praat.github.io/fon/Sound_to_PointProcess.cpp`
**Recommendation**: **IMPLEMENT** - Direct C++ function wrappers

---

### Category 2: MEDIUM PRIORITY - LPC Inverse Filtering ✅

**Function from `Sound_and_LPC.h`**:

3. `LPC_Sound_filterInverseWithFilterAtTime()` - Extract voice source

**Impact**: 5-8% of archive scripts (glottal flow analysis)
**Status**: ✅ EXISTS in `src/praat.github.io/LPC/Sound_and_LPC.cpp`
**Recommendation**: **IMPLEMENT** - Direct C++ function wrapper

---

### Category 3: MEDIUM PRIORITY - MFCC ✅

**Functions from `Sound_to_MFCC.h`**:

4. `Sound_to_MFCC()` - Mel-frequency cepstral coefficients

**Impact**: 5-8% of archive scripts (speech recognition)
**Status**: ✅ EXISTS in `src/praat.github.io/dwtools/MFCC.h`
**Recommendation**: **CONSIDER** - Useful but R alternatives exist

---

### Category 4: LOW PRIORITY - Convenience Methods ⏸️

**Functions**:

5. `Sound_to_PointProcess_maxima()` - Peak detection (no parameters)
6. `Sound_to_PointProcess_minima()` - Trough detection (no parameters)

**Impact**: 15-20% of archive scripts
**Status**: ✅ EXISTS but `Sound_to_PointProcess_extrema()` already wraps this
**Recommendation**: **SKIP** - Already have wrapper with parameters

---

### Category 5: EXCLUDE - Data Export ❌

**Function**:

7. `TextGrid_downto_Table()` - Export to Table format

**Reason**: **Violates user requirement** - This is data transformation, not acoustic analysis
**Better Solution**: R native functions are superior
```r
# R is better at this:
df <- tg$as_data_frame()  # Already exists!
write.csv(df, "output.csv")
```
**Recommendation**: **DO NOT IMPLEMENT** - Use R's existing `as_data_frame()`

---

### Category 6: EXCLUDE - Interactive/GUI Features ❌

Based on user requirements to exclude:
- FormantGrid interactive formulas
- Demo window functions  
- Editor window operations
- Manual annotation tools

**Recommendation**: **DO NOT IMPLEMENT** - Per user exclusion criteria

---

## Implementation Plan

### Phase 1: Voice Quality Analysis (HIGH PRIORITY) 🔴

**Estimated Time**: 1-2 days

**Tasks**:
1. Add C++ wrappers to `src/pointprocess_wrappers.cpp`:
   - `sound_to_pointprocess_periodic_cc()`
   - `sound_to_pointprocess_periodic_peaks()`

2. Add R6 methods to `R/sound-r6.R`:
   - `Sound$to_pointprocess_periodic_cc(fmin, fmax)`
   - `Sound$to_pointprocess_periodic_peaks(fmin, fmax, include_maxima, include_minima)`

3. Add tests

**Impact**: Enables 20-25% more archive scripts

---

### Phase 2: LPC Inverse Filtering (MEDIUM PRIORITY) 🟡

**Estimated Time**: 1 day

**Tasks**:
1. Add C++ wrapper to `src/lpc_wrappers.cpp`:
   - `lpc_sound_filter_inverse_with_filter_at_time()`

2. Add R6 method to `R/lpc-r6.R`:
   - `LPC$filter_inverse_with_filter_at_time(sound, channel, time)`

3. Add tests

**Impact**: Enables 5-8% more archive scripts

---

### Phase 3: MFCC (OPTIONAL) 🟢

**Estimated Time**: 2-3 days (more complex)

**Tasks**:
1. Verify MFCC.cpp is compiled (check Makevars)
2. Add C++ wrappers to `src/mfcc_wrappers.cpp` (NEW FILE):
   - `sound_to_mfcc()`
   - `mfcc_to_matrix()`

3. Create R6 class `R/mfcc-r6.R` (NEW FILE)

4. Add tests

**Impact**: Enables 5-8% more archive scripts
**Note**: R packages (tuneR, phonTools) have MFCC, but Praat's version ensures consistency

---

## Verification Checklist

Before implementing, verify each function:

- [ ] Exists in `src/praat.github.io/` source code (not a stub)
- [ ] Is non-interactive (no GUI, no user input)
- [ ] Is not data export/transformation (R does this better)
- [ ] Is acoustic analysis or signal processing
- [ ] Has real implementation (not just a wrapper to other functions)

---

## Expected Outcomes

### Coverage Improvement

**Before**: 92% of programmatic Praat use cases (after v1.0.5)

**After Phase 1**: ~95% (voice quality analysis enabled)
**After Phase 2**: ~96% (LPC inverse filtering enabled)  
**After Phase 3**: ~97% (MFCC enabled)

**Remaining 3%**:
- Interactive features (excluded by design)
- Third-party algorithms not in Praat (DTW, etc.)
- Batch processing (R native is superior)

---

## Recommendations

### Implement Now (v1.0.6)
1. ✅ `Sound_to_PointProcess_periodic_cc()`
2. ✅ `Sound_to_PointProcess_periodic_peaks()`

**Reason**: High impact (25% of scripts), low complexity (1-2 days)

### Consider for v1.1.0
3. ⏸️ `LPC_Sound_filterInverseWithFilterAtTime()`
4. ⏸️ `Sound_to_MFCC()`

**Reason**: Moderate impact, more complex

### Do NOT Implement
5. ❌ `TextGrid_downto_Table()` - Use R's `as_data_frame()`
6. ❌ Interactive/GUI features - Per user exclusion
7. ❌ Convenience methods already covered by existing wrappers

---

## Conclusion

The assessment documents identify legitimate gaps, but many are:
1. Already covered by existing wrappers with different signatures
2. Better handled by R native functions
3. Interactive features excluded by user requirements

**Actionable Items**: 2-4 high-value wrappers that would boost coverage to ~95-97%

**Recommendation**: Implement Phase 1 (voice quality) in v1.0.6, defer others to v1.1.0

