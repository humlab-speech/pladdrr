# FTrI Implementation Fix - Session Summary

## Date: 2025-12-12

## Problem
FTrI was returning 0.0000% instead of expected 2.1697% due to missing `Sound$from_values()` `start_time` parameter.

## Root Cause
1. Brückl's algorithm requires creating a Sound object from normalized F0 contour
2. `Sound$from_values()` existed but didn't support `start_time` parameter
3. Code was trying to use non-existent `Sound$new_from_values()` method
4. Without proper timing, peak detection couldn't work correctly

## Changes Made

### 1. Added `start_time` parameter to C++ wrapper
**File**: `src/sound_wrappers.cpp` (lines 80-118)
- Added `start_time` parameter with default value 0.0
- Set Sound object's `xmin`, `xmax`, and `x1` based on start_time
- Ensures Sound object has correct time axis alignment

### 2. Updated R6 static method
**File**: `R/sound-r6-new.R` (lines 1209-1227, 1229-1237)
- Added `start_time` parameter to `Sound$from_values()`
- Updated documentation
- Added alias `Sound$new_from_values()` for clarity

### 3. Fixed tremor analysis calls
**File**: `R/tremor.R` (lines 236-241, 391-397)
- Added `start_time = min(times)` to both frequency and amplitude tremor
- Ensures F0/amplitude contours align with original pitch extraction times

## Algorithm Verification

Tested peak detection in isolation with simulated 4 Hz tremor:
```r
f0_normalized <- sin(2 * pi * seq(0, 2.73, length.out = 274) * 4) * 0.025
# Found 11 maxima, 11 minima
# FTrI: 2.4951%  ✅ CORRECT ORDER OF MAGNITUDE
```

## Next Steps

1. **Rebuild package** (long process ~2 min):
   ```bash
   cd /Users/frkkan96/Documents/src/pladdrr
   R CMD INSTALL --preclean .
   ```

2. **Run test script**:
   ```bash
   Rscript test_ftri_fixed.R
   ```

3. **Expected Results**:
   - FTrI: ~2.17% (error < 5%)
   - Sound$from_values with start_time works correctly
   - Peak detection finds tremor oscillations

## Technical Details

### Brückl's FTrI Algorithm (Implemented)
1. Extract F0 from audio (voiced frames only)
2. Detrend: `f0_detrended = f0 - loess(f0)`
3. Normalize: `f0_normalized = f0_detrended / mean(f0)`
4. Create Sound from normalized contour with correct timing
5. Find local maxima/minima using `diff(sign(diff()))`
6. Calculate:
   - `tri_max = 100 × mean(|maxima_values|)`
   - `tri_min = 100 × mean(|minima_values|)`
   - `FTrI = (tri_max + tri_min) / 2`

### Why Previous Attempts Failed
- **Praat PointProcess**: Normalized contour [-0.2 to 0.04] isn't periodic → 0 voiced frames
- **Missing start_time**: Time axis misalignment prevented correct peak detection
- **Wrong method name**: `new_from_values()` didn't exist, code would hang

## Files Modified
1. `src/sound_wrappers.cpp` - Add start_time support (6 lines)
2. `R/sound-r6-new.R` - Update static method + docs (10 lines)
3. `R/tremor.R` - Add start_time in 2 calls (4 lines)
4. `test_ftri_fixed.R` - New test script (created)

## Commit Message
```
Fix FTrI: add start_time to Sound$from_values()

- Add start_time parameter to .sound_create_from_values() C++ wrapper
- Update Sound$from_values() R6 method with start_time
- Pass min(times) as start_time in tremor analysis
- Add Sound$new_from_values() alias for clarity
- Enables correct time alignment for peak detection in normalized F0 contour
```

## Status
✅ Code changes complete
⏳ Awaiting package rebuild
🎯 Expected: FTrI error < 5% (currently 100%)
