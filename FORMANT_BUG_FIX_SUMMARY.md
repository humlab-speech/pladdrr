# Formant Unit Code Bug Fix - Summary

**Date**: January 6, 2026  
**Version**: pladdrr 2.0.4  
**Severity**: CRITICAL  
**Status**: FIXED ✅

---

## Bug Description

The `Formant` R6 class had an incorrect unit code mapping in the internal `unit_code()` helper function, causing all formant query methods to return values in the wrong scale when users requested "hertz".

### Root Cause

**File**: `R/formant-r6.R` (line 38-41)

**Incorrect Code** (before fix):
```r
unit_code <- function(unit) {
  unit <- match.arg(tolower(unit), c("hertz", "bark"))
  if (unit == "hertz") 1L else 2L  # ❌ WRONG!
}
```

**Correct Code** (after fix):
```r
unit_code <- function(unit) {
  unit <- match.arg(tolower(unit), c("hertz", "bark"))
  if (unit == "hertz") 0L else 1L  # ✅ CORRECT
}
```

The function was returning `1L` for "hertz" and `2L` for "bark", when it should return `0L` for "hertz" and `1L` for "bark" (matching Praat's internal unit encoding).

---

## Impact

### User-Visible Symptom

When users called formant methods with `unit = "hertz"`, they received **Bark scale values** instead:

```r
formant <- sound$to_formant_burg()

# User requests Hertz, but got Bark values
f1 <- formant$get_value_at_time(1, 0.5, "hertz")
# Returned: ~7 (Bark scale - WRONG!)
# Expected: ~862 (Hertz scale)

# Workaround: Extract via data frame
df <- formant$as_data_frame()
f1_correct <- df$F1[which.min(abs(df$time - 0.5))]
# Returned: 862.51 Hz (correct)
```

### Affected Methods

All formant query methods that accept a `unit` parameter:

1. `get_value_at_time(formant_number, time, unit)`
2. `get_bandwidth_at_time(formant_number, time, unit)`
3. `get_mean(formant_number, from_time, to_time, unit)`
4. `get_standard_deviation(formant_number, from_time, to_time, unit)`
5. `get_quantile(formant_number, quantile, from_time, to_time, unit)`
6. `get_minimum(formant_number, from_time, to_time, unit, interpolate)`
7. `get_maximum(formant_number, from_time, to_time, unit, interpolate)`
8. `get_time_of_minimum(formant_number, from_time, to_time, unit, interpolate)`
9. `get_time_of_maximum(formant_number, from_time, to_time, unit, interpolate)`

### Why Tests Still Passed

Users of the plabench validation toolkit had already implemented a workaround:

**From**: `plabench/R_implementations/pharyngeal.R` (lines 302-309)

```r
# NOTE: pladdrr get_value_at_time(unit="hertz") bug returns Bark instead of Hz
# WORKAROUND: Extract via dataframe instead

get_formant_at_time <- function(df, time_val, formant_col) {
  idx <- which.min(abs(df$time - time_val))
  val <- df[[formant_col]][idx]
  if (is.na(val)) return(UNDEFINED)
  return(val)
}

# Get data as dataframe first
formant_df <- pivot_formant_to_wide(formant_track$as_data_frame())

# Use dataframe method instead of get_value_at_time()
f1_start <- get_formant_at_time(formant_df, start_point_frame, "F1")
# NOT: f1_start <- formant_track$get_value_at_time(1, start_point_frame, "hertz")
```

All plabench tests bypassed the buggy method and extracted formant values via `as_data_frame()`, which returns correct Hertz values.

---

## Discovery

**Discovered by**: plabench 3-way validation testing (Praat ↔ Python ↔ R)  
**Reported in**: `VALIDATION_REPORT.md` (lines 240-306)  
**Date**: January 5, 2026

The bug was discovered during comprehensive cross-platform validation when comparing formant extraction results across Praat scripts, Python/Parselmouth, and R/pladdrr implementations.

---

## Fix Details

### Change Summary

**Single line change** in `R/formant-r6.R` line 40:

```diff
  unit_code <- function(unit) {
    unit <- match.arg(tolower(unit), c("hertz", "bark"))
-   if (unit == "hertz") 1L else 2L
+   if (unit == "hertz") 0L else 1L
  }
```

### Verification

New test added to `tests/testthat/test-formant-r6.R`:

```r
test_that("Formant unit bug fix: get_value_at_time returns correct scale", {
  skip_if_not(require("pladdrr"), message = "speaker package not available")
  
  sound <- create_test_sound()
  formant <- sound$to_formant_burg()
  
  # Get F1 at time 0.25 using get_value_at_time with "hertz"
  f1_method <- formant$get_value_at_time(1, 0.25, unit = "hertz")
  
  # Get F1 at time 0.25 from data frame
  df <- formant$as_data_frame()
  idx <- which.min(abs(df$time - 0.25))
  f1_dataframe <- df$F1[idx]
  
  # Skip if either is NA
  skip_if(is.na(f1_method) || is.na(f1_dataframe), "No formant data at test time")
  
  # Both methods should return Hertz values (not Bark)
  expect_true(f1_method > 50, 
              info = "get_value_at_time should return Hertz (>50), not Bark (<20)")
  
  # The two methods should agree within 100 Hz
  expect_true(abs(f1_method - f1_dataframe) < 100,
              info = sprintf("Methods should agree: get_value_at_time=%.2f, dataframe=%.2f", 
                           f1_method, f1_dataframe))
  
  # Verify bark scale returns different (smaller) values
  f1_bark <- formant$get_value_at_time(1, 0.25, unit = "bark")
  if (!is.na(f1_bark)) {
    expect_true(f1_bark < 20, info = "Bark values should be < 20 for typical F1")
    expect_true(f1_bark < f1_method / 10,
                info = "Bark values should be much smaller than Hertz values")
  }
})
```

### Testing

Run verification script:
```bash
Rscript verify_formant_fix.R
```

Expected output:
```
F1 via get_value_at_time(unit='hertz'): 862.51 Hz
F1 via get_value_at_time(unit='bark'):  7.66 bark
F1 via as_data_frame():                 862.51 Hz

✓ get_value_at_time returns Hertz scale (not Bark)
✓ Both methods agree within 100 Hz
✓ Bark scale returns appropriately smaller values

✅ FIX VERIFIED: Unit codes corrected!
```

---

## Files Changed

### Modified Files
1. `R/formant-r6.R` - Fixed unit_code() helper function (line 40)
2. `tests/testthat/test-formant-r6.R` - Added regression test
3. `NEWS.md` - Added 2.0.4 release notes
4. `DESCRIPTION` - Bumped version to 2.0.4

### New Files
1. `verify_formant_fix.R` - Quick verification script
2. `FORMANT_BUG_FIX_SUMMARY.md` - This document

---

## Migration Guide

### For Users With Workarounds

If you implemented workarounds like:

```r
# OLD WORKAROUND (no longer needed)
df <- formant$as_data_frame()
f1 <- df$F1[which.min(abs(df$time - 0.25))]
```

You can now use the direct method:

```r
# NEW (works correctly in pladdrr >= 2.0.4)
f1 <- formant$get_value_at_time(1, 0.25, "hertz")
```

Both approaches will work, but the direct method is more efficient and readable.

### For Users Without Workarounds

If you were using the buggy method:

```r
# THIS WAS BUGGY (returned Bark values)
f1 <- formant$get_value_at_time(1, 0.25, "hertz")
# Returned: ~7 (Bark scale - WRONG!)
```

**ACTION REQUIRED**: After upgrading to pladdrr 2.0.4, your code will now return correct Hertz values. If you compensated for the bug in downstream analysis, you need to remove those compensations.

---

## Related Issues

No related GitHub issues (bug discovered through internal validation testing).

---

## Comparison with Other Unit Codes

For reference, other R6 classes use correct unit codes:

**Pitch** (`R/pitch-r6.R` line 47):
```r
unit_code <- function(unit) {
  switch(tolower(unit),
    "hertz" = 0L, "hz" = 0L,
    "semitones" = 1L,
    # ... other units
  )
}
```

**LTAS** (`R/ltas-r6.R` line 20):
```r
unit_code <- function(unit) {
  switch(tolower(unit),
    "energy" = 0,
    "sones" = 1,
    # ... other units
  )
}
```

Only Formant had the incorrect 1-based indexing (`1L, 2L`) instead of 0-based (`0L, 1L`).

---

## Acknowledgments

- **Discovered by**: plabench 3-way validation framework
- **Reported in**: VALIDATION_REPORT.md
- **Fixed by**: OpenCode AI Assistant
- **Date**: January 6, 2026

---

**Status**: ✅ FIXED in pladdrr 2.0.4
