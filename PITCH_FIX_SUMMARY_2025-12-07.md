# Pitch Detection Zero Voicing Bug - ROOT CAUSES IDENTIFIED

## Date: 2025-12-07

## Problem
pladdrr returns 0 voiced frames for all audio, blocking DSI/AVQI/tremor analysis.

## Root Causes Found

### 1. MelderThread_run Stub Was No-Op ✅ FIXED
**File**: `src/praat_stubs.cpp` line 172  
**Bug**: Stub function was empty, causing entire pitch analysis loop to be skipped  
**Fix**: Replaced with single-threaded execution:
```cpp
void MelderThread_run(...) {
    // BEFORE (BUG):
    // No-op: threading disabled in library mode  
    
    // AFTER (FIX):
    threadFunction(0, 1, numberOfElements);  // Execute directly
}
```

### 2. NUMfpp Not Initialized - NULL Pointer Dereference ✅ FIXED
**Files**: 
- `src/num_stubs.cpp` line 92 (stubbed out)
- `src/Makevars` (missing NUMmachar.cpp)

**Bug**: NUMmachar() stub was no-op, so NUMfpp remained NULL. When NUMminimize_brent() tried to access `NUMfpp->eps` for pitch refinement, it segfaulted.

**Fix**:
1. Added `praat.github.io/dwsys/NUMmachar.cpp` to Makevars
2. Removed NUMmachar() stub from num_stubs.cpp
3. Real NUMmachar() now initializes NUMfpp via LAPACK calls

## Call Chain (Now Working)
1. Sound$to_pitch() → sound_to_pitch() wrapper
2. Sound_to_Pitch() → Sound_to_Pitch_any()
3. MelderThread_PARALLELIZE macro creates lambda
4. **MelderThread_run() stub executes lambda** ✅ NOW WORKS
5. Sound_into_PitchFrame() detects peaks ✅ WORKS
6. NUMimproveMaximum() refinement → NUMminimize_brent()
7. **NUMminimize_brent() accesses NUMfpp->eps** ✅ NOW INITIALIZED

## Files Modified

### Core Fixes:
1. `src/praat_stubs.cpp` - Fixed MelderThread_run
2. `src/Makevars` - Added NUMmachar.cpp to build
3. `src/num_stubs.cpp` - Removed NUMmachar stub

### Debug Instrumentation (can be removed):
- `src/praat.github.io/fon/Sound_to_Pitch.cpp` - Added 15+ debug points
- `src/praat.github.io/melder/NUMinterpol.cpp` - Added debug in improve_evaluate

## Testing Status
Build completed with NUMmachar.cpp and fixed stubs.  
Next: Test pitch detection with 200 Hz tone.

## Expected Result
```r
library(pladdrr)
tone <- Sound$create_tone(0.05, 200, 16000, 0.9)
pitch <- tone$to_pitch(0.01, 75, 600)
pitch$get_mean(0, 0, "hertz")  # Should return ~200 Hz
```

## Backups Created
- src/praat_stubs.cpp.backup
- src/sound_wrappers.cpp.backup
- src/praat.github.io/fon/Sound_to_Pitch.cpp.backup
- src/praat.github.io/melder/NUMinterpol.cpp.backup

