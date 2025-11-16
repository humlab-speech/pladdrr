# SIMD Integration Plan for speaker Package
## Integrating RcppXsimd into Package Development Roadmap

**Date**: 2025-11-12
**Package Version**: 0.4.1 → 1.0.0 → 2.0.0
**Integration Timeline**: Parallel to feature development

---

## Overview

This document integrates SIMD optimization using RcppXsimd into the existing package development roadmap documented in `OOP_CONFIRMED_PLAN_2025-11-12.md`. SIMD optimizations will be implemented **in parallel** with feature completion to maximize performance gains in the v1.0.0 release.

---

## Integration Strategy

### Guiding Principles

1. **Parallel Development**: SIMD optimizations proceed alongside feature completion
2. **Incremental Integration**: Start with high-impact, low-risk optimizations
3. **Maintain Compatibility**: Keep scalar fallbacks for unsupported platforms
4. **Validate Thoroughly**: Ensure numerical accuracy matches Praat/scalar versions
5. **Document Performance**: Benchmark and document all optimizations

---

## Revised Timeline: v0.4.1 → v1.0.0 (4 Weeks)

### Week 1: Foundation + Phase 1 SIMD (REVISED 2025-11-16)

#### Feature Work (from OOP_CONFIRMED_PLAN_2025-11-12.md)
- ✅ Complete examples from superassp
- ✅ Begin documentation work

#### SIMD Integration (UPDATED)
**Priority**: High-impact, low-complexity wins
**Status**: REVISED - Matrix operations not available, focusing on Sound/data operations

**Tasks**:
1. **Setup RcppXsimd infrastructure**
   - Add `LinkingTo: RcppXsimd` to DESCRIPTION
   - Update `SystemRequirements` to C++14 (minimum for xsimd)
   - Create `src/simd/` directory structure
   - Add SIMD test suite template
   - Create configure script to detect SIMD capabilities

2. **Sound data conversion loops** (`src/sound_wrappers.cpp:72-76, 509-521`) ⭐ TOP PRIORITY
   - `sound_create_from_values()` → SIMD bulk copy (lines 72-76)
   - `sound_as_matrix()` → SIMD bulk copy (lines 514-518)
   - `sound_as_data_frame()` → SIMD data extraction (lines 490-497)
   - **Expected speedup**: 4-8x for large audio files

3. **Tone generation** (`src/sound_wrappers.cpp:88-110`) ⭐ HIGH IMPACT
   - `sound_create_tone()` → Vectorized sine function
   - Use `xsimd::sin()` for batch processing
   - **Expected speedup**: 4-6x for tone generation

4. **Intensity/RMS calculations** (`src/sound_wrappers.cpp:180-202`)
   - `sound_get_rms()` → SIMD sum-of-squares
   - `sound_get_energy()` → SIMD implementation
   - `sound_get_power()` → SIMD implementation
   - **Expected speedup**: 3-5x for intensity calculations

5. **Table operations** (`src/table_wrappers.cpp`)
   - `table_get_column_statistics()` → SIMD aggregations
   - Bulk numeric value access with SIMD
   - **Expected speedup**: 3-5x for statistical operations

**Deliverables**:
- 5-7 SIMD-optimized functions (Sound-focused)
- Microbenchmark suite showing 3-5x speedups
- Test suite validating numerical accuracy (tolerance: 1e-12)
- `SIMD_PATTERNS.md` developer guide
- Configure script for platform detection

**Estimated Effort**: 3-4 days
**Expected Speedup**: 3-6x for targeted operations

**Note**: Matrix operations deferred - no matrix_wrappers.cpp file exists. Matrix functionality appears to be handled through Table or direct Praat objects.

---

### Week 2: Documentation + Phase 2 SIMD

#### Feature Work
- 📝 Complete 6 comprehensive vignettes
- 📝 Migration guides (Praat scripts, Parselmouth)
- 📝 Package website (pkgdown)

#### SIMD Integration
**Priority**: Signal processing and acoustic analysis

**Tasks**:
1. **Intensity calculations** (`src/intensity_wrappers.cpp`, `src/sound_wrappers.cpp:180-202`)
   - ✅ Replace `Sound_getRootMeanSquare()` with SIMD version
   - ✅ Vectorize `sound_get_rms()`
   - ✅ Optimize `Sound_getEnergy()` and `Sound_getPower()`

2. **Sound mixing and scaling** (`src/sound_wrappers.cpp:705-935`)
   - ✅ `sound_scale_peak()` → SIMD scalar multiplication
   - ✅ `sound_scale_intensity()` → SIMD implementation
   - ✅ `sound_mix()` → SIMD weighted sum

3. **Spectrogram export** (`src/spectrogram_wrappers.cpp:138-152`)
   - ✅ `spectrogram_as_matrix()` → SIMD data reorganization

4. **DataFrame assembly** (`src/sound_wrappers.cpp:478-504`)
   - ✅ Vectorize time vector generation
   - ✅ Optimize multi-column assembly

**Deliverables**:
- 6-8 additional SIMD functions
- Integration with real phonetic workflows
- Vignette: "SIMD Performance in speaker" (`vignettes/simd-optimization.Rmd`)

**Estimated Effort**: 3-4 days
**Expected Speedup**: 2-4x for signal processing operations

---

### Week 3: Testing & Validation + Phase 3 SIMD (Evaluation)

#### Feature Work
- ✅ Comprehensive test suite (>95% coverage)
- ✅ Cross-platform testing (Windows, macOS, Linux)
- ✅ Validation against Praat desktop output

#### SIMD Integration
**Priority**: Evaluate complex algorithms (FFT, formant, pitch)

**Tasks**:
1. **FFT evaluation**
   - 📊 Benchmark Praat's FFT performance
   - 📊 Profile spectrogram generation bottlenecks
   - ⚠️ **Decision point**: Integrate FFTW or optimize Praat's FFT?

2. **Window functions** (for spectrogram)
   - ✅ Vectorize Hamming window: `0.54 - 0.46 * cos(2πi/N)`
   - ✅ Vectorize Hanning window
   - ✅ Vectorize Gaussian window

3. **LPC preprocessing** (for formant extraction)
   - ✅ Implement SIMD pre-emphasis filter
   - 📊 Profile autocorrelation bottlenecks
   - ⚠️ **Decision point**: Vectorize Burg's algorithm?

4. **Pitch autocorrelation** (if time permits)
   - 📊 Profile `Sound_to_Pitch()` performance
   - 📊 Identify vectorizable lag correlation loops

**Deliverables**:
- FFT performance analysis report
- Decision: FFTW integration vs. Praat optimization
- Window function SIMD implementations (if FFT remains bottleneck)
- Phase 3 go/no-go decision

**Estimated Effort**: 3-4 days (evaluation-heavy)
**Expected Speedup**: TBD based on profiling results

---

### Week 4: CRAN Preparation + SIMD Finalization

#### Feature Work
- ✅ R CMD check --as-cran (clean)
- ✅ Performance benchmarks
- ✅ Documentation polish
- ✅ Version 1.0.0 release preparation

#### SIMD Finalization
**Priority**: Polish, document, validate

**Tasks**:
1. **Comprehensive benchmarks**
   - 📊 End-to-end pipeline benchmarks
   - 📊 Comparison: speaker SIMD vs. speaker baseline vs. Parselmouth
   - 📊 Hardware-specific results (Intel, AMD, ARM)

2. **Documentation completion**
   - 📝 Technical vignette: "SIMD Optimization in speaker"
   - 📝 Developer guide: `SIMD_PATTERNS.md`
   - 📝 Benchmark report: `SIMD_BENCHMARKS.md`
   - 📝 Update README with performance highlights

3. **CRAN compliance**
   - ✅ Ensure all SIMD code compiles on all platforms
   - ✅ Test on CRAN build systems (win-builder, R-hub)
   - ✅ Address any compilation warnings
   - ✅ Verify scalar fallbacks work

4. **Release notes**
   - 📝 Highlight SIMD performance improvements
   - 📝 Document system requirements (C++14)
   - 📝 Benchmark summary for users

**Deliverables**:
- Complete SIMD integration for v1.0.0
- Benchmark report demonstrating 2-4x pipeline speedups
- CRAN-ready package with SIMD support

**Estimated Effort**: 3-4 days

---

## Post-v1.0.0: Advanced SIMD Optimizations

### v1.1.0: Advanced Signal Processing (If Phase 3 Approved)

**Timeline**: 4-6 weeks post-v1.0.0
**Condition**: If FFT/formant profiling shows significant SIMD potential

#### Potential Tasks:
1. **FFTW Integration** (if GPL-compatible decision made)
   - Replace Praat's FFT with FFTW (SIMD-optimized)
   - Benchmark speedup for spectrogram generation
   - Estimated speedup: 2-3x additional for FFT operations

2. **Formant extraction optimization**
   - Vectorize LPC autocorrelation loops
   - Optimize Burg's algorithm inner loops
   - Estimated speedup: 2-3x for formant tracking

3. **Pitch detection optimization**
   - Vectorize autocorrelation method
   - Optimize lag computation loops
   - Implement SIMD peak detection
   - Estimated speedup: 2-3x for pitch tracking

4. **Filtering operations**
   - Vectorize FIR filtering with FMA
   - Implement SIMD convolution kernels
   - Estimated speedup: 2-4x for filtering

**Estimated Overall Pipeline Speedup**: 3-5x (vs. 2-4x in v1.0.0)

---

## SIMD Code Organization (REVISED 2025-11-16)

### Directory Structure

```
speaker/
├── src/
│   ├── simd/                          # NEW: SIMD-optimized implementations
│   │   ├── sound_simd.cpp            # Sound processing (bulk copy, tone gen)
│   │   ├── intensity_simd.cpp        # Intensity/RMS calculations
│   │   ├── table_simd.cpp            # Table statistical operations
│   │   ├── conversion_simd.cpp       # Data conversion utilities
│   │   ├── window_functions_simd.cpp # Window functions (Phase 2)
│   │   └── simd_utils.h              # SIMD utility functions & macros
│   ├── sound_wrappers.cpp            # Calls SIMD versions conditionally
│   ├── table_wrappers.cpp            # Calls SIMD versions conditionally
│   ├── configure                      # NEW: Detect SIMD capabilities
│   └── ...
├── tests/testthat/
│   ├── test-simd-matrix.R            # NEW: SIMD validation tests
│   ├── test-simd-sound.R
│   ├── test-simd-accuracy.R          # Numerical accuracy tests
│   └── ...
├── vignettes/
│   ├── simd-optimization.Rmd         # NEW: SIMD performance vignette
│   └── ...
├── SIMD_OPTIMIZATION_REPORT.md       # ✅ Created (this document's companion)
├── SIMD_INTEGRATION_PLAN.md          # ✅ Created (this document)
├── SIMD_PATTERNS.md                  # To create in Week 1
└── SIMD_BENCHMARKS.md                # To create in Week 4
```

---

## Implementation Details by Component

### 1. Sound Data Conversion Operations (Week 1) - REVISED

**Files to Modify**:
- `src/sound_wrappers.cpp` (add SIMD versions, conditional dispatch)
- `src/simd/sound_simd.cpp` (NEW)
- `src/simd/simd_utils.h` (NEW - helper macros)
- `tests/testthat/test-simd-sound.R` (NEW)

**Implementation Pattern**:
```cpp
// src/simd/sound_simd.cpp
#include <xsimd/xsimd.hpp>
#include <Rcpp.h>
#include "simd_utils.h"

// [[Rcpp::export(.sound_as_matrix_simd)]]
Rcpp::NumericMatrix sound_as_matrix_simd(SEXP xptr) {
    structSound* sound = get_ptr(xptr, "Sound");

    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    Rcpp::NumericMatrix mat(sound->ny, sound->nx);

    for (int ch = 1; ch <= sound->ny; ch++) {
        const double* src = &sound->z[ch][1];
        double* dst = &mat(ch - 1, 0);

        int i = 0;
        // SIMD loop - process in batches
        for (; i + simd_size <= sound->nx; i += simd_size) {
            batch b = xsimd::load_unaligned(&src[i]);
            xsimd::store_unaligned(&dst[i], b);
        }

        // Remainder loop
        for (; i < sound->nx; ++i) {
            dst[i] = src[i];
        }
    }

    return mat;
}

// [[Rcpp::export(.sound_create_from_values_simd)]]
Rcpp::XPtr<structSound> sound_create_from_values_simd(
    Rcpp::NumericMatrix values,
    double sampling_rate
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    int n_channels = values.nrow();
    int n_samples = values.ncol();
    double duration = n_samples / sampling_rate;

    autoSound sound = Sound_createSimple(n_channels, duration, sampling_rate);

    for (int ch = 1; ch <= n_channels; ch++) {
        const double* src = &values(ch - 1, 0);
        double* dst = &sound->z[ch][1];

        int i = 0;
        // SIMD bulk copy
        for (; i + simd_size <= n_samples; i += simd_size) {
            batch b = xsimd::load_unaligned(&src[i]);
            xsimd::store_unaligned(&dst[i], b);
        }

        // Remainder
        for (; i < n_samples; ++i) {
            dst[i] = src[i];
        }
    }

    return create_xptr_from_auto<structSound>(sound);
}
```

**Conditional Dispatch**:
```cpp
// src/sound_wrappers.cpp
// [[Rcpp::export(.sound_as_matrix)]]
NumericMatrix sound_as_matrix(XPtr<structSound> xptr) {
#ifdef HAVE_XSIMD
    if (use_simd()) {
        return sound_as_matrix_simd(xptr);
    }
#endif
    // Fallback to scalar version
    return sound_as_matrix_scalar(xptr);
}
```

**Testing**:
```r
# tests/testthat/test-simd-sound.R
test_that("SIMD sound conversion matches scalar", {
  # Create test sound
  sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100,
                             frequency = 440, amplitude = 1.0)

  # Compare outputs
  mat_scalar <- .sound_as_matrix_scalar(sound$.__enclos_env__$private$ptr)
  mat_simd <- .sound_as_matrix_simd(sound$.__enclos_env__$private$ptr)

  expect_equal(mat_scalar, mat_simd, tolerance = 1e-15)
})

test_that("SIMD sound conversion is faster", {
  sound <- Sound$create_tone(duration = 10.0, sampling_rate = 44100,
                             frequency = 440, amplitude = 1.0)

  bench_result <- bench::mark(
    scalar = .sound_as_matrix_scalar(sound$.__enclos_env__$private$ptr),
    simd   = .sound_as_matrix_simd(sound$.__enclos_env__$private$ptr),
    iterations = 50,
    check = FALSE
  )

  speedup <- median(bench_result$time[bench_result$expression == "scalar"]) /
             median(bench_result$time[bench_result$expression == "simd"])

  expect_gt(speedup, 2.0)  # Expect at least 2x speedup
})
```

---

### 2. Sound Processing (Weeks 1-2)

**Key Optimizations**:

#### Tone Generation
```cpp
// src/simd/sound_simd.cpp
#include <xsimd/xsimd.hpp>

XPtr<structSound> sound_create_tone_simd(
    double duration,
    double sampling_rate,
    double frequency,
    double amplitude
) {
    try {
        autoSound sound = Sound_createSimple(1, duration, sampling_rate);

        using batch = xsimd::batch<double>;
        constexpr size_t simd_size = batch::size;

        batch t_base(sound->x1);
        batch dt(sound->dx);
        batch two_pi_f(2.0 * M_PI * frequency);
        batch amp(amplitude);

        // Generate sequential indices: [0, 1, 2, 3], [4, 5, 6, 7], ...
        alignas(batch::size * sizeof(double)) double idx_arr[simd_size];
        for (size_t k = 0; k < simd_size; ++k) idx_arr[k] = k;
        batch idx_incr = xsimd::load_aligned(idx_arr);
        batch simd_size_batch(simd_size);

        integer i = 1;
        for (; i + simd_size <= sound->nx; i += simd_size) {
            batch i_batch(i - 1);
            batch t = t_base + (i_batch + idx_incr) * dt;
            batch values = amp * xsimd::sin(two_pi_f * t);
            xsimd::store_unaligned(&sound->z[1][i], values);
        }

        // Remainder loop
        for (; i <= sound->nx; i++) {
            double t = sound->x1 + (i - 1) * sound->dx;
            sound->z[1][i] = amplitude * sin(2.0 * M_PI * frequency * t);
        }

        return create_xptr_from_auto<structSound>(sound);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create tone");
    }
}
```

#### Data Conversion
```cpp
// Optimized sound creation from R matrix
XPtr<structSound> sound_create_from_values_simd(
    NumericMatrix values,
    double sampling_rate
) {
    // ... validation ...

    try {
        int n_channels = values.nrow();
        int n_samples = values.ncol();
        double duration = n_samples / sampling_rate;

        autoSound sound = Sound_createSimple(n_channels, duration, sampling_rate);

        using batch = xsimd::batch<double>;
        constexpr size_t simd_size = batch::size;

        // Copy values with SIMD
        for (int ch = 1; ch <= n_channels; ch++) {
            double* dest = &sound->z[ch][1];
            const double* src = &values(ch - 1, 0);

            int i = 0;
            for (; i + simd_size <= n_samples; i += simd_size) {
                batch b = xsimd::load_unaligned(&src[i]);
                xsimd::store_unaligned(&dest[i], b);
            }

            // Remainder
            for (; i < n_samples; ++i) {
                dest[i] = src[i];
            }
        }

        return create_xptr_from_auto<structSound>(sound);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create sound from values");
    }
}
```

---

### 3. Intensity Calculations (Week 2)

**SIMD RMS Implementation**:
```cpp
// src/simd/intensity_simd.cpp

double sound_get_rms_simd(
    XPtr<structSound> xptr,
    double from_time,
    double to_time
) {
    structSound* sound = get_ptr(xptr, "Sound");

    if (from_time == 0.0) from_time = sound->xmin;
    if (to_time == 0.0) to_time = sound->xmax;

    // Convert times to sample indices
    integer i_start = Sampled_xToNearestIndex(sound, from_time);
    integer i_end = Sampled_xToNearestIndex(sound, to_time);
    if (i_start < 1) i_start = 1;
    if (i_end > sound->nx) i_end = sound->nx;

    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    double sum_squares = 0.0;
    integer total_samples = 0;

    for (int ch = 1; ch <= sound->ny; ch++) {
        const double* data = &sound->z[ch][i_start];
        integer n_samples = i_end - i_start + 1;

        // SIMD sum of squares
        batch acc(0.0);
        integer i = 0;
        for (; i + simd_size <= n_samples; i += simd_size) {
            batch x = xsimd::load_unaligned(&data[i]);
            acc = xsimd::fma(x, x, acc);  // acc += x * x
        }
        sum_squares += xsimd::reduce_add(acc);

        // Remainder
        for (; i < n_samples; ++i) {
            sum_squares += data[i] * data[i];
        }

        total_samples += n_samples;
    }

    // RMS = sqrt(mean(x^2))
    double mean_square = sum_squares / total_samples;
    return std::sqrt(mean_square);
}
```

---

## Testing and Validation Strategy

### Unit Tests (All SIMD Functions)

**Template**:
```r
# tests/testthat/test-simd-COMPONENT.R

test_that("SIMD FUNCTION matches scalar", {
  # Setup test data
  data <- ...

  # Call both versions
  scalar_result <- .function_scalar(data)
  simd_result <- .function_simd(data)

  # Validate numerical accuracy
  expect_equal(scalar_result, simd_result, tolerance = 1e-12)
})

test_that("SIMD FUNCTION is faster than scalar", {
  # Large enough data to see speedup
  data <- ...

  bench_result <- bench::mark(
    scalar = .function_scalar(data),
    simd   = .function_simd(data),
    iterations = 100,
    check = FALSE  # Already validated above
  )

  # Expect speedup (conservative: 1.5x minimum)
  speedup <- median(bench_result$time[bench_result$expression == "scalar"]) /
             median(bench_result$time[bench_result$expression == "simd"])

  expect_gt(speedup, 1.5,
            label = sprintf("Expected >1.5x speedup, got %.2fx", speedup))
})
```

---

### Integration Tests (Phonetic Workflows)

**Example: Formant Extraction Pipeline**
```r
test_that("SIMD improves formant extraction pipeline", {
  # Load test audio
  sound <- Sound$new(system.file("extdata/test.wav", package = "speaker"))

  # Baseline (scalar)
  options(speaker.use_simd = FALSE)
  time_scalar <- system.time({
    formants_scalar <- sound$to_formant_burg(0.01, 5, 5500, 0.025, 50)
    df_scalar <- formants_scalar$as_data_frame()
  })

  # SIMD-optimized
  options(speaker.use_simd = TRUE)
  time_simd <- system.time({
    formants_simd <- sound$to_formant_burg(0.01, 5, 5500, 0.025, 50)
    df_simd <- formants_simd$as_data_frame()
  })

  # Validate results match
  expect_equal(df_scalar$F1, df_simd$F1, tolerance = 1e-6)
  expect_equal(df_scalar$F2, df_simd$F2, tolerance = 1e-6)

  # Expect overall speedup
  speedup <- time_scalar[["elapsed"]] / time_simd[["elapsed"]]
  expect_gt(speedup, 1.3,  # Conservative for integration test
            label = sprintf("Expected >1.3x speedup, got %.2fx", speedup))
})
```

---

### Platform Validation

**Test Matrix**:
| Platform | CPU | SIMD Support | Tested |
|----------|-----|--------------|--------|
| Windows 10 | Intel x86-64 | SSE2/AVX2 | ⬜ |
| macOS (Intel) | Intel x86-64 | SSE2/AVX2 | ⬜ |
| macOS (ARM) | Apple M1/M2 | NEON | ⬜ |
| Ubuntu 22.04 | Intel x86-64 | SSE2/AVX2 | ⬜ |
| Ubuntu 22.04 | AMD x86-64 | SSE2/AVX2 | ⬜ |
| R-hub (win-builder) | - | SSE2 | ⬜ |
| GitHub Actions | - | SSE2/AVX | ⬜ |

**CI/CD Integration**:
```yaml
# .github/workflows/R-CMD-check.yaml
- name: Test SIMD support
  run: |
    Rscript -e 'library(speaker); cat("SIMD support:", use_simd(), "\n")'
    Rscript -e 'testthat::test_dir("tests/testthat/", filter = "simd")'
```

---

## Documentation Plan

### 1. Technical Vignette: "SIMD Performance in speaker"

**Location**: `vignettes/simd-optimization.Rmd`

**Outline**:
1. Introduction to SIMD
2. Why SIMD matters for phonetic analysis
3. Which operations are accelerated
4. Benchmark results
5. How to disable SIMD (if needed)
6. Platform compatibility notes

**Example content**:
```r
# vignettes/simd-optimization.Rmd

## Performance Benchmarks

### Matrix Operations

```{r benchmark-matrix}
library(speaker)
library(bench)

mat <- matrix(rnorm(1000*1000), 1000, 1000)
m <- Matrix$from_r_matrix(mat)

bench::mark(
  sum = m$get_sum(),
  mean = m$get_mean(),
  min = m$get_minimum(),
  max = m$get_maximum(),
  iterations = 100
)
```

**Results**: Matrix operations show 4-6x speedup with SIMD.

### Tone Generation

```{r benchmark-tone}
bench::mark(
  tone_1s = Sound$create_tone(1.0, 44100, 440, 1.0),
  tone_10s = Sound$create_tone(10.0, 44100, 440, 1.0),
  iterations = 50
)
```

**Results**: Tone generation shows 4-5x speedup, scaling with duration.
```

---

### 2. Developer Guide: "SIMD Patterns"

**Location**: `SIMD_PATTERNS.md`

**Contents**:
- Code templates for common SIMD operations
- Best practices for alignment
- How to handle remainders
- Testing guidelines
- Debugging SIMD code

---

### 3. Benchmark Report

**Location**: `SIMD_BENCHMARKS.md`

**Contents**:
- Microbenchmark results for all optimized functions
- End-to-end pipeline comparisons
- Hardware-specific results
- Comparison with Parselmouth (Python)

---

### 4. User-Facing Documentation

**README.md additions**:
```markdown
## Performance

The `speaker` package uses SIMD (Single Instruction Multiple Data) vectorization
for significant performance improvements:

- **Matrix operations**: 4-8x faster
- **Signal generation**: 4-6x faster
- **Data conversion**: 4-8x faster
- **Overall pipelines**: 2-4x faster

SIMD is enabled by default and automatically adapts to your CPU's capabilities
(SSE2, AVX, AVX2, AVX512, or NEON on ARM).

To disable SIMD:
```r
options(speaker.use_simd = FALSE)
```

System requirements: C++14 compiler (automatic with R 4.0+)
```

---

## Risk Mitigation and Contingency Plans

### Contingency 1: SIMD Compilation Issues

**Risk**: RcppXsimd fails to compile on some platforms

**Mitigation**:
1. Test on multiple platforms early (Week 1)
2. Provide clear error messages in `configure` script
3. Make SIMD optional via conditional compilation:

```cpp
// src/config.h
#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#define USE_SIMD 1
#else
#define USE_SIMD 0
#endif

// Conditional implementation
#if USE_SIMD
double matrix_get_sum(SEXP xptr) {
    return matrix_get_sum_simd(xptr);
}
#else
double matrix_get_sum(SEXP xptr) {
    return matrix_get_sum_scalar(xptr);
}
#endif
```

**Fallback**: Ship package with SIMD as optional feature

---

### Contingency 2: SIMD Doesn't Provide Expected Speedup

**Risk**: Real-world speedups are lower than projected

**Mitigation**:
1. Profile early and often (Week 1)
2. Focus on highest-impact operations first
3. Measure end-to-end pipeline performance, not just microbenchmarks

**Decision Tree**:
- If <1.5x speedup → Don't merge SIMD code
- If 1.5-2x speedup → Merge but don't advertise prominently
- If 2-4x speedup → Merge and highlight in docs ✅
- If >4x speedup → Merge and make it a headliner feature

**Fallback**: Keep SIMD branch for future optimization, release v1.0.0 without SIMD

---

### Contingency 3: Numerical Accuracy Issues

**Risk**: SIMD results differ too much from Praat/scalar

**Mitigation**:
1. Comprehensive validation tests with tight tolerances (1e-12)
2. Compare against known Praat output
3. Document any known differences

**Action if issues found**:
- Investigate root cause (floating-point order of operations?)
- Adjust tolerance if differences are insignificant
- If unresolvable, revert specific SIMD function

**Fallback**: Keep only validated SIMD functions in v1.0.0

---

## Success Metrics

### Technical Metrics

| Metric | Target | Status |
|--------|--------|--------|
| Microbenchmark speedup (matrix ops) | >4x | ⬜ TBD |
| Microbenchmark speedup (signal processing) | >3x | ⬜ TBD |
| End-to-end pipeline speedup | >2x | ⬜ TBD |
| Test coverage (SIMD code) | >90% | ⬜ TBD |
| Platform compatibility | Win/Mac/Linux | ⬜ TBD |
| Numerical accuracy (tolerance) | <1e-10 | ⬜ TBD |
| CRAN checks | All pass | ⬜ TBD |

---

### User-Facing Metrics

| Metric | Target | Status |
|--------|--------|--------|
| Formant extraction (10-min audio) | <20s | ⬜ TBD |
| Spectrogram generation (10-min audio) | <15s | ⬜ TBD |
| Batch processing (100 files) | <10s | ⬜ TBD |
| User satisfaction (speed) | "Much faster" feedback | ⬜ TBD |

---

## Alignment with Package Roadmap

### Integration with OOP_CONFIRMED_PLAN_2025-11-12.md

**Original Timeline (4 weeks to v1.0.0)**:
- Week 1-2: Examples from superassp
- Week 2-3: Documentation
- Week 3-4: Testing & CRAN prep

**Revised Timeline with SIMD**:
- Week 1: Examples + **SIMD Phase 1** (matrix, data conversion, tone)
- Week 2: Documentation + **SIMD Phase 2** (intensity, mixing, spectrogram)
- Week 3: Testing + **SIMD Phase 3 Evaluation** (FFT, formant, pitch)
- Week 4: CRAN prep + **SIMD Finalization** (benchmarks, docs)

**No delay to v1.0.0 timeline**: SIMD work proceeds in parallel with planned tasks.

---

### Post-v1.0.0 Roadmap Integration

**v1.0.0**: Feature-complete with initial SIMD optimizations (2-4x pipeline speedup)

**v1.1.0** (Optional, 4-6 weeks later): Advanced SIMD
- FFTW integration (if approved)
- Formant extraction optimization
- Pitch detection optimization
- **Target**: 3-5x pipeline speedup

**v2.0.0** (6-9 months): R7 migration
- Maintain SIMD optimizations in R7 refactor
- Potentially add OpenMP for batch processing
- **Target**: Maintain or improve performance

---

## Conclusion

This plan integrates SIMD optimization into the speaker package development roadmap **without delaying v1.0.0**. By implementing SIMD in parallel with documentation and testing work, we can deliver:

✅ **v1.0.0 features** (all 17 Praat objects, comprehensive docs)
✅ **2-4x performance improvement** for phonetic analysis pipelines
✅ **Platform compatibility** (Windows, macOS, Linux, Intel, AMD, ARM)
✅ **CRAN-ready package** with optional SIMD acceleration

**Next Actions**:
1. ✅ Add RcppXsimd to DESCRIPTION (Week 1, Day 1)
2. ✅ Implement Phase 1 SIMD optimizations (Week 1)
3. ✅ Create benchmark suite (Week 1)
4. ✅ Continue with planned documentation work (Week 2)

---

**Document prepared by**: Claude (Anthropic)
**Date**: 2025-11-12
**Status**: Ready for implementation
**Integration with**: `OOP_CONFIRMED_PLAN_2025-11-12.md`, `SIMD_OPTIMIZATION_REPORT.md`
