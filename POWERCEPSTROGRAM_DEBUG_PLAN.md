# PowerCepstrogram Bug - Diagnostic and Fix Plan

**Date:** 2025-12-05  
**Status:** 🔍 INVESTIGATION PHASE  
**Package:** pladdrr v1.0.7

---

## Problem Statement

`sound$to_powercepstrogram()` fails with error, but Praat application can successfully create PowerCepstrograms. This indicates the issue is in our wrapper code, not Praat's C++ core.

---

## Previous Fix Attempt (Not Applied)

Document `POWERCEPSTROGRAM_FIX_STATUS.md` describes a fix that:
1. Improved error reporting in wrapper
2. Added `Sound_extensions.cpp` to build

**Status**: Not currently in codebase (needs to be re-applied or was reverted)

---

## Current State Analysis

### Wrapper Code (`src/powercepstrum_wrappers.cpp`)

```cpp
// [[Rcpp::export(.sound_to_powercepstrogram)]]
SEXP sound_to_powercepstrogram(SEXP sound_xptr, double pitch_floor, double time_step, 
                                double maximum_frequency, double pre_emphasis_frequency) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound) stop("Invalid Sound pointer");
    
    try {
        autoPowerCepstrogram cepstrogram = Sound_to_PowerCepstrogram(
            sound.get(),
            pitch_floor,
            time_step,
            maximum_frequency,
            pre_emphasis_frequency
        );
        return create_xptr_from_auto<structPowerCepstrogram>(cepstrogram);
    } catch (MelderError) {
        // Capture Praat error message before clearing
        autostring32 error_message = Melder_dup (Melder_getError());
        Melder_clearError();
        std::string error_str = Melder_peek32to8(error_message.get());
        stop("PowerCepstrogram creation failed. Praat error: " + error_str);
    }
}
```

✅ **Error reporting is good** - captures actual Praat error

### Supporting Function (`src/sound_extensions_minimal.cpp`)

```cpp
autoSound Sound_resampleAndOrPreemphasize (constSound me, 
    double maximumFrequency, integer depth, double preEmphasisFrequency) {
    try {
        const double nyquistFrequency = 0.5 / my dx;
        autoSound sound;
        if (maximumFrequency <= 0.0 || fabs (maximumFrequency / nyquistFrequency - 1.0) < 1.0e-12)
            sound = Data_copy (me);
        else
            sound = Sound_resample (me, maximumFrequency * 2.0, depth);
        Sound_preEmphasize_inplace (sound.get(), preEmphasisFrequency);
        return sound;
    } catch (MelderError) {
        Melder_throw (me, U": could not resample.");
    }
}
```

✅ **Function implemented**

### Build Configuration (`src/Makevars`)

```makefile
DWTOOLS_SRC = ... sound_extensions_minimal.cpp
```

✅ **Included in build**

---

## Diagnostic Steps

### Step 1: Capture Exact Error Message

Create test script to get actual Praat error:

```r
library(pladdrr)

# Create simple test sound
sound <- Sound$new_tone(
  frequency = 440,
  amplitude = 0.2,
  duration = 1.0,
  sampling_frequency = 44100
)

# Try to create PowerCepstrogram
tryCatch({
  pcep <- sound$to_powercepstrogram(
    pitch_floor = 60,
    time_step = 0.002,
    maximum_frequency = 5000,
    pre_emphasis_frequency = 50
  )
  cat("✓ SUCCESS\n")
}, error = function(e) {
  cat("✗ ERROR:", e$message, "\n")
})
```

### Step 2: Check Function Availability

Verify all required functions are available:

```cpp
// Add to wrapper for testing
Rcpp::Rcout << "Testing Sound_resample..." << std::endl;
auto test_resample = Sound_resample(sound.get(), 10000.0, 50);
Rcpp::Rcout << "✓ Sound_resample works" << std::endl;

Rcpp::Rcout << "Testing Sound_resampleAndOrPreemphasize..." << std::endl;
auto test_resampler = Sound_resampleAndOrPreemphasize(sound.get(), 5000.0, 50, 50.0);
Rcpp::Rcout << "✓ Sound_resampleAndOrPreemphasize works" << std::endl;
```

### Step 3: Check Parameter Values

Ensure wrapper passes correct parameters:

```r
# Test with Praat-like defaults
sound$to_powercepstrogram(
  pitch_floor = 60.0,      # Matches Praat
  time_step = 0.002,       # 2ms - standard
  maximum_frequency = 5000.0,  # 5kHz - standard
  pre_emphasis_frequency = 50.0  # 50Hz - standard
)
```

### Step 4: Compare with Praat Script

Create equivalent Praat script to verify parameters:

```praat
# test_powercepstrogram.praat
sound = Create Sound from formula: "test", 1, 0, 1, 44100, "0.2 * sin(2*pi*440*x)"
cepstrogram = To PowerCepstrogram: 60, 0.002, 5000, 50
# If this works in Praat but not pladdrr, it's a wrapper issue
```

---

## Potential Issues & Fixes

### Issue 1: Sound Pointer Validity ⚠️ LIKELY

**Problem**: Sound pointer might not be properly initialized or validated

**Test**:
```cpp
if (!sound) stop("Invalid Sound pointer");
Rcpp::Rcout << "Sound duration: " << sound->xmax - sound->xmin << std::endl;
Rcpp::Rcout << "Sound samples: " << sound->nx << std::endl;
Rcpp::Rcout << "Sound rate: " << 1.0/sound->dx << std::endl;
```

**Fix**: Ensure Sound object is valid before passing to Praat

### Issue 2: Minimum Duration Requirement ⚠️ LIKELY

**Problem**: Praat requires sound duration >= analysis window

From Praat source:
```cpp
Melder_require (physicalSoundDuration >= physicalAnalysisWidth,
    U"Your sound is too short:\n"
    U"it should be longer than ", physicalAnalysisWidth, U" s."
);
```

**Test**: Create longer test sound (>= 0.05s)

**Fix**: Document minimum duration or add validation in wrapper

### Issue 3: Parameter Range Validation ⚠️ POSSIBLE

**Problem**: Parameters might be out of valid ranges

**Tests**:
- `pitch_floor` > 0 and < Nyquist frequency
- `time_step` > 0
- `maximum_frequency` < Nyquist frequency of sound
- `maximum_frequency` > 0

**Fix**: Add parameter validation in wrapper

### Issue 4: Memory Management ⚠️ POSSIBLE

**Problem**: XPtr creation might fail for PowerCepstrogram

**Test**:
```cpp
autoPowerCepstrogram cepstrogram = Sound_to_PowerCepstrogram(...);
Rcpp::Rcout << "PowerCepstrogram created, frames: " << cepstrogram->nx << std::endl;
auto xptr = create_xptr_from_auto<structPowerCepstrogram>(cepstrogram);
Rcpp::Rcout << "XPtr created successfully" << std::endl;
return xptr;
```

**Fix**: Check XPtr creation utility function

### Issue 5: Missing Praat Initialization ❌ UNLIKELY

**Problem**: Praat might need initialization

**Status**: Other Praat functions work, so initialization is fine

---

## Recommended Fix Strategy

### Phase 1: Diagnosis (15 minutes)

1. Create diagnostic test script
2. Capture exact error message
3. Test with simple sound
4. Test with different parameter values
5. Compare with Praat script output

### Phase 2: Targeted Fix (30 minutes)

Based on diagnosis, implement appropriate fix:

**If minimum duration issue**:
```cpp
// Add validation
double duration = sound->xmax - sound->xmin;
double min_duration = 1.0 / pitch_floor * 3.0;  // At least 3 periods
if (duration < min_duration) {
    stop("Sound too short. Minimum duration for pitch_floor " + 
         std::to_string(pitch_floor) + " Hz is " + 
         std::to_string(min_duration) + " s");
}
```

**If parameter range issue**:
```cpp
// Add validation
double nyquist = 0.5 / sound->dx;
if (maximum_frequency >= nyquist) {
    stop("maximum_frequency (" + std::to_string(maximum_frequency) + 
         ") must be less than Nyquist frequency (" + 
         std::to_string(nyquist) + ")");
}
if (pitch_floor <= 0 || pitch_floor >= nyquist) {
    stop("pitch_floor must be between 0 and Nyquist frequency");
}
if (time_step <= 0) {
    stop("time_step must be positive");
}
```

**If Sound pointer issue**:
```cpp
// More thorough validation
if (!sound) stop("Invalid Sound pointer");
if (sound->nx <= 0) stop("Sound has no samples");
if (sound->dx <= 0) stop("Sound has invalid sample period");
if (sound->xmax <= sound->xmin) stop("Sound has invalid time domain");
```

### Phase 3: Testing (15 minutes)

1. Test with simple tone
2. Test with real voice recording
3. Test edge cases (very short, very long, extreme parameters)
4. Verify CPPS calculation works
5. Run full AVQI workflow

### Phase 4: Documentation (10 minutes)

1. Document parameter constraints
2. Add usage examples
3. Update error messages to be user-friendly
4. Add to NEWS.md

---

## Test Cases

### Test 1: Minimal Valid Sound
```r
sound <- Sound$new_tone(440, 0.2, 1.0, 44100)  # 1 second
pcep <- sound$to_powercepstrogram()
```
**Expected**: SUCCESS

### Test 2: Very Short Sound
```r
sound <- Sound$new_tone(440, 0.2, 0.01, 44100)  # 10ms
pcep <- sound$to_powercepstrogram(pitch_floor = 60)
```
**Expected**: May FAIL with "sound too short" if duration < 3/pitch_floor

### Test 3: Custom Parameters
```r
sound <- Sound$new_tone(440, 0.2, 2.0, 44100)
pcep <- sound$to_powercepstrogram(
  pitch_floor = 75,
  time_step = 0.001,
  maximum_frequency = 8000,
  pre_emphasis_frequency = 60
)
```
**Expected**: SUCCESS

### Test 4: Real Voice File
```r
sound <- Sound$new("inst/extdata/vowel.wav")
pcep <- sound$to_powercepstrogram()
cpps <- pcep$get_cpps()
```
**Expected**: SUCCESS, CPPS between 5-20 dB

---

## Implementation Priority

1. **HIGH**: Run diagnostic test to get actual error
2. **HIGH**: Implement appropriate fix based on error
3. **MEDIUM**: Add parameter validation
4. **MEDIUM**: Add better error messages
5. **LOW**: Add convenience method with smart defaults

---

## Success Criteria

- [ ] `sound$to_powercepstrogram()` works with default parameters
- [ ] Works with custom parameters
- [ ] Returns valid PowerCepstrogram object
- [ ] `get_cpps()` returns reasonable values
- [ ] Works with real voice recordings
- [ ] Error messages are clear and actionable
- [ ] No regression in other functionality

---

## Files to Modify

1. `src/powercepstrum_wrappers.cpp` - Add validation/fix
2. `R/sound-r6-new.R` - Update documentation
3. `tests/testthat/test-powercepstrogram.R` - Add tests (create if needed)
4. `NEWS.md` - Document fix

---

## Next Action

**RUN DIAGNOSTIC TEST** to determine exact failure point:

```bash
cd /Users/frkkan96/Documents/src/pladdrr
cat > test_powercepstrogram_debug.R << 'EOF'
library(pladdrr)

cat("Creating test sound...\n")
sound <- Sound$new_tone(440, 0.2, 1.0, 44100)
cat("✓ Sound created: duration =", sound$get_duration(), "s\n")
cat("✓ Sample rate =", sound$get_sampling_frequency(), "Hz\n")

cat("\nAttempting PowerCepstrogram creation...\n")
tryCatch({
  pcep <- sound$to_powercepstrogram(
    pitch_floor = 60,
    time_step = 0.002,
    maximum_frequency = 5000,
    pre_emphasis_frequency = 50
  )
  cat("✓ ✓ ✓ SUCCESS! PowerCepstrogram created\n")
  cat("  Frames:", pcep$nx, "\n")
}, error = function(e) {
  cat("✗ ✗ ✗ FAILED\n")
  cat("Error message:", e$message, "\n")
})
EOF

Rscript test_powercepstrogram_debug.R
```
