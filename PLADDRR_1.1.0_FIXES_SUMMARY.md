# pladdrr 1.1.0 Fixes Summary ✅

**Status**: COMPLETE - All tests passing  
**Date**: 2025-12-06

## Fixes Applied

### 1. PointProcess$voice_report() - Pointer Access ✅
- **File**: `R/pointprocess-r6.R` (lines 670-672)
- **Issue**: Crashed accessing `.xptr` (not exposed)
- **Fix**: Use `$.__enclos_env__$private$ptr` pattern

### 2. Pitch$to_textgrid_vuv() - Implementation ✅
- **File**: `src/pitch_wrappers.cpp`
- **Issue**: C++ function missing
- **Fix**: Removed duplicates, kept clean version

### 3. Pitch$to_textgrid_silences() - Implementation ✅
- **File**: `src/pitch_wrappers.cpp`  
- **Issue**: C++ function missing
- **Fix**: Removed duplicates, kept clean version

### 4. TextGrid$extract_intervals_where() - Enum Fix ✅
- **Files**: 
  - `R/textgrid-r6.R` (lines 568-581) - Fixed 0→1 based enum mapping
  - `src/textgrid_wrappers.cpp` (lines 696-701) - Added validation
- **Issue**: Segfault from `UNDEFINED` enum value (0) calling `Melder_fatal()`
- **Root Cause**: Praat `kMelder_string` enum is 1-based, R was passing 0-based
- **Fix**: Corrected enum map to start at 1, added bounds check

## Test Results

```
✓ PointProcess$voice_report() - PASS
✓ Pitch$to_textgrid_vuv() - PASS  
✓ Pitch$to_textgrid_silences() - PASS
✓ TextGrid$extract_intervals_where() - PASS
```

## Next Steps

**High Priority**:
1. Add Sound$extract_intervals_where() R6 method
2. Implement DSI calculation
3. Implement AVQI calculation  
4. Implement tremor analysis

**Medium Priority**:
- Sound$new_from_values() for pure tone generation
- Update vignettes
- Add tests

**Build**: `R CMD INSTALL --preclean .` (~3 min)
