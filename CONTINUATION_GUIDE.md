# pladdrr v1.2.2 - Continuation Guide

## Current State (2025-12-11 09:20 CET)

### ✅ COMPLETE
- All code fixes committed (3 issues addressed)
- Test scripts created and ready
- Documentation updated
- Version bumped to 1.2.2

### ⏳ IN PROGRESS
- Build compiling (~30% done, 1.5 hours remaining)
- Monitoring: `tail -f install.log`

### ⏸️ BLOCKED ON BUILD
- Cannot test until build finishes
- 3 test scripts waiting to run

---

## What Was Fixed (v1.2.1 → v1.2.2)

### Critical Issues
1. **Pitch Type Mismatch (v1.2.1)** - FIXED
   - Problem: 188% tremor frequency error
   - Cause: 32-bit int vs 64-bit integer type
   - Solution: Cast to `integer` when calling Praat
   - File: `src/sound_wrappers.cpp` (4 methods)

2. **Window Shape Enum (v1.2.2)** - FIXED
   - Problem: hamming/hanning SWAPPED + 8 missing types
   - Impact: ALL windowed extracts were wrong
   - Solution: Correct mapping to kSound_windowShape 0-11
   - File: `R/sound-r6-new.R` lines 932-947

3. **Two-Object Peaks (v1.2.2)** - ADDED
   - Missing: `[Sound, Pitch] → To PointProcess (peaks)`
   - Solution: Added `Pitch$to_pointprocess_peaks(sound, ...)`
   - Files: `src/sound_wrappers.cpp`, `R/pitch-r6.R`

---

## Testing Checklist (Run After Build)

### Test 1: Pitch Detection Fix (v1.2.1)
```bash
cd /Users/frkkan96/Documents/src/pladdrr
Rscript test_pitch_fix.R
```

**Expected**:
- Frames 4-9 mostly unvoiced (not all voiced)
- Tremor frequency ~1.7 Hz (not 4.999 Hz)
- <5% error from expected

**If Fails**:
- Check pitch object creation
- Verify type casting in sound_wrappers.cpp
- Compare to Praat desktop output

### Test 2: Window Shapes (v1.2.2)
```bash
Rscript test_window_shapes.R
```

**Expected**:
- All 12 window types pass: rectangular, triangular, parabolic, hanning, hamming, Gaussian1-5, Kaiser1-2
- No errors or crashes
- Each returns valid Sound object

**If Fails**:
- Check enum values in R/sound-r6-new.R
- Verify against Sound_enums.h
- Test individual window type

### Test 3: Two-Object Peaks (v1.2.2)
```bash
Rscript test_two_object_peaks.R
```

**Expected**:
- Creates PointProcess from [Sound, Pitch]
- Maxima, minima, both modes work
- Points > 0 for valid audio

**If Fails**:
- Check wrapper exists: .sound_pitch_to_pointprocess_peaks
- Verify Rcpp exports regenerated
- Test Pitch object validity first

---

## Quick Commands

### Monitor Build
```bash
# Watch compilation progress
tail -f install.log

# Check for errors
grep -i error build.log

# Estimate completion
wc -l install.log  # ~700 lines = done
```

### Load Package (After Build)
```r
library(pladdrr)
packageVersion("pladdrr")  # Should be 1.2.2
```

### Quick Smoke Test
```r
# Test basic functionality
snd <- Sound$create(0.5, 0, 0.5, 16000, 1/16000, 0)

# Test window (should not crash)
part <- snd$extract_part(0, 0.25, window_shape = "hamming")

# Test pitch (should be accurate)
pitch <- snd$to_pitch(time_step = 0.01, pitch_floor = 75, 
                      pitch_ceiling = 600, max_candidates = 15)

# Test new method (should exist)
pp <- pitch$to_pointprocess_peaks(snd, TRUE, FALSE)
```

---

## File Locations

### Modified Code
- `src/sound_wrappers.cpp` - Pitch type cast + peaks wrapper
- `R/sound-r6-new.R` - Window enum fix (lines 932-947)
- `R/pitch-r6.R` - Added to_pointprocess_peaks() method
- `DESCRIPTION` - Version 1.2.2

### Documentation
- `NEWS.md` - Changelogs for v1.2.1 & v1.2.2
- `MISSING_FEATURES_AUDIT.md` - Detailed analysis
- `PITCH_FIX_SESSION_SUMMARY.md` - Technical details
- `SESSION_SUMMARY_2025-12-11.md` - Today's summary
- `PLADDRR_1.2.2_STATUS.md` - Build status tracker

### Tests
- `test_pitch_fix.R` - Validates v1.2.1
- `test_window_shapes.R` - Validates window enum
- `test_two_object_peaks.R` - Validates new method

### Logs
- `install.log` - Build output (active)
- `build.log` - Error summary (should be empty)

---

## Troubleshooting

### Build Hangs
```bash
# Check if still compiling
ps aux | grep -i "r cmd"

# Kill and restart
pkill -f "R CMD INSTALL"
R CMD INSTALL --preclean .
```

### Build Fails
```bash
# Clean everything
rm -rf src/*.o src/*.so
R CMD INSTALL --preclean .

# Check for actual errors (ignore warnings)
grep "^Error" install.log
```

### Tests Fail
```r
# Load package in debug mode
devtools::load_all()

# Test individual components
snd <- Sound$create(0.1, 0, 0.1, 1000, 0.001, 0)
class(snd)  # Should be "Sound"
snd$get_duration()  # Should be 0.1

# Check method exists
"to_pointprocess_peaks" %in% names(Pitch)
```

---

## Next Steps After Testing

### If All Tests Pass ✅
1. Update PLADDRR_1.2.2_STATUS.md with results
2. Create final commit: "v1.2.2 testing complete"
3. Consider CRAN submission:
   - Run `R CMD check --as-cran`
   - Verify no errors/warnings
   - Update documentation if needed

### If Tests Fail ❌
1. Identify which test failed
2. Check relevant code changes
3. Compare to Praat desktop behavior
4. Debug and fix
5. Rebuild and retest

### Additional Validation
1. Run full test suite: `devtools::test()`
2. Check examples: `devtools::run_examples()`
3. Build vignettes: `devtools::build_vignettes()`
4. Memory check: Run with valgrind (if on Linux)

---

## Key Technical Details

### Type Casting Pattern (v1.2.1)
```cpp
// WRONG (old code)
autoPitch pitch = Sound_to_Pitch(sound, time_step, pitch_floor, 
                                  pitch_ceiling, max_candidates, ...);

// RIGHT (new code)  
autoPitch pitch = Sound_to_Pitch(sound, time_step, pitch_floor, 
                                  pitch_ceiling, 
                                  static_cast<integer>(max_candidates), ...);
```

### Window Enum Mapping (v1.2.2)
```r
# Maps to kSound_windowShape in Sound_enums.h
window_codes <- c(
  rectangular = 0,
  triangular = 1,
  parabolic = 2,
  hanning = 3,      # Was 4 - FIXED
  hamming = 4,      # Was 1 - FIXED
  Gaussian1 = 5,    # NEW
  # ... up to Kaiser2 = 11
)
```

### Two-Object Method Pattern (v1.2.2)
```cpp
// C++ wrapper takes both objects
XPtr<structPointProcess> sound_pitch_to_pointprocess_peaks(
    XPtr<structSound> sound,
    XPtr<structPitch> pitch,
    bool include_maxima,
    bool include_minima
) {
    // Call Praat function with both
    autoPointProcess pp = Sound_Pitch_to_PointProcess_peaks(
        sound.get(), pitch.get(), include_maxima, include_minima
    );
    return create_xptr(pp);
}
```

```r
# R6 method on Pitch class
to_pointprocess_peaks = function(sound, 
                                 include_maxima = TRUE, 
                                 include_minima = FALSE) {
    # Pass both self (pitch) and sound
    pp_ptr <- .sound_pitch_to_pointprocess_peaks(
        sound$get_ptr(),
        private$ptr,  # self as Pitch
        include_maxima,
        include_minima
    )
    PointProcess$new(.xptr = pp_ptr)
}
```

---

## Commit History
```
c21b22e - Add v1.2.2 build status tracker
de88d6f - Add test scripts for v1.2.2 fixes
67e4b65 - v1.2.2: Fix window enums, add peaks method
ae27d05 - Fix 3 missing features
64867f7 - Update session summary
d762fd7 - Add test script for pitch fix
d203e28 - v1.2.1: Pitch type mismatch fix
6da6e20 - Fix pitch detection type cast
```

---

## Contact Points

### Repository
- Local: `/Users/frkkan96/Documents/src/pladdrr`
- Branch: `001-praat-r-access`
- Remote: (check with `git remote -v`)

### Related Projects
- Praat source: `src/praat.github.io/` (submodule)
- Original issue: User reported 3 missing features

---

**Last Updated**: 2025-12-11 09:20 CET  
**Next Action**: Wait for build, then run 3 test scripts  
**Expected Resolution**: ~2 hours
