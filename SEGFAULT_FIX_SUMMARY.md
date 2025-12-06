# pladdrr 1.1.1 Segfault Fix - Summary

## Problem
`Sound$extract_intervals_where()` crashed (segfault at 0x68) when no TextGrid intervals matched search criterion.

## Root Cause
Praat's warning system used NULL function pointer (`MelderWarning::_p_currentProc`) when no intervals found.

## Solution
Custom warning handler in `src/textgrid_wrappers.cpp`:
- Static handler converts UTF-32 warnings to UTF-8 for R console
- Lazy initialization on first function call
- No .onLoad() needed, no exports required

## Test Result
```r
library(pladdrr)
s <- Sound$new('tests/testthat/fixtures/speech_sample.wav')
p <- s$to_pitch()
tg <- p$to_textgrid_vuv()

# Previously segfaulted, now works:
empty <- s$extract_intervals_where(tg, 1, "is equal to", "NONEXISTENT", FALSE)
# Praat warning: No label that is equal to the text "NONEXISTENT" was found.
# Returns: list() (length 0)
```

## Status
✅ **FIXED** - DSI/AVQI workflows unblocked

## Files Modified
- `src/textgrid_wrappers.cpp` - Added handler (lines 14-54, 725)
- `R/pladdrr-package.R` - Removed broken .onLoad() call
- `tests/testthat/test-extract-intervals-where.R` - New test suite
- `test_warning_handler.R` - Verification script

Build: ✅ `R CMD INSTALL --preclean .` succeeds
