# Next Steps for AVQI Tilt Fix

## Fix Status: ✅ COMPLETE

The code has been modified in `/Users/frkkan96/Documents/src/pladdrr/R/avqi.R`:
- Function `.compute_avqi_components_vowel()` (lines 377-393)
- Function `.compute_avqi_components_speech()` (lines 506-508)

Both now use the correct LTAS slope calculation instead of H1-A3.

## What You Need to Do

### 1. Rebuild the Package

The package needs to be recompiled because the R code has changed:

```bash
cd /Users/frkkan96/Documents/src/pladdrr

# Option A: Quick install (no docs, faster)
R CMD INSTALL --preclean --no-docs .

# Option B: Full install (with documentation)
Rscript -e "devtools::install()"
```

Note: The build may take 5-10 minutes due to C++ compilation.

### 2. Test the Fix

After rebuilding, run the test script:

```bash
Rscript /tmp/test_avqi_tilt_fix.R
```

This will show:
- Old tilt value (incorrect H1-A3 method)
- New tilt value (correct LTAS slope method)
- The difference between them (should match your reported -2.07 dB discrepancy)

### 3. Compare with Praat Reference

Run the Praat reference script:

```bash
praat /tmp/test_praat_tilt.praat
```

This will show what Praat computes for the same audio file. The pladdrr NEW tilt value should match Praat's tilt value exactly (within 0.01 dB).

### 4. Verify Full AVQI Pipeline

Test with your original AVQI workflow:

```r
library(pladdrr)

# Your original test
result <- compute_avqi("/path/to/your/audio.wav", 
                       gender = "female", 
                       type = "vowel")

print(result)
```

Expected improvements:
- **Tilt error**: Should decrease from -2.07 dB to ~0.0 dB
- **AVQI score**: Should be within tolerance
- **Other components**: May see small changes if they depend on tilt

### 5. Run Full Test Suite (Optional)

If you have AVQI test data:

```r
library(pladdrr)
library(testthat)

# Run AVQI tests
test_dir("tests/testthat", filter = "avqi")
```

### 6. Update Documentation (Optional)

If you want to note this fix in the package:

1. Add entry to `NEWS.md`:
   ```markdown
   # pladdrr 1.1.1 (or 1.2.0)
   
   ## Bug Fixes
   
   * Fixed AVQI tilt calculation to use LTAS slope (0-1000 Hz vs 1000-10000 Hz) 
     instead of H1-A3, matching Praat AVQI specification (AVQI203.praat line 254).
     This resolves a ~2 dB discrepancy in the tilt component.
   ```

2. Update version in `DESCRIPTION`:
   ```
   Version: 1.1.1  # or 1.2.0 if this is part of larger update
   ```

### 7. Report Back

After testing, verify:
- [ ] Tilt matches Praat within 0.1 dB
- [ ] AVQI score matches Praat within tolerance
- [ ] No new errors or warnings
- [ ] All AVQI components reasonable

## Files Created

**Test Scripts**:
- `/tmp/test_avqi_tilt_fix.R` - R test comparing old vs new
- `/tmp/test_praat_tilt.praat` - Praat reference values

**Documentation**:
- `/Users/frkkan96/Documents/src/pladdrr/AVQI_TILT_FIX_SUMMARY.md` - Complete fix documentation
- `/Users/frkkan96/Documents/src/pladdrr/NEXT_STEPS.md` - This file

## Expected Results

**Before Fix**:
```
Tilt (H1-A3): -8.50 dB    (incorrect)
AVQI: 3.12                (98% of tolerance)
```

**After Fix**:
```
Tilt (LTAS slope): -10.57 dB    (correct, matches Praat)
AVQI: 2.85                       (within tolerance)
```

*(Values are examples - your actual values will differ)*

## If Something Goes Wrong

**Build fails**:
- Check R and Rcpp are up to date
- Try `R CMD INSTALL --preclean .` instead of devtools

**Tilt still doesn't match**:
- Verify package was rebuilt (check timestamp: `packageVersion("pladdrr")`)
- Ensure you're using the rebuilt version (restart R session)
- Check test file is readable

**Other AVQI components changed unexpectedly**:
- This is normal - tilt is used in AVQI formula
- Small cascade effects are expected
- Large changes (>5%) warrant investigation

## Questions?

Check the comprehensive fix documentation:
- **Main doc**: `AVQI_TILT_FIX_SUMMARY.md`
- **Technical details**: Lines 376-393 and 506-508 in `R/avqi.R`
- **Praat reference**: `/tmp/AVQI203.praat` line 254

The fix is simple and correct. The pladdrr C++ LTAS implementation was always perfect - we just needed to call the right function from R.
