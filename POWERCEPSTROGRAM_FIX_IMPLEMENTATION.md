# PowerCepstrogram Fix - Implementation Plan

**Date:** 2025-12-05  
**Status:** 📋 READY TO IMPLEMENT  
**Issue:** `sound$to_powercepstrogram()` fails despite Praat application working

---

## Root Cause Analysis

Since Praat application successfully creates PowerCepstrograms but pladdrr fails, the issue is **definitely in our wrapper code**, not Praat's C++ core.

### Most Likely Causes (Ranked by Probability)

1. **Parameter validation/constraints** (80% probability)
   - Sound duration too short for analysis window
   - Invalid parameter ranges
   - Nyquist frequency violations

2. **Sound object state** (15% probability)
   - Sound pointer not properly initialized
   - Missing sound data

3. **Memory management** (5% probability)
   - XPtr creation issues
   - AutoPtr transfer problems

---

## Immediate Fixes to Apply

### Fix 1: Add Comprehensive Parameter Validation

**File:** `src/powercepstrum_wrappers.cpp`

**Location:** In `.sound_to_powercepstrogram()` function, after `if (!sound) stop("Invalid Sound pointer");`

```cpp
// Validate Sound object
if (sound->nx <= 0) {
    stop("Sound object has no samples");
}
if (sound->dx <= 0) {
    stop("Sound object has invalid sample period (dx <= 0)");
}

double duration = sound->xmax - sound->xmin;
if (duration <= 0) {
    stop("Sound object has invalid duration");
}

double nyquist_freq = 0.5 / sound->dx;
double sampling_rate = 1.0 / sound->dx;

// Validate pitch_floor
if (pitch_floor <= 0) {
    stop("pitch_floor must be positive");
}
if (pitch_floor >= nyquist_freq) {
    stop("pitch_floor (" + std::to_string(pitch_floor) + 
         " Hz) must be less than Nyquist frequency (" + 
         std::to_string(nyquist_freq) + " Hz)");
}

// Validate duration vs pitch_floor
// Praat requires at least ~3 pitch periods for analysis
double min_duration = 3.0 / pitch_floor;
if (duration < min_duration) {
    stop("Sound duration (" + std::to_string(duration) + 
         " s) is too short for pitch_floor " + 
         std::to_string(pitch_floor) + " Hz. " +
         "Minimum duration: " + std::to_string(min_duration) + " s. " +
         "Either use a longer sound or increase pitch_floor.");
}

// Validate time_step
if (time_step <= 0) {
    stop("time_step must be positive");
}
if (time_step > duration) {
    stop("time_step (" + std::to_string(time_step) + 
         " s) cannot be longer than sound duration (" + 
         std::to_string(duration) + " s)");
}

// Validate maximum_frequency
if (maximum_frequency <= 0) {
    stop("maximum_frequency must be positive");
}
if (maximum_frequency >= nyquist_freq) {
    stop("maximum_frequency (" + std::to_string(maximum_frequency) + 
         " Hz) must be less than Nyquist frequency (" + 
         std::to_string(nyquist_freq) + " Hz). " +
         "Sound sampling rate is " + std::to_string(sampling_rate) + " Hz.");
}

// Validate pre_emphasis_frequency
if (pre_emphasis_frequency < 0) {
    stop("pre_emphasis_frequency cannot be negative");
}
if (pre_emphasis_frequency > 0 && pre_emphasis_frequency >= nyquist_freq) {
    stop("pre_emphasis_frequency (" + std::to_string(pre_emphasis_frequency) + 
         " Hz) must be less than Nyquist frequency (" + 
         std::to_string(nyquist_freq) + " Hz)");
}
```

### Fix 2: Improve Error Handling

**Already implemented** - Good error reporting exists, just needs the validation above.

### Fix 3: Add Debug Information (Optional, for Testing)

```cpp
#ifdef PLADDRR_DEBUG
Rcpp::Rcout << "PowerCepstrogram parameters:" << std::endl;
Rcpp::Rcout << "  Sound duration: " << duration << " s" << std::endl;
Rcpp::Rcout << "  Sampling rate: " << sampling_rate << " Hz" << std::endl;
Rcpp::Rcout << "  Nyquist freq: " << nyquist_freq << " Hz" << std::endl;
Rcpp::Rcout << "  pitch_floor: " << pitch_floor << " Hz" << std::endl;
Rcpp::Rcout << "  time_step: " << time_step << " s" << std::endl;
Rcpp::Rcout << "  maximum_frequency: " << maximum_frequency << " Hz" << std::endl;
Rcpp::Rcout << "  pre_emphasis_frequency: " << pre_emphasis_frequency << " Hz" << std::endl;
#endif
```

---

## R-Side Improvements

### Fix 4: Update R6 Method with Better Defaults

**File:** `R/sound-r6-new.R`

Find the `to_powercepstrogram()` method and update documentation:

```r
#' @description
#' Convert Sound to PowerCepstrogram
#' 
#' Creates a time-varying power cepstrum representation. This is essential
#' for computing CPPS (Smoothed Cepstral Peak Prominence) used in voice
#' quality analysis.
#' 
#' **Important constraints:**
#' - Sound duration must be at least 3 pitch periods (3/pitch_floor seconds)
#' - maximum_frequency must be less than Nyquist frequency of the sound
#' - For standard voice analysis, use a sound of at least 0.5 seconds
#' 
#' @param pitch_floor Numeric. Minimum pitch in Hz (default: 60).
#'   Lower values require longer sounds.
#' @param time_step Numeric. Time step between frames in seconds (default: 0.002).
#'   Smaller values give finer time resolution.
#' @param maximum_frequency Numeric. Maximum frequency to analyze in Hz (default: 5000).
#'   Must be less than half the sampling rate. For voice: 5000-8000 Hz is typical.
#' @param pre_emphasis_frequency Numeric. Pre-emphasis from this frequency in Hz (default: 50).
#'   Boosts high frequencies. Use 50 Hz for voice.
#' 
#' @return PowerCepstrogram object
#' 
#' @examples
#' \dontrun{
#' # Ensure sound is long enough
#' sound <- Sound$new("voice.wav")
#' if (sound$get_duration() < 0.5) {
#'   warning("Sound may be too short for reliable analysis")
#' }
#' 
#' # Create PowerCepstrogram
#' pcep <- sound$to_powercepstrogram(
#'   pitch_floor = 75,
#'   time_step = 0.002,
#'   maximum_frequency = 5000,
#'   pre_emphasis_frequency = 50
#' )
#' 
#' # Get CPPS
#' cpps <- pcep$get_cpps()
#' }
```

### Fix 5: Add Helper Function for Parameter Validation

**File:** `R/sound-r6-new.R` (before the Sound class definition)

```r
#' Validate PowerCepstrogram parameters
#' @keywords internal
validate_powercepstrogram_params <- function(sound_duration, sampling_rate, 
                                              pitch_floor, time_step, 
                                              maximum_frequency, 
                                              pre_emphasis_frequency) {
  nyquist <- sampling_rate / 2
  
  # Check minimum duration
  min_dur <- 3.0 / pitch_floor
  if (sound_duration < min_dur) {
    stop(sprintf(
      "Sound duration (%.3f s) is too short for pitch_floor = %.1f Hz.\n", 
      sound_duration, pitch_floor,
      "  Minimum required duration: %.3f s\n",
      min_dur,
      "  Options:\n",
      "  1. Use a longer sound recording\n",
      "  2. Increase pitch_floor (e.g., %.1f Hz for current duration)\n",
      "  3. For speech: typical minimum is 0.5 seconds"
    ), min_dur, 3.0 / sound_duration)
  }
  
  # Check Nyquist violations
  if (maximum_frequency >= nyquist) {
    stop(sprintf(
      "maximum_frequency (%.1f Hz) must be < Nyquist frequency (%.1f Hz).\n",
      maximum_frequency, nyquist,
      "  Sound sampling rate: %.1f Hz\n",
      sampling_rate,
      "  Suggestion: Use maximum_frequency = %.1f Hz",
      nyquist * 0.8
    ))
  }
  
  invisible(TRUE)
}
```

Then call it in `to_powercepstrogram()`:

```r
to_powercepstrogram = function(pitch_floor = 60.0, time_step = 0.002, 
                               maximum_frequency = 5000.0, 
                               pre_emphasis_frequency = 50.0) {
  # Validate parameters (R-side)
  validate_powercepstrogram_params(
    sound_duration = self$get_duration(),
    sampling_rate = self$get_sampling_frequency(),
    pitch_floor = pitch_floor,
    time_step = time_step,
    maximum_frequency = maximum_frequency,
    pre_emphasis_frequency = pre_emphasis_frequency
  )
  
  # Call C++ wrapper
  pcep_ptr <- .sound_to_powercepstrogram(
    private$ptr, pitch_floor, time_step, 
    maximum_frequency, pre_emphasis_frequency
  )
  PowerCepstrogram$new(pcep_ptr)
}
```

---

## Testing Plan

### Test 1: Simple Tone (Should Work)
```r
sound <- Sound$new_tone(440, 0.2, 1.0, 44100)
pcep <- sound$to_powercepstrogram()  # Should succeed
```

### Test 2: Too Short Sound (Should Fail with Clear Message)
```r
sound <- Sound$new_tone(440, 0.2, 0.01, 44100)  # 10ms
pcep <- sound$to_powercepstrogram(pitch_floor = 60)  # Should fail
# Expected error: "Sound duration (0.010 s) is too short for pitch_floor = 60.0 Hz..."
```

### Test 3: Nyquist Violation (Should Fail with Clear Message)
```r
sound <- Sound$new_tone(440, 0.2, 1.0, 10000)  # Low sample rate
pcep <- sound$to_powercepstrogram(maximum_frequency = 6000)  # Should fail
# Expected error: "maximum_frequency (6000.0 Hz) must be < Nyquist frequency (5000.0 Hz)..."
```

### Test 4: Real Voice File (Should Work)
```r
sound <- Sound$new("inst/extdata/vowel.wav")
pcep <- sound$to_powercepstrogram()
cpps <- pcep$get_cpps()
# Expected: CPPS value between 5-20 dB
```

---

## Implementation Steps

1. ✅ **Analyze current code** - DONE
2. ✅ **Create fix plan** - DONE (this document)
3. ⬜ **Apply Fix 1** - Add C++ validation to `powercepstrum_wrappers.cpp`
4. ⬜ **Apply Fix 4** - Update R documentation
5. ⬜ **Apply Fix 5** - Add R-side validation helper
6. ⬜ **Compile package** - `R CMD INSTALL --preclean .`
7. ⬜ **Run Test 1-4** - Verify fixes work
8. ⬜ **Create unit tests** - Add to `tests/testthat/`
9. ⬜ **Update NEWS.md** - Document fix
10. ⬜ **Commit changes** - With descriptive message

---

## Expected Outcomes

### Before Fix
```
Error: Failed to create PowerCepstrogram from Sound
```
(Unhelpful, doesn't explain why)

### After Fix
```
Error: Sound duration (0.010 s) is too short for pitch_floor = 60.0 Hz.
  Minimum required duration: 0.050 s
  Options:
  1. Use a longer sound recording
  2. Increase pitch_floor (e.g., 300.0 Hz for current duration)
  3. For speech: typical minimum is 0.5 seconds
```
(Clear, actionable error message)

---

## Files to Modify

1. `src/powercepstrum_wrappers.cpp` - Add validation (Fix 1)
2. `R/sound-r6-new.R` - Update docs and add R validation (Fix 4, 5)
3. `tests/testthat/test-powercepstrogram.R` - Add tests (create if needed)
4. `NEWS.md` - Document fix

---

## Success Criteria

- [ ] PowerCepstrogram creation works with valid parameters
- [ ] Clear error messages for invalid parameters
- [ ] Works with real voice files
- [ ] CPPS calculation returns reasonable values
- [ ] All tests pass
- [ ] No regression in other functionality

---

## Rollout Strategy

1. **Implement fixes** (30 min)
2. **Test locally** (15 min)
3. **Create unit tests** (15 min)
4. **Documentation** (10 min)
5. **Commit** (5 min)

**Total time estimate:** 75 minutes

---

##Next Action

**APPLY FIX 1** - Add validation to C++ wrapper
