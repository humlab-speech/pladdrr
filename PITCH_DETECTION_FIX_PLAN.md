# Pitch Detection Bug Fix Plan
**Status**: Diagnostic Phase - READ ONLY
**Date**: 2025-12-07
**Bug**: All pitch detection returns 0 voiced frames

## Investigation Summary

### ✅ Confirmed Working
- **Praat Desktop**: `/Applications/Praat.app/Contents/MacOS/Praat` works correctly
- **Audio Data**: Sound object verified (correlation=1.0, RMS correct)
- **FFT Implementation**: Uses Praat's NUMfft_core.h (FFTPACK, not PFFFT)
- **Compilation**: Package builds successfully with GSL linked

### ❌ Bug Scope
- **Affected**: ALL pitch detection methods (to_pitch, to_pitch_ac, to_pitch_cc)
- **All Inputs**: Pure 200 Hz tones, Praat-generated tones, real audio
- **All Parameters**: Default and relaxed thresholds
- **Symptom**: 0 voiced frames (97 frames created, all unvoiced)

## Call Chain Analysis

```
R User Code:
  sound$to_pitch(time_step=0.0, pitch_floor=75, pitch_ceiling=600)
    ↓
R6 Method (R/sound-r6-new.R:230):
  pitch_ptr <- .sound_to_pitch(private$ptr, time_step, pitch_floor, pitch_ceiling)
    ↓
Rcpp Export (R/RcppExports.R:1486):
  .Call(`_pladdrr_sound_to_pitch`, ...)
    ↓
C++ Wrapper (src/sound_wrappers.cpp:307):
  autoPitch pitch = Sound_to_Pitch(sound, time_step, pitch_floor, pitch_ceiling);
    ↓
Praat Function (src/praat.github.io/fon/Sound_to_Pitch.cpp:488):
  return Sound_to_Pitch_rawAc(me, timeStep, pitchFloor, pitchCeiling,
                               15, false, 0.03, 0.45, 0.01, 0.35, 0.14);
    ↓
Praat Core (src/praat.github.io/fon/Sound_to_Pitch.cpp:493):
  return Sound_to_Pitch_any(me, 0, 3.0, ...);   // method=0 (AC_HANNING)
    ↓
Per-Frame Analysis (Sound_into_PitchFrame):
  - Window signal → compute localPeak (RMS)
  - FFT forward → power spectrum
  - FFT backward → autocorrelation
  - Find candidates via peak detection
  ❌ RETURNS 0 CANDIDATES
```

## Root Cause Hypotheses (Ranked)

### 1. ⭐⭐⭐ Silence Detection Too Aggressive (95% confidence)
**Location**: `Sound_to_Pitch.cpp:177`
```cpp
if (localPeak == 0.0) {
    return;  // Early exit - NO candidates added
}
```

**Theory**: `localPeak` calculated incorrectly → all frames treated as silence

**Evidence**:
- Even 0.9 amplitude pure tones fail
- Relaxed silence_threshold (0.001) doesn't help
- Suggests localPeak computation bug, not threshold issue

**Likely Causes**:
- Window function zeroing signal (lines 407-415)
- DC removal too aggressive (lines 94-99)
- RMS calculation error (lines 90-101)

### 2. ⭐⭐ FFT Normalization Missing (70% confidence)
**Location**: `Sound_to_Pitch.cpp:149-155`

**Theory**: FFT round-trip not normalized → autocorrelation wrong

**Evidence**:
- NUMFourier.h:63 documents: "forward + backward multiplies by n"
- If division by `nsampFFT` missing → autocorrelation too large/small
- Would cause threshold checks to fail (line 186)

**Praat Code**:
```cpp
NUMfft_forward(fftTable, frame);      // Line 149
// ... power spectrum calculation ...
NUMfft_backward(fftTable, ac);        // Line 155
// Missing: ac /= nsampFFT ?
```

### 3. ⭐ Autocorrelation Window Normalization (40% confidence)
**Location**: `Sound_to_Pitch.cpp:177-191`

**Theory**: Division by window autocorrelation fails

**Code**:
```cpp
r[i] = ac[i+1] / ac[1] / windowR[i+1];  // Line 179
```
If `windowR[i+1] == 0` → division error → `r[i]` becomes NaN/Inf

## Diagnostic Strategy

### Phase 1: Instrumentation (Minimal Edits)
Add debug output at 5 strategic points in `Sound_to_Pitch.cpp`:

**File to Edit**: `src/praat.github.io/fon/Sound_to_Pitch.cpp`

**Edit 1** - After localPeak calculation (line 102):
```cpp
pitchFrame->intensity = (localPeak > globalPeak ? 1.0 : localPeak / globalPeak);
fprintf(stderr, "[PITCH] t=%.3f localPeak=%.6f globalPeak=%.6f intensity=%.3f\n", 
        t, localPeak, globalPeak, pitchFrame->intensity);
```

**Edit 2** - Before silence check (line 177):
```cpp
if (localPeak == 0.0) {
    fprintf(stderr, "[PITCH] t=%.3f SKIPPED (localPeak=0)\n", t);
    return;
}
```

**Edit 3** - After autocorrelation (line 156):
```cpp
NUMfft_backward(fftTable, ac);
fprintf(stderr, "[PITCH] t=%.3f ac[0-3]={%.4f,%.4f,%.4f,%.4f}\n",
        t, ac[1], ac[2], ac[3], ac[4]);
```

**Edit 4** - In candidate loop (after line 186):
```cpp
if (r[i] > 0.5 * my voicingThreshold) {
    // ... existing code ...
    fprintf(stderr, "[PITCH] t=%.3f candidate: lag=%ld r=%.4f (thresh=%.4f)\n",
            t, i, r[i], 0.5 * my voicingThreshold);
}
```

**Edit 5** - After candidate loop (line 200):
```cpp
fprintf(stderr, "[PITCH] t=%.3f nCandidates=%d\n", t, pitchFrame->nCandidates);
```

### Phase 2: Rebuild and Test

```bash
cd /Users/frkkan96/Documents/src/pladdrr
R CMD INSTALL --preclean .
```

```r
library(pladdrr)
tone <- Sound$create_tone(1.0, 200, 0.9, 16000)
pitch <- tone$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
# Debug output appears in R console or stderr
```

### Phase 3: Interpret Debug Output

**Scenario A** - localPeak is zero:
```
[PITCH] t=0.050 SKIPPED (localPeak=0)
```
→ Fix window function or RMS calculation (lines 90-115)

**Scenario B** - ac values all zero:
```
[PITCH] t=0.050 localPeak=0.450 globalPeak=0.900 intensity=0.500
[PITCH] t=0.050 ac[0-3]={0.0000,0.0000,0.0000,0.0000}
[PITCH] t=0.050 nCandidates=0
```
→ FFT normalization issue (add division by nsampFFT)

**Scenario C** - ac values non-zero but no candidates:
```
[PITCH] t=0.050 localPeak=0.450 globalPeak=0.900 intensity=0.500
[PITCH] t=0.050 ac[0-3]={9999.0,9950.0,9800.0,9600.0}
[PITCH] t=0.050 nCandidates=0
```
→ Division by windowR or threshold too high

## Alternative: Praat Desktop Scripting Test

Validate end-to-end without code changes using Praat CLI:

**Create test script** (`/tmp/test_pitch.praat`):
```praat
sound = Read from file: "/tmp/test_tone_200hz.wav"
pitch = To Pitch: 0.01, 75, 600
n_frames = Get number of frames
mean_f0 = Get mean: 0, 0, "Hertz"

appendInfoLine: "Frames: ", n_frames
appendInfoLine: "Mean F0: ", mean_f0
```

**Run**:
```bash
/Applications/Praat.app/Contents/MacOS/Praat --run /tmp/test_pitch.praat
```

**Expected** (if Praat Desktop works):
```
Frames: 97
Mean F0: 200.0
```

This confirms the WAV file is valid and Praat Desktop pitch detection works.

## Recommended Fix Paths (Based on Diagnosis)

### If localPeak==0 (Hypothesis #1):

**Check lines 90-101** - RMS calculation:
```cpp
for (integer channel = 1; channel <= my ny; channel ++) {
    double s = 0.0, p = 0.0;
    for (integer j = 1; j <= nsamp_window; j ++) {
        s += frame [channel] [j];  // Sum (for DC removal)
    }
    s /= nsamp_window;  // Mean
    for (integer j = 1; j <= nsamp_window; j ++) {
        double value = (frame [channel] [j] - s) * window [j];
        p += value * value;  // Power
        frame [channel] [j] = value;  // Store windowed, DC-removed
    }
    if (p > localPeak) localPeak = p;
}
```

**Possible issues**:
1. `p` not divided by `nsamp_window` (should be RMS not sum-of-squares?)
2. Window values all zero? (check lines 407-415)
3. DC removal leaving zero signal?

**Test fix** - Add after line 101:
```cpp
localPeak = sqrt(localPeak / nsamp_window);  // Convert to RMS
```

### If ac values wrong (Hypothesis #2):

**Add normalization after line 155**:
```cpp
NUMfft_backward(fftTable, ac);
for (integer i = 1; i <= nsampFFT; i++) {
    ac[i] /= nsampFFT;  // Normalize FFT round-trip
}
```

### If windowR division fails (Hypothesis #3):

**Add safety check before line 179**:
```cpp
if (windowR[i+1] < 1e-12) {
    r[i] = 0.0;  // Avoid division by zero
} else {
    r[i] = ac[i+1] / ac[1] / windowR[i+1];
}
```

## Testing Validation

After fix applied, validate:

1. **Pure tone 200 Hz** → Should detect ~200 Hz with high voicing
2. **Various frequencies** → 100, 150, 250, 400 Hz
3. **Real speech** → Load actual audio files
4. **Compare to Praat Desktop** → Numerical accuracy ±1 Hz

## Success Criteria

- ✅ Pure 200 Hz tone: 95+ voiced frames, mean F0 = 199-201 Hz
- ✅ All test cases pass with >90% voiced frames
- ✅ Results match Praat Desktop ±2 Hz
- ✅ No memory leaks (valgrind clean)

## Next Steps

**User Decision Required**:

1. **Option A**: Proceed with instrumentation (5 fprintf additions)
   - Pro: Precise diagnosis
   - Con: Requires editing Praat source file
   - Time: 5 min edit + 2 min rebuild + 1 min test = 8 minutes

2. **Option B**: Attempt direct fix based on hypothesis #1
   - Pro: Faster if guess is correct
   - Con: May miss actual root cause
   - Time: Variable (could be 5 min or 2 hours of trial-error)

3. **Option C**: Run Praat Desktop CLI test first
   - Pro: Zero code changes, validates WAV file
   - Con: We already know desktop works (user confirmed)
   - Time: 2 minutes

**Recommendation**: Option A (instrumentation) - provides definitive diagnosis with minimal investment.

