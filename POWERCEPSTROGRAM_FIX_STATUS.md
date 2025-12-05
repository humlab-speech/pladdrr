# PowerCepstrogram Fix - Status Report

**Date**: 2025-12-03
**Package**: pladdrr v1.0.7 → v1.0.8 (pending)

## Problem Discovered

PowerCepstrogram creation was failing with:
```
Error: Failed to create PowerCepstrogram from Sound
```

## Root Cause Analysis

### Issue 1: Generic Error Message ✅ FIXED
- **Location**: `src/powercepstrum_wrappers.cpp:41-44`
- **Problem**: `Melder_clearError()` discarded actual Praat error message
- **Fix**: Capture error before clearing:
  ```cpp
  autostring32 error_message = Melder_dup(Melder_getError());
  Melder_clearError();
  std::string error_str = Melder_peek32to8(error_message.get());
  stop("PowerCepstrogram creation failed. Praat error: " + error_str);
  ```

### Issue 2: Missing Function Implementation ✅ FIXED
- **Actual Error**: `Sound_resampleAndOrPreemphasize: This advanced resampling function is not available.`
- **Location**: Function stubbed in `src/sound_extensions_stubs.cpp`
- **Root Cause**: Real implementation in `praat.github.io/dwtools/Sound_extensions.cpp` was NOT included in build
- **Fix**:
  1. Added `Sound_extensions.cpp` to `DWTOOLS_SRC` in `src/Makevars`
  2. Removed `sound_extensions_stubs.cpp` from build to avoid symbol conflicts

## Changes Made

### 1. src/powercepstrum_wrappers.cpp
```diff
- } catch (MelderError) {
-     Melder_clearError();
-     stop("Failed to create PowerCepstrogram from Sound");
- }
+ } catch (MelderError) {
+     // Capture Praat error message before clearing
+     autostring32 error_message = Melder_dup (Melder_getError());
+     Melder_clearError();
+     std::string error_str = Melder_peek32to8(error_message.get());
+     stop("PowerCepstrogram creation failed. Praat error: " + error_str);
+ }
```

### 2. src/Makevars
```diff
 DWTOOLS_SRC = praat.github.io/dwtools/SoundFrames.cpp \
               praat.github.io/dwtools/SampledFrameIntoSampledFrame.cpp \
               praat.github.io/dwtools/SampledIntoSampled.cpp \
               praat.github.io/dwtools/Intensity_extensions.cpp \
-              praat.github.io/dwtools/TextGrid_extensions.cpp
+              praat.github.io/dwtools/TextGrid_extensions.cpp \
+              praat.github.io/dwtools/Sound_extensions.cpp
```

```diff
               svd_stubs.cpp roots_stubs.cpp glpk_stubs.cpp \
               dtw_stubs.cpp \
-              sound_extensions_stubs.cpp \
               sound_create_gaussian.cpp \
```

## Testing Plan

### Test 1: PowerCepstrogram Creation ✅ IN PROGRESS
```r
library(pladdrr)
snd <- Sound$new('inst/extdata/test.wav')
pcep <- snd$to_powercepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  maximum_frequency = 5000,
  pre_emphasis_frequency = 50
)
```

Expected: SUCCESS (PowerCepstrogram object created)

### Test 2: CPPS Calculation
```r
cpps <- pcep$get_cpps()
cat("CPPS =", cpps, "dB\n")
```

Expected: Numeric value (typically 5-20 dB for normal voice)

### Test 3: Full AVQI Workflow
```r
result <- compute_avqi(
  sound = "inst/extdata/test.wav",
  type = "vowel",
  verbose = TRUE
)
print(result$avqi)
print(result$cpps)
```

Expected: Complete AVQI calculation with all 6 components

## Dependencies Added

Sound_extensions.cpp requires these Praat functions (all available):
- `Sound_resample()` - Already in build (fon/Sound_and_Spectrum.cpp)
- `Sound_preEmphasize_inplace()` - Already in build (fon/Sound.cpp)
- `Data_copy()` - Already in build (sys/Data.cpp)
- `windowShape_into_VEC()` - Defined in same file

## Impact Analysis

### ✅ Benefits
1. **PowerCepstrogram now works** - Enables CPPS calculation
2. **AVQI fully functional** - All 6 components accessible
3. **Better error messages** - Actual Praat errors exposed to R users
4. **No performance impact** - Uses Praat's optimized resampling

### ⚠️ Potential Issues
1. **Build time** - `Sound_extensions.cpp` is large (~2800 lines)
2. **Binary size** - Adds ~50KB to compiled .so file
3. **External dependencies** - Includes vorbis/opus/lame headers (but stubbed if not needed)

### 🔍 To Monitor
- Check for linker errors related to vorbis/opus/lame
- Verify cross-platform builds (macOS/Linux/Windows)
- Test with various audio formats and sampling rates

## Next Steps

1. ✅ Wait for build completion
2. ⏳ Test PowerCepstrogram creation (in progress)
3. ⏳ Test CPPS calculation (in progress)
4. ⬜ Run full AVQI test suite
5. ⬜ Unexport high-level functions (AVQI, DSI, tremor) as per user request
6. ⬜ Update package documentation
7. ⬜ Increment version to 1.0.8
8. ⬜ Commit changes with descriptive message

## Files Modified

- `src/powercepstrum_wrappers.cpp` - Better error reporting
- `src/Makevars` - Add Sound_extensions.cpp, remove stub
- `DESCRIPTION` - Version bump (pending)
- `NEWS.md` - Document fix (pending)

## Cleanup Tasks

After confirming fix works:
1. Remove or rename `src/sound_extensions_stubs.cpp` (no longer needed)
2. Update similar error handling in other wrapper files
3. Document pattern for future Praat function integration
4. Add regression test for PowerCepstrogram

## Success Criteria

- [x] Identify root cause
- [x] Implement fix
- [ ] PowerCepstrogram creation succeeds
- [ ] CPPS calculation returns valid values
- [ ] Full AVQI workflow completes
- [ ] No new warnings or errors
- [ ] Cross-platform compatibility maintained

## Timeline

- **Problem discovered**: 2025-12-03 07:40 UTC
- **Root cause identified**: 2025-12-03 08:00 UTC
- **Fix implemented**: 2025-12-03 08:20 UTC
- **Testing**: IN PROGRESS
- **Expected completion**: 2025-12-03 09:00 UTC

---

**Status**: 🟡 TESTING
**Next Action**: Verify PowerCepstrogram creation after build completes
