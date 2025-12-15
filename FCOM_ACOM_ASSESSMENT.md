# FCoM/ACoM Assessment - 2025-12-15

## Issue Summary

FCoM and ACoM tremor metrics are returning 0.0 instead of expected values (0.599 and 0.442).

## Root Cause Analysis

### Bug 1: Variable Name Typo ✅ FIXED

**Location:** `R/tremor.R` lines 240 and 395

**Problem:** 
```r
# Line 240 (F0 contour)
start_time = min(times)  # ❌ Variable 'times' doesn't exist

# Line 395 (amplitude contour)  
start_time = min(times)  # ❌ Variable 'times' doesn't exist
```

**Cause:**
- Commit 5475179 (Dec 12) added `start_time` parameter to `Sound$from_values()`
- Used wrong variable name `times` instead of `time_values` / `amp_times`
- This caused runtime error: `Error: object 'times' not found`
- FCoM/ACoM calculation never executed, defaulted to 0.0

**Fix Applied:**
```r
# Line 240 - F0 contour
start_time = min(time_values)  # ✅ Correct variable

# Line 395 - Amplitude contour
start_time = min(amp_times)    # ✅ Correct variable
```

**Status:** ✅ FIXED (not yet tested due to build issues)

---

## Algorithm Question: intensity[1] vs max(intensity)?

### What Commit 5475179 Claimed

**Commit message:**
> Fix FCoM/ACoM calculation to use frame 1 intensity (Brückl protocol)
> - Changed from max(intensity) to intensity[1] per readPitchOb.praat
> - Expected: FCoM ~0.599 (was 0.155), ACoM ~0.442 (was 0.156)

**Implementation in commit 5475179:**
```r
# Use frame 1 intensity (following Brückl's readPitchOb.praat implementation)
fcom <- ifelse(nrow(f0_pitch_df) > 0 && "intensity" %in% names(f0_pitch_df) &&
               !is.na(f0_pitch_df$intensity[1]),
               f0_pitch_df$intensity[1],  # ← Frame 1 only
               0.0)
```

### What Previous Session Found

**From SESSION_SUMMARY_2025-12-11_TREMOR_METRICS.md:**

**Test Results with max(intensity):**
- FCoM = 0.1550 (expected ~0.599) ❌
- ACoM = 0.1561 (expected ~0.442) ❌

**Diagnostic output:**
```
F0 pitch df: 54 rows
Intensity range: [0.0802, 0.1550]
FCoM = 0.1550  (using max)
```

**Analysis:** Using `max(intensity)` gave 0.15, but expected was 0.599 (4x difference)

### What Documentation Says

**From TREMOR_ALGORITHM_ANALYSIS.md:**

Two contradicting statements:

**Statement 1 (lines 40-50):**
```praat
# Brückl reads Pitch object's first frame intensity
if startsWith(tEkst$, "intensity")
    trm = extractNumber(tEkst$, "intensity=")  # ← First frame
```
Comment says: "**first frame intensity**"

**Statement 2 (lines 54-58):**
```r
# Our implementation
fcom <- max(f0_pitch_df$intensity, na.rm = TRUE)
```
Comment says: "✅ Our approach is correct!" (using max)

**These contradict each other!**

### What We Need to Determine

**Three possibilities:**

#### Hypothesis A: Frame 1 is Correct (intensity[1])
- Brückl's `readPitchOb.praat` reads first frame from text file
- Commit 5475179 says this gives correct values (0.599, 0.442)
- BUT: Commit 5475179 has typo bug, so **never actually tested**

**To test:** 
1. Fix typo (done)
2. Build package
3. Run test with `intensity[1]`
4. Check if FCoM ≈ 0.599, ACoM ≈ 0.442

#### Hypothesis B: Max is Correct (max(intensity))
- Previous session tested with `max()` and got 0.15
- Expected is 0.599 (4x higher)
- Maybe the issue is elsewhere (normalization, Pitch parameters)

**To test:**
1. Revert to `max(intensity)` 
2. Investigate why values are 4x too low
3. Check normalization/preprocessing steps

#### Hypothesis C: Neither is Correct
- Problem might be in the contour creation/preprocessing
- F0 normalization method incorrect
- Pitch parameters need adjustment
- Different scaling needed

**To test:**
1. Compare our preprocessing with Brückl's Praat scripts line-by-line
2. Check if contour normalization matches Brückl protocol
3. Validate Pitch object creation parameters

---

## Next Steps Priority

### Step 1: Test intensity[1] Approach ⚡ URGENT

**Why:** Commit 5475179 claims this works but was never tested due to typo

**Action:**
1. Build package with typo fix
2. Run tremor analysis on `inst/signalfiles/AVQI/input/sv1.wav`
3. Check if FCoM ≈ 0.599 and ACoM ≈ 0.442

**Expected outcomes:**
- **If YES:** Bug is fixed! ✅
- **If NO:** Need to investigate preprocessing/normalization

### Step 2: If intensity[1] Doesn't Work

**Compare with Brückl Reference:**
1. Find original Brückl Praat scripts (if available)
2. Compare preprocessing step-by-step:
   - F0 extraction parameters
   - Detrending method
   - Normalization formula
   - Uniform resampling method
   - Pitch creation parameters (floor=1.5, ceiling=15 Hz)

**Check Pitch intensity semantics:**
1. What does "intensity" mean in Pitch object from contour Sound?
2. Is it autocorrelation peak height?
3. Does it need rescaling?

### Step 3: Build Test

**Build command:**
```bash
cd /Users/frkkan96/Documents/src/pladdrr
rm -rf /Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/00LOCK-pladdrr
R CMD INSTALL --preclean --no-test-load .
```

**Test command:**
```r
library(pladdrr)
s <- Sound$new('inst/signalfiles/AVQI/input/sv1.wav')
t <- analyze_tremor(s, verbose=TRUE)

# Expected:
# FCoM: 0.599
# ACoM: 0.442
```

---

## Current Code State

### Fixed (uncommitted):
- ✅ Line 240: `start_time = min(time_values)` 
- ✅ Line 395: `start_time = min(amp_times)`

### Current algorithm (from commit 5475179):
- Uses `intensity[1]` (frame 1 only)
- Claimed to give correct values but never tested

### Alternative algorithm (from Dec 11 session):
- Uses `max(intensity)` (maximum across all frames)
- Tested and gave 0.15 (expected 0.599)

---

## References

1. **Commit 5475179** - "Fix FCoM/ACoM tremor metrics & remove debug output"
   - Added `intensity[1]` approach
   - Introduced `times` typo bug
   - Never tested due to bug

2. **SESSION_SUMMARY_2025-12-11** - Tremor metrics investigation
   - Tested `max(intensity)` approach
   - Got FCoM=0.15, expected 0.599
   - Identified that contours have no voiced frames

3. **TREMOR_ALGORITHM_ANALYSIS.md** - Brückl protocol analysis
   - Contains contradicting statements about first frame vs max
   - Need to verify against original Brückl papers

---

## Assessment: Can We Determine if intensity[1] is Correct?

**Answer:** ❌ NO - Cannot determine without testing

**Why:**
1. Commit 5475179 **claimed** intensity[1] works but had typo bug
2. Code never executed, so claim was never validated
3. Previous session only tested max() approach (got wrong values)
4. Documentation has contradicting statements

**What We Know:**
- ✅ Typo bug is fixed
- ✅ Previous max() approach gave 0.15 (wrong)
- ❓ Current intensity[1] approach never tested
- ❓ Which approach Brückl actually uses unclear

**Required:** Build package and run actual test to determine correctness

---

## Recommendation

**Test intensity[1] first** because:
1. Typo is now fixed
2. Commit message claims it works
3. Matches "frame 1" language in some docs
4. Quick to test (just build & run)

**If intensity[1] fails:**
1. Review Brückl papers for exact protocol
2. Check contour preprocessing steps
3. Investigate Pitch intensity scaling
4. May need different approach entirely

---

**Status:** Waiting for package build to complete testing
**Blocker:** R CMD INSTALL hanging/failing on lazy loading
**Next:** Get clean build, then test tremor analysis
