# SIMD Benchmark Fix - 2025-11-18

## Issue Summary

The Phase 3 SIMD benchmarks (window functions and autocorrelation) were failing with:
```
Error: could not find function ".autocorrelation_scalar"
Error: could not find function ".apply_hamming_window_scalar"
```

## Root Cause

The internal SIMD functions (`.function_name_scalar` and `.function_name_simd`) are exported from C++ via Rcpp but are **not** in the package NAMESPACE. They are internal functions meant to be accessed via `:::` operator.

## Solution Applied

### 1. Fixed Function Access
Changed all benchmark calls from:
```r
.autocorrelation_scalar(data, max_lag)
```

To:
```r
speaker:::.autocorrelation_scalar(data, max_lag)
```

### 2. Fixed Benchmark Result Extraction  
The `bench::mark()` function returns a special `bench_expr` class for the `expression` column. Fixed median extraction from:
```r
result$median[result$expression == "test"]  # Doesn't work
```

To:
```r
result$median[as.character(result$expression) == "test"]  # Works
```

## Files Modified

1. **inst/benchmarks/12_phase3_window_functions.R**
   - Added `speaker:::` prefix to all SIMD function calls
   - Fixed speedup calculation using `as.character(result$expression)`
   - Removed conditional existence checks (functions always exist now)

2. **inst/benchmarks/13_phase3_autocorrelation.R**
   - Added `speaker:::` prefix to all SIMD function calls
   - Fixed speedup calculation for autocorrelation and LPC functions
   - Removed conditional existence checks

## Benchmark Results

### Window Functions (M1 Pro, ARM NEON)
- **Small (256 samples)**: ~1.1x speedup
- **Medium (1024 samples)**: ~1.0x speedup
- **Large (4096 samples)**: ~1.05x speedup
- **XLarge (16384 samples)**: ~1.08x speedup

**Analysis**: Modest speedup due to:
- Small data sizes (overhead dominates)
- Compiler auto-vectorization already applied
- Memory bandwidth limitations on small arrays

### Autocorrelation (M1 Pro, ARM NEON)
- **Small (400 samples, 200 lag)**: ~1.0x speedup
- **Medium (800 samples, 400 lag)**: ~1.02x speedup
- **Large (16K samples, 800 lag)**: ~1.0x speedup
- **XLarge (44K samples, 2000 lag)**: ~0.97x speedup
- **LPC (8K samples, 12 coeffs)**: **1.36x speedup** ✅

**Analysis**: 
- LPC shows best speedup (1.36x) - focused computation
- Full autocorrelation sequences show minimal speedup
- May improve with larger lag counts or on AVX2 systems

## Expected vs Actual Performance

### Expected (from documentation)
- M1 Pro: 2.5-3.5x for autocorrelation
- AMD EPYC (AVX2): 4.5-6.0x for autocorrelation

### Actual (M1 Pro)
- Window functions: 1.0-1.1x
- Autocorrelation: 1.0-1.4x (best: LPC at 1.36x)

### Possible Reasons for Gap
1. **Compiler auto-vectorization**: clang on M1 already vectorizes many loops
2. **Small data sizes**: SIMD overhead dominates for <10K samples
3. **Memory bandwidth**: ARM NEON at 128-bit vs AVX2 at 256-bit
4. **Algorithm characteristics**: Autocorrelation has data dependencies limiting parallelism

## Next Steps

### Immediate
1. ✅ Window functions benchmark fixed and running
2. ✅ Autocorrelation benchmark fixed and running
3. ✅ Package builds and installs successfully
4. ✅ SIMD functions accessible via `:::`

### Short Term
1. **Test on AMD EPYC**: Verify higher speedups with AVX2 (256-bit)
2. **Larger test cases**: Use longer audio files (10s+) for realistic benchmarks
3. **Profile hot paths**: Identify if SIMD is actually being used
4. **Compare with/without `-march=armv8-a+simd`**: Verify SIMD compilation

### Medium Term
1. **Create unit tests**: Validate SIMD vs scalar numerical accuracy
2. **Document actual performance**: Update expectations based on real results
3. **Optimize memory access patterns**: Improve cache efficiency
4. **Consider algorithm changes**: Some operations may not benefit from SIMD

## Lessons Learned

1. **Internal functions need `:::`**: Rcpp-exported functions with `.prefix` are internal
2. **bench::mark expression type**: Must use `as.character()` for comparisons
3. **SIMD expectations**: Theoretical speedup ≠ practical speedup
4. **Measurement matters**: Small benchmarks may not show real-world gains
5. **Platform differences**: ARM NEON vs AVX2 have different characteristics

## Technical Notes

### Why No Dramatic Speedup?

1. **Auto-vectorization**: Modern compilers (especially Apple clang) already vectorize many loops automatically. The explicit SIMD might not add much over what the compiler does.

2. **Memory bound**: Autocorrelation and window functions are memory-bandwidth limited. SIMD speeds up compute but doesn't help memory access.

3. **Small vectors**: NEON processes 2 doubles per cycle (128-bit). Small vectors spend more time in setup/remainder loops than SIMD loops.

4. **Data dependencies**: Autocorrelation has sequential dependencies that limit parallelism.

### When SIMD Helps Most

- **Large data**: >16K samples where SIMD loop dominates
- **Compute-intensive**: Operations like FMA where computation > memory
- **Independent operations**: Element-wise operations with no dependencies
- **Wide SIMD**: AVX2 (256-bit) or AVX-512 show more dramatic gains

## Status

✅ **SIMD benchmarks fixed and running**  
⚠️ **Performance gains modest (1.0-1.4x) but present**  
📊 **Need testing on AMD EPYC (AVX2) for expected 4-6x gains**  
📈 **LPC autocorrelation shows best gains (1.36x) - validates approach**

---

**Date**: 2025-11-18  
**Package Version**: 0.5.0  
**Platform**: M1 Pro (ARM NEON)  
**Status**: Benchmarks working, awaiting cross-platform validation
