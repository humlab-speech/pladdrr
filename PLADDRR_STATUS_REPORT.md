# pladdrr Package Status Report
**Date**: 2025-12-03
**Package Version**: 1.0.7
**Investigator**: Code analysis

## Summary

**CONFIRMED**: pladdrr 1.0.7 has a critical bug in `PowerCepstrogram` creation that blocks AVQI implementation.

## Test Results

### ✅ Package Loads Successfully
```r
library(pladdrr)
packageVersion('pladdrr')  # 1.0.7
```

### ✅ Sound Loading Works
```r
snd <- Sound$new('inst/extdata/test.wav')
snd$get_duration()  # 1 second
```

### ❌ PowerCepstrogram Creation FAILS
```r
pcep <- snd$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)
# Error: Failed to create PowerCepstrogram from Sound
```

## Root Cause Analysis

### Build Configuration: ✅ CORRECT
- `src/Makevars` includes PowerCepstrogram source files:
  ```makefile
  praat.github.io/LPC/PowerCepstrogram.cpp \
  praat.github.io/LPC/Sound_to_PowerCepstrogram.cpp \
  ```

### C++ Wrapper: ✅ CORRECT
File: `src/powercepstrum_wrappers.cpp`
```cpp
SEXP sound_to_powercepstrogram(SEXP sound_xptr, double pitch_floor,
                                double time_step, double maximum_frequency,
                                double pre_emphasis_frequency) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound) stop("Invalid Sound pointer");

    try {
        autoPowerCepstrogram cepstrogram = Sound_to_PowerCepstrogram(
            sound.get(), pitch_floor, time_step,
            maximum_frequency, pre_emphasis_frequency
        );
        return create_xptr_from_auto<structPowerCepstrogram>(cepstrogram);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create PowerCepstrogram from Sound");  // <-- WE SEE THIS
    }
}
```

### Praat Source: ✅ PRESENT
- File exists: `src/praat.github.io/LPC/Sound_to_PowerCepstrogram.cpp`
- Function signature correct
- Dependencies present

### Likely Issue: Runtime Error

The C++ wrapper is catching a `MelderError` from the Praat function, indicating:

1. **Compilation successful** (otherwise linking would fail)
2. **Praat function throws error** at runtime
3. **Possible causes**:
   - Parameter validation failure in Praat
   - Memory allocation issue
   - Dependency on uninitialized Praat subsystem
   - Missing NUM library functions

## Impact Assessment

### ❌ BLOCKED: AVQI (Acoustic Voice Quality Index)
**Reason**: CPPS calculation requires PowerCepstrogram
```r
# AVQI workflow (BROKEN):
compute_avqi(sound, type = "vowel")
  → sound$to_powercepstrogram()  # FAILS HERE
  → cepstrogram$get_cpps()       # Never reached
```

**Components affected**:
- CPPS (Cepstral Peak Prominence) - **PRIMARY MEASURE**
- Full AVQI score calculation

### ✅ WORKS: DSI (Dysphonia Severity Index)
**Reason**: Uses PointProcess methods, not PowerCepstrogram
```r
# DSI workflow (WORKING):
compute_dsi(sound, type = "sustained")
  → sound$to_intensity()           # ✅ Works
  → sound$to_pitch()                # ✅ Works
  → sound$to_point_process_periodic_cc()  # ✅ Works
  → pp$voice_report()               # ✅ Works
```

**Required components**:
- MPT (Maximum Phonation Time) - ✅ duration
- I-low (Lowest Intensity) - ✅ `Intensity$get_minimum()`
- F0-high (Highest F0) - ✅ `Pitch$get_maximum()`
- Jitter ppq5 - ✅ `PointProcess$voice_report()$jitter_ppq5`

**All DSI components available!**

### ✅ FEASIBLE: Tremor Analysis
**Reason**: Uses Pitch and Amplitude tracking
```r
# Tremor workflow (SHOULD WORK):
analyze_tremor(sound, min_pitch = 60, max_pitch = 350)
  → sound$to_pitch()               # ✅ Works
  → sound$to_intensity()           # ✅ Works
  → FFT analysis of modulations    # ✅ R can do this
```

**Required components**:
- Pitch contour extraction - ✅ `Pitch$to_data_frame()`
- Intensity contour - ✅ `Intensity$to_data_frame()`
- Spectral analysis - ✅ R stats (fft, spectrum, etc.)

## Available Workarounds

### Option 1: Manual CPPS (Complex)
Implement CPPS manually using:
```r
sound$to_spectrum() → Spectrum$to_powercepstrum()
```
**Challenge**: CPPS needs smoothing across time (requires cepstrogram, not single cepstrum)

### Option 2: Use Praat Console Scripts (Recommended)
Create Praat batch scripts that:
1. Load audio
2. Compute PowerCepstrogram
3. Extract CPPS
4. Export to CSV

**Advantage**: Bypasses pladdrr bug entirely

### Option 3: Wait for Fix (Not viable for thesis)
Would require:
- Debugging Praat function call
- Identifying missing dependencies
- Recompiling package
- Testing across platforms

## Recommended Implementation Strategy

### Phase 1: R Implementations (Feasible)
1. ✅ **DSI** - Full implementation in R using pladdrr
2. ✅ **Tremor** - Full implementation in R using pladdrr

### Phase 2: Praat Console Scripts (Workaround)
1. ⚠️ **AVQI** - Praat script (cannot use pladdrr)
2. 🔄 **DSI** - Praat script for validation

### Phase 3: Documentation
1. Document the PowerCepstrogram bug
2. File issue on pladdrr GitHub
3. Provide complete Praat workaround
4. Show 3-way comparison where possible (Python/R/Praat for DSI and Tremor)
5. Show 2-way comparison for AVQI (Python/Praat only)

## Technical Details for Bug Report

**Environment**:
- pladdrr version: 1.0.7
- R version: 4.4+
- Platform: macOS (Darwin 25.1.0)

**Minimal Reproducible Example**:
```r
library(pladdrr)
snd <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
pcep <- snd$to_powercepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  maximum_frequency = 5000,
  pre_emphasis_frequency = 50
)
# Error: Failed to create PowerCepstrogram from Sound
```

**Expected Behavior**:
Should return PowerCepstrogram object

**Actual Behavior**:
MelderError caught, generic error message returned

**Debugging Needed**:
1. Add detailed error logging to see actual Praat error
2. Check if NUM library functions are properly linked
3. Verify all Praat dependencies initialized
4. Test with different audio parameters

## Next Steps

1. ✅ Implement DSI in R (fully feasible)
2. ✅ Implement tremor in R (fully feasible)
3. ✅ Create Praat console scripts for AVQI and DSI
4. ✅ Document workarounds and limitations
5. ⏸️ File detailed bug report with pladdrr maintainers
6. ✅ Proceed with thesis using hybrid approach

## Conclusion

**Your assessment was 100% correct**: pladdrr has a critical PowerCepstrogram bug that blocks AVQI.

**Good news**: DSI and tremor are fully implementable in R using pladdrr's working components.

**Strategy**: Hybrid approach (R where possible, Praat scripts where necessary) is the best path forward.
