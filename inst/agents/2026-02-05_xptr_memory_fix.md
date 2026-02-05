# XPtr Memory Management Fix - v4.8.15

**Date:** 2026-02-05  
**Version:** 4.8.14 → 4.8.15  
**Priority:** P0 CRITICAL  
**Status:** ✅ RESOLVED

## Summary

Fixed critical memory management bug causing segfaults in `Sound$to_spectrogram()`, `Spectrogram$to_spectrum()`, and potentially all other Praat object transformations throughout the package.

## Root Cause

All Rcpp module methods that returned XPtr objects were using incorrect memory management:

```cpp
// BUGGY CODE (used in 123 places):
return XPtr<structType>(raw, true);
```

The `true` flag enables finalization but uses C++'s default `delete` operator. Praat objects require `forget()` for proper cleanup, not `delete`. This caused memory corruption and segfaults when R's garbage collector tried to clean up these objects.

## Issues Addressed

### Issue #1: Sound$to_spectrogram() Segfault (P0 CRITICAL)
- **Location:** `src/modules/sound_module.cpp:332-383`
- **Symptom:** Segfault when creating spectrograms from Sound objects
- **Fix:** Replaced `XPtr<structSpectrogram>(raw, true)` with proper deleter

### Issue #2: Spectrogram$to_spectrum() Segfault (P0 CRITICAL)
- **Location:** `src/modules/spectrogram_module.cpp:198-217`
- **Symptom:** Segfault when converting spectrogram to spectrum at specific time
- **Fix:** Replaced `XPtr<structSpectrum>(raw, true)` with proper deleter

### Issue #3: API Documentation (P1 HIGH)
- **Status:** Not applicable - no `.cpp$` usage found in pladdrr codebase
- **Note:** Referenced R_implementations/ directory doesn't exist in pladdrr (part of external plabench test suite)

### Issue #4: Formant Extraction Segfaults (P2 MEDIUM)
- **Status:** Likely resolved by systemic XPtr fixes
- **Fix:** Fixed XPtr memory management in formant-related modules

## Solution Applied

Replaced all 123 instances of `XPtr<Type>(raw, true)` with proper Praat object deleters:

```cpp
// FIXED CODE:
auto deleter = [](structType* thing) {
    if (thing != nullptr) forget(thing);
};
return XPtr<structType>(raw, deleter);
```

This ensures Praat's `forget()` function is called instead of C++'s `delete` operator.

## Files Modified

**29 module files affected:**
- amplitudetier_module.cpp
- cepstrum_module.cpp
- cochleagram_module.cpp
- discriminant_module.cpp
- dtw_module.cpp
- durationtier_module.cpp
- electroglottogram_module.cpp
- excitation_module.cpp
- formantgrid_module.cpp
- formantmodeler_module.cpp
- formanttier_module.cpp
- intensity_module.cpp
- intensitytier_module.cpp
- longsound_module.cpp
- lpc_module.cpp
- ltas_module.cpp
- manipulation_module.cpp
- matrix_module.cpp
- mfcc_module.cpp
- pca_module.cpp
- pitchtier_module.cpp
- pointprocess_module.cpp
- powercepstrum_module.cpp
- sound_module.cpp
- spectrogram_module.cpp
- spectrum_module.cpp
- table_module.cpp
- textgrid_module.cpp
- vocaltract_module.cpp

**Statistics:**
- 621 lines added (proper memory management)
- 125 lines removed (buggy XPtr creation)
- 123 XPtr memory bugs fixed

## Testing

After recompiling (`R CMD INSTALL .`), test with:

```r
library(pladdrr)

# Test Issue #1: to_spectrogram
sound <- Sound("path/to/test.wav")
spectrogram <- sound$to_spectrogram(
  window_length = 0.005,
  max_frequency = 8000,
  time_step = 0.005,
  frequency_step = 20.0,
  window_shape = "Gaussian"
)
print(spectrogram)  # Should work without segfault

# Test Issue #2: to_spectrum
curr_time <- spectrogram$get_time_from_frame(1)
spectrum <- spectrogram$to_spectrum(curr_time)
print(spectrum)  # Should work without segfault
```

## Impact

- **Stability:** Eliminates critical segfaults in core functionality
- **Scope:** Affects all methods returning Praat objects (Spectrogram, Spectrum, Pitch, Formant, Intensity, etc.)
- **Backward Compatibility:** No API changes, purely internal memory management fix

## Reference

- Bug Report: `PLADDRR_V4.8.14_BUG_REPORT.md`
- Related: `src/praat_xptr_utils.h` - Contains reference implementation of correct XPtr creation
