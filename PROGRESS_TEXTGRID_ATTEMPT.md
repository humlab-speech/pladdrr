# TextGrid Implementation Attempt - 2025-11-10

## Summary

Attempted to implement full TextGrid support but encountered extensive dependency chains requiring additional Praat subsystems.

## What Was Implemented

1. **R6 Class**: Complete `R/textgrid-r6.R` with ~35 methods for TextGrid manipulation
   - Tier query methods
   - IntervalTier operations
   - PointTier operations
   - Tier management
   - Export to data frame

2. **C++ Wrappers**: `src/textgrid_wrappers.cpp` with Rcpp bindings for all methods

## Blocking Issues

TextGrid functionality requires these additional Praat subsystems that are not yet integrated:

1. **File I/O**: `MelderFile_close`, `MelderFile_create`, and full file reading/writing
2. **Graphics System**: `Graphics_function`, `Graphics_polyline`, and rendering functions
3. **Threading**: `MelderThread_run` for parallel processing
4. **Numeric Algorithms**: `NUMminimize_brent` and optimization functions

These dependencies pull in:
- `fon/TextGrid.cpp` (requires Graphics for rendering)
- `fon/TextGrid_Sound.cpp` (requires complete file I/O)
- Extensive Melder file handling
- Graphics rendering subsystem
- Threading library

## Resolution

TextGrid support deferred to future release. Files moved to `.disabled`:
- `R/textgrid-r6.R.disabled`
- `src/textgrid_wrappers.cpp.disabled`

## Future Work

To enable TextGrid:

1. Integrate Melder file I/O subsystem
2. Add comprehensive Graphics stubs (or integrate minimal Graphics)
3. Implement threading stubs or actual threading support
4. Add missing numeric algorithm implementations
5. Test with real TextGrid files

Estimated effort: 3-5 days of focused development

## Current Package State

Package builds successfully WITHOUT TextGrid:
- Sound, Pitch, Formant, Harmonicity, PointProcess, Intensity all functional
- Voice quality analysis working
- Spectral analysis operational
- Pitch manipulation available via Manipulation class

