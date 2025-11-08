# Phase 1 Implementation Summary - R6 Foundation

**Date**: 2025-01-08  
**Status**: In Progress - Blocked by C++ standard compatibility  
**Completion**: ~70%

## What Was Completed

### 1. R6 Package Dependency ✅
- Added R6 (>= 2.5.0) to DESCRIPTION Imports
- Package now depends on R6 for object-oriented functionality

### 2. Base PraatObject Class ✅
**File**: `R/praat-object.R`

Created abstract base class with:
- External pointer management
- Pointer validation methods (`is_valid()`)
- Automatic cleanup via finalizers
- Common print method
- Lock to prevent field modification after creation

```r
# Usage (by derived classes):
Sound <- R6Class("Sound", inherit = PraatObject, ...)
```

### 3. Sound R6 Class ✅  
**File**: `R/sound-r6.R`

Implemented complete Sound class with Praat-aligned naming:

**Constructor**:
- `Sound$new(path)` - Read from file
- `Sound_from_values(values, sampling_rate)` - Factory function

**Query Methods** (get_* pattern):
- `get_duration()` - Duration in seconds
- `get_sampling_frequency()` - Sampling rate in Hz
- `get_number_of_channels()` - Channel count
- `get_number_of_samples()` - Total samples
- `get_time_from_sample(sample)` - Time for sample number
- `get_value_at_time(time, channel)` - Amplitude at time

**Transformation Methods** (to_* pattern):
- `to_pitch(...)` - Create Pitch object (follows "To Pitch..." command)

**Extraction Methods** (extract_* pattern):
- `extract_part(from_time, to_time)` - Extract time slice

**Modification Methods**:
- `scale_intensity(new_level)` - In-place intensity scaling

**Export Methods**:
- `as_data_frame()` - Export to R data.frame
- `save(path, format)` - Write to file

### 4. Pitch R6 Class ✅
**File**: `R/pitch-r6.R`

Implemented complete Pitch class:

**Constructor**:
- `Pitch$new(path)` or `Pitch$new(from_pointer=ptr)`

**Query Methods**:
- `get_number_of_frames()` - Frame count
- `get_time_step()` - Time between frames
- `get_value_at_time(time, unit)` - F0 at specific time
- `get_mean(from_time, to_time, unit)` - Mean F0
- `get_minimum(...)`, `get_maximum(...)` - F0 range
- `get_quantile(quantile, ...)` - F0 quantile

**Export Methods**:
- `as_data_frame()` - Export to data.frame(time, frequency, strength)
- `save(path)` - Write Pitch file

### 5. C++ R6 Wrappers ✅
**File**: `src/r6_wrappers.cpp`

Implemented XPtr-based C++ functions:

**Finalizers**:
- `sound_finalizer()` - Auto-cleanup for Sound objects
- `pitch_finalizer()` - Auto-cleanup for Pitch objects

**Sound Functions** (23 functions):
- I/O: `sound_read_from_file()`, `sound_save()`
- Creation: `sound_create_from_values()`
- Queries: `sound_get_duration()`, `sound_get_sampling_frequency()`, etc.
- Transformations: `sound_to_pitch()`, `sound_extract_part()`
- Modifications: `sound_scale_intensity()`
- Export: `sound_as_data_frame()`

**Pitch Functions** (9 functions):
- I/O: `pitch_read_from_file()`, `pitch_save()`
- Queries: `pitch_get_mean()`, `pitch_get_value_at_time()`, etc.
- Export: `pitch_as_data_frame()`

All functions:
- Use `XPtr<Sound>` or `XPtr<Pitch>` for pointer passing
- Include finalizers for automatic cleanup
- Handle Praat errors gracefully
- Return NA for undefined values

## What's Blocking Completion

### C++11 vs C++17 Compatibility Issue

**Problem**: R package builds use C++11 by default (via SystemRequirements in DESCRIPTION), but Praat source code uses C++17 features:

```cpp
// Praat code (C++17 digit separators):
constexpr int64 factorial[] = { 1, 1, 2, 6, 24, 120, 720, 5'040, ... };

// C++11 doesn't recognize the apostrophe separator
```

**Error Messages**:
```
error: expected '}'
   243 |         1, 1, 2, 6, 24, 120, 720, 5'040, 40'320, 362'880, ...
praat/melder/melder_real.h:57:71: error: expected ')'
   57 | inline bool isdefined (double x) { return ((* (uint64 *) & x) & 0x7FF0'0000'0000'0000) ...
```

**Current Status**: r6_wrappers.cpp won't compile due to Praat headers requiring C++17

### Possible Solutions

#### Option 1: Update to C++17 (Recommended)
```r
# DESCRIPTION:
SystemRequirements: C++17

# src/Makevars:
CXX_STD = CXX17
```

**Pros**: Clean, future-proof, allows full Praat functionality  
**Cons**: Requires R >= 4.0, some older compilers may not support

#### Option 2: Patch Praat Code for C++11
- Remove digit separators from Praat headers
- May need to patch multiple files
- Maintenance burden on updates

**Pros**: Works with older R versions  
**Cons**: Technical debt, harder to update Praat

#### Option 3: Hybrid Approach
- Keep existing S3 interface functional
- Add R6 classes incrementally as compilation issues are resolved
- Use C++17-compatible Praat functions first

**Pros**: Incremental progress, no breaking changes  
**Cons**: Slower migration, duplicate code

## Files Created

| File | Size | Purpose |
|------|------|---------|
| `R/praat-object.R` | 2.3 KB | Base class for all Praat R6 objects |
| `R/sound-r6.R` | 8.2 KB | Sound R6 class with full API |
| `R/pitch-r6.R` | 7.2 KB | Pitch R6 class with full API |
| `src/r6_wrappers.cpp` | 14.8 KB | C++ XPtr-based wrappers |

**Total**: ~32.5 KB of new R6 code

## Testing Status

- [ ] Unit tests for PraatObject
- [ ] Unit tests for Sound R6 class
- [ ] Unit tests for Pitch R6 class
- [ ] Integration tests for Sound → Pitch workflow
- [ ] Memory leak tests (valgrind)

**Reason**: Cannot test until compilation issues resolved

## Next Steps

### Immediate (To Unblock)
1. **Decision**: Choose C++17 upgrade vs. hybrid approach
2. **If C++17**: Update DESCRIPTION and Makevars
3. **If Hybrid**: Keep S3, add R6 methods one-by-one

### After Unblocking
1. Fix any remaining compilation errors
2. Generate RcppExports with corrected code
3. Build and install package
4. Create comprehensive tests
5. Validate memory management with valgrind

### Then Continue to Phase 2
- Implement Formant R6 class
- Implement Intensity R6 class
- Full test coverage

## Code Quality

### Naming Conventions Applied ✅
All methods follow the established patterns:
- `get_*()` - Query methods (matches "Get X" in Praat)
- `to_*()` - Transformation methods (matches "To X..." in Praat)
- `extract_*()` - Subset operations (matches "Extract X" in Praat)
- Parameters: `time`, `from_time`, `to_time`, `pitch_floor`, etc.

### Documentation ✅
All R6 classes and methods have:
- roxygen2 @description tags
- @param documentation
- @return type specifications
- @examples showing usage

### Error Handling ✅
- Pointer validation before every operation
- Graceful handling of Praat errors
- Informative error messages
- NA returns for undefined values

## Performance Expectations

Once compiled, the R6 approach should provide:
- **Zero-copy operations**: Data stays in C++
- **Faster chaining**: `sound$to_pitch()$get_mean()` with no data transfer
- **Lower memory**: Single copy of audio data in C++
- **Method call overhead**: Minimal (~microseconds per call)

## Summary

**Phase 1 is ~70% complete**. The R6 class architecture is fully designed and implemented, following all naming conventions and best practices. The only blocker is C++ standard compatibility between R's build system (C++11) and Praat's modern code (C++17).

**Recommended Path Forward**: Update to C++17 in DESCRIPTION and Makevars, then proceed with testing and Phase 2.
