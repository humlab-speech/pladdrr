# pladdrr Critical Bugs Status (2025-12-07)

## TWO CRITICAL BUGS IDENTIFIED

### Bug 1: PITCH DETECTION CRASH ❌ (BLOCKING ALL VOICE ANALYSIS)

**Status**: ACTIVE BUG in v1.1.5  
**Severity**: CRITICAL - Complete package failure  
**Affects**: DSI, AVQI, tremor, jitter, shimmer, HNR, ALL pitch-based analysis  

**Crash**:
```r
sound <- Sound$create_tone(frequency = 100, duration = 0.1, sampling_rate = 16000)
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 50, pitch_ceiling = 800)
# *** caught segfault ***
# address 0x20, cause 'invalid permissions'
```

**Root Cause**: NULL function pointer in `NUMminimize_brent` during Brent optimization  
**Location**: `src/praat.github.io/melder/NUMinterpol.cpp` line 377  
**Evidence**: Debug shows "Calling brent" but `improve_evaluate` never called (pointer is NULL)  

**Action Taken**: Added enhanced debug output to identify NULL pointer  
**Next**: Rebuild and test to confirm function pointer is NULL, then fix linkage issue  

---

### Bug 2: FORMANT EXTRACTION CRASH ✅ (FIXED)

**Status**: FIXED in this session  
**Test Result**: ✅ SUCCESS - 190 frames extracted from test.wav  

**Fixed By**:
- Added Roots.cpp (polynomial root finding)
- Added NUMsorting.cpp (formant tracking)
- Initialized NUMmachar() and RNG
- Created table_stubs.cpp for SSCP/PCA

**Files Modified**: 11 files ready to commit (see FORMANT_FIX_SUMMARY)  

---

## Priority

1. ❌ **FIX PITCH CRASH FIRST** - Package completely unusable without this
2. ✅ Then commit formant fixes
3. Release v1.1.6 with both fixes

**Cannot proceed with DSI/AVQI/tremor implementations until pitch crash is fixed.**

See:
- PLADDRR_1.1.5_STATUS.md - Detailed pitch crash analysis
- FORMANT_FIX_SUMMARY_2025-12-07.md - Formant fix details
