# Minor Improvements TODO

**Date**: 2025-11-26
**Package Version**: 0.9.11
**Status**: Tracking minor improvements from compliance analysis

## Outstanding TODO Comments (From C++ Code)

### 1. Pitch Wrapper Enhancement
**File**: `src/pitch_wrappers.cpp`
**Location**: Line with TODO comment
**Description**: Implement pitch functions with full parameter support
**Priority**: MEDIUM
**Estimated Effort**: 2-4 hours

### 2. Praat Version Integration
**File**: `src/praat_wrapper.cpp`
**Location**: Multiple TODO comments
**Description**: Integrate proper Praat headers and version detection
**Priority**: LOW
**Estimated Effort**: 1-2 hours
**Notes**: Currently using placeholder version string

## Suggested Enhancements

### 3. Standardize Input Validation
**Priority**: MEDIUM
**Estimated Effort**: 3-4 hours
**Description**: Convert appropriate validation checks to use `stopifnot()` for clarity
**Example**:
```r
# Before:
if (is.null(x)) {
  stop("x cannot be NULL")
}

# After:
stopifnot("x cannot be NULL" = !is.null(x))
```
**Impact**: Better code readability and consistency

### 4. Add More Documentation Examples
**Priority**: MEDIUM
**Estimated Effort**: 4-6 hours
**Description**: Add @examples to more exported functions
**Current**: 48 files with examples
**Target**: 80+ files with examples

### 5. Create Migration Vignettes
**Priority**: HIGH
**Estimated Effort**: 8-10 hours
**Vignettes to Create**:
- Migration guide from Praat scripts
- Migration guide from Parselmouth (Python)
- Performance benchmarking guide
- Advanced acoustic analysis workflows

### 6. Increase Test Coverage
**Priority**: MEDIUM
**Estimated Effort**: Ongoing
**Current**: 19 test files
**Target**: 95%+ code coverage

### 7. Add Performance Benchmarks
**Priority**: LOW
**Estimated Effort**: 4-6 hours
**Description**: Create comprehensive benchmarks comparing to Parselmouth

## Completed Improvements

- [x] ✅ Verified XPtr finalizers are properly implemented
- [x] ✅ Confirmed error messages are informative
- [x] ✅ Documented compliance analysis
- [x] ✅ Zero S3 methods remaining (full R6 migration)
- [x] ✅ All audio loading via av package
- [x] ✅ Memory management robust with proper finalizers

## Notes

- Most validation patterns using `is.null()` are appropriate for default parameter handling
- Error messages are generally informative and helpful
- Code quality is excellent (no debug calls, no hard-coded paths)
- Package is in excellent shape overall (compliance score: 9.5/10)

## Next Session Priorities

1. Create migration vignettes (HIGH PRIORITY)
2. Add documentation examples to more functions (MEDIUM)
3. Standardize validation patterns where beneficial (LOW)
4. Track TODO items as GitHub issues (LOW)
