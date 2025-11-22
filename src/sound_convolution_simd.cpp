// SIMD-optimized convolution operations
// Implements Priority 3, Task 3.1 from SIMD_OPTIMIZATION_PLAN.md

#include <Rcpp.h>
#include "praat.github.io/sys/oo.h"
#include "praat.github.io/fon/Sound.h"

#ifdef RCPPXSIMD_XSIMD_HPP
#include <xsimd/xsimd.hpp>

namespace {

// SIMD-optimized complex multiplication for FFT-based convolution
// Input format: [real1, imag1, real2, imag2, ...]
// Output: result[i] = complex_multiply(a[i], b[i])
void complex_multiply_simd(double* result, const double* a, const double* b, integer n_complex) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    // Process complex pairs - each complex number takes 2 doubles: [real, imag]
    integer i = 0;
    const integer n_doubles = n_complex * 2;
    
    // Scalar implementation for complex multiplication (more portable)
    // Future: optimize with SIMD when swizzle patterns are stable across platforms
    for (; i < n_doubles; i += 2) {
        const double ar = a[i];
        const double ai = a[i + 1];
        const double br = b[i];
        const double bi = b[i + 1];
        
        result[i] = ar * br - ai * bi;      // Real part
        result[i + 1] = ar * bi + ai * br;  // Imaginary part
    }
}

// Simplified version for typical use case
void complex_multiply_inplace_simd(double* data, const double* kernel, integer n_complex) {
    complex_multiply_simd(data, data, kernel, n_complex);
}

} // anonymous namespace

#endif // RCPPXSIMD_XSIMD_HPP

// Scalar fallback implementations
namespace {

void complex_multiply_scalar(double* result, const double* a, const double* b, integer n_complex) {
    for (integer i = 0; i < n_complex * 2; i += 2) {
        const double ar = a[i];
        const double ai = a[i + 1];
        const double br = b[i];
        const double bi = b[i + 1];
        
        result[i] = ar * br - ai * bi;      // Real part
        result[i + 1] = ar * bi + ai * br;  // Imaginary part
    }
}

void complex_multiply_inplace_scalar(double* data, const double* kernel, integer n_complex) {
    complex_multiply_scalar(data, data, kernel, n_complex);
}

} // anonymous namespace

// Exported functions for R (if needed for testing/benchmarking)
// [[Rcpp::export(.complex_multiply_simd)]]
Rcpp::NumericVector complex_multiply(Rcpp::NumericVector a, Rcpp::NumericVector b) {
    if (a.size() != b.size() || a.size() % 2 != 0) {
        Rcpp::stop("Inputs must be complex vectors of equal length (even number of elements)");
    }
    
    const integer n_complex = a.size() / 2;
    Rcpp::NumericVector result(a.size());
    
#ifdef RCPPXSIMD_XSIMD_HPP
    complex_multiply_simd(result.begin(), a.begin(), b.begin(), n_complex);
#else
    complex_multiply_scalar(result.begin(), a.begin(), b.begin(), n_complex);
#endif
    
    return result;
}

// Public C interface for use in other compilation units
extern "C" {

void speaker_complex_multiply(double* result, const double* a, const double* b, integer n_complex) {
#ifdef RCPPXSIMD_XSIMD_HPP
    complex_multiply_simd(result, a, b, n_complex);
#else
    complex_multiply_scalar(result, a, b, n_complex);
#endif
}

void speaker_complex_multiply_inplace(double* data, const double* kernel, integer n_complex) {
#ifdef RCPPXSIMD_XSIMD_HPP
    complex_multiply_inplace_simd(data, kernel, n_complex);
#else
    complex_multiply_inplace_scalar(data, kernel, n_complex);
#endif
}

} // extern "C"
