# Pitch Detection Bug - Detailed Investigation (2025-12-06)

## Summary
Pitch detection returns 0 voiced frames for ALL inputs, including:
- Pure 200 Hz sine waves (0.9 amplitude)
- Praat's own `create_tone` function
- 0.1s to 1.0s durations
- All three methods: `to_pitch()`, `to_pitch_ac()`, `to_pitch_cc()`
- With relaxed thresholds (silence_threshold=0.001, voicing_threshold=0.1)

## Evidence

### Test 1: Pure Sine Wave (from_values)
```r
signal <- 0.9 * sin(2 * pi * 200 * seq(0, 0.1, by=1/16000))
sound <- Sound$from_values(matrix(signal, nrow = 1), sampling_rate = 16000)
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
# Result: Frames=7, Voiced=0 (0%)
```

### Test 2: Praat's create_tone
```r
tone <- Sound$create_tone(duration = 1.0, frequency = 200, amplitude = 0.9, sampling_rate = 16000)
pitch <- tone$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
# Result: Frames=97, Voiced=0 (0%)
```

### Test 3: With relaxed parameters
```r
pitch <- tone$to_pitch_ac(
  time_step = 0.01,
  pitch_floor = 50,
  pitch_ceiling = 1000,
  silence_threshold = 0.001,  # Almost no silence detection
  voicing_threshold = 0.1     # Very low voicing threshold
)
# Result: Frames=39, Voiced=0 (0%)
```

### Data Verification
- ✅ Audio data correctly stored (correlation=1.0, max_diff=0)
- ✅ Sound object properties correct (duration, samples, SR, RMS)
- ✅ Pitch object created with correct number of frames
- ❌ ALL pitch frames marked as unvoiced (frequency=NA)

## Root Cause Analysis

### What's NOT the problem:
1. ❌ Audio normalization (fixed in previous session)
2. ❌ Data storage/retrieval (verified identical)
3. ❌ Sound object creation (Praat's own create_tone also fails)
4. ❌ Parameter passing (tried all methods and ranges)

### What IS the problem:
The issue is in Praat's pitch detection itself within the compiled library.

**Possible causes:**
1. ⭐⭐⭐ FFT/NUM2 library compilation issue
2. ⭐⭐ Missing initialization or thread-local storage
3. ⭐ Incorrect method parameter in `Sound_to_Pitch_any` call

### Evidence from Code

#### Praat calls chain:
```
Sound_to_Pitch() 
  → Sound_to_Pitch_rawAc(defaults)
    → Sound_to_Pitch_any(method=AC_HANNING, periodsPerWindow=3.0, ...)
      → Sound_into_PitchFrame (for each frame)
        → Creates NUMFourierTable
        → Performs autocorrelation
        → Finds pitch candidates
```

#### Key observation:
```cpp
// Sound_to_Pitch.cpp line ~60
autoPitch Sound_to_Pitch_rawAc (...) {
	return Sound_to_Pitch_any (me, (int) veryAccurate, 3.0, /* AC method */
		timeStep, pitchFloor, pitchCeiling, ...);
}
```

The `(int) veryAccurate` is cast to `method` parameter. If `veryAccurate=false`:
- method = 0 → AC_HANNING
- method = 1 → AC_GAUSS

But `very_accurate` should be a bool, not an int for method selection!

## Next Steps

1. **Check method parameter**: Verify Sound_to_Pitch_any gets correct method value
2. **Test FFT directly**: Create minimal C++ test of NUMFourierTable
3. **Compare with working Praat**: Test same audio in Praat desktop
4. **Add debug output**: Insert Rcpp::Rcout in Sound_to_Pitch_any to trace execution

## Files Involved
- `src/sound_wrappers.cpp` - Pitch extraction wrappers
- `src/praat.github.io/fon/Sound_to_Pitch.cpp` - Praat's pitch detection
- `src/praat.github.io/NUM/NUM2.cpp` - FFT implementation
- `R/sound-r6-new.R` - R6 Sound class
