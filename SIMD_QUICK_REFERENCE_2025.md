# SIMD Implementation Quick Reference

**For Developers**: Quick guide to SIMD optimizations in the speaker package

---

## What is SIMD?

**SIMD** = Single Instruction, Multiple Data
- Process multiple data points with one instruction
- Modern CPUs have 128-bit to 512-bit SIMD registers
- ARM64: 2 doubles per register (NEON)
- x86-64: 2-8 doubles per register (SSE to AVX-512)

**Result**: 2-8x speedup for array operations

---

## Quick Start

### Check if SIMD is Available

```r
# In R
library(speaker)

# SIMD automatically used if available
# No user action required
```

### Disable SIMD (for testing)

```r
options(speaker.use_simd = FALSE)
```

---

## Optimized Operations

### Sound Statistics
```r
sound <- Sound$new("audio.wav")

# These use SIMD when available:
sound$get_minimum(0, 0)      # 3-4x faster
sound$get_maximum(0, 0)      # 3-4x faster
sound$get_mean(0, 0)         # 3-4x faster
sound$get_rms(0, 0)          # 3-4x faster
```

### Mono Conversion
```r
stereo <- Sound$new("stereo.wav")

# SIMD-optimized conversion:
mono <- stereo$convert_to_mono()  # 3-4x faster
```

### Matrix Operations
```r
# Dot product (SIMD-optimized)
result <- .dot_product_simd(x, y)  # 2.5-3.5x faster

# AXPY: y = alpha * x + y
.axpy_simd(alpha, x, y)            # 3-4x faster
```

---

## For Developers: Adding SIMD Operations

### Basic Pattern

```cpp
#ifdef RCPPXSIMD_XSIMD_HPP
#include <xsimd/xsimd.hpp>

double my_function_simd(const double* data, size_t n) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    batch acc(0.0);
    size_t i = 0;
    
    // SIMD loop (processes simd_size elements per iteration)
    for (; i + simd_size <= n; i += simd_size) {
        batch values = xsimd::load_unaligned(&data[i]);
        acc += values;  // or other operation
    }
    
    double sum = xsimd::reduce_add(acc);
    
    // Scalar remainder
    for (; i < n; ++i) {
        sum += data[i];
    }
    
    return sum;
}
#endif

// Scalar fallback
double my_function_scalar(const double* data, size_t n) {
    double sum = 0.0;
    for (size_t i = 0; i < n; ++i) {
        sum += data[i];
    }
    return sum;
}

// Dispatcher
double my_function(const double* data, size_t n) {
#ifdef RCPPXSIMD_XSIMD_HPP
    return my_function_simd(data, n);
#else
    return my_function_scalar(data, n);
#endif
}
```

---

## Common SIMD Operations

### Load/Store
```cpp
batch data = xsimd::load_unaligned(&array[i]);
xsimd::store_unaligned(&array[i], data);
```

### Arithmetic
```cpp
batch result = a + b;           // Addition
batch result = a - b;           // Subtraction
batch result = a * b;           // Multiplication
batch result = a / b;           // Division
batch result = xsimd::fma(a, b, c);  // Fused multiply-add: a*b+c
batch result = xsimd::fnma(a, b, c); // Fused neg multiply-add: -a*b+c
```

### Comparisons
```cpp
batch result = xsimd::min(a, b);
batch result = xsimd::max(a, b);
```

### Reductions
```cpp
double sum = xsimd::reduce_add(batch_data);
double min = xsimd::reduce_min(batch_data);
double max = xsimd::reduce_max(batch_data);
```

### Broadcast
```cpp
batch all_same(3.14);  // All lanes = 3.14
```

---

## Testing Your SIMD Code

### Accuracy Test
```r
# tests/testthat/test-my-simd.R
test_that("SIMD function is accurate", {
  x <- rnorm(10000)
  
  # Compare with R
  expected <- sum(x^2)
  computed <- my_simd_function(x)
  
  expect_equal(computed, expected, tolerance = 1e-14)
})
```

### Benchmark
```r
# inst/benchmarks/my_benchmark.R
library(rbenchmark)

x <- rnorm(100000)

benchmark(
  "base_R" = sum(x^2),
  "simd" = my_simd_function(x),
  replications = 100
)
```

---

## Performance Tips

### DO:
✅ Use `xsimd::fma()` for multiply-add operations
✅ Process large arrays (> 1000 elements)
✅ Use `load_unaligned()` for arbitrary memory
✅ Test both SIMD and scalar versions
✅ Validate numerical accuracy

### DON'T:
❌ Use SIMD for small arrays (< 100 elements)
❌ Use SIMD with data-dependent branching
❌ Assume perfect speedup (expect 2-4x, not 8x)
❌ Forget the scalar remainder loop
❌ Ignore numerical accuracy validation

---

## Troubleshooting

### "RCPPXSIMD_XSIMD_HPP not defined"
- Check that RcppXsimd is in DESCRIPTION
- Verify PKG_CPPFLAGS includes $(RCPPXSIMD_CXXFLAGS)
- Ensure CXX_STD = CXX17 in Makevars

### "Different results from SIMD vs scalar"
- Floating-point operations may differ by ≤ 1 ULP
- This is normal due to different rounding order
- Use tolerance in tests: `expect_equal(a, b, tolerance = 1e-14)`

### "No speedup observed"
- Array too small (SIMD overhead dominates)
- Compiler auto-vectorization already active
- Memory bandwidth limited (not compute-bound)
- Profile to verify hotspot

---

## Resources

- **xsimd docs**: https://xsimd.readthedocs.io/
- **RcppXsimd**: https://github.com/Rcpp/RcppXsimd
- **SIMD_OPTIMIZATION_PLAN.md**: Full implementation plan
- **SIMD_PHASE1_IMPLEMENTATION_REPORT.md**: Detailed report

---

## Current Status (v0.9.8)

| Module | Status | Expected Speedup |
|--------|--------|------------------|
| Sound statistics | ✅ Implemented | 3-4x |
| Mono conversion | ✅ Implemented | 3-4x |
| Matrix operations | ✅ Implemented | 2.5-3.5x |
| Autocorrelation | ✅ Implemented (v0.9.6) | 3x |
| Window functions | ✅ Implemented (v0.9.5) | 2.5x |
| Intensity calculations | ✅ Implemented (v0.9.4) | 3x |

**Overall**: ~35% of planned optimizations complete

---

## Next Optimizations (Phase 2)

Planned for next release:
- FFT complex multiplication (2-3x)
- Pitch processing (2.5-3.5x)
- IIR filtering (2-3x)
- DCT transform (2-3x)

---

**Last Updated**: 2025-01-22
**Version**: 0.9.8
**Author**: speaker package maintainers
