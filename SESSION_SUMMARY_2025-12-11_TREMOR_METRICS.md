# Tremor Metrics Implementation Session Summary
## Date: 2025-12-11

## Completed ✅

### 1. Pitch Intensity & Strength API
**New R6 methods:**
- `pitch$get_intensity_at_time(time)`
- `pitch$get_mean_intensity(from_time, to_time)`  
- `pitch$get_strength_at_time(time, unit, interpolate)`
- `pitch$get_mean_strength(from_time, to_time, unit)`
- `pitch$as_data_frame(include_intensity=TRUE, include_strength=TRUE)`

**Implementation:** Direct C struct field access via new C++ wrappers in `src/pitch_wrappers.cpp`

### 2. Tremor Analysis Function
**File:** `R/tremor.R`  
**Function:** `analyze_tremor(sound, ...)`  
**Exports:** Added to `NAMESPACE`

**18 tremor measures extracted:**
- Frequency modulation: FCoM, FTrC, FMoN, FTrF, FTrI, FTrP, FTrCIP, FTrPS, FCoHNR
- Amplitude modulation: ACoM, ATrC, AMoN, ATrF, ATrI, ATrP, ATrCIP, ATrPS, ACoHNR

### 3. Bug Fixes in tremor.R
1. ✅ Fixed `pitch$get_value_in_frame()` → `pitch$get_value_at_time(t, unit, interpolate=FALSE)`
2. ✅ Fixed `pitch$get_time_from_frame_number()` → `pitch$get_time_from_frame(i)`
3. ✅ Fixed `Sound$from_values(..., sampling_frequency=...)` → `sampling_rate=...`
4. ✅ Added missing `mean_amp` variable calculation
5. ✅ Fixed contour intensity extraction (use ALL frames, not just voiced)

**Critical insight:** F0/amplitude contour Pitch objects have NO voiced frames (they're not periodic audio). FCoM/ACoM must use `max(all intensity values)`.

## Current Test Results ⚠️

**Test file:** `inst/signalfiles/AVQI/input/sv1.wav`

| Measure | Current | Expected | Status |
|---------|---------|----------|--------|
| FCoM | 0.1550 | ~0.599 | ❌ Too low |
| FTrC | 0.2557 | ~0.353 | ✅ Close |
| FTrF | 1.82 Hz | | ✅ Working |
| FTrI | 15.48% | | ✅ Working |
| ACoM | 0.1561 | ~0.442 | ❌ Too low |
| ATrC | 0.8625 | | ✅ Working |
| ATrF | 1.82 Hz | | ✅ Working |
| ATrI | 24.59% | | ✅ Working |

## Outstanding Issues 🔍

### Issue 1: FCoM/ACoM Values Too Low

**Problem:** Getting 0.15 but expect ~0.5-0.6

**Current implementation:**
```r
# 1. Extract F0 contour from audio
# 2. Detrend: f0_detrended = f0_values - linear_trend
# 3. Normalize: f0_normalized = f0_detrended / mean_f0
# 4. Create Sound from normalized contour
# 5. Create Pitch from contour Sound (pitch_floor=1.5, pitch_ceiling=15 Hz)
# 6. FCoM = max(intensity from all frames)
```

**Diagnostic output:**
```
F0 pitch df: 54 rows
Voiced frames: 0/54  (expected - contours aren't periodic)
Intensity range: [0.0802, 0.1550]
FCoM = 0.1550
```

**Possible causes:**
1. Contour normalization method incorrect
2. Pitch parameters for tremor range need adjustment
3. Different interpretation of "intensity" in Brückl protocol
4. May need different scaling/preprocessing

**Next steps:**
1. Review original Brückl (2012, 2015) papers for exact protocol
2. Check if FCoM should be calculated differently
3. Compare with reference Praat Tremor script implementation
4. Test with multiple audio files to see if pattern holds

### Issue 2: Excessive Debug Logging

**Files with debug output:**
- `src/praat.github.io/fon/Sound_to_Pitch.cpp`
- `src/praat.github.io/melder/NUMinterpol.cpp`

**Output pollution:** Thousands of lines of:
```
LOOP ITERATION iframe=1
[PITCH_DEBUG] t=0.027 localPeak=...
[NUMINTERPOL_DEBUG] Enter: ixmid=403...
```

**Solution needed:** Comment out fprintf debug statements

## Technical Implementation Details

### Brückl Protocol Steps (as understood)

**Frequency tremor:**
1. Extract F0 from audio (standard pitch tracking)
2. Remove linear trend from F0 contour
3. Normalize: `(f0 - trend) / mean_f0`
4. Create uniform-sampled signal (interpolate to fixed rate)
5. Convert to Sound object
6. Extract Pitch from contour Sound (1.5-15 Hz range for tremor)
7. FCoM = max intensity from contour Pitch
8. FTrC = autocorrelation-based cyclicality
9. FTrF, FTrI = dominant frequency & power from spectrum

**Amplitude tremor:**
1. Extract intensity from audio
2. Convert dB to linear scale
3. Normalize: `(amp - mean_amp) / mean_amp`
4. Create uniform-sampled signal
5. Convert to Sound object
6. Extract Pitch from contour Sound (1.5-15 Hz range)
7. ACoM = max intensity from contour Pitch
8. ATrC, ATrF, ATrI = similar to frequency measures

### Key Design Decisions

1. **No voiced frame filtering for contours:** Contour signals are NOT periodic audio, so all frames are used
2. **Uniform sampling:** Interpolate irregular F0/intensity samples to uniform grid for FFT
3. **Tremor frequency range:** 1.5-15 Hz (characteristic of vocal tremor)
4. **Autocorrelation for cyclicality:** Following Brückl's formulation

## Files Modified

**C++ (wrappers):**
- `src/pitch_wrappers.cpp` - Added intensity/strength field access

**R (code):**
- `R/pitch-r6.R` - Added intensity/strength methods
- `R/tremor.R` - Complete tremor analysis implementation
- `NAMESPACE` - Exported `analyze_tremor`

**Auto-generated:**
- `R/RcppExports.R`
- `src/RcppExports.cpp`

## Package Info

**Package:** pladdrr v1.2.2  
**Branch:** 001-praat-r-access  
**Status:** 15 commits ahead of main

## Next Steps (Priority Order)

1. **HIGH:** Review Brückl papers to verify FCoM/ACoM calculation
2. **HIGH:** Test with additional audio files to confirm pattern
3. **MEDIUM:** Remove debug fprintf statements from Praat source
4. **MEDIUM:** Validate tremor metrics against reference implementation
5. **LOW:** Add unit tests for tremor functions
6. **LOW:** Document tremor analysis in vignette

## References

- Brückl, M. (2012). Vocal Tremor Measurement Based on Autocorrelation of Contours. Interspeech '12.
- Brückl, M., Ghio, A., & Viallet, F. (2015). Measurement of Tremor in the Voices of Speakers with Parkinson's Disease. ICNLSP 2015.

## Questions for Resolution

1. What is the correct calculation for FCoM/ACoM in Brückl's protocol?
2. Should contour normalization use different method?
3. Are the pitch_floor/pitch_ceiling parameters correct for tremor analysis?
4. Should intensity values be scaled or transformed before max() calculation?
