# Session Summary 2025-12-15: Tremor Metrics Fix - Session 4

## What We Accomplished

### 1. Fixed Critical Variable Typo ✅
**Location:** `R/tremor.R` line 395

**Bug Found:**
```r
# BROKEN:
start_time = min(amp_times)  # ❌ Variable 'amp_times' doesn't exist
```

**Fix Applied:**
```r
# FIXED:
start_time = time_values[1]  # ✅ Correct variable
```

**Impact:** This bug caused ACoM calculation to fail completely, returning 0.000.

### 2. Obtained Brückl Reference Implementation ✅
**Location:** `/tmp/tremor3.05/`

**Key Files:**
- `procedures/readPitchOb.praat` - Extracts intensity from Pitch frame 1
- `procedures/freqtrem.praat` - Frequency tremor analysis
- `procedures/amptrem.praat` - Amplitude tremor analysis
- `results/tremor_resCon.txt` - Reference output values
- `sounds/test_F3_I10_envel_A5_I20.wav` - Test audio file

### 3. Test Results After Fix

**Test file:** `test_F3_I10_envel_A5_I20.wav` (3.0s, synthetic tremor)

| Metric | pladdrr | Praat Ref | Diff | Status |
|--------|---------|-----------|------|--------|
| **FCoM** | 0.920 | 0.938 | -0.018 | ⚠️ Close |
| **FTrC** | 0.886 | 0.999 | -0.113 | ❌ Off |
| **FMoN** | 18.000 | 1.000 | +17.000 | ❌ Off |
| **FTrF** | 3.125 | 3.000 | +0.125 | ✓ Good |
| **FTrI** | 9.760 | 9.899 | -0.139 | ⚠️ Close |
| **FTrP** | 7.394 | 7.424 | -0.030 | ✓ Good |
| **ACoM** | 0.641 | 0.974 | -0.333 | ❌ Off |
| **ATrC** | 0.805 | 0.998 | -0.193 | ❌ Off |
| **AMoN** | 28.000 | 3.000 | +25.000 | ❌ Off |
| **ATrF** | 4.948 | 2.498 | +2.450 | ❌ Off |
| **ATrI** | 18.612 | 17.062 | +1.550 | ⚠️ Close |
| **ATrP** | 15.483 | 12.184 | +3.299 | ❌ Off |

**Summary:**
- ✅ **Fixed**: ACoM no longer returns 0.000 (now 0.641)
- ✓ **Good**: FTrF, FTrP within acceptable range
- ⚠️ **Close**: FCoM, FTrI, ATrI within 2% error
- ❌ **Issues**: Cyclicality (FTrC, ATrC), modulation number (FMoN, AMoN), frequency (ATrF)

## Key Findings from Brückl Source Code

### Algorithm Structure (from `freqtrem.praat`)

```praat
# 1. Extract F0 contour from Pitch
for i to numberOfFrames
   f0 = Get value in frame: i, "Hertz"
   # Store in matrix
endfor

# 2. Remove linear trend (F0 declination)
pi_ftrem_0_linID = Subtract linear fit: "Hertz"

# 3. Normalize by mean F0
am_F0 = Get mean: 0, 0, "Hertz"
Formula: "(self-am_F0)/am_F0"

# 4. Set unvoiced frames to zero
for i from 1 to numberOfFrames
   if f0 = undefined
      Set value: 1, i, 0
   endif
endfor

# 5. Convert Matrix → Sound (at 200 Hz sample rate implicitly)
snd_tremID = To Sound (slice): 1

# 6. Create Pitch from F0 contour Sound
pitrem_nID = To Pitch (cc): slength, minTr, 15, "yes", 
                           tremMagThresh, tremthresh, ocFtrem, 
                           0.35, 0.14, maxTr

# 7. Extract FCoM and FTrC via readPitchOb procedure
call readPiO
ftrm = trm      # intensity field from frame 1
ftrc = trc      # max strength among candidates
```

### Key Parameters

**From Brückl's code:**
- Pitch floor: 1.5 Hz
- Pitch ceiling: 15 Hz
- Time step: Matches original signal (0.005s based on file)
- Voicing threshold: 0.03 (tremMagThresh)
- Octave cost: 0.35 (ocFtrem)

**Current pladdrr:**
- ✅ Pitch floor: 1.5 Hz
- ✅ Pitch ceiling: 15 Hz
- ✅ Time step: 0.005s
- ❌ Other parameters: Using Praat defaults, not Brückl's specific values

### Amplitude Tremor (from `amptrem.praat`)

**Method 1 (manual RMS):**
```praat
# For each glottal period
for iAmpPoint to numbOfAmpPoints
   perStart = Get time from index: iAmpPoint
   perEnd = Get time from index: iAmpPoint+1
   selectObject: sndID
   rms = Get root-mean-square: perStart, perEnd
   Add point: (perStart+perEnd)/2, rms
endfor
```

**Current pladdrr approach:**
- Uses Intensity object → convert dB to linear
- This matches **Method 2** in Brückl's code
- Should be equivalent, but may have subtle differences

## Remaining Issues

### Issue 1: Cyclicality (FTrC, ATrC) Too Low

**Observed:**
- FTrC: 0.886 vs 0.999 expected
- ATrC: 0.805 vs 0.998 expected

**Root Cause:** `readPiO` procedure extracts:
```praat
# Sort candidates by strength (descending)
Sort by column: 3, 0
# Get highest strength
trc = Get value: 1, 3
```

**pladdrr implementation:** Uses autocorrelation of normalized contour, not Pitch candidate strength.

**Solution Needed:** Extract `trc` from Pitch candidates, not from autocorrelation.

### Issue 2: Modulation Number (FMoN, AMoN) Way Too High

**Observed:**
- FMoN: 18 vs 1 expected
- AMoN: 28 vs 3 expected

**Root Cause:** Unknown - need to trace Brückl's `tremProdSum` procedure.

### Issue 3: Contour Magnitude (FCoM, ACoM) Slightly Low

**Observed:**
- FCoM: 0.920 vs 0.938 (-1.9% error)
- ACoM: 0.641 vs 0.974 (-34% error!)

**Possible Causes:**
1. Preprocessing differences (normalization formula?)
2. Pitch extraction parameters (voicing threshold, octave cost)
3. Intensity calculation in Praat vs our extraction

### Issue 4: Amplitude Tremor Frequency (ATrF) Too High

**Observed:**
- ATrF: 4.948 Hz vs 2.498 Hz expected (+98% error!)

**Root Cause:** Spectrum peak detection algorithm differs from Brückl's.

## Next Steps

### Priority 1: Fix Cyclicality (FTrC, ATrC) 🔴 HIGH

**Task:** Implement `readPiO` correctly - extract strength from Pitch candidates.

**Changes needed:**
1. Save Pitch to text file (or access internal candidates directly)
2. Extract all candidates with frequency ≤ maxTr (15 Hz)
3. Sort by strength (descending)
4. Return highest strength as cyclicality

**Code location:** `R/tremor.R` `.compute_tremor_cyclicality()` function

### Priority 2: Fix Modulation Number (FMoN, AMoN) 🔴 HIGH

**Task:** Understand and implement `tremProdSum` procedure.

**Actions:**
1. Read `/tmp/tremor3.05/procedures/tremProdSum.praat`
2. Understand algorithm for counting modulation periods
3. Reimplement in `.detect_tremor_from_spectrum()`

### Priority 3: Improve Contour Magnitude (FCoM, ACoM) 🟡 MEDIUM

**Task:** Match Brückl's exact Pitch parameters.

**Changes:**
1. Use `tremMagThresh = 0.03` (voicing threshold)
2. Use `ocFtrem = 0.35` (octave cost)
3. Verify normalization formula matches

**Expected improvement:** FCoM 0.920 → 0.938, ACoM 0.641 → 0.974

### Priority 4: Fix Amplitude Frequency (ATrF) 🟡 MEDIUM

**Task:** Match spectrum peak detection to Brückl's algorithm.

**Investigate:**
- How Brückl finds dominant tremor frequency
- Whether it uses simple peak or weighted average
- Parameter differences in spectrum analysis

## Files Modified

```
R/tremor.R  (line 395)  - Fixed amp_times → time_values[1]
```

**Status:** Ready to commit after verification

## Build Status

✅ Package builds successfully  
✅ No compilation errors  
✅ Tests run without crashes  
❌ Output values don't match Praat reference

## Commands for Next Session

### Re-test Current State
```bash
cd /Users/frkkan96/Documents/src/pladdrr
Rscript /tmp/test_tremor_clean.R
```

### Examine Brückl Procedures
```bash
iconv -f UTF-16BE -t UTF-8 /tmp/tremor3.05/procedures/tremProdSum.praat
iconv -f UTF-16BE -t UTF-8 /tmp/tremor3.05/procedures/readPitchOb.praat
```

### Debug Specific Metric
```r
library(pladdrr)
sound <- Sound$new('/tmp/tremor3.05/sounds/test_F3_I10_envel_A5_I20.wav')
# Set verbose=TRUE to see intermediate values
result <- analyze_tremor(sound, verbose = TRUE)
```

## References

- **Brückl tremor 3.05 source:** `/tmp/tremor3.05/`
- **Test audio:** `/tmp/tremor3.05/sounds/test_F3_I10_envel_A5_I20.wav`
- **Reference output:** `/tmp/tremor3.05/results/tremor_resCon.txt`
- **Session 3 summary:** `SESSION_SUMMARY_2025-12-11_TREMOR_METRICS.md`
- **Issue status:** `TREMOR_ISSUES_STATUS.md`

---

**Conclusion:** Fixed critical typo enabling ACoM calculation, but algorithm differences remain. Need to implement exact Brückl procedures for cyclicality, modulation number, and refined magnitude calculations.
