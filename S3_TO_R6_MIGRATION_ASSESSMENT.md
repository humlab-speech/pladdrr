# S3 to R6 Migration Assessment

**Date**: 2025-11-24  
**Package**: pladdrr v1.0.0  
**Status**: Assessment Complete

## Executive Summary

The package currently has **DUAL INTERFACE**: Both S3 (legacy) and R6 (modern) interfaces coexist. The S3 interface is **DEPRECATED** but still functional and used in examples/tests.

### Recommendation: **KEEP BOTH INTERFACES**

**Rationale**:
1. **242 usage instances** across tests, vignettes, examples
2. **Smooth migration path** for existing users
3. **Backward compatibility** essential for v1.0.0 release
4. **Documented deprecation** already in place
5. **R6 is primary**, S3 provides compatibility layer

## Current S3 Objects

### 1. **Sound** (`praat_sound`)
- **Location**: `R/sound.R`
- **Functions**: 
  - `create_sound()` - Create from values
  - `read_sound()` - Load from file
  - Accessors: `get_duration()`, `get_sampling_rate()`, etc.
- **R6 Equivalent**: `Sound` class in `R/sound-r6-new.R`
- **Status**: ✅ R6 exists, S3 functional
- **Usage**: High (used in examples, tests)

### 2. **Pitch** (`praat_pitch`)  
- **Location**: `R/pitch.R`
- **Functions**:
  - `extract_pitch()` - Extract F0 contour
  - `get_pitch_at_time()`, `get_mean_pitch()`, etc.
- **R6 Equivalent**: `Pitch` class in `R/pitch-r6.R`
- **Status**: ✅ R6 exists, S3 functional
- **Usage**: High

### 3. **Formant** (`praat_formant`)
- **Location**: `R/formant.R`
- **Functions**:
  - `extract_formants()` - **ALREADY DEPRECATED**
  - `get_formant_at_time()` - **ALREADY DEPRECATED**
  - `get_mean_formant()` - **ALREADY DEPRECATED**
- **R6 Equivalent**: `Formant` class in `R/formant-r6.R`
- **Status**: ✅ R6 exists, S3 **deprecated with .Deprecated()**
- **Usage**: Medium (legacy code)

### 4. **Intensity** (`praat_intensity`)
- **Location**: `R/intensity.R`
- **Functions**:
  - `extract_intensity()` - Extract intensity contour
  - `get_intensity_at_time()`, `get_mean_intensity()`, etc.
- **R6 Equivalent**: `Intensity` class in `R/intensity-r6.R`  
- **Status**: ✅ R6 exists, S3 functional
- **Usage**: Medium

## S3 Methods (Generic Dispatch)

**Location**: `R/s3-methods.R`

Provides standard R generic methods for all S3 objects:

- `print.praat_sound()` / `print.praat_pitch()` / `print.praat_formant()` / `print.praat_intensity()`
- `summary.praat_*()` - Statistical summaries
- `as.data.frame.praat_*()` - Convert to data frame

**Status**: ✅ **KEEP** - These provide excellent UX for R users

## Migration Strategy: DUAL INTERFACE (Recommended)

### Phase 1: Documentation Update ✅ (Already Done for Formant)
```r
#' Extract formants (DEPRECATED)
#' 
#' **DEPRECATED:** Use the R6 interface instead: sound$to_formant_burg()
#' 
#' @export
extract_formants <- function(...) {
  .Deprecated("sound$to_formant_burg()", package = "pladdrr")
  # ... implementation stays ...
}
```

### Phase 2: Add Wrapper Functions (Optional Enhancement)
```r
#' Extract pitch (Simplified Interface)
#' 
#' Convenience wrapper for R6 Pitch extraction.
#' For advanced usage, use Sound$new()$to_pitch()
#' 
#' @param file_path Path to audio file
#' @param ... Arguments passed to Sound$to_pitch()
#' @export
extract_pitch <- function(file_path, ...) {
  Sound$new(file_path)$to_pitch(...)
}
```

### Phase 3: Update Examples & Vignettes
Replace S3 examples with R6 equivalents:

**Before (S3)**:
```r
sound <- read_sound("audio.wav")
pitch <- extract_pitch(sound)
mean_f0 <- get_mean_pitch(pitch)
```

**After (R6)**:
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch()
mean_f0 <- pitch$get_mean()
```

## Comparison: S3 vs R6

| Feature | S3 | R6 | Recommendation |
|---------|----|----|----------------|
| **Simplicity** | ✅ Simple functions | ❌ Class-based | S3 easier for beginners |
| **Consistency** | ❌ Mixed APIs | ✅ Unified methods | R6 better design |
| **Performance** | ✅ No overhead | ✅ Same (XPtr) | Equal |
| **Praat Parity** | ❌ Functional style | ✅ Object methods | R6 matches Praat |
| **IDE Support** | ❌ Limited autocomplete | ✅ Method autocomplete | R6 better UX |
| **Type Safety** | ❌ Loose | ✅ Method validation | R6 safer |
| **Chaining** | ❌ Not possible | ✅ `sound$to_pitch()$get_mean()` | R6 more fluent |

## Usage Statistics

```bash
grep -r "extract_pitch\|extract_formants\|extract_intensity\|create_sound\|read_sound" \
  tests/ inst/examples/ vignettes/ | wc -l
# Result: 242 instances
```

**Breakdown**:
- Tests: ~80 instances
- Vignettes: ~120 instances  
- Examples: ~42 instances

## Decision: Keep Dual Interface

### ✅ **KEEP S3 Interface** (with deprecation warnings)

**Reasons**:
1. **Backward Compatibility**: Essential for v1.0.0 stable release
2. **Migration Period**: Give users time to transition (deprecate in v1.0, remove in v2.0)
3. **Learning Curve**: S3 functions easier for R users unfamiliar with OOP
4. **Examples Work**: 242 usage instances don't break immediately
5. **Documentation**: Already has deprecation warnings (`extract_formants`)

### ✅ **PROMOTE R6 as Primary**

**Actions**:
1. **Update README**: Show R6 examples first
2. **Update Vignettes**: Use R6 throughout, mention S3 as legacy
3. **Deprecation Warnings**: Add `.Deprecated()` to remaining S3 functions
4. **NEWS.md Entry**: Document S3 → R6 transition path

### ❌ **DO NOT Remove S3 Yet**

**Timeline**:
- **v1.0.0** (current): Dual interface, S3 deprecated
- **v1.x.x**: Maintain S3, add warnings
- **v2.0.0** (future): Consider removing S3

## Implementation Plan

### Task 1: Add Deprecation Warnings (Low Priority)
Add `.Deprecated()` to remaining S3 functions:
- `extract_pitch()` → `sound$to_pitch()`
- `extract_intensity()` → `sound$to_intensity()`  
- `create_sound()` → `Sound$from_values()`
- `read_sound()` → `Sound$new(path)`

### Task 2: Update Documentation (Medium Priority)
- README: Show R6 first, S3 as "Legacy API"
- Vignettes: Convert to R6 examples
- Function help: Add "See Also: Sound$new()"

### Task 3: Add Transition Guide (High Priority)
Create `vignettes/s3-to-r6-migration.Rmd`:
```r
# Migrating from S3 to R6 API

## Why Migrate?
- Better IDE autocomplete
- Consistent with Praat's OOP design
- Method chaining support
- Future-proof

## Migration Examples

### Sound Objects
# Old (S3)
sound <- read_sound("audio.wav")

# New (R6)
sound <- Sound$new("audio.wav")

### Pitch Analysis
# Old (S3)
pitch <- extract_pitch(sound)
mean_f0 <- get_mean_pitch(pitch)

# New (R6)
pitch <- sound$to_pitch()
mean_f0 <- pitch$get_mean()
```

## Conclusion

**Status**: S3 and R6 coexist successfully  
**Action**: Document deprecation, promote R6, keep S3 for compatibility  
**Timeline**: Remove S3 in v2.0.0 (not before)

The dual interface approach provides:
- ✅ Smooth transition for existing users
- ✅ Backward compatibility for scripts
- ✅ Clear migration path (documented)
- ✅ R6 as primary, S3 as legacy

**No immediate action required** - the current implementation is appropriate for v1.0.0.
