# SIMD Assessment Update - 2025-11-16

## Overview

This document provides an updated SIMD optimization assessment for the speaker package based on the actual codebase structure as of 2025-11-16. This update corrects earlier assumptions and focuses optimization efforts on the available C++ wrapper files.

## Key Findings

### 1. Codebase Structure Clarification

**Initial Assessment Assumption**: Presence of active `src/matrix_wrappers.cpp` with matrix statistical operations.

**Actual Finding**:
- ⚠️ **`src/matrix_wrappers.cpp.wip` file EXISTS but is NOT COMPILED**
- ⚠️ Matrix R6 class fully defined in `R/matrix-r6.R` but non-functional
- ⚠️ 15 C++ wrapper functions prepared (244 lines) but not exported
- ⚠️ Matrix implementation is **intentionally deferred** (low priority per CLAUDE.md)
- ✅ Primary optimization targets are Sound and Table wrappers
- ✅ Praat Matrix C++ source available and compiled, but not exposed to R

**Detailed Status**:
- **R6 Class**: `/Users/frkkan96/Documents/src/speaker/R/matrix-r6.R` (229 lines, 15 methods)
- **C++ Wrapper (WIP)**: `/Users/frkkan96/Documents/src/speaker/src/matrix_wrappers.cpp.wip` (244 lines)
- **C++ Wrapper (Backup)**: `/Users/frkkan96/Documents/src/speaker/src/matrix_wrappers.cpp.bak`
- **Makevars Inclusion**: ❌ Not in WRAPPER_SRC list
- **RcppExports**: ❌ No `.matrix_*()` functions generated
- **Praat Source**: ✅ Available in `src/praat.github.io/fon/Matrix.cpp` and related files

**Architectural Decision** (per CLAUDE.md):
> Matrix implementation is low-priority. R's data.frame is superior for R workflows. Other objects provide `as_data_frame()` for data export (preferred approach).

**Impact**:
- Refocused Phase 1 priorities from matrix operations to Sound data conversion and Table statistical operations
- Matrix SIMD optimization **deferred to optional Phase 1b** (if Matrix is activated)
- If Matrix is activated, benchmarks already exist in `inst/benchmarks/01_matrix_operations.R`

### 2. Available C++ Wrapper Files for SIMD Optimization

Analysis of `src/` directory reveals the following high-value targets:

#### **Tier 1: Sound Operations** (Highest Impact)

**File**: `src/sound_wrappers.cpp` (primary audio processing file)

**Critical Functions for SIMD**:

1. **`sound_create_from_values()`** (lines 53-84)
   - Current: Nested loop copying from R matrix to Praat Sound
   - SIMD opportunity: Bulk memory transfer with vectorized loads/stores
   - Expected speedup: 4-8x
   - Impact: VERY HIGH (called on every audio import)

2. **`sound_as_matrix()`** (lines 509-521)
   - Current: Nested loop copying from Praat Sound to R matrix
   - SIMD opportunity: Vectorized bulk copy
   - Expected speedup: 4-8x
   - Impact: VERY HIGH (called on every audio export)

3. **`sound_create_tone()`** (lines 88-110)
   - Current: Scalar sine calculation in loop
   - SIMD opportunity: `xsimd::sin()` batch processing
   - Expected speedup: 4-6x
   - Impact: HIGH (tone generation, synthesis)

4. **`sound_get_rms()`** (lines 180-202)
   - Current: Scalar sum-of-squares calculation
   - SIMD opportunity: Vectorized multiply-add with `xsimd::fma()`
   - Expected speedup: 3-5x
   - Impact: HIGH (intensity analysis)

5. **`sound_as_data_frame()`** (lines 478-504)
   - Current: Nested loop extracting time/channel/value
   - SIMD opportunity: Vectorized time vector generation
   - Expected speedup: 2-4x
   - Impact: MEDIUM-HIGH (data export)

#### **Tier 2: Table Operations** (High Impact for Statistical Analysis)

**File**: `src/table_wrappers.cpp`

**Opportunities**:

1. **Column statistical operations** (potential new functions)
   - Add SIMD-optimized: `table_get_column_mean_simd()`
   - Add SIMD-optimized: `table_get_column_sum_simd()`
   - Add SIMD-optimized: `table_get_column_min_max_simd()`
   - Expected speedup: 4-6x
   - Impact: HIGH (data analysis workflows)

2. **Bulk numeric value access**
   - Optimize: `table_get_numeric_value()` for column-wise access
   - Vectorize column extraction
   - Expected speedup: 3-5x

#### **Tier 3: Other Wrapper Files** (Lower Priority)

**Files with potential SIMD opportunities**:

- `src/intensity_wrappers.cpp` - Intensity calculations
- `src/spectrum_wrappers.cpp` - Spectral operations
- `src/formant_wrappers.cpp` - Formant extraction
- `src/pitch_wrappers.cpp` - Pitch tracking
- `src/harmonicity_wrappers.cpp` - HNR calculations

**Note**: These files primarily call Praat internal functions. SIMD optimization would require modifying Praat source code (more complex, deferred to Phase 3).

### 3. Revised Priority List

| Rank | Operation | File | Lines | Speedup | Impact | Phase |
|------|-----------|------|-------|---------|--------|-------|
| 1 | Sound data conversion (to R) | sound_wrappers.cpp | 509-521 | 4-8x | VERY HIGH | 1 |
| 2 | Sound data conversion (from R) | sound_wrappers.cpp | 72-76 | 4-8x | VERY HIGH | 1 |
| 3 | Tone generation | sound_wrappers.cpp | 98-102 | 4-6x | HIGH | 1 |
| 4 | RMS calculation | sound_wrappers.cpp | 192-197 | 3-5x | HIGH | 1 |
| 5 | Table column statistics | table_wrappers.cpp | NEW | 4-6x | HIGH | 1-2 |
| 6 | Sound data frame export | sound_wrappers.cpp | 490-497 | 2-4x | MEDIUM-HIGH | 2 |
| 7 | Intensity calculations | intensity_wrappers.cpp | Various | 2-4x | MEDIUM-HIGH | 2 |
| 8 | Spectral operations | spectrum_wrappers.cpp | Various | 2-4x | MEDIUM | 2 |
| 9 | EGG derivative | electroglottogram_wrappers.cpp | 82-94 | 3-4x | MEDIUM | 2 |
| 10 | Formant extraction | formant_wrappers.cpp | Various | 2-4x | HIGH | 3 |

### 4. Phase 1 Implementation Plan (REVISED)

**Duration**: 3-4 days

**Deliverables**:

1. **Infrastructure Setup**
   - Add `LinkingTo: RcppXsimd` to DESCRIPTION
   - Update `SystemRequirements: C++14` (minimum for xsimd)
   - Create `src/simd/` directory
   - Create `src/simd/simd_utils.h` with helper macros
   - Create `configure` script for SIMD detection

2. **Sound SIMD Implementations**
   - `src/simd/sound_simd.cpp`:
     - `sound_as_matrix_simd()`
     - `sound_create_from_values_simd()`
     - `sound_create_tone_simd()`
     - `sound_get_rms_simd()`

3. **Conditional Dispatch in Wrappers**
   - Modify `src/sound_wrappers.cpp`:
     - Add `#ifdef HAVE_XSIMD` guards
     - Add runtime SIMD availability check
     - Maintain scalar fallback paths

4. **Testing Suite**
   - `tests/testthat/test-simd-sound.R`:
     - Numerical accuracy tests (tolerance: 1e-12)
     - Performance benchmarks
     - Platform compatibility tests

5. **Documentation**
   - `SIMD_PATTERNS.md` - Developer guide
   - Update README with SIMD capabilities
   - Document performance gains

**Expected Results**:
- 4-8x speedup for audio I/O operations
- 4-6x speedup for tone generation
- 3-5x speedup for RMS/intensity calculations
- Overall: 2-4x improvement in typical audio processing pipelines

### 5. Technical Implementation Details

#### SIMD Utilities Header

```cpp
// src/simd/simd_utils.h
#ifndef SIMD_UTILS_H
#define SIMD_UTILS_H

#include <xsimd/xsimd.hpp>

// Helper macros for SIMD operations
#define SIMD_BATCH_SIZE (xsimd::batch<double>::size)

// Compile-time SIMD availability
#ifdef HAVE_XSIMD
  #define SIMD_AVAILABLE 1
#else
  #define SIMD_AVAILABLE 0
#endif

// Runtime SIMD check
inline bool use_simd() {
  static bool enabled = std::getenv("SPEAKER_DISABLE_SIMD") == nullptr;
  return enabled && SIMD_AVAILABLE;
}

// Aligned allocation helper
template<typename T>
inline bool is_aligned(const T* ptr, size_t alignment = SIMD_BATCH_SIZE * sizeof(T)) {
  return reinterpret_cast<std::uintptr_t>(ptr) % alignment == 0;
}

#endif // SIMD_UTILS_H
```

#### Example: Sound to Matrix SIMD

```cpp
// src/simd/sound_simd.cpp
#include <xsimd/xsimd.hpp>
#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "simd_utils.h"

// [[Rcpp::export(.sound_as_matrix_simd)]]
Rcpp::NumericMatrix sound_as_matrix_simd(SEXP xptr) {
    structSound* sound = get_ptr(xptr, "Sound");

    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    Rcpp::NumericMatrix mat(sound->ny, sound->nx);

    for (int ch = 1; ch <= sound->ny; ch++) {
        const double* src = &sound->z[ch][1];  // Praat uses 1-based indexing
        double* dst = &mat(ch - 1, 0);          // R uses 0-based indexing

        int i = 0;
        // SIMD loop - process in batches of 2, 4, or 8 doubles
        for (; i + simd_size <= sound->nx; i += simd_size) {
            batch b = xsimd::load_unaligned(&src[i]);
            xsimd::store_unaligned(&dst[i], b);
        }

        // Scalar remainder loop
        for (; i < sound->nx; ++i) {
            dst[i] = src[i];
        }
    }

    return mat;
}
```

#### Example: Tone Generation SIMD

```cpp
// src/simd/sound_simd.cpp (continued)

// [[Rcpp::export(.sound_create_tone_simd)]]
Rcpp::XPtr<structSound> sound_create_tone_simd(
    double duration,
    double sampling_rate,
    double frequency,
    double amplitude
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    autoSound sound = Sound_createSimple(1, duration, sampling_rate);

    const double t_start = sound->x1;
    const double dt = sound->dx;
    const double omega = 2.0 * M_PI * frequency;

    // Prepare SIMD constants
    batch amp_vec(amplitude);
    batch omega_vec(omega);
    batch t_start_vec(t_start);
    batch dt_vec(dt);

    // Create index offset vector [0, 1, 2, 3, ...]
    alignas(simd_size * sizeof(double)) double indices[simd_size];
    for (size_t k = 0; k < simd_size; ++k) {
        indices[k] = static_cast<double>(k);
    }
    batch idx_offset = xsimd::load_aligned(indices);
    batch idx_increment(simd_size);

    double* data = &sound->z[1][1];
    int i = 0;
    batch current_idx(0.0);

    // SIMD loop
    for (; i + simd_size <= sound->nx; i += simd_size) {
        // t = t_start + (i + [0,1,2,3,...]) * dt
        batch t = t_start_vec + (current_idx + idx_offset) * dt_vec;

        // value = amplitude * sin(omega * t)
        batch values = amp_vec * xsimd::sin(omega_vec * t);

        xsimd::store_unaligned(&data[i], values);

        current_idx = current_idx + idx_increment;
    }

    // Scalar remainder
    for (; i < sound->nx; ++i) {
        double t = t_start + i * dt;
        data[i] = amplitude * std::sin(omega * t);
    }

    return create_xptr_from_auto<structSound>(sound);
}
```

### 6. Platform Compatibility Strategy

**SIMD Instruction Sets Supported by xsimd**:

| Platform | CPU Type | SIMD Instructions | Batch Size |
|----------|----------|-------------------|------------|
| x86_64 | Intel/AMD | SSE2 (baseline) | 2 doubles |
| x86_64 | Intel/AMD | AVX | 4 doubles |
| x86_64 | Intel/AMD | AVX2 | 4 doubles |
| x86_64 | Intel/AMD | AVX512 | 8 doubles |
| ARM64 | Apple Silicon | NEON | 2 doubles |
| ARM64 | ARM v8 | NEON | 2 doubles |

**Implementation Strategy**:
1. **Automatic Detection**: xsimd automatically selects best available instruction set
2. **Runtime Fallback**: Scalar version available if SIMD unavailable
3. **User Control**: Environment variable `SPEAKER_DISABLE_SIMD=1` to disable
4. **Configure Script**: Detect SIMD support during package installation

### 7. Performance Expectations

**Microbenchmarks** (individual operations):

| Operation | Baseline | SIMD | Expected Speedup |
|-----------|----------|------|------------------|
| sound_as_matrix (10s audio) | 15 ms | 2-3 ms | 5-7x |
| sound_create_from_values (10s) | 12 ms | 2-3 ms | 4-6x |
| sound_create_tone (10s) | 8 ms | 1.5-2 ms | 4-5x |
| sound_get_rms (10s) | 10 ms | 2.5-3 ms | 3-4x |

**End-to-End Pipelines**:

| Workflow | Baseline | SIMD | Expected Speedup |
|----------|----------|------|------------------|
| Audio import + export | 30 ms | 6-8 ms | 3.5-5x |
| Intensity analysis (10min audio) | 45 s | 15-18 s | 2.5-3x |
| Formant extraction (10min) | 60 s | 25-30 s | 2-2.4x |

**Note**: End-to-end speedups are lower because they include Praat internal functions that aren't SIMD-optimized in Phase 1.

### 8. Risk Mitigation

**Identified Risks**:

1. **Platform Compatibility**
   - **Risk**: SIMD code may not compile on all platforms
   - **Mitigation**: Maintain scalar fallback, test on multiple platforms
   - **Priority**: HIGH

2. **Numerical Accuracy**
   - **Risk**: SIMD results may differ slightly from scalar
   - **Mitigation**: Strict tolerance testing (1e-12), compare to Praat
   - **Priority**: HIGH

3. **Maintenance Burden**
   - **Risk**: Duplicate code paths increase complexity
   - **Mitigation**: Clear abstraction, comprehensive tests
   - **Priority**: MEDIUM

4. **Limited Speedup**
   - **Risk**: Actual speedups may be lower than expected
   - **Mitigation**: Extensive benchmarking, focus on high-impact operations
   - **Priority**: MEDIUM

### 9. Success Criteria

**Phase 1 Goals**:

- ✅ SIMD infrastructure setup (configure, headers, build system)
- ✅ 4-5 SIMD-optimized Sound functions
- ✅ Numerical accuracy validation (tolerance: 1e-12)
- ✅ Performance benchmarks showing 3-6x speedups
- ✅ Cross-platform compilation (macOS, Linux, Windows)
- ✅ Zero regressions in existing tests
- ✅ Documentation for developers and users

**Minimum Acceptable Performance**:
- At least 2x speedup for Sound I/O operations
- At least 3x speedup for tone generation
- No numerical differences beyond floating-point tolerance

**Stretch Goals**:
- 6-8x speedup for bulk data operations
- SIMD optimization for Table statistical functions
- Initial work on intensity/spectral SIMD

### 10. Optional: Matrix Activation and SIMD (Phase 1b)

**Status**: Matrix implementation exists but is intentionally deferred

**If Matrix activation is desired**, the following work would be required:

#### Activation Steps

1. **Activate C++ Wrappers**:
   ```bash
   # Move .wip file to active
   mv src/matrix_wrappers.cpp.wip src/matrix_wrappers.cpp

   # Add to Makevars WRAPPER_SRC list
   # Edit src/Makevars and add matrix_wrappers.cpp

   # Regenerate RcppExports
   Rcpp::compileAttributes()

   # Rebuild package
   R CMD INSTALL --preclean .
   ```

2. **Verify Functionality**:
   ```r
   # Test basic matrix creation
   mat <- praat_matrix_simple(10, 10)
   mat$get_nx()  # Should return 10
   mat$get_ny()  # Should return 10

   # Test statistical operations
   mat$set_value(1, 1, 100.0)
   mat$get_sum()
   mat$get_mean()
   ```

#### SIMD Optimization for Matrix (if activated)

**Files to Create**:
- `src/simd/matrix_simd.cpp` - SIMD implementations
- Tests already exist: `inst/benchmarks/01_matrix_operations.R`

**Functions to Optimize**:

1. **`matrix_get_sum_simd()`** - Most critical
   ```cpp
   // Process 2D array row by row with SIMD
   for each row:
     vectorize sum across columns
     accumulate to total
   ```
   - Expected speedup: 4-8x
   - High impact: Used in all statistical operations

2. **`matrix_get_mean_simd()`**
   - Wrapper around `matrix_get_sum_simd()` with division
   - Expected speedup: 4-8x

3. **`matrix_get_min_max_simd()`** - Single-pass min/max
   ```cpp
   // Process with SIMD min/max reductions
   batch min_vec = batch::max();
   batch max_vec = batch::min();
   for each element:
     min_vec = xsimd::min(min_vec, batch)
     max_vec = xsimd::max(max_vec, batch)
   ```
   - Expected speedup: 4-6x
   - Single pass more efficient than two calls

4. **`matrix_to_r_matrix_simd()`** - Bulk copy
   ```cpp
   // Similar to sound_as_matrix_simd()
   for each row:
     vectorized load from Praat matrix
     vectorized store to R matrix
   ```
   - Expected speedup: 4-8x
   - High impact: Used for data export

5. **`matrix_from_r_matrix_simd()`** - Bulk copy
   - Mirror of `matrix_to_r_matrix_simd()`
   - Expected speedup: 4-8x
   - High impact: Used for data import

**Implementation Pattern**:
```cpp
// src/simd/matrix_simd.cpp
#include <xsimd/xsimd.hpp>

// [[Rcpp::export(.matrix_get_sum_simd)]]
double matrix_get_sum_simd(SEXP xptr) {
    structMatrix* matrix = get_ptr(xptr, "Matrix");
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    double sum = 0.0;
    for (integer row = 1; row <= matrix->ny; row++) {
        double* row_data = &matrix->z[row][1];
        integer nx = matrix->nx;

        batch acc(0.0);
        integer col = 0;

        // SIMD loop
        for (; col + simd_size <= nx; col += simd_size) {
            batch b = xsimd::load_unaligned(&row_data[col]);
            acc += b;
        }
        sum += xsimd::reduce_add(acc);

        // Remainder
        for (; col < nx; ++col) {
            sum += row_data[col];
        }
    }
    return sum;
}
```

**Estimated Effort** (if Matrix is activated):
- Matrix activation: 1-2 hours
- SIMD implementation: 1-2 days
- Testing and benchmarking: 0.5-1 day
- **Total**: 2-3 days

**Expected Performance Gains**:
- 4-8x speedup for statistical operations (sum, mean, min, max)
- 4-8x speedup for bulk data conversions
- 2-4x improvement in workflows using matrix-heavy operations

**Decision Point**:
Discuss with package maintainers whether Matrix activation is desired for v1.0.0 or should remain deferred.

---

### 11. Next Steps (Phase 2)

After Phase 1 completion, proceed to:

1. **Week 2**: Signal Processing SIMD
   - Intensity calculations (intensity_wrappers.cpp)
   - Spectral operations (spectrum_wrappers.cpp)
   - EGG signal processing (electroglottogram_wrappers.cpp)
   - Table statistical operations (table_wrappers.cpp)

2. **Week 3**: Complex Algorithms (Evaluation)
   - Profile FFT performance in Praat
   - Evaluate formant extraction bottlenecks
   - Decision point: FFTW integration vs Praat optimization

3. **Week 4**: Finalization
   - Comprehensive benchmarks
   - Documentation completion
   - CRAN compliance testing

---

## Conclusion

This updated assessment corrects the initial assumption about matrix operations and refocuses SIMD optimization efforts on the actual codebase structure. The primary targets are:

1. ✅ **Sound data conversion operations** - Highest impact, most frequently called
2. ✅ **Tone generation and synthesis** - High performance gains available
3. ✅ **Intensity/RMS calculations** - Common in phonetic workflows
4. ✅ **Table statistical operations** - Important for data analysis

The revised Phase 1 plan maintains the 3-4 day timeline while focusing on achievable, high-impact optimizations that will deliver measurable performance improvements to speaker package users.

---

**Analysis Date**: 2025-11-16
**Analyst**: Claude (Anthropic)
**Codebase Version**: speaker 0.4.1
**Status**: Assessment complete, ready for implementation
