# Pitch Detection Fix - Actionable Steps (2025-12-06)

## Problem Statement

Pitch detection returns **0 voiced frames** for ALL inputs, including:
- Pure 200 Hz sine waves (perfect periodic signal, 0.9 amplitude)
- Praat's built-in `Sound$create_tone()` 
- All durations tested (0.1s to 1.0s)
- All three methods: `to_pitch()`, `to_pitch_ac()`, `to_pitch_cc()`
- Even with extremely relaxed thresholds

**This completely blocks all voice quality analysis (DSI, AVQI, jitter, shimmer, tremor).**

## Verification Tests Run

### Test 1: Data Integrity ✅ PASSED
```r
# Created 200 Hz sine, stored in Sound, retrieved
max(abs(retrieved - original)) = 0
cor(retrieved, original) = 1.0
```
**Conclusion**: Audio data storage/retrieval is correct.

### Test 2: Praat's Own Generator ❌ FAILED
```r
tone <- Sound$create_tone(duration=1.0, frequency=200, amplitude=0.9, sampling_rate=16000)
pitch <- tone$to_pitch(time_step=0.01, pitch_floor=75, pitch_ceiling=600)
# Result: 97 frames, 0 voiced (0%)
```
**Conclusion**: Problem is NOT in our Sound creation - Praat's own generator also fails.

### Test 3: All Methods Fail ❌ FAILED
```r
p1 <- sound$to_pitch()        # 0 voiced
p2 <- sound$to_pitch_ac()     # 0 voiced  
p3 <- sound$to_pitch_cc()     # 0 voiced
```
**Conclusion**: Problem is in Praat's pitch detection core, affects all methods.

### Test 4: Relaxed Thresholds ❌ FAILED
```r
pitch <- sound$to_pitch_ac(
  silence_threshold = 0.001,  # Almost disabled
  voicing_threshold = 0.1     # Very low
)
# Result: Still 0 voiced
```
**Conclusion**: Not a threshold/parameter issue.

## Root Cause Analysis

### What We Know:
1. ✅ Sound object correctly created with proper data
2. ✅ Pitch object created with correct number of frames
3. ✅ FFT libraries compiled and linked (nm shows NUMFourierTable symbols)
4. ❌ **ALL pitch frames have nCandidates=0 or candidates[1].frequency=0**

### Most Likely Causes (in order):

#### 1. ⭐⭐⭐ Sound_into_PitchFrame Fails Silently
`Sound_to_Pitch_any` calls `Sound_into_PitchFrame` for each frame, which:
- Creates NUMFourierTable
- Performs autocorrelation/cross-correlation
- Finds pitch candidates

**If this function fails silently** (catches exception, doesn't propagate), frames would be left empty.

**Test**: Add debug output inside `Sound_into_PitchFrame` to trace execution.

#### 2. ⭐⭐ Global Peak Calculation Issue
```cpp
// Sound_to_Pitch.cpp
double globalPeak = 0.0;
for (integer channel = 1; channel <= my ny; channel ++) {
    for (integer i = 1; i <= my nx; i ++) {
        double value = std::abs (my z [channel] [i]);
        if (value > globalPeak)
            globalPeak = value;
    }
}
```

If `globalPeak == 0`, silence threshold check would mark everything as silent.

**Test**: Print globalPeak value before pitch analysis.

#### 3. ⭐ Thread-Local Storage Issue
Praat uses `MelderThread_PARALLELIZE` for multi-threaded pitch detection. If thread-local variables not properly initialized, frames could fail.

**Test**: Force single-threaded execution.

## Immediate Next Steps

### Option A: Add Debug Output (RECOMMENDED)
1. Add debug wrapper `pitch_debug_sound_to_pitch()` that prints:
   - Sound data range, first 5 samples
   - Global peak value
   - Each frame's intensity, nCandidates, top candidate
2. Call from R and examine output
3. Identify exactly where the failure occurs

**File**: `src/pitch_debug.cpp` (already created)
**Action**: Rebuild package with debug wrapper

### Option B: Compare with Working Praat
1. Save audio to WAV: `sound$save("test.wav")`
2. Load in Praat desktop: `Open > Read from file`
3. Extract pitch: `To Pitch...` with same parameters
4. Compare results
5. If Praat desktop WORKS → our wrapper issue
6. If Praat desktop FAILS → audio encoding issue

### Option C: Bypass Praat's Wrapper
Try calling `Sound_to_Pitch_rawAc` directly with explicit parameters instead of relying on `Sound_to_Pitch`:

```cpp
// In sound_wrappers.cpp, modify .sound_to_pitch:
autoPitch pitch = Sound_to_Pitch_rawAc(
    sound,
    time_step,
    pitch_floor,
    pitch_ceiling,
    15,      // maxnCandidates
    false,   // veryAccurate
    0.03,    // silenceThreshold
    0.45,    // voicingThreshold
    0.01,    // octaveCost
    0.35,    // octaveJumpCost
    0.14     // voicedUnvoicedCost
);
```

## Expected Behavior

For a 200 Hz pure tone at 0.9 amplitude:
- **Expected**: 95-98% voicing, mean F0 ≈ 200 Hz
- **Actual**: 0% voicing, all frames NA

## Files to Examine

1. `src/praat.github.io/fon/Sound_to_Pitch.cpp` - Main pitch detection logic
2. `src/sound_wrappers.cpp` - Our C++ wrappers
3. `src/pitch_debug.cpp` - Debug wrapper (created)
4. `R/sound-r6-new.R` - R6 Sound class

## Success Criteria

Fix is successful when:
```r
tone <- Sound$create_tone(duration=1.0, frequency=200, amplitude=0.8, sampling_rate=16000)
pitch <- tone$to_pitch()
pitch$count_voiced_frames() > 90  # At least 90% voicing
abs(pitch$get_mean(unit="hertz") - 200) < 5  # Mean F0 within 5 Hz
```

## Commands to Run

```bash
# Rebuild with debug
cd /Users/frkkan96/Documents/src/pladdrr
R CMD INSTALL --preclean .

# Test with debug output
Rscript -e '
library(pladdrr)
tone <- Sound$create_tone(1.0, 200, 0.9, 16000)
pitch <- .pitch_debug_sound_to_pitch(tone$.__enclos_env__$private$ptr, 0.01, 75, 600)
'
```
