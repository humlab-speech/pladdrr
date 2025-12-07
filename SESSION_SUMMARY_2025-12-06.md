# Pladdrr Pitch Detection Bug - Investigation Summary
**Date**: 2025-12-06  
**Session Focus**: Critical pitch detection failure blocking DSI/AVQI/tremor workflows

---

## Executive Summary

**TWO BUGS IDENTIFIED** - One fixed ✅, one critical ❌:

### Bug #1: Audio Normalization ✅ FIXED
- **Problem**: Audio loaded at ±30,000 scale instead of ±1.0
- **Root Cause**: `av::read_audio_bin()` returns non-standard scale, `bit_depth` is NULL
- **Fix Applied**: Added normalization in `Sound$new()` (R/sound-r6-new.R:125-130)
- **Status**: FIXED in commit 539b5c2, installed and working

### Bug #2: Pitch Detection Algorithm Failure ❌ CRITICAL
- **Problem**: ALL pitch detection methods return 0 voiced frames
- **Scope**: Affects ALL audio (synthesized + file-loaded), ALL methods (AC/CC/filtered)
- **Evidence**: Pure 200 Hz sine wave → 0 voiced frames (expected: 98%)
- **Return Value**: NaN (not NA) from `Pitch_getValueAtTime()`
- **Impact**: BLOCKS all voice quality analysis (DSI, AVQI, tremor, jitter, shimmer)

---

## Bug #2 Investigation Details

### Symptoms

1. **Zero Voicing Across All Conditions**:
   - Pure 200 Hz sine wave: 0/97 voiced frames ❌
   - Pure 440 Hz sine wave: 0/130 voiced frames ❌  
   - Pure 100 Hz sine wave: 0/63 voiced frames ❌
   - Real speech (ppq1.wav): 0/286 voiced frames ❌

2. **Sound Object is PERFECT**:
   ```
   Duration: 1.0s, Sample rate: 16000 Hz
   RMS: 0.636, Range: -0.899 to +0.899
   Audio data verified correct
   ```

3. **Pitch Object Created Successfully**:
   ```
   Frames: 97 (correct based on time_step)
   Time step: 0.01 (as requested)
   Pitch floor: 75 Hz
   Pitch ceiling: 600 Hz
   ```

4. **All Methods Return NaN**:
   ```r
   pitch$get_value_at_time(0.1) → NaN
   pitch$get_mean() → NaN
   pitch$as_data_frame() → all NA (converted from NaN)
   ```

### What Works

- ✅ Sound object creation (both file-loaded and synthesized)
- ✅ Audio data correct (RMS, range, samples all valid)
- ✅ Pitch object creation (no errors, correct frame count)
- ✅ Basic pitch queries (don't crash, return NaN)
- ✅ Normalization fix (audio now in ±1.0 range)

### What Fails

- ❌ Pitch detection algorithm finds NO voicing in pure sine waves
- ❌ `Pitch_getValueAtTime()` returns NaN for all frames
- ❌ All pitch candidates have frequency = 0 or out of range
- ❌ Autocorrelation not finding periodicity
- ❌ Cross-correlation also failing

---

## Root Cause Hypotheses

### Hypothesis 1: Sound Data Not Accessible to Algorithm ⭐⭐⭐
**Likelihood**: HIGH

**Evidence**:
- Sound object creation uses `Sound_createSimple()` + `memcpy` to `z` matrix
- Pitch detection may not be reading from `sound->z[1][i]` correctly
- Both file-loaded AND synthesized sounds fail identically

**Test**:
- Create pure tone with Praat's `Sound_createSimple()` directly
- Check if `z` matrix pointer is valid
- Verify `sound->nx`, `sound->dx`, `sound->x1` values

**If True**:
- Fix: Ensure `z` matrix is properly allocated and accessible
- Check memory layout compatibility between R and Praat

### Hypothesis 2: Autocorrelation Algorithm Broken in Build ⭐⭐
**Likelihood**: MEDIUM

**Evidence**:
- ALL pitch methods fail (AC, CC, filtered AC)
- NaN return suggests algorithm runs but finds nothing
- May be SIMD/vectorization issue

**Test**:
- Compare build flags with working Parselmouth build
- Check if NUM library compiled correctly
- Verify autocorrelation SIMD code

**If True**:
- Fix: Rebuild with different compiler flags
- Check SIMD implementations in `src/*_simd.cpp`

### Hypothesis 3: Praat Version Incompatibility ⭐
**Likelihood**: LOW

**Evidence**:
- Praat source is from specific commit
- Algorithm API may have changed
- Wrapper calls may be passing wrong parameters

**Test**:
- Check Praat version/commit hash
- Compare with Parselmouth's Praat version
- Verify function signatures match

**If True**:
- Fix: Update Praat source or adjust wrapper calls

### Hypothesis 4: XPtr/Memory Management Issue ⭐
**Likelihood**: LOW

**Evidence**:
- Objects can be created and basic properties accessed
- But save() causes segfault
- Frame data may not be properly initialized

**Test**:
- Check if `pitch->frames[]` array is allocated
- Verify `pitch->maxnCandidates` is set
- Check finalizer behavior

**If True**:
- Fix: Ensure proper object initialization in XPtr wrapper

---

## Technical Details

### Sound Creation Flow (VERIFIED WORKING)

1. `av::read_audio_bin()` → raw PCM data
2. **Normalize** by `max(abs(audio_data))` ✅ (NEW FIX)
3. Transpose to channels×samples matrix
4. `.sound_create_from_values()` → C++ wrapper
5. `Sound_createSimple()` allocates Praat Sound object
6. `memcpy()` copies data to `sound->z` matrix

**Both file-loaded and `create_tone()` use same underlying `Sound_createSimple()`**

### Pitch Detection Flow (FAILING)

1. `Sound$to_pitch()` → R6 method
2. `.pitch_from_sound()` → C++ wrapper
3. `Sound_to_Pitch(sound, timestep, floor, ceiling)` → Praat function
4. `Sound_to_Pitch_rawAc()` → Autocorrelation algorithm
5. `Sound_to_Pitch_any()` → Core implementation
6. **PROBLEM HERE**: Algorithm runs but finds no periodicity
7. All `pitch->frames[i].candidates[1].frequency` = 0 or invalid
8. `Pitch_getValueAtTime()` returns NaN

### Comparison with Parselmouth (Python)

**Parselmouth on same audio**:
```python
pitch = pm.Sound("ppq1.wav").to_pitch()
# Result: 2826/2879 voiced frames (98%)
```

**pladdrr on same audio**:
```r
pitch <- Sound$new("ppq1.wav")$to_pitch()
# Result: 0/286 voiced frames (0%)
```

---

## Next Debugging Steps

### Immediate (Can't Rebuild Due to GSL Linking)

1. ✅ **Verified Sound data is correct** - RMS matches expected
2. ✅ **Confirmed pitch object creates successfully**
3. ✅ **Identified NaN return value** - algorithm runs but fails
4. ❌ **Cannot add debug code** - rebuild blocked by GSL linking issue

### When Rebuild is Possible

1. **Add Debug Exports**:
   ```cpp
   // [[Rcpp::export(.pitch_debug_candidates)]]
   Rcpp::List pitch_debug_candidates(Rcpp::XPtr<structPitch> pitch);
   ```
   Already implemented in `src/pitch_wrappers.cpp:388` but not exported to R

2. **Inspect Raw Candidate Data**:
   - Print `pitch->frames[i].candidates[j].frequency` for each frame
   - Check `pitch->frames[i].candidates[j].strength` values
   - Verify `pitch->maxnCandidates` is set correctly

3. **Test Sound Data Access**:
   ```cpp
   // Verify Sound z matrix is accessible
   for (integer i = 1; i <= sound->nx && i <= 10; i++) {
       Rcout << "sound->z[1][" << i << "] = " << sound->z[1][i] << "\n";
   }
   ```

4. **Compare with Direct Praat Call**:
   - Create standalone C++ test bypassing R/Rcpp
   - Call `Sound_to_Pitch()` directly with same parameters
   - Check if problem is in wrapper or Praat itself

### GSL Linking Issue Resolution

Current error:
```
ld: library 'gsl' not found
```

**Options**:
1. Install GSL via Homebrew: `brew install gsl`
2. Remove GSL dependency if not actually needed
3. Update `src/Makevars` to find GSL in correct location
4. Use R's built-in numerical routines instead

---

## Files Modified in This Session

### Fixed (Bug #1)
- `R/sound-r6-new.R` (lines 125-130) - Added audio normalization ✅

### Created for Investigation
- `test_pladdrr_1.1.4_critical.R` - Critical features test
- `test_pitch_debug.cpp` - C++ debug script (not compiled)
- `test_pitch_detailed.R` - Detailed pitch testing
- `test_pitch_nan.R` - NaN vs NA investigation
- `test_simple_vuv.R` - Simple voicing test
- `test_pitch_properties.R` - Property access test
- `PITCH_DETECTION_BUG_INVESTIGATION.md` - Full analysis

### Documentation
- `PITCH_DETECTION_FIX.md` - Original normalization bug doc
- `SESSION_SUMMARY_2025-12-06.md` - This document

---

## Impact Assessment

### Features Blocked by Bug #2

**HIGH PRIORITY**:
- ✅ DSI (Dysphonia Severity Index) - needs pitch + jitter/shimmer
- ✅ AVQI (Acoustic Voice Quality Index) - needs pitch + HNR
- ✅ Tremor analysis - needs pitch contour
- ✅ Jitter/shimmer - needs voiced frames from pitch

**ALL VOICE QUALITY WORKFLOWS ARE BLOCKED**

### Workarounds

**SHORT TERM**: NONE - pitch detection is fundamental to voice analysis

**LONG TERM**: 
- Could use external pitch tracker (e.g., REAPER, PYIN)
- Would break Praat compatibility
- Not acceptable for research reproducibility

---

## Recommendations

### Immediate Actions

1. **Fix GSL Linking**:
   - `brew install gsl` 
   - Or modify `src/Makevars` to remove GSL dependency
   - Required to enable debugging

2. **Add Debug Exports**:
   - Compile `pitch_debug_candidates()` function
   - Inspect raw autocorrelation output
   - Verify what Praat algorithm is producing

3. **Minimal Reproduction**:
   - Create standalone C++ test
   - Bypass R/Rcpp entirely
   - Isolate where failure occurs

### Investigation Priority

1. ⭐⭐⭐ **Check Sound z matrix accessibility** - most likely cause
2. ⭐⭐ **Compare build configuration with Parselmouth**
3. ⭐ **Verify Praat version compatibility**
4. ⭐ **Inspect XPtr memory management**

---

## Conclusion

The pladdrr package has a **critical pitch detection algorithm failure** that makes it unusable for voice quality research. While audio normalization has been fixed (Bug #1), the core pitch detection (Bug #2) returns 0 voiced frames even for perfect sine waves.

The algorithm executes without crashing but returns NaN for all frames, suggesting the autocorrelation is running but finding no periodicity. This is almost certainly due to:

1. Sound data not accessible to the algorithm, OR
2. Autocorrelation algorithm broken in our build configuration

**Without pitch detection working, DSI, AVQI, tremor, jitter, and shimmer analysis are all blocked.**

**Critical Path**: Fix GSL linking → Add debug exports → Inspect raw pitch candidates → Identify exact failure point → Implement fix.

**Estimated Time to Fix**: 2-4 hours once rebuild is possible.

---

**END OF SESSION SUMMARY**
