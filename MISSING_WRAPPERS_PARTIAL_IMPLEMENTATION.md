# Missing Praat Wrappers - Partial Implementation

**Date**: 2025-11-28
**Status**: ⏸️ **PARTIAL** - C++ wrappers added, R6 integration needs debugging
**Package Version**: Targeting v1.0.6

---

## Summary

Implemented C++ wrappers for the 2 highest-priority missing Praat functions identified in the assessment documents. These functions enable voice quality analysis (jitter, shimmer) workflows used in 20-25% of archive scripts.

---

## What Was Implemented ✅

### C++ Wrappers Added

**File**: `src/sound_wrappers.cpp` (+60 lines)

1. **`sound_to_pointprocess_periodic_cc()`**
   - Wraps: `Sound_to_PointProcess_periodic_cc()` from Praat source
   - Function: Periodic pulse detection via cross-correlation
   - Parameters: `(sound_xptr, pitch_floor, pitch_ceiling)`
   - Use case: Voice quality analysis (jitter, shimmer, HNR)

2. **`sound_to_pointprocess_periodic_peaks()`**
   - Wraps: `Sound_to_PointProcess_periodic_peaks()` from Praat source
   - Function: Periodic pulse detection via peak finding
   - Parameters: `(sound_xptr, pitch_floor, pitch_ceiling, include_maxima, include_minima)`
   - Use case: Alternative voice quality method

### Build Status

✅ **Compiles successfully** (`R CMD INSTALL --preclean .`)
✅ **Rcpp exports generated**
✅ **Functions callable from C++ layer**

---

## Known Issue ⏸️

### R6 Method Access Problem

**Symptom**: "attempt to apply non-function" error when calling Sound methods

**Root Cause**: Unknown - same issue encountered with TextGrid methods in v1.0.5
- Methods exist in R6 class definition
- `str(object$method)` shows they're functions
- But calling them throws "attempt to apply non-function"

**Workaround**: Methods can be called via internal `.` functions:
```r
# Doesn't work:
# pp <- sound$to_pointprocess_periodic_cc(75, 600)

# Works:
pp_ptr <- .sound_to_pointprocess_periodic_cc(sound$.__enclos_env__$private$ptr, 75.0, 600.0)
pp <- PointProcess$new(.xptr = pp_ptr)
```

**Note**: This issue affects BOTH new and existing Sound methods, suggesting a broader R6/package loading problem.

---

## Assessment of Other Missing Functions

### Implemented (2 functions) ✅
1. ✅ `Sound_to_PointProcess_periodic_cc()`
2. ✅ `Sound_to_PointProcess_periodic_peaks()`

### Should NOT Implement (Per User Requirements) ❌

3. ❌ **`TextGrid_downto_Table()`**
   - **Reason**: Data export, not acoustic analysis
   - **Better solution**: R native (`tg$as_data_frame()` already exists)
   - **User requirement**: "actual implementations of functionality of src/praat.github.io, not data transformation"

4. ❌ **`Pitch_to_Sound()` / `Pitch_to_Sound_sine()`**
   - **Reason**: Synthesis, not analysis
   - **Status**: Low priority for research workflows
   - **Can defer**: To future release if user requests

5. ❌ **`Spectrum_to_Formant()`**
   - **Reason**: Alternative method (LPC is standard)
   - **Status**: Specialized use case (<5% of scripts)
   - **Can defer**: To future release

### Consider for Future (2 functions) ⏸️

6. ⏸️ **`LPC_Sound_filterInverseWithFilterAtTime()`**
   - **Impact**: 5-8% of scripts (glottal flow analysis)
   - **Status**: ✅ EXISTS in Praat source
   - **Recommendation**: v1.1.0

7. ⏸️ **`Sound_to_MFCC()`**
   - **Impact**: 5-8% of scripts (speech recognition)
   - **Status**: ✅ EXISTS in Praat source  
   - **Recommendation**: v1.1.0 (R alternatives exist: tuneR, phonTools)

---

## Impact Assessment

### Coverage

**Before v1.0.5**: 85% of programmatic use cases
**After v1.0.5**: 92% (TextGrid automation + audio quality)
**After v1.0.6** (when R6 issue fixed): **~95%** (voice quality analysis enabled)

### Enabled Workflows (When Functional)

1. ✅ Jitter analysis (local, RAP, PPQ5, DDP)
2. ✅ Shimmer analysis (local, APQ3, APQ5, APQ11, DDA)
3. ✅ Voice quality assessment (TEVA, other toolkits)
4. ✅ Glottal pulse timing analysis
5. ✅ Alternative to Pitch_to_PointProcess() pathway

---

## Files Modified

### C++
- `src/sound_wrappers.cpp` (+60 lines) - 2 new wrapper functions
- `src/RcppExports.cpp` (auto-generated)

### R
- `R/sound-r6-new.R` - Methods already exist (!)
- `R/RcppExports.R` (auto-generated)

### Documentation
- `MISSING_WRAPPERS_IMPLEMENTATION_PLAN.md` - Analysis & plan
- `MISSING_WRAPPERS_PARTIAL_IMPLEMENTATION.md` - This file

---

## Next Steps

### Immediate (Debug R6 Issue)

1. **Investigate R6 method access problem** (affects multiple classes)
   - Check if related to package loading
   - Compare with working methods
   - Test in fresh R session

2. **Fix or document workaround**
   - If fixable: Update R6 classes
   - If structural: Document internal function usage

### Future Releases

**v1.0.7** (if R6 fixed):
- Test and document new voice quality workflows
- Add examples for jitter/shimmer analysis

**v1.1.0** (Optional):
- `LPC_Sound_filterInverseWithFilterAtTime()`
- `Sound_to_MFCC()`
- Additional specialized functions

---

## Testing (When R6 Fixed)

Planned test workflow:
```r
library(pladdrr)

# Load voice sample
sound <- Sound$new("voice.wav")

# Extract periodic pulses (cross-correlation method)
pp_cc <- sound$to_pointprocess_periodic_cc(
  pitch_floor = 75,
  pitch_ceiling = 600
)

# Calculate voice quality metrics
# (This would use PointProcess_Sound_voiceReport which already exists)
quality <- pp_cc$get_voice_report(sound, time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)

# Access jitter/shimmer
print(quality$jitter_local)
print(quality$shimmer_local)
```

---

## Conclusion

**Implemented**: 2 high-value C++ wrappers for voice quality analysis
**Status**: Compiles but R6 method access blocked by existing package issue
**Next**: Debug R6 problem (affects v1.0.5 TextGrid methods too)
**Impact**: When functional, increases coverage from 92% to ~95%

**Recommendation**: 
- Focus on fixing R6 method access issue (affects multiple releases)
- Once fixed, both v1.0.5 and v1.0.6 features will be fully functional
- Defer additional wrappers (LPC, MFCC) to v1.1.0

---

**Implemented by**: Claude (GitHub Copilot CLI)
**Date**: 2025-11-28
**Next Session**: Debug R6 method access across package

