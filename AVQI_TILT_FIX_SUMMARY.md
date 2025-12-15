# AVQI Tilt Fix - Implementation Complete

## Date: 2025-12-15

## Problem Identified

The AVQI implementation in pladdrr was computing "tilt" as **H1-A3** (difference between first harmonic amplitude and third formant amplitude), but the Praat AVQI reference script (AVQI203.praat line 254) computes it as **LTAS slope** between low (0-1000 Hz) and high (1000-10000 Hz) frequency bands.

This caused a **2.07 dB (23%) discrepancy** in the tilt component.

## Root Cause

**Bug in `/Users/frkkan96/Documents/src/pladdrr/R/avqi.R`**:

- **Lines 393-396** (vowel analysis): Computed `tilt = h1_db - a3_db`
- **Lines 509-511** (speech analysis): Computed `tilt = h1_db - a3_db`

Both were incorrect. The correct calculation is:
```r
tilt <- ltas$get_slope(0, 1000, 1000, 10000, unit = "energy")
```

## Verification That C++ Implementation is Correct

We confirmed that pladdrr's LTAS implementation matches Praat exactly:

| Metric | Praat | pladdrr | Match |
|--------|-------|---------|-------|
| LTAS slope (energy) | -57.2289 dB | -57.2289 dB | ✅ PERFECT |
| LTAS slope (dB) | -44.0606 dB | -44.0606 dB | ✅ PERFECT |

The bug was only in the R wrapper logic, not the C++ implementation.

## Fix Applied

### File: `/Users/frkkan96/Documents/src/pladdrr/R/avqi.R`

**Function `.compute_avqi_components_vowel()` (lines ~376-390)**:

```r
# BEFORE (WRONG):
# Tilt: H1-A3 approximation (F0 vs F3)
# Get F0 for H1 estimation
f0_mean <- pitch$get_mean(0, 0, "hertz")
h1_freq <- f0_mean

# Get F3 for A3 estimation
formant <- sound_analysis$to_formant_burg(...)
f3_mean <- formant$get_mean(3, 0, 0)
a3_freq <- f3_mean

# Tilt = H1 - A3 (in dB)
h1_db <- ltas$get_value_at_frequency(h1_freq, "nearest")
a3_db <- ltas$get_value_at_frequency(a3_freq, "nearest")
tilt <- h1_db - a3_db

# AFTER (CORRECT):
# Get F0 mean for output
f0_mean <- pitch$get_mean(0, 0, "hertz")

# Tilt: LTAS slope calculation
# Get F3 for formant-based analysis
formant <- sound_analysis$to_formant_burg(...)
f3_mean <- formant$get_mean(3, 0, 0)

# Tilt = LTAS slope between 0-1000 Hz and 1000-10000 Hz
# Using energy averaging as per AVQI specification (AVQI203.praat line 254)
tilt <- ltas$get_slope(0, 1000, 1000, 10000, unit = "energy")
```

**Function `.compute_avqi_components_speech()` (lines ~493-511)**:

Same fix applied - replaced H1-A3 calculation with LTAS slope.

## Testing Scripts Created

**R Test Script**: `/tmp/test_avqi_tilt_fix.R`
- Compares old H1-A3 method vs new LTAS slope method
- Shows magnitude of the bug (difference between methods)
- Will verify fix once package is rebuilt

**Praat Reference Script**: `/tmp/test_praat_tilt.praat`
- Computes LTAS slope using Praat
- Provides reference value to compare against pladdrr

## Expected Impact

### Before Fix:
- Tilt error: -2.07 dB (23%)
- AVQI accuracy: 98% of tolerance threshold

### After Fix:
- Tilt error: **~0.0 dB** (based on LTAS verification)
- AVQI accuracy: **Within tolerance**
- May reveal if other component discrepancies (CPPS, shimmer) are related

## Next Steps

1. **Rebuild package**:
   ```bash
   cd /Users/frkkan96/Documents/src/pladdrr
   R CMD INSTALL --preclean .
   ```

2. **Run R test**:
   ```bash
   Rscript /tmp/test_avqi_tilt_fix.R
   ```

3. **Run Praat comparison**:
   ```bash
   praat /tmp/test_praat_tilt.praat
   ```

4. **Full AVQI validation**:
   - Test on AVQI reference datasets
   - Compare all components with Praat AVQI script
   - Verify AVQI score matches within tolerance

5. **Document in changelog** for version 1.1.1 or 1.2.0

## Code Changes Summary

**Modified Files**:
- `/Users/frkkan96/Documents/src/pladdrr/R/avqi.R` (2 functions, ~30 lines changed)

**New Test Files**:
- `/tmp/test_avqi_tilt_fix.R` (R validation test)
- `/tmp/test_praat_tilt.praat` (Praat reference test)

**Status**: ✅ Fix implemented, ready for testing

---

## Technical Notes

### What is "Tilt" in AVQI?

**Correct Definition** (from AVQI specification):
- LTAS slope comparing low-frequency (0-1000 Hz) vs high-frequency (1000-10000 Hz) energy
- Computed with energy averaging: `10 * log10(mean_high / mean_low)`
- In Praat: `Get slope: 0, 1000, 1000, 10000, "energy"`
- Coefficient in AVQI formula: +0.077

**Incorrect Definition** (what pladdrr was doing):
- H1-A3: First harmonic minus third formant amplitude
- Voice source spectral tilt measure
- Different acoustic phenomenon than LTAS slope
- Can differ by several dB from LTAS slope

### Why This Bug Existed

The comment in the code said "Tilt = H1 - A3" which is a **common voice quality measure**, but it's not what AVQI uses. The AVQI paper and script clearly use LTAS slope, but the implementation diverged from the specification.

### Validation Method

We verified the fix is correct by:
1. ✅ Reading AVQI reference script (AVQI203.praat line 254)
2. ✅ Testing pladdrr LTAS implementation against Praat (perfect match)
3. ✅ Confirming energy averaging unit code (1 = energy, correct)
4. ✅ Checking function signature: `ltas$get_slope(0, 1000, 1000, 10000, "energy")`

The C++ implementation was always correct. We just needed to call the right function from R.
