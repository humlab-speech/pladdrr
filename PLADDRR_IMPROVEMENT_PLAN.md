# pladdrr 2.2.6 Comprehensive Review & Improvement Plan

**Date:** 2026-01-09
**Current Version:** 2.2.6
**Status:** Review Complete, Plan Ready for Implementation

---

## Executive Summary

This document provides a comprehensive review of the pladdrr R package, identifying API inconsistencies introduced during iterative development, bugs in pointer extraction code, and optimization opportunities. The package has evolved through multiple phases, resulting in a 3-tier API architecture with some naming and implementation inconsistencies that should be addressed.

---

## 1. Package Architecture Overview

### 1.1 The Three API Tiers

```
User Code
   │
   ▼
┌─────────────────────────────────────────────────────────────┐
│ TIER 1: High-Level Classes (Sound, Pitch, Formant, etc.)    │
│ - Function wrapper or R6 style                               │
│ - Object-oriented method chaining                            │
│ - Full validation & error handling                           │
│ - Overhead: 2-3x slower than Tier 2                          │
└─────────────────────────────────────────────────────────────┘
   │ (.xptr extraction)
   ▼
┌─────────────────────────────────────────────────────────────┐
│ TIER 2: Direct API (*_direct functions)                      │
│ - Accept XPtr directly, skip R6 dispatch                     │
│ - 2-3x faster than Tier 1                                    │
│ - Single operation queries                                   │
└─────────────────────────────────────────────────────────────┘
   │ (XPtrs)
   ▼
┌─────────────────────────────────────────────────────────────┐
│ TIER 3: Advanced API (*_fast, *_batch)                       │
│ - Maximum performance for bulk operations                    │
│ - 5-20x faster for batch processing                          │
│ - Zero-copy access for large files                           │
└─────────────────────────────────────────────────────────────┘
   │
   ▼
   C++ Layer (Rcpp Modules + Praat)
```

### 1.2 Current Statistics

- **R files:** 60 files (~20,000 lines)
- **C++ files:** 78 files
- **Rcpp Modules:** 33 classes
- **Exported functions:** 307
- **S3 methods:** 80+

---

## 2. Issues Identified

### 2.1 CRITICAL: Pointer Extraction Bug in batch-ops.R

**Location:** `R/batch-ops.R` lines 87-93, 138-144, 204-210, 247-253, 284-290

**Problem:** Batch functions use legacy R6 pointer extraction that's incompatible with current function-wrapper Sound implementation:

```r
# BROKEN - batch-ops.R uses legacy R6 pattern:
xptrs <- lapply(sounds, function(s) {
  if (inherits(s, "Sound")) {
    s$.__enclos_env__$private$ptr  # FAILS - Sound is no longer R6!
  } else {
    s
  }
})
```

**Affected functions:**
- `sound_to_pitch_batch()`
- `sound_to_pitch_ac_batch()`
- `sound_to_pitch_cc_batch()`
- `sound_to_formant_batch()`
- `sound_to_intensity_batch()`
- `sound_extract_and_pitch()`
- `sound_extract_and_formant()`
- `pitch_get_values_at_times()`
- `formant_get_values_at_times()`
- `intensity_get_values_at_times()`

**Fix required:**
```r
# CORRECT - use current extraction pattern (from sound_concatenate_all):
xptrs <- lapply(sounds, function(s) {
  if (inherits(s, "Sound")) {
    ptr <- s$.xptr  # Primary method
    if (is.null(ptr)) ptr <- s$get_xptr()  # Fallback
    if (is.null(ptr)) stop("Could not extract pointer")
    ptr
  } else if (inherits(s, "externalptr")) {
    s
  } else {
    stop("Invalid input type")
  }
})
```

### 2.2 Class Implementation Inconsistencies

| Class | Style | `.xptr` Field | Notes |
|-------|-------|---------------|-------|
| Sound | Function wrapper | Yes (`.xptr`) | Modern style |
| Pitch | Function wrapper | Yes (`.xptr`) | Modern style |
| Formant | Function wrapper | Yes (`.xptr`) | Modern style |
| Intensity | Function wrapper | Yes (`.xptr`) | Modern style |
| PowerCepstrum | Function wrapper | Yes (`.xptr`) | Modern style |
| **PowerCepstrogram** | **R6 Class** | No (`private$ptr`) | **INCONSISTENT** |
| PraatInterpreter | R6 Class | N/A | Intentional (reference semantics) |
| TextGrid | Function wrapper | Yes (`.xptr`) | Modern style |

**Issue:** `PowerCepstrogram` uses R6 style with `private$ptr` while `PowerCepstrum` uses function wrapper with `.xptr`. This causes confusion and potential bugs.

### 2.3 Function Naming Inconsistencies

#### Pattern Analysis

| Suffix | Purpose | Count | Consistency |
|--------|---------|-------|-------------|
| `*_direct` | XPtr input, raw output | 12 | Good |
| `*_fast` | Maximum performance variant | 3 | Poor (only CPPS-related) |
| `*_batch` | Multi-item processing | 15 | Good |
| `*_cc` | Cross-correlation pitch | 3 | Good |
| `*_ac` | Autocorrelation pitch | 3 | Good |
| `get_*_at_times` | Vectorized query | 6 | Good |

#### Naming Issues Found

1. **`_fast` vs `_direct` confusion:**
   - `calculate_cpps_fast()` - combines create + query
   - `to_powercepstrogram_fast()` - returns XPtr
   - `get_cpps_fast()` - query from XPtr

   These should arguably use `_direct` suffix for consistency.

2. **Duplicate function patterns:**
   - `get_pitch_at_times()` (batch-queries.R)
   - `pitch_get_values_at_times()` (batch-ops.R)

   Both do the same thing with slightly different signatures.

3. **Inconsistent naming for similar operations:**
   - `get_formants_at_times()` vs `formant_get_values_at_times()`
   - `get_intensity_at_times()` vs `intensity_get_values_at_times()`

### 2.4 Unit Code Inconsistencies

Different functions use different conventions for the same units:

```r
# praat-direct.R (get_pitch_stats_direct):
unit_code <- switch(unit,
  hertz = 0L, semitones = 1L, mel = 2L, erb = 3L, loghertz = 4L)

# batch-ops.R (pitch_get_values_at_times):
unit_int <- switch(tolower(unit),
  hertz = 0L, hertz_logarithmic = 1L, mel = 2L, loghertz = 3L,
  semitones_re_1hz = 4L, ...)  # Different mapping!
```

This inconsistency can lead to incorrect results when mixing APIs.

---

## 3. Optimization Opportunities

### 3.1 High Priority (Based on PLADDRR_2.2.6_OPTIMIZATION_SUMMARY.md)

#### 3.1.1 Batch Formant Value Extraction

**Current bottleneck in VQ analysis:**
```r
# Current (slow - 4n C++ calls for n time points):
for (time in times) {
  f1 <- formant$get_value_at_time(1, time, "hertz")
  f2 <- formant$get_value_at_time(2, time, "hertz")
  f3 <- formant$get_value_at_time(3, time, "hertz")
  f4 <- formant$get_value_at_time(4, time, "hertz")
}
```

**Existing solution needs exposure:**
`get_formants_at_times()` already exists in `batch-queries.R` but isn't widely used.

**Recommendation:** Document and promote existing batch query functions.

#### 3.1.2 CPPS Calculation Performance

CPPS dominates AVQI runtime (77% of 7.4s). Current optimizations provide 1.5-2x speedup but further C++ level optimization could help.

**Potential improvements:**
1. Profile C++ `PowerCepstrogram_getCPPS()` function
2. Consider SIMD optimization for cepstral smoothing
3. Cache intermediate results for multiple CPPS queries

#### 3.1.3 Parallel Multi-File Processing

**Current:** Sequential processing only
**Opportunity:** Use `parallel::mclapply()` for batch workflows

```r
# Proposed high-level batch API:
analyze_files_parallel <- function(files, analysis_func, n_cores = 4) {
  parallel::mclapply(files, analysis_func, mc.cores = n_cores)
}
```

### 3.2 Medium Priority

#### 3.2.1 Unified Module Access Pattern

Currently, pointer extraction varies across files. Standardize to:

```r
extract_xptr <- function(obj, class_name) {
  if (inherits(obj, class_name)) {
    ptr <- obj$.xptr
    if (is.null(ptr)) ptr <- obj$get_xptr()
    if (is.null(ptr)) stop(sprintf("Invalid %s object", class_name))
    ptr
  } else if (inherits(obj, "externalptr")) {
    obj
  } else {
    stop(sprintf("Expected %s or externalptr, got %s",
                 class_name, class(obj)[1]))
  }
}
```

#### 3.2.2 Add Missing Direct API Functions

Currently missing from Direct API:
- `to_spectrum_direct()`
- `to_spectrogram_direct()`
- `to_point_process_direct()`
- `to_ltas_direct()`

### 3.3 Low Priority (Cleanup)

#### 3.3.1 Consolidate Duplicate Functions

| Keep | Remove/Deprecate |
|------|------------------|
| `get_formants_at_times()` | `formant_get_values_at_times()` |
| `get_pitch_at_times()` | `pitch_get_values_at_times()` |
| `get_intensity_at_times()` | `intensity_get_values_at_times()` |

#### 3.3.2 Remove Legacy R6 Code

Files with legacy patterns to clean:
- `R/batch-ops.R` (pointer extraction)
- `R/powercepstrum.R` (PowerCepstrogram R6 class)

---

## 4. Recommended Implementation Plan

### Phase 1: Critical Bug Fixes (v2.2.7)

**Estimated effort:** 1-2 hours

1. **Fix batch-ops.R pointer extraction**
   - Update all 10 affected functions
   - Add test coverage for function-wrapper objects
   - Test backward compatibility with any remaining R6 objects

2. **Add unit tests**
   - Test all batch functions with current Sound implementation
   - Verify results match non-batch equivalents

### Phase 2: API Consistency (v2.3.0)

**Estimated effort:** 4-6 hours

1. **Standardize naming convention**
   - Rename `*_fast` functions to `*_direct` or create clear documentation
   - Deprecate duplicate functions with warnings

2. **Convert PowerCepstrogram to function wrapper**
   - Match PowerCepstrum implementation style
   - Update all references

3. **Standardize unit code mappings**
   - Create central `unit_to_code()` helper function
   - Use consistently across all files

4. **Create unified pointer extraction utility**
   - `extract_xptr(obj, expected_class)`
   - Use in all batch operations

### Phase 3: Performance Enhancements (v2.4.0)

**Estimated effort:** 8-16 hours

1. **Promote batch query functions**
   - Add prominent documentation
   - Create performance comparison vignette

2. **Add parallel processing support**
   - New `analyze_batch_parallel()` function
   - Integration with existing batch operations

3. **Complete Direct API coverage**
   - Add missing `to_*_direct()` functions
   - Ensure parity with R6 methods

4. **Profile and optimize CPPS**
   - C++ profiling of PowerCepstrogram_getCPPS
   - Identify SIMD optimization candidates

### Phase 4: Documentation & Polish (v2.5.0)

1. **API documentation overhaul**
   - Clear tier 1/2/3 usage guidelines
   - Performance comparison tables
   - Migration guide for heavy users

2. **Deprecation cycle**
   - Phase 1: Add `.Deprecated()` warnings
   - Phase 2: Remove deprecated functions

---

## 5. Detailed Function Inventory

### 5.1 Direct API Functions (Tier 2)

| Function | Input | Output | Location |
|----------|-------|--------|----------|
| `get_pitch_stats_direct()` | Pitch XPtr | Named list | praat-direct.R |
| `get_formants_direct()` | Formant XPtr | Named vector | praat-direct.R |
| `get_pitch_value_direct()` | Pitch XPtr | Numeric | praat-direct.R |
| `get_intensity_value_direct()` | Intensity XPtr | Numeric | praat-direct.R |
| `get_formant_value_direct()` | Formant XPtr | Numeric | praat-direct.R |
| `to_pitch_direct()` | Sound XPtr | Pitch XPtr | praat-direct.R |
| `to_formant_direct()` | Sound XPtr | Formant XPtr | praat-direct.R |
| `to_intensity_direct()` | Sound XPtr | Intensity XPtr | praat-direct.R |
| `to_harmonicity_direct()` | Sound XPtr | Harmonicity XPtr | praat-direct.R |

### 5.2 Batch Functions (Tier 3)

| Function | Purpose | Location |
|----------|---------|----------|
| `sound_concatenate_all()` | Concatenate sounds | batch-ops.R |
| `sound_to_pitch_batch()` | Extract pitch from multiple sounds | batch-ops.R |
| `sound_to_pitch_ac_batch()` | Batch pitch (AC) | batch-ops.R |
| `sound_to_pitch_cc_batch()` | Batch pitch (CC) | batch-ops.R |
| `sound_to_formant_batch()` | Batch formant extraction | batch-ops.R |
| `sound_to_intensity_batch()` | Batch intensity extraction | batch-ops.R |
| `sound_extract_and_pitch()` | Extract parts + pitch in one call | batch-ops.R |
| `sound_extract_and_formant()` | Extract parts + formant in one call | batch-ops.R |
| `get_formants_at_times()` | Batch formant query | batch-queries.R |
| `get_pitch_at_times()` | Batch pitch query | batch-queries.R |
| `get_intensity_at_times()` | Batch intensity query | batch-queries.R |
| `get_formant_bandwidths_at_times()` | Batch bandwidth query | batch-queries.R |
| `get_pitch_strengths_at_times()` | Batch strength query | batch-queries.R |
| `get_pointprocess_times()` | Get all point times | batch-queries.R |
| `get_pointprocess_intervals()` | Get all intervals | batch-queries.R |

### 5.3 Fast/Advanced Functions

| Function | Purpose | Location |
|----------|---------|----------|
| `calculate_cpps_fast()` | CPPS in single call | performance-helpers.R |
| `to_powercepstrogram_fast()` | Create PowerCepstrogram (XPtr) | performance-helpers.R |
| `get_cpps_fast()` | Query CPPS from XPtr | performance-helpers.R |
| `get_sound_values_zerocopy()` | Zero-copy sample access | zerocopy-access.R |
| `sound_as_matrix_zerocopy()` | Zero-copy matrix | zerocopy-access.R |

---

## 6. Testing Requirements

### 6.1 Unit Tests Needed

```r
# Test batch functions with function-wrapper objects
test_that("batch functions work with function-wrapper Sound", {
  sounds <- lapply(1:3, function(i) {
    Sound$from_values(sin(seq(0, 2*pi, length.out = 44100)), 44100)
  })

  # These should all work without error
  expect_no_error(sound_to_pitch_batch(sounds))
  expect_no_error(sound_to_formant_batch(sounds))
  expect_no_error(sound_to_intensity_batch(sounds))
})

# Test result equivalence
test_that("batch results match individual calls", {
  sounds <- lapply(1:3, function(i) Sound("test.wav"))

  # Batch
  batch_results <- sound_to_pitch_batch(sounds)

  # Individual
  individual_results <- lapply(sounds, function(s) s$to_pitch())

  # Should be equivalent
  for (i in seq_along(sounds)) {
    expect_equal(
      batch_results[[i]]$get_mean(0, 0, "hertz"),
      individual_results[[i]]$get_mean(0, 0, "hertz"),
      tolerance = 1e-10
    )
  }
})
```

### 6.2 Integration Tests

- Cross-validate all tier 1/2/3 functions produce identical results
- Verify unit code consistency across APIs
- Performance regression tests

---

## 7. Appendix: File-by-File Analysis

### R/ Directory Key Files

| File | Purpose | Issues |
|------|---------|--------|
| `sound-r6-new.R` | Sound class (function wrapper) | Reference implementation |
| `batch-ops.R` | Batch operations | **BUG: Legacy pointer extraction** |
| `batch-queries.R` | Vectorized queries | Good |
| `praat-direct.R` | Direct API | Good, incomplete |
| `performance-helpers.R` | CPPS fast path | `_fast` naming inconsistent |
| `powercepstrum.R` | PowerCepstrum + PowerCepstrogram | **Mixed styles** |
| `zerocopy-access.R` | Zero-copy access | Good |

### src/ Directory Key Files

| File | Purpose |
|------|---------|
| `praat_direct.cpp` | Direct API C++ implementation |
| `batch_queries.cpp` | Batch query C++ implementation |
| `sound_wrappers.cpp` | Sound conversion wrappers |
| `powercepstrum_wrappers.cpp` | CPPS implementation |
| `*_simd.cpp` (14 files) | SIMD-optimized operations |

---

## 8. Conclusion

The pladdrr package has a solid 3-tier architecture but has accumulated inconsistencies during iterative development. The critical bug in `batch-ops.R` should be fixed immediately (v2.2.7). API consolidation and naming standardization should follow (v2.3.0). Performance work can continue incrementally (v2.4.0+).

**Priority Order:**
1. Fix batch-ops.R pointer extraction bug
2. Standardize PowerCepstrogram class style
3. Create unified unit code mappings
4. Consolidate duplicate batch query functions
5. Add missing Direct API functions
6. Implement parallel processing support
