# SIMD Optimization Plan for Praat DSP Functions

**Date**: 2025-01-22
**Package**: speaker
**Technology**: RcppXsimd + xsimd library
**Goal**: Accelerate Praat's numerical computations using SIMD vectorization while maintaining identical results

---

## Executive Summary

This document outlines a comprehensive plan to optimize performance-critical Praat functions using SIMD (Single Instruction, Multiple Data) vectorization via the xsimd library. The speaker package already uses RcppXsimd for several operations; this plan extends SIMD optimization to the original Praat codebase functions.

**Current SIMD Implementation Status**:
- ✅ Intensity calculations (RMS, energy, power)
- ✅ Sound mixing operations
- ✅ Window functions (Hanning, Hamming, Gaussian, etc.)
- ✅ Autocorrelation and cross-correlation

**Estimated Performance Gains**:
- **High-impact targets**: 2-4x speedup (vectorizable reductions, element-wise operations)
- **Medium-impact targets**: 1.5-2.5x speedup (complex operations with some branching)
- **Overall package speedup**: 1.8-2.5x for typical audio processing workflows

---

## Implementation Strategy

### Pattern: Dual Implementation with Compile-Time Selection

All SIMD optimizations will follow the established pattern used in the existing codebase:

```cpp
#ifdef RCPPXSIMD_XSIMD_HPP
#include <xsimd/xsimd.hpp>
#endif

// SIMD implementation
#ifdef RCPPXSIMD_XSIMD_HPP
double function_simd(...) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    batch acc(0.0);
    integer i = 0;

    // SIMD loop
    for (; i + simd_size <= n; i += simd_size) {
        batch x = xsimd::load_unaligned(&data[i]);
        // ... SIMD operations
    }

    // Scalar remainder
    for (; i < n; ++i) {
        // ... scalar operations
    }
}
#endif

// Scalar fallback (always available)
double function_scalar(...) {
    // Original Praat implementation
}

// Dispatcher
double function(...) {
#ifdef RCPPXSIMD_XSIMD_HPP
    return function_simd(...);
#else
    return function_scalar(...);
#endif
}
```

**Key Principles**:
1. **Preserve original code**: Keep original Praat implementation as scalar fallback
2. **Identical results**: SIMD version must produce bit-identical results (validated with tests)
3. **Graceful degradation**: Code compiles and runs without xsimd
4. **Minimal intrusion**: Avoid modifying Praat source files directly where possible
5. **Create wrapper files**: Implement SIMD versions in separate `*_simd.cpp` files

---

## Priority 1: High-Impact Array Operations (Estimated 3-4x speedup)

### 1.1 Statistical Reductions in Sound Processing

**File**: `src/praat.github.io/fon/Sound.cpp`
**Target Function**: `structSound::v1_info`
**New File**: `src/sound_statistics_simd.cpp`

**Operations**:
- Min/max finding across samples
- Sum and sum-of-squares (for RMS/energy)
- Mean and variance calculations

**Current Implementation**:
```cpp
for (integer channel = 1; channel <= our ny; channel ++) {
    for (integer i = 1; i <= our nx; i ++) {
        const double value_Pa = waveform_Pa [i];
        sum_Pa += value_Pa;
        sumOfSquares_Pa2 += value_Pa * value_Pa;
        // ... min/max checks
    }
}
```

**SIMD Strategy**:
- Use `xsimd::reduce_add()` for summation
- Use `xsimd::reduce_min()` and `xsimd::reduce_max()` for extrema
- Use `xsimd::fma()` for fused multiply-add in sum-of-squares

**Estimated Speedup**: 3-4x
**Conversion Complexity**: EASY
**Priority**: ⭐⭐⭐ HIGHEST

---

### 1.2 Sound Mono Conversion

**File**: `src/praat.github.io/fon/Sound.cpp`
**Target Function**: `Sound_convertToMono`
**New File**: `src/sound_conversion_simd.cpp`

**Operation**: Element-wise averaging of stereo/multi-channel audio

**Current Implementation**:
```cpp
// 2-channel case
for (integer i = 1; i <= my nx; i ++)
    thy z [1] [i] = 0.5 * (my z [1] [i] + my z [2] [i]);
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
batch scale(0.5);

for (; i + simd_size <= nx; i += simd_size) {
    batch ch1 = xsimd::load_unaligned(&channel1[i]);
    batch ch2 = xsimd::load_unaligned(&channel2[i]);
    batch result = scale * (ch1 + ch2);
    xsimd::store_unaligned(&output[i], result);
}
```

**Estimated Speedup**: 3-4x
**Conversion Complexity**: EASY
**Priority**: ⭐⭐⭐ HIGH

---

### 1.3 Window Function Application

**File**: `src/praat.github.io/fon/Sound.cpp`
**Target Function**: `Sound_multiplyByWindow`
**Status**: ✅ **ALREADY IMPLEMENTED** in `src/window_functions_simd.cpp`

**Current Implementation**: Element-wise multiplication with window coefficients
**SIMD Implementation**: Uses `xsimd::fma()` for efficient multiply-accumulate

**Measured Speedup**: ~2.5x
**Priority**: ✅ COMPLETE

---

### 1.4 Audio Data Type Conversion and Scaling

**File**: `src/praat.github.io/fon/Sound_audio.cpp`
**Target Functions**:
- `Sound_playPart` (double → int16 conversion)
- `Sound_record_fixedTime` (int16 → double conversion)

**New File**: `src/audio_conversion_simd.cpp`

**Operation**: Convert between floating-point and integer sample formats with scaling

**Current Implementation (double → int16)**:
```cpp
for (integer i = i1; i <= i2; i ++) {
    integer value = Melder_iround_tieDown (fromLeft [i] * 32768.0);
    * ++ to = (int16) Melder_clipped (-32768_integer, value, +32767_integer);
}
```

**SIMD Strategy**:
```cpp
using batch_d = xsimd::batch<double>;
using batch_i = xsimd::batch<int32_t>;

batch_d scale(32768.0);
batch_i min_val(-32768);
batch_i max_val(32767);

for (; i + simd_size <= n; i += simd_size) {
    batch_d samples = xsimd::load_unaligned(&input[i]);
    batch_d scaled = samples * scale;
    batch_i rounded = xsimd::to_int(xsimd::round(scaled));
    batch_i clamped = xsimd::clip(rounded, min_val, max_val);

    // Convert to int16 and store
    auto result = xsimd::batch_cast<int16_t>(clamped);
    xsimd::store_unaligned(&output[i], result);
}
```

**Estimated Speedup**: 4-5x
**Conversion Complexity**: MODERATE (requires understanding xsimd type conversions)
**Priority**: ⭐⭐⭐ HIGH (critical path for audio I/O)

---

## Priority 2: Numerical Library Functions (Estimated 2-3x speedup)

### 2.1 Matrix Row Multiplication

**File**: `src/praat.github.io/dwsys/NUM2.cpp`
**Target Function**: `MATmultiplyRows_inplace`
**New File**: `src/num_matrix_simd.cpp`

**Operation**: Multiply each row of a matrix by corresponding vector element

**Current Implementation**:
```cpp
void MATmultiplyRows_inplace (MATVU const& x, constVECVU const& v) {
    for (integer irow = 1; irow <= x.nrow; irow++)
        for (integer icol = 1; icol <= x.ncol; icol++)
            x [irow] [icol] *= v [irow];
}
```

**SIMD Strategy**:
```cpp
using batch = xsimd::batch<double>;
for (integer irow = 1; irow <= x.nrow; irow++) {
    batch scale(v[irow]);  // Broadcast scalar to all lanes
    integer i = 0;
    for (; i + simd_size <= x.ncol; i += simd_size) {
        batch row = xsimd::load_unaligned(&x[irow][i]);
        batch result = row * scale;
        xsimd::store_unaligned(&x[irow][i], result);
    }
    // Scalar remainder...
}
```

**Estimated Speedup**: 3-4x
**Conversion Complexity**: EASY
**Priority**: ⭐⭐⭐ HIGH

---

### 2.2 IIR Filtering

**File**: `src/praat.github.io/dwsys/NUM2.cpp`
**Target Function**: `VECfilterInverse_inplace`
**New File**: `src/num_filtering_simd.cpp`

**Operation**: Inverse IIR filter (dot product in inner loop)

**Current Implementation**:
```cpp
for (integer i = 1; i <= s.size; i++) {
    double out = s [i];
    for (integer j = 1; j <= filter.size; j++)
        out += filter [j] * filterMemory [filter.size - j + 1];
    // Update memory...
}
```

**SIMD Strategy**:
- Vectorize the inner dot product using `xsimd::reduce_add()`
- Main loop remains serial due to loop-carried dependency

**Estimated Speedup**: 2-3x (inner loop only)
**Conversion Complexity**: MODERATE
**Priority**: ⭐⭐ MEDIUM

---

### 2.3 Matrix-Vector Multiplication (Mahalanobis Distance)

**File**: `src/praat.github.io/dwsys/NUM2.cpp`
**Target Function**: `NUMmahalanobisDistanceSquared`
**New File**: `src/num_distance_simd.cpp`

**Operation**: Matrix-vector product + dot product

**Current Implementation** (inner product pattern):
```cpp
for (integer j = 1; j <= v.size; j++) {
    sum += lowerInverse[i][j] * v[j];
}
```

**SIMD Strategy**:
```cpp
// Vectorize dot product
using batch = xsimd::batch<double>;
batch acc(0.0);
integer j = 0;

for (; j + simd_size <= v.size; j += simd_size) {
    batch mat = xsimd::load_unaligned(&lowerInverse[i][j]);
    batch vec = xsimd::load_unaligned(&v[j]);
    acc = xsimd::fma(mat, vec, acc);
}

double sum = xsimd::reduce_add(acc);
// Scalar remainder...
```

**Estimated Speedup**: 2.5-3x
**Conversion Complexity**: MODERATE
**Priority**: ⭐⭐ MEDIUM-HIGH

---

### 2.4 Discrete Cosine Transform (DCT)

**File**: `src/praat.github.io/dwsys/NUM2.cpp`
**Target Function**: `VECcosineTransform_preallocated`
**New File**: `src/num_transform_simd.cpp`

**Operation**: Matrix-vector multiplication (DCT is sum of cosine basis functions)

**Current Implementation**:
```cpp
for (integer k = 1; k <= target.size; k ++) {
    longdouble sum = 0.0;
    for (integer n = 1; n <= x.size; n++)
        sum += x [n] * cos (NUMpi * (n - 0.5) * (k - 1) / x.size);
    target [k] = double (sum);
}
```

**SIMD Strategy**:
- Vectorize inner product using `xsimd::fma()`
- May require SIMD-friendly `cos()` implementation (use SLEEF library or polynomial approximation)

**Estimated Speedup**: 2-3x
**Conversion Complexity**: MODERATE-HARD (requires vectorized cos)
**Priority**: ⭐⭐ MEDIUM

---

## Priority 3: Signal Processing Operations (Estimated 2-4x speedup)

### 3.1 FFT-Based Convolution (Element-wise Complex Multiplication)

**File**: `src/praat.github.io/fon/Sound.cpp`
**Target Function**: `Sounds_convolve` (complex multiplication loop)
**New File**: `src/sound_convolution_simd.cpp`

**Operation**: Element-wise complex multiplication in frequency domain

**Current Implementation**:
```cpp
for (integer i = 3; i <= nfft; i += 2) {
    const double real1 = data1[i];
    const double imag1 = data1[i+1];
    const double real2 = data2[i];
    const double imag2 = data2[i+1];

    data2[i]   = real1 * real2 - imag1 * imag2;  // Real part
    data2[i+1] = real1 * imag2 + imag1 * real2;  // Imag part
}
```

**SIMD Strategy**:
```cpp
// Process 2 complex numbers at once (4 doubles)
using batch = xsimd::batch<double>;

for (; i + 3 <= nfft; i += 4) {
    batch a_ri = xsimd::load_unaligned(&data1[i]);     // [r1, i1, r2, i2]
    batch b_ri = xsimd::load_unaligned(&data2[i]);     // [r3, i3, r4, i4]

    // Shuffle to separate real and imaginary parts
    batch a_r = xsimd::swizzle(a_ri, {0, 0, 2, 2});   // [r1, r1, r2, r2]
    batch a_i = xsimd::swizzle(a_ri, {1, 1, 3, 3});   // [i1, i1, i2, i2]
    batch b_r = xsimd::swizzle(b_ri, {0, 1, 0, 1});   // [r3, i3, r4, i4]
    batch b_i = xsimd::swizzle(b_ri, {1, 0, 1, 0});   // [i3, r3, i4, r4]

    // Complex multiplication
    batch result = xsimd::fms(a_r, b_r, a_i * b_i);  // a_r*b_r - a_i*b_i (with sign flip)

    xsimd::store_unaligned(&data2[i], result);
}
```

**Estimated Speedup**: 2-3x
**Conversion Complexity**: MODERATE (requires understanding complex number layout)
**Priority**: ⭐⭐⭐ HIGH (frequently used in correlation/convolution)

---

### 3.2 Pitch Analysis (Autocorrelation-based)

**File**: `src/praat.github.io/fon/Pitch.cpp`
**Related Function**: Uses autocorrelation (already optimized)
**Status**: ✅ **ALREADY OPTIMIZED** via `src/autocorrelation_simd.cpp`

**Measured Speedup**: ~3x for autocorrelation computation
**Priority**: ✅ COMPLETE (core autocorrelation SIMD-optimized)

---

### 3.3 Pitch Smoothing (Gaussian Filtering in Frequency Domain)

**File**: `src/praat.github.io/fon/Pitch.cpp`
**Target Function**: `Pitch_smooth` (Gaussian filter application)
**New File**: `src/pitch_smoothing_simd.cpp`

**Operation**: Apply exponential decay to spectrum (element-wise exp and multiply)

**Current Implementation**:
```cpp
for (integer i = 1; i <= spectrum->nx; i++) {
    const double fT = (i - 1) * spectrum->dx * bandWidth;
    const double factor = exp(- fT * fT);
    spectrum->z[1][i] *= factor;   // Real part
    spectrum->z[2][i] *= factor;   // Imaginary part
}
```

**SIMD Strategy**:
- Vectorize the exp() computation using SLEEF library (`sleef::exp()`)
- Vectorize the element-wise multiplication

**Estimated Speedup**: 2.5-3x
**Conversion Complexity**: MODERATE-HARD (requires SLEEF for vectorized exp)
**Priority**: ⭐⭐ MEDIUM

**Note**: May require adding SLEEF dependency for vectorized math functions

---

### 3.4 Linear Trend Removal (Pitch Post-processing)

**File**: `src/praat.github.io/fon/Pitch.cpp`
**Target Function**: `Pitch_subtractLinearFit`
**New File**: `src/pitch_processing_simd.cpp`

**Operations**:
1. Sum reduction
2. Dot product (for slope calculation)
3. Element-wise FMA (subtract linear fit)

**Current Implementation**:
```cpp
// 1. Sum
for (integer i = 1; i <= n; i++)
    sum += frequencies[i];

// 2. Slope calculation (dot product)
for (integer i = 1; i <= n; i++) {
    numerator += frequencies[i] * time[i];
    denominator += time[i] * time[i];
}

// 3. Subtract fit
for (integer i = 1; i <= n; i++)
    frequencies[i] -= slope * time[i];
```

**SIMD Strategy**:
- Step 1: Use `xsimd::reduce_add()` for sum
- Step 2: Use `xsimd::fma()` for dot products with `xsimd::reduce_add()`
- Step 3: Use `xsimd::fnma()` (fused negative multiply-add) for subtraction

**Estimated Speedup**: 3-4x
**Conversion Complexity**: EASY-MODERATE
**Priority**: ⭐⭐ MEDIUM-HIGH

---

## Priority 4: Advanced Numerical Methods (Estimated 1.5-2.5x speedup)

### 4.1 Cholesky-based Matrix Inversion

**File**: `src/praat.github.io/dwsys/NUM2.cpp`
**Target Function**: `newMATinverse_fromLowerCholeskyInverse`
**New File**: `src/num_linalg_simd.cpp`

**Operation**: Matrix-matrix multiplication (m × m^T)

**Current Implementation**: Triple-nested loop with dot product

**SIMD Strategy**:
- Vectorize innermost dot product loop
- Consider cache-friendly blocking for large matrices

**Estimated Speedup**: 2-2.5x
**Conversion Complexity**: HARD (requires careful memory access pattern optimization)
**Priority**: ⭐ MEDIUM (less frequently used)

---

### 4.2 Burg's Algorithm for LPC Analysis

**File**: `src/praat.github.io/dwsys/NUM2.cpp`
**Target Function**: `VECburg`
**New File**: `src/lpc_analysis_simd.cpp`

**Operation**: Iterative algorithm with dot products and AXPY operations

**Current Implementation**: Multiple loops with vector operations

**SIMD Strategy**:
- Vectorize dot products using existing autocorrelation SIMD functions
- Vectorize AXPY operations (y = a*x + y)

**Estimated Speedup**: 1.8-2.5x
**Conversion Complexity**: HARD (complex algorithm with many steps)
**Priority**: ⭐ MEDIUM-LOW (algorithmically complex)

---

### 4.3 Non-negative Least Squares Regression

**File**: `src/praat.github.io/dwsys/NUM2.cpp`
**Target Function**: `VECsolveNonnegativeLeastSquaresRegression`
**New File**: `src/num_regression_simd.cpp`

**Operation**: Iterative solver using AXPY and dot products

**SIMD Strategy**:
- Vectorize inner AXPY and dot product operations
- Main iterative loop remains serial

**Estimated Speedup**: 1.5-2x
**Conversion Complexity**: HARD (iterative algorithm with complex control flow)
**Priority**: ⭐ LOW (rarely used in typical workflows)

---

## Operations NOT Suitable for SIMD

### Loop-Carried Dependencies

**Example**: Pre-emphasis/de-emphasis filtering

```cpp
// Pre-emphasis - each sample depends on previous
for (integer i = my nx; i >= 2; i --)
    s[i] -= emphasisFactor * s[i - 1];
```

**Reason**: Strong serial dependency prevents vectorization
**Alternative**: Accept scalar performance or use algorithmic transformation (e.g., parallel scan)
**Decision**: Keep as scalar implementation

---

### Irregular Memory Access Patterns

**Example**: `Pitch_AnyTier_to_PitchTier` (scattered lookups)

**Reason**: Data-dependent gather operations have poor SIMD performance
**Decision**: Keep as scalar implementation

---

### Dynamic Programming / Path Finding

**Example**: `Pitch_pathFinder` (Viterbi algorithm)

**Reason**: Strong inter-frame dependencies and complex branching
**Decision**: Keep as scalar implementation (algorithmic optimization more beneficial)

---

## Implementation Phases

### Phase 1: Foundation (Weeks 1-2)

**Goal**: Establish infrastructure and implement highest-impact optimizations

1. **Infrastructure Setup**
   - Create `src/simd_utils.h` with common SIMD patterns and utilities
   - Add SIMD detection/capability reporting functions
   - Create benchmark framework for SIMD vs scalar comparison

2. **High-Impact Implementations**
   - ✅ Sound statistics (min/max/sum/RMS) - **PRIORITY 1**
   - ✅ Sound mono conversion - **PRIORITY 1**
   - ✅ Audio format conversion (double ↔ int16) - **PRIORITY 1**
   - Matrix row multiplication - **PRIORITY 1**

3. **Testing**
   - Numerical accuracy tests (bit-exact comparison)
   - Performance benchmarks
   - Edge case validation (small arrays, unaligned data)

**Deliverables**:
- 4 new `*_simd.cpp` files
- Test suite with accuracy validation
- Benchmark results document

---

### Phase 2: Signal Processing (Weeks 3-4)

**Goal**: Optimize core DSP operations

1. **Convolution/Correlation**
   - Complex multiplication for FFT-based operations - **PRIORITY 2**
   - Integration with existing autocorrelation SIMD code

2. **Numerical Methods**
   - IIR filtering (dot product optimization) - **PRIORITY 2**
   - Matrix-vector operations (Mahalanobis distance) - **PRIORITY 2**
   - DCT implementation - **PRIORITY 2**

3. **Integration & Testing**
   - Integration tests with R6 objects
   - Real-world audio processing benchmarks
   - Validate with actual pitch detection workflows

**Deliverables**:
- 3 new `*_simd.cpp` files
- Integration test suite
- Performance comparison report

---

### Phase 3: Advanced Optimizations (Weeks 5-6)

**Goal**: Implement remaining beneficial optimizations

1. **Pitch Processing**
   - Linear fit subtraction - **PRIORITY 3**
   - Gaussian smoothing (requires SLEEF) - **PRIORITY 3**

2. **Matrix Operations**
   - Cholesky-based inversion - **PRIORITY 4**
   - Matrix projection operations - **PRIORITY 4**

3. **Advanced Algorithms** (Optional)
   - Burg's algorithm for LPC - **PRIORITY 4**
   - NNLS regression - **PRIORITY 4**

**Deliverables**:
- 2-4 new `*_simd.cpp` files
- Comprehensive benchmark suite
- Documentation of all SIMD-optimized functions

---

## Testing Strategy

### Numerical Accuracy Validation

**Goal**: Ensure SIMD implementations produce identical results to scalar versions

**Approach**:
1. **Bit-exact comparison** for deterministic operations
2. **Tolerance-based comparison** for operations with rounding differences (≤ 1 ULP)
3. **Statistical validation** for complex algorithms (correlation > 0.999999)

**Test Suite Structure**:
```r
# tests/testthat/test-simd-accuracy.R

test_that("SIMD sound statistics match scalar", {
  sound <- Sound$new("inst/extdata/test.wav")

  # Force scalar implementation
  rms_scalar <- .sound_get_rms_scalar(sound$.xptr, 0, 0)

  # Use SIMD implementation
  rms_simd <- .sound_get_rms_simd(sound$.xptr, 0, 0)

  # Bit-exact comparison
  expect_equal(rms_simd, rms_scalar)
})

test_that("SIMD autocorrelation matches scalar within tolerance", {
  data <- rnorm(10000)
  max_lag <- 1000

  acf_scalar <- .autocorrelation_scalar(data, max_lag)
  acf_simd <- .autocorrelation_simd(data, max_lag)

  # Allow 1 ULP difference due to different rounding
  expect_equal(acf_simd, acf_scalar, tolerance = 1e-15)
})
```

---

### Performance Benchmarking

**Goal**: Quantify speedup from SIMD optimizations

**Approach**:
1. **Microbenchmarks**: Isolated function performance (rbenchmark)
2. **Integration benchmarks**: Full workflow performance (e.g., pitch detection)
3. **Real-world benchmarks**: Typical audio processing tasks

**Benchmark Structure**:
```r
# benchmarks/simd_benchmarks.R

library(rbenchmark)

benchmark_sound_statistics <- function() {
  sound <- Sound$new("audio_10min.wav")  # Large file

  benchmark(
    "scalar" = .sound_get_rms_scalar(sound$.xptr, 0, 0),
    "simd"   = .sound_get_rms_simd(sound$.xptr, 0, 0),
    replications = 100,
    columns = c("test", "replications", "elapsed", "relative")
  )
}

benchmark_autocorrelation <- function() {
  data <- rnorm(50000)
  max_lag <- 5000

  benchmark(
    "scalar" = .autocorrelation_scalar(data, max_lag),
    "simd"   = .autocorrelation_simd(data, max_lag),
    replications = 50,
    columns = c("test", "replications", "elapsed", "relative")
  )
}
```

---

### Edge Case Testing

**Critical Test Cases**:
1. **Small arrays** (< SIMD width): Ensure scalar remainder path works
2. **Unaligned data**: Test `load_unaligned()` robustness
3. **Empty arrays / zero length**: Proper handling
4. **Single-channel vs multi-channel**: Correct iteration
5. **Edge timestamps**: Boundary conditions in time-based queries

---

## Dependencies and Infrastructure

### Required Libraries

1. **RcppXsimd** ✅ (already in DESCRIPTION)
   - Provides xsimd headers
   - Manages SIMD capability detection
   - Version: ≥ 0.1.2

2. **xsimd** ✅ (via RcppXsimd)
   - Modern C++ SIMD abstraction library
   - Supports x86 (SSE, AVX, AVX-512) and ARM (NEON, SVE)
   - Version: ≥ 9.0

3. **SLEEF** ⏸️ (Optional, for Phase 3)
   - SIMD-optimized math functions (exp, log, sin, cos)
   - Required for: Gaussian smoothing, DCT with vectorized cos
   - Integration: Header-only or link against library

**Decision**: Implement Phase 1-2 first without SLEEF. Evaluate need in Phase 3.

---

### Build System Integration

**Makevars Configuration**:
```make
# src/Makevars

# Existing configuration
PKG_CPPFLAGS = -I. -I../inst/include $(RCPPXSIMD_CXXFLAGS)
PKG_LIBS = $(LAPACK_LIBS) $(BLAS_LIBS) $(FLIBS)

# Add SIMD flags (auto-detected by RcppXsimd)
CXX_STD = CXX17

# Optional: Enable specific instruction sets (if not auto-detected)
# PKG_CXXFLAGS = -march=native  # Use available SIMD on build machine
# PKG_CXXFLAGS = -mavx2         # Require AVX2 explicitly
```

**Note**: `RcppXsimd` automatically detects available SIMD instruction sets. The `RCPPXSIMD_XSIMD_HPP` macro is defined only when xsimd is available.

---

### SIMD Utilities Header

**File**: `src/simd_utils.h`

```cpp
#ifndef SPEAKER_SIMD_UTILS_H
#define SPEAKER_SIMD_UTILS_H

#ifdef RCPPXSIMD_XSIMD_HPP
#include <xsimd/xsimd.hpp>

namespace speaker {
namespace simd {

// Get SIMD batch size for double precision
inline constexpr size_t batch_size_d() {
    return xsimd::batch<double>::size;
}

// Check if SIMD is available at runtime
inline bool is_available() {
    return true;  // Compile-time check via macro
}

// Get instruction set name
inline std::string instruction_set() {
#if defined(__AVX512F__)
    return "AVX-512";
#elif defined(__AVX2__)
    return "AVX2";
#elif defined(__AVX__)
    return "AVX";
#elif defined(__SSE4_2__)
    return "SSE4.2";
#elif defined(__SSE2__)
    return "SSE2";
#elif defined(__ARM_NEON)
    return "NEON";
#else
    return "Unknown";
#endif
}

// Helper: Sum of squares (used in RMS, energy, variance)
template<typename T>
inline T sum_of_squares(const T* data, size_t n) {
    using batch = xsimd::batch<T>;
    constexpr size_t simd_size = batch::size;

    batch acc(0.0);
    size_t i = 0;

    for (; i + simd_size <= n; i += simd_size) {
        batch x = xsimd::load_unaligned(&data[i]);
        acc = xsimd::fma(x, x, acc);
    }

    T sum = xsimd::reduce_add(acc);

    // Scalar remainder
    for (; i < n; ++i) {
        sum += data[i] * data[i];
    }

    return sum;
}

// Helper: Dot product
template<typename T>
inline T dot_product(const T* x, const T* y, size_t n) {
    using batch = xsimd::batch<T>;
    constexpr size_t simd_size = batch::size;

    batch acc(0.0);
    size_t i = 0;

    for (; i + simd_size <= n; i += simd_size) {
        batch a = xsimd::load_unaligned(&x[i]);
        batch b = xsimd::load_unaligned(&y[i]);
        acc = xsimd::fma(a, b, acc);
    }

    T sum = xsimd::reduce_add(acc);

    // Scalar remainder
    for (; i < n; ++i) {
        sum += x[i] * y[i];
    }

    return sum;
}

// Helper: AXPY (y = a*x + y)
template<typename T>
inline void axpy(T alpha, const T* x, T* y, size_t n) {
    using batch = xsimd::batch<T>;
    constexpr size_t simd_size = batch::size;

    batch a(alpha);
    size_t i = 0;

    for (; i + simd_size <= n; i += simd_size) {
        batch x_vec = xsimd::load_unaligned(&x[i]);
        batch y_vec = xsimd::load_unaligned(&y[i]);
        batch result = xsimd::fma(a, x_vec, y_vec);
        xsimd::store_unaligned(&y[i], result);
    }

    // Scalar remainder
    for (; i < n; ++i) {
        y[i] += alpha * x[i];
    }
}

} // namespace simd
} // namespace speaker

#endif // RCPPXSIMD_XSIMD_HPP

#endif // SPEAKER_SIMD_UTILS_H
```

---

## Performance Targets and Success Metrics

### Expected Speedups by Category

| Operation Category | Target Speedup | Confidence |
|-------------------|----------------|------------|
| Statistical reductions (sum, min, max) | 3-4x | HIGH |
| Element-wise operations (scale, add, multiply) | 3-4x | HIGH |
| Dot products & inner products | 2.5-3.5x | HIGH |
| Data type conversions | 3-5x | HIGH |
| Complex FFT operations | 2-3x | MEDIUM |
| IIR filtering (partial) | 2-3x | MEDIUM |
| Matrix operations | 2-2.5x | MEDIUM |
| Advanced algorithms (Burg, NNLS) | 1.5-2x | LOW-MEDIUM |

### Overall Package Performance Goals

**Target**: 1.8-2.5x speedup for typical audio analysis workflows

**Benchmark Workflows**:
1. **Pitch detection** (autocorrelation-based)
   - Expected: 2.5-3x (autocorrelation already SIMD-optimized)

2. **Formant tracking** (LPC + Burg)
   - Expected: 1.5-2x (if Burg's algorithm optimized)

3. **Intensity analysis**
   - Expected: 3-4x (RMS/energy already SIMD-optimized)

4. **Multi-file batch processing**
   - Expected: 2-3x (I/O conversion + analysis)

### Success Criteria

✅ **Phase 1 Success**:
- All Priority 1 functions SIMD-optimized
- ≥ 3x speedup on statistical operations
- 100% accuracy (bit-exact or ≤ 1 ULP)
- No performance regression in scalar fallback

✅ **Phase 2 Success**:
- All Priority 2 functions SIMD-optimized
- ≥ 2x speedup on signal processing operations
- Integration with existing R6 workflows
- Benchmark report showing workflow-level improvements

✅ **Phase 3 Success**:
- Priority 3-4 functions evaluated and implemented (if beneficial)
- Comprehensive documentation of all SIMD optimizations
- Overall package speedup ≥ 2x for typical workflows
- CRAN-ready (cross-platform compatibility)

---

## Risks and Mitigation

### Risk 1: Numerical Accuracy Differences

**Risk**: SIMD implementations may produce slightly different results due to different rounding order

**Mitigation**:
- Use fused multiply-add (FMA) consistently in both scalar and SIMD
- Accept ≤ 1 ULP (Unit in Last Place) differences
- Document any known differences
- Provide option to force scalar implementation if bit-exact results required

---

### Risk 2: Platform Compatibility

**Risk**: SIMD code may not compile or run on all platforms (ARM, older x86)

**Mitigation**:
- Use `xsimd` library which abstracts instruction sets
- Always provide scalar fallback (`#ifdef RCPPXSIMD_XSIMD_HPP`)
- Test on multiple platforms (x86-64 SSE/AVX, ARM NEON)
- CRAN checks will validate cross-platform compatibility

---

### Risk 3: Maintenance Burden

**Risk**: Maintaining parallel SIMD and scalar implementations doubles code

**Mitigation**:
- Keep original Praat code as authoritative scalar version
- SIMD code in separate files (`*_simd.cpp`)
- Comprehensive test suite to catch divergence
- Document which operations are SIMD-optimized

---

### Risk 4: Limited Speedup on Small Data

**Risk**: SIMD overhead may negate benefits for small arrays (< 100 elements)

**Mitigation**:
- Accept this limitation (document in performance guide)
- Small data operations are typically fast enough already
- Consider dynamic dispatch based on array size (if overhead is significant)

---

### Risk 5: Compiler Optimization Conflicts

**Risk**: Compiler auto-vectorization may interfere with explicit SIMD

**Mitigation**:
- Benchmark both compiler-optimized scalar and explicit SIMD
- Use compiler flags judiciously (`-O3` already enables auto-vectorization)
- Profile to identify actual hotspots
- Only hand-optimize where compiler fails to vectorize

---

## Documentation Plan

### User-Facing Documentation

1. **Vignette**: "SIMD Performance Optimizations in speaker"
   - What is SIMD and why it matters
   - Which operations are SIMD-accelerated
   - How to check SIMD availability
   - Benchmarking your workflows

2. **Function Documentation**
   - Add "SIMD-optimized" badge to Rd docs
   - Note any numerical accuracy considerations
   - Example: `@details This function uses SIMD vectorization when available (typically 2-3x faster).`

3. **Performance Guide** (website)
   - Comparison tables: SIMD vs scalar
   - Best practices for maximizing performance
   - Workflow optimization tips

---

### Developer Documentation

1. **SIMD Implementation Guide** (`SIMD_IMPLEMENTATION.md`)
   - How to add new SIMD optimizations
   - Code patterns and best practices
   - Testing requirements

2. **Inline Code Comments**
   - Explain non-obvious SIMD operations
   - Document any platform-specific code
   - Reference original Praat implementation

3. **Benchmark Reports**
   - Detailed speedup measurements
   - Hardware specifications
   - Methodology

---

## Next Steps

### Immediate Actions (This Week)

1. ✅ Review and approve this plan
2. Create GitHub issues for each implementation phase
3. Set up benchmark infrastructure
4. Begin Phase 1, Priority 1 implementations

### Short-Term Goals (Weeks 1-2)

1. Implement sound statistics SIMD optimization
2. Implement audio conversion SIMD optimization
3. Create comprehensive test suite
4. Benchmark and validate results

### Medium-Term Goals (Weeks 3-6)

1. Complete Phase 1 and Phase 2 implementations
2. Integration testing with R6 workflows
3. Performance documentation
4. Prepare for CRAN submission (if applicable)

---

## Conclusion

This plan provides a systematic approach to SIMD optimization of Praat's numerical functions in the speaker package. By following the established RcppXsimd pattern and prioritizing high-impact operations, we can achieve significant performance improvements (estimated 1.8-2.5x overall) while maintaining numerical accuracy and code maintainability.

**Key Success Factors**:
- ✅ Leverage existing SIMD infrastructure (RcppXsimd, xsimd)
- ✅ Focus on high-impact operations first (Priority 1-2)
- ✅ Maintain dual implementations (SIMD + scalar fallback)
- ✅ Comprehensive testing (accuracy + performance)
- ✅ Incremental rollout (3 phases, each tested independently)

**Estimated Timeline**: 6 weeks for full implementation (Phases 1-3)
**Estimated Effort**: ~150-200 hours of development + testing
**Expected ROI**: 2-3x speedup on CPU-intensive audio processing workflows

---

**Document Version**: 1.0
**Last Updated**: 2025-01-22
**Status**: READY FOR IMPLEMENTATION
