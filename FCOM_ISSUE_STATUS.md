# FCoM/ACoM Issue Status - 2025-12-15

## Problem Summary

FCoM and ACoM tremor metrics returning wrong values after typo fix.

**Expected:**
- FCoM: 0.599
- ACoM: 0.442

**Getting (after typo fix):**
- FCoM: 0.087
- ACoM: 0.000

## Root Cause Found

The F0 contour Sound **produces NO detectable pitch** when converted to Pitch object!

### Evidence

```r
f0_pitch <- f0_sound$to_pitch(pitch_floor=1.5, pitch_ceiling=15)
f0_pitch_df <- f0_pitch$as_data_frame(include_intensity=TRUE, include_strength=TRUE)
```

Result:
- All `frequency` = NA (no pitch detected!)
- All `strength` = NA (no autocorrelation peaks!)
- Only `intensity` values exist: range 0.12-0.19

This is expected because:
- F0 contour is normalized: values ~±0.15
- Sample rate is only 200 Hz
- Pitch parameters: floor=1.5 Hz, ceiling=15 Hz
- The signal is too weak for autocorrelation to find peaks

## Historical Context

### Commit History

**Before 5475179:**
```r
# Used strength from AUDIO Pitch object (wrong approach)
pitch_df <- pitch$as_data_frame(include_strength = TRUE)
fcom <- max(strength[voiced])  # Got 0.155
```

**Commit 5475179 (Dec 12):**
```r
# Changed to intensity from F0 CONTOUR Pitch
f0_pitch <- f0_sound$to_pitch(...)
fcom <- f0_pitch_df$intensity[1]  # Had typo bug, never tested
```

**Now (typo fixed):**
```r
# Typo fixed but approach still wrong
fcom <- f0_pitch_df$intensity[1]  # Gets 0.087 (expected 0.599)
```

## Fundamental Issue

**Question:** What does Brückl's protocol ACTUALLY require?

**Current implementation:** Create Pitch from F0 contour, extract intensity
- This is failing because F0 contour has no detectable pitch!
- Intensity values (0.12-0.19) are much lower than expected (0.599)

**Possible alternatives:**
1. Use different Pitch property (not intensity)
2. Calculate RMS/energy directly from F0 contour samples
3. Use spectrum magnitude at tremor frequency
4. Different normalization/scaling

## Test Results

### Test 1: Current Implementation
```
FCoM: 0.087 (expected 0.599) - WRONG
ACoM: 0.000 (expected 0.442) - WRONG
FTrC: 0.256 (expected 0.998) - WRONG
FTrF: 1.823 Hz (expected 5.169) - WRONG
```

### Test 2: Intensity Values from F0 Pitch
```
intensity[1]: 0.119
max(intensity): 0.192
mean(intensity): 0.153
All frequency: NA (no pitch detected!)
All strength: NA (no autocorrelation!)
```

## Questions for User

1. **What does Brückl's readPitchOb.praat actually do?**
   - Does it create Pitch from F0 contour?
   - What frame does it use (first, max, mean)?
   - Does it use intensity or a different field?

2. **Is the F0 contour preprocessing correct?**
   - Detrending: `f0_detrended = f0_values - predict(lm(f0_values ~ f0_times))`
   - Normalization: `f0_normalized = f0_detrended / mean_f0`
   - Expected range: -0.27 to +0.04
   - Is this the correct formula?

3. **Should we use intensity at all?**
   - Given F0 contour has no detectable pitch...
   - Maybe RMS of contour samples instead?
   - Or spectrum magnitude?
   - Or different metric entirely?

4. **External analysis mentioned bug:**
   > External codebase has: `intensity <- strength` (conflates two properties)
   
   - Is this referring to a bug in pladdrr's R/tremor.R?
   - Or in separate R_implementations/ codebase?
   - Should pladdrr be using strength instead of intensity?

## Next Steps

**BLOCKED:** Cannot proceed without clarification on Brückl protocol

**Need:**
1. Reference to readPitchOb.praat script
2. Brückl papers (2012, 2015) with FCoM definition
3. Confirmation of correct approach

**Once clarified, options:**
- **Option A:** Fix preprocessing (if normalization wrong)
- **Option B:** Use different Pitch property (if intensity wrong field)
- **Option C:** Calculate RMS directly (if Pitch approach wrong)
- **Option D:** Use spectrum-based calculation (alternative metric)

## Files Modified (Uncommitted)

- `R/tremor.R` - Lines 240, 395 (typo fixes: `times` → `time_values`, `amp_times`)

## Build Status

✅ Package builds successfully  
✅ Tests run without errors  
❌ Values are wrong

---

**Status:** INVESTIGATION PAUSED - Need Brückl protocol clarification
**Last Updated:** 2025-12-15
