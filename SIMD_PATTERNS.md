# SIMD Implementation Patterns - Developer Guide

## Overview

This guide documents the SIMD optimization patterns used in the speaker package using RcppXsimd. Follow these patterns when adding new SIMD-optimized operations.

---

## Table of Contents

1. [Setup and Detection](#setup-and-detection)
2. [Basic Patterns](#basic-patterns)
3. [Common Operations](#common-operations)
4. [Best Practices](#best-practices)
5. [Testing](#testing)
6. [Debugging](#debugging)

---

## Setup and Detection

### File Structure

```
src/
├── simd_utils.h                    # Inline utility functions
├── simd/
│   ├── intensity_simd.cpp          # Exported SIMD operations
│   ├── sound_mixing_simd.cpp
│   ├── autocorrelation_simd.cpp
│   └── window_functions_simd.cpp
└── [name]_wrappers.cpp             # Integration with Praat objects
```

### Header Template

```cpp
// [[Rcpp::plugins(cpp17)]]

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

#include <Rcpp.h>
#include "../praat_types.h"
#include "../praat_xptr_utils.h"

// Praat headers
#include "praat.github.io/fon/Sound.h"

using namespace Rcpp;
```

### SIMD Detection

```cpp
#ifdef HAVE_XSIMD
  // SIMD implementation
#else
  // Scalar fallback
#endif
```

---

## Basic Patterns

### Pattern 1: Horizontal Reduction (Sum)

**Problem**: Sum all elements in an array

**SIMD Solution**:
```cpp
inline double sum_array(const double* data, size_t n) {
    double sum = 0.0;
    size_t i = 0;
    
#ifdef __ARM_NEON
    float64x2_t sum_vec = vdupq_n_f64(0.0);
    
    // Process 2 doubles at a time
    for (; i + 2 <= n; i += 2) {
        float64x2_t v = vld1q_f64(&data[i]);
        sum_vec = vaddq_f64(sum_vec, v);
    }
    
    // Reduce: sum both lanes
    sum = vgetq_lane_f64(sum_vec, 0) + vgetq_lane_f64(sum_vec, 1);
    
#elif defined(__SSE2__)
    __m128d sum_vec = _mm_setzero_pd();
    
    for (; i + 2 <= n; i += 2) {
        __m128d v = _mm_loadu_pd(&data[i]);
        sum_vec = _mm_add_pd(sum_vec, v);
    }
    
    double sum_arr[2];
    _mm_storeu_pd(sum_arr, sum_vec);
    sum = sum_arr[0] + sum_arr[1];
#endif
    
    // Scalar remainder
    for (; i < n; i++) {
        sum += data[i];
    }
    
    return sum;
}
```

**Key Points**:
- Initialize accumulator to zero
- Process vector-width elements per iteration
- Reduce SIMD register to scalar
- Handle remainder with scalar loop

### Pattern 2: Fused Multiply-Add (FMA)

**Problem**: Compute sum of squares (for RMS, energy)

**SIMD Solution**:
```cpp
inline double sum_of_squares(const double* data, size_t n) {
    double sum = 0.0;
    size_t i = 0;
    
#ifdef __ARM_NEON
    float64x2_t sum_vec = vdupq_n_f64(0.0);
    
    for (; i + 2 <= n; i += 2) {
        float64x2_t v = vld1q_f64(&data[i]);
        sum_vec = vfmaq_f64(sum_vec, v, v);  // sum += v * v (FMA!)
    }
    
    sum = vgetq_lane_f64(sum_vec, 0) + vgetq_lane_f64(sum_vec, 1);
#endif
    
    // Remainder
    for (; i < n; i++) {
        sum += data[i] * data[i];
    }
    
    return sum;
}
```

**Key Points**:
- FMA is single instruction on ARM/AVX2
- Faster and more accurate than separate multiply + add
- Use for: RMS, energy, variance, correlation

### Pattern 3: Element-wise Operations

**Problem**: Apply function to each element

**SIMD Solution**:
```cpp
inline void multiply_scalar(double* data, size_t n, double scalar) {
    size_t i = 0;
    
#ifdef __ARM_NEON
    float64x2_t scalar_vec = vdupq_n_f64(scalar);
    
    for (; i + 2 <= n; i += 2) {
        float64x2_t v = vld1q_f64(&data[i]);
        v = vmulq_f64(v, scalar_vec);
        vst1q_f64(&data[i], v);
    }
#endif
    
    // Remainder
    for (; i < n; i++) {
        data[i] *= scalar;
    }
}
```

**Key Points**:
- Broadcast scalar to SIMD register
- Store results back to memory
- In-place modification possible

### Pattern 4: Comparison Operations

**Problem**: Find minimum/maximum

**SIMD Solution**:
```cpp
inline double min_array(const double* data, size_t n) {
    if (n == 0) return NAN;
    
    double min_val = INFINITY;
    size_t i = 0;
    
#ifdef __ARM_NEON
    float64x2_t min_vec = vdupq_n_f64(INFINITY);
    
    for (; i + 2 <= n; i += 2) {
        float64x2_t v = vld1q_f64(&data[i]);
        min_vec = vminq_f64(min_vec, v);  // Element-wise min
    }
    
    min_val = std::min(vgetq_lane_f64(min_vec, 0), 
                       vgetq_lane_f64(min_vec, 1));
#endif
    
    // Remainder
    for (; i < n; i++) {
        if (data[i] < min_val) min_val = data[i];
    }
    
    return min_val;
}
```

---

## Common Operations

### RMS Calculation

```cpp
double sound_get_rms_simd(XPtr<structSound> xptr, double from, double to) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    // Convert times to sample indices
    integer i_start = Sampled_xToNearestIndex(sound, from);
    integer i_end = Sampled_xToNearestIndex(sound, to);
    
    using batch = xsimd::batch<double, 2>;
    constexpr size_t simd_size = batch::size;
    
    double sum_squares = 0.0;
    integer total_samples = 0;
    
    // Process each channel
    for (integer ch = 1; ch <= sound->ny; ch++) {
        const double* data = &sound->z[ch][i_start];
        integer n_samples = i_end - i_start + 1;
        
        // SIMD sum of squares
        batch acc(0.0);
        integer i = 0;
        
        for (; i + simd_size <= n_samples; i += simd_size) {
            batch x = xsimd::load_unaligned(&data[i]);
            acc = xsimd::fma(x, x, acc);  // acc += x * x
        }
        
        // Reduction
        for (size_t j = 0; j < simd_size; ++j) {
            sum_squares += acc[j];
        }
        
        // Scalar remainder
        for (; i < n_samples; ++i) {
            sum_squares += data[i] * data[i];
        }
        
        total_samples += n_samples;
    }
    
    return std::sqrt(sum_squares / total_samples);
}
```

### Window Functions

```cpp
NumericVector apply_hamming_window_simd(NumericVector data) {
    const int n = data.size();
    NumericVector result(n);
    
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    const double* src = REAL(data);
    double* dst = REAL(result);
    
    const double two_pi = 2.0 * M_PI;
    const double n_minus_1 = static_cast<double>(n - 1);
    const batch alpha(0.54);
    const batch beta(0.46);
    const batch two_pi_batch(two_pi);
    const batch n_minus_1_batch(n_minus_1);
    
    int i = 0;
    for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
        // Create index vector [i, i+1, i+2, ...]
        alignas(batch::arch_type::alignment()) double indices[simd_size];
        for (size_t k = 0; k < simd_size; ++k) {
            indices[k] = static_cast<double>(i + k);
        }
        batch idx = xsimd::load_aligned(indices);
        
        // Compute window: 0.54 - 0.46 * cos(2π * i / (N-1))
        batch angle = two_pi_batch * idx / n_minus_1_batch;
        batch window = alpha - beta * xsimd::cos(angle);
        
        // Apply window
        batch data_batch = xsimd::load_unaligned(&src[i]);
        batch windowed = data_batch * window;
        xsimd::store_unaligned(&dst[i], windowed);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        double window = 0.54 - 0.46 * std::cos(two_pi * i / n_minus_1);
        dst[i] = src[i] * window;
    }
    
    return result;
}
```

---

## Best Practices

### 1. Memory Alignment

```cpp
// Use unaligned loads/stores for flexibility
xsimd::load_unaligned(&data[i]);    // OK for any address
xsimd::store_unaligned(&result[i]); // OK for any address

// Use aligned loads/stores when guaranteed aligned
alignas(32) double aligned_data[1024];
xsimd::load_aligned(aligned_data);   // Faster, but requires alignment
```

### 2. Cache-Friendly Processing

```cpp
// Process in chunks that fit in L2 cache
const size_t CHUNK_SIZE = 32768;  // 256KB / 8 bytes per double

for (size_t chunk_start = 0; chunk_start < n; chunk_start += CHUNK_SIZE) {
    size_t chunk_end = std::min(chunk_start + CHUNK_SIZE, n);
    process_chunk(&data[chunk_start], chunk_end - chunk_start);
}
```

### 3. Loop Unrolling

```cpp
// Process 4 SIMD vectors at once for better pipeline utilization
for (; i + 4*simd_size <= n; i += 4*simd_size) {
    batch v0 = xsimd::load_unaligned(&data[i + 0*simd_size]);
    batch v1 = xsimd::load_unaligned(&data[i + 1*simd_size]);
    batch v2 = xsimd::load_unaligned(&data[i + 2*simd_size]);
    batch v3 = xsimd::load_unaligned(&data[i + 3*simd_size]);
    
    acc0 = xsimd::fma(v0, v0, acc0);
    acc1 = xsimd::fma(v1, v1, acc1);
    acc2 = xsimd::fma(v2, v2, acc2);
    acc3 = xsimd::fma(v3, v3, acc3);
}
```

### 4. Avoid Conditional Branches

```cpp
// BAD: Branches inside SIMD loop
for (; i + simd_size <= n; i += simd_size) {
    batch v = xsimd::load_unaligned(&data[i]);
    if (condition) {  // ❌ Branch prediction miss!
        v = v * 2.0;
    }
    xsimd::store_unaligned(&result[i], v);
}

// GOOD: Use SIMD select
batch mask = condition_vector();
batch v_modified = v * 2.0;
batch v_result = xsimd::select(mask, v_modified, v);
```

---

## Testing

### Numerical Accuracy Tests

```r
test_that("SIMD operation matches scalar", {
  library(speaker)
  
  # Generate test data
  mat <- matrix(runif(1000 * 1000), 1000, 1000)
  mat_obj <- praat_matrix_from_matrix(mat)
  
  # SIMD result
  simd_sum <- mat_obj$get_sum()
  
  # Scalar result
  scalar_sum <- sum(mat)
  
  # Compare (tight tolerance)
  expect_equal(simd_sum, scalar_sum, tolerance = 1e-10)
})
```

### Performance Tests

```r
test_that("SIMD is faster than scalar", {
  library(bench)
  
  mat <- matrix(rnorm(1000 * 1000), 1000, 1000)
  mat_obj <- praat_matrix_from_matrix(mat)
  
  # Benchmark
  result <- bench::mark(
    simd = mat_obj$get_sum(),
    scalar = sum(mat),
    iterations = 100
  )
  
  # SIMD should be faster
  speedup <- median(result$time[result$expression == "scalar"]) / 
             median(result$time[result$expression == "simd"])
  
  expect_gt(speedup, 1.5)  # At least 1.5x faster
})
```

---

## Debugging

### Check SIMD is Active

```cpp
#ifdef HAVE_XSIMD
  Rcpp::Rcout << "SIMD: ACTIVE\n";
#else
  Rcpp::Rcout << "SIMD: DISABLED\n";
#endif
```

### Verify Results

```cpp
// Save SIMD and scalar results
double simd_result = simd_operation(data, n);
double scalar_result = scalar_operation(data, n);

// Compare
if (std::abs(simd_result - scalar_result) > 1e-10) {
    Rcpp::Rcerr << "SIMD mismatch: " << simd_result 
                << " vs " << scalar_result << "\n";
}
```

### Print SIMD Register Contents

```cpp
#ifdef __ARM_NEON
float64x2_t vec = vld1q_f64(data);
double values[2];
vst1q_f64(values, vec);
Rcpp::Rcout << "SIMD register: [" << values[0] << ", " << values[1] << "]\n";
#endif
```

---

## Performance Checklist

Before committing SIMD code:

- [ ] Numerical accuracy tests pass (tolerance < 1e-10)
- [ ] Scalar fallback works correctly
- [ ] Remainder loop handles odd sizes
- [ ] Performance improvement ≥ 1.5x
- [ ] No memory leaks (valgrind clean)
- [ ] Works on ARM NEON and SSE2
- [ ] Documentation updated
- [ ] Benchmark results recorded

---

## References

- **xsimd documentation**: https://xsimd.readthedocs.io
- **ARM NEON intrinsics**: https://developer.arm.com/architectures/instruction-sets/intrinsics/
- **Intel intrinsics guide**: https://www.intel.com/content/www/us/en/docs/intrinsics-guide/

---

**Version**: 1.0  
**Last Updated**: 2025-11-18  
**Package**: speaker 0.5.0
