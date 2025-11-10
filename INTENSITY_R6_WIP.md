# Intensity R6 Implementation - Work in Progress

**Date:** 2025-11-10  
**Status:** ⚠️ INCOMPLETE - Build errors

## What Was Implemented

1. **R6 Intensity Class** (`R/intensity-r6.R`)
   - Complete R6 class following Harmonicity pattern
   - All query methods defined
   - Time domain methods
   - Export methods (as_data_frame, as_matrix, print)

2. **C++ Wrappers** (`src/intensity_wrappers.cpp`)
   - Complete C++ wrappers for all Intensity methods
   - Query: get_value_at_time, get_mean, get_min/max, get_std_dev, get_quantile
   - Time domain: get_time_from_frame, get_frame_from_time, etc.
   - Follows same pattern as harmonicity_wrappers.cpp

3. **Build System Updates**
   - Added intensity_wrappers.cpp to Makevars WRAPPER_SRC
   - Added NUMFourier.cpp to DWSYS_SRC (for FFT support)

4. **Stub Improvements**
   - Added Demo_clickedIn, Demo_peekInput to uiform_stubs.cpp
   - Added praat_deselect, praat_deselectAll, praat_selectAll to praat_stubs.cpp

## Current Build Issues

**Symbol not found errors:**
- `__Z14praat_doActionPKDilP13structStackelP17structInterpreter` (praat_doAction)
- Various Praat interactive GUI functions being referenced

**Root Cause:**
The build system is pulling in more Praat code than before, which references
interactive GUI functions (praat_doAction, selection management, etc.).  
These need to be stubbed out.

## Next Steps to Complete

1. **Add Missing Stubs:**
   - `praat_doAction` - Interactive command execution
   - Any other symbols that appear during linking

2. **Test Build:**
   - Ensure package installs cleanly
   - Run Rcpp::compileAttributes() to update exports

3. **Create Tests:**
   - Unit tests for Intensity class
   - Test all query methods
   - Test integration with Sound$to_intensity()

4. **Documentation:**
   - Generate man page: `devtools::document()`
   - Add examples to Intensity class
   - Update vignettes

## Files Modified

- `R/intensity-r6.R` - NEW
- `src/intensity_wrappers.cpp` - NEW  
- `src/Makevars` - Added intensity_wrappers, NUMFourier
- `src/uiform_stubs.cpp` - Added Demo stubs
- `src/praat_stubs.cpp` - Added praat selection stubs
- `R/RcppExports.R` - Auto-generated
- `src/RcppExports.cpp` - Auto-generated
- `inst/include/speaker_RcppExports.h` - Auto-generated

## Estimated Time to Complete

- **Fix stubs:** 1-2 hours
- **Testing:** 1 hour
- **Documentation:** 1 hour
- **Total:** 3-4 hours

## Status

⚠️ Build fails with missing symbol errors. Need to add praat_doAction and
potentially other interactive Praat function stubs before package will install.

---

**Note:** The R6 class and C++ wrappers are complete and follow established patterns.
Only build system issues remain.
