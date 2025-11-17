// autocorrelation_simd.cpp
// SIMD-optimized autocorrelation for pitch detection and LPC
// Part of speaker package SIMD Phase 3

#include <Rcpp.h>

#ifdef RCPPXSIMD_XSIMD_HPP
#include <xsimd/xsimd.hpp>
#endif

#include "../praat_xptr_utils.h"
#include "../praat.github.io/melder/melder.h"

using namespace Rcpp;

// ============================================================================
// SIMD Autocorrelation Functions
// ============================================================================

#ifdef RCPPXSIMD_XSIMD_HPP

// Compute autocorrelation at a single lag using SIMD
// This is the core operation for pitch detection and LPC
inline double autocorr_at_lag_simd(const double* data, int n, int lag) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    const double* x1 = data;
    const double* x2 = data + lag;
    int count = n - lag;
    
    // SIMD accumulation
    batch acc(0.0);
    int i = 0;
    
    for (; i + static_cast<int>(simd_size) <= count; i += simd_size) {
        batch a = xsimd::load_unaligned(&x1[i]);
        batch b = xsimd::load_unaligned(&x2[i]);
        acc = xsimd::fma(a, b, acc);  // acc += a * b (fused multiply-add)
    }
    
    double sum = xsimd::reduce_add(acc);
    
    // Scalar remainder
    for (; i < count; ++i) {
        sum += x1[i] * x2[i];
    }
    
    return sum;
}

// Full autocorrelation sequence (for pitch detection)
// [[Rcpp::export(.autocorrelation_simd)]]
NumericVector autocorrelation_simd(NumericVector data, int max_lag) {
    const int n = data.size();
    if (max_lag >= n) max_lag = n - 1;
    
    NumericVector result(max_lag + 1);
    const double* src = REAL(data);
    double* dst = REAL(result);
    
    // Compute autocorrelation for each lag
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_simd(src, n, lag);
    }
    
    return result;
}

// Normalized autocorrelation (ACF)
// [[Rcpp::export(.autocorrelation_normalized_simd)]]
NumericVector autocorrelation_normalized_simd(NumericVector data, int max_lag) {
    const int n = data.size();
    if (max_lag >= n) max_lag = n - 1;
    
    const double* src = REAL(data);
    
    // Compute lag-0 (variance)
    double var = autocorr_at_lag_simd(src, n, 0);
    
    if (var == 0.0) {
        return NumericVector(max_lag + 1, 0.0);
    }
    
    NumericVector result(max_lag + 1);
    double* dst = REAL(result);
    
    // Normalized values
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_simd(src, n, lag) / var;
    }
    
    return result;
}

// Cross-correlation (used in pitch detection)
// [[Rcpp::export(.cross_correlation_simd)]]
double cross_correlation_simd(NumericVector x, NumericVector y) {
    if (x.size() != y.size()) {
        Rcpp::stop("Vectors must have same length for cross-correlation");
    }
    
    const int n = x.size();
    const double* x_ptr = REAL(x);
    const double* y_ptr = REAL(y);
    
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    batch acc(0.0);
    int i = 0;
    
    for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
        batch a = xsimd::load_unaligned(&x_ptr[i]);
        batch b = xsimd::load_unaligned(&y_ptr[i]);
        acc = xsimd::fma(a, b, acc);
    }
    
    double sum = xsimd::reduce_add(acc);
    
    // Remainder
    for (; i < n; ++i) {
        sum += x_ptr[i] * y_ptr[i];
    }
    
    return sum;
}

// Windowed autocorrelation (for pitch detection with frames)
// [[Rcpp::export(.windowed_autocorrelation_simd)]]
NumericMatrix windowed_autocorrelation_simd(
    NumericVector data,
    int frame_length,
    int max_lag,
    int hop_size
) {
    const int n = data.size();
    const int num_frames = (n - frame_length) / hop_size + 1;
    
    if (max_lag >= frame_length) max_lag = frame_length - 1;
    
    NumericMatrix result(num_frames, max_lag + 1);
    const double* src = REAL(data);
    
    for (int frame = 0; frame < num_frames; ++frame) {
        int start = frame * hop_size;
        const double* frame_data = src + start;
        
        for (int lag = 0; lag <= max_lag; ++lag) {
            result(frame, lag) = autocorr_at_lag_simd(frame_data, frame_length, lag);
        }
    }
    
    return result;
}

// Burg algorithm preprocessing (compute autocorrelation for LPC)
// [[Rcpp::export(.lpc_autocorrelation_simd)]]
NumericVector lpc_autocorrelation_simd(NumericVector data, int num_coefficients) {
    const int n = data.size();
    const int max_lag = num_coefficients;
    
    if (max_lag >= n) {
        Rcpp::stop("Number of LPC coefficients must be less than data length");
    }
    
    NumericVector result(max_lag + 1);
    const double* src = REAL(data);
    double* dst = REAL(result);
    
    // Compute autocorrelation for each lag
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_simd(src, n, lag);
    }
    
    return result;
}

#endif // RCPPXSIMD_XSIMD_HPP

// ============================================================================
// Scalar fallback versions
// ============================================================================

// Scalar autocorrelation at single lag
inline double autocorr_at_lag_scalar(const double* data, int n, int lag) {
    const double* x1 = data;
    const double* x2 = data + lag;
    int count = n - lag;
    
    double sum = 0.0;
    for (int i = 0; i < count; ++i) {
        sum += x1[i] * x2[i];
    }
    
    return sum;
}

// [[Rcpp::export(.autocorrelation_scalar)]]
NumericVector autocorrelation_scalar(NumericVector data, int max_lag) {
    const int n = data.size();
    if (max_lag >= n) max_lag = n - 1;
    
    NumericVector result(max_lag + 1);
    const double* src = REAL(data);
    double* dst = REAL(result);
    
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_scalar(src, n, lag);
    }
    
    return result;
}

// [[Rcpp::export(.autocorrelation_normalized_scalar)]]
NumericVector autocorrelation_normalized_scalar(NumericVector data, int max_lag) {
    const int n = data.size();
    if (max_lag >= n) max_lag = n - 1;
    
    const double* src = REAL(data);
    double var = autocorr_at_lag_scalar(src, n, 0);
    
    if (var == 0.0) {
        return NumericVector(max_lag + 1, 0.0);
    }
    
    NumericVector result(max_lag + 1);
    double* dst = REAL(result);
    
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_scalar(src, n, lag) / var;
    }
    
    return result;
}

// [[Rcpp::export(.cross_correlation_scalar)]]
double cross_correlation_scalar(NumericVector x, NumericVector y) {
    if (x.size() != y.size()) {
        Rcpp::stop("Vectors must have same length for cross-correlation");
    }
    
    const int n = x.size();
    const double* x_ptr = REAL(x);
    const double* y_ptr = REAL(y);
    
    double sum = 0.0;
    for (int i = 0; i < n; ++i) {
        sum += x_ptr[i] * y_ptr[i];
    }
    
    return sum;
}

// [[Rcpp::export(.windowed_autocorrelation_scalar)]]
NumericMatrix windowed_autocorrelation_scalar(
    NumericVector data,
    int frame_length,
    int max_lag,
    int hop_size
) {
    const int n = data.size();
    const int num_frames = (n - frame_length) / hop_size + 1;
    
    if (max_lag >= frame_length) max_lag = frame_length - 1;
    
    NumericMatrix result(num_frames, max_lag + 1);
    const double* src = REAL(data);
    
    for (int frame = 0; frame < num_frames; ++frame) {
        int start = frame * hop_size;
        const double* frame_data = src + start;
        
        for (int lag = 0; lag <= max_lag; ++lag) {
            result(frame, lag) = autocorr_at_lag_scalar(frame_data, frame_length, lag);
        }
    }
    
    return result;
}

// [[Rcpp::export(.lpc_autocorrelation_scalar)]]
NumericVector lpc_autocorrelation_scalar(NumericVector data, int num_coefficients) {
    const int n = data.size();
    const int max_lag = num_coefficients;
    
    if (max_lag >= n) {
        Rcpp::stop("Number of LPC coefficients must be less than data length");
    }
    
    NumericVector result(max_lag + 1);
    const double* src = REAL(data);
    double* dst = REAL(result);
    
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_scalar(src, n, lag);
    }
    
    return result;
}

// ============================================================================
// Dispatcher functions
// ============================================================================

// [[Rcpp::export(.autocorrelation)]]
NumericVector autocorrelation(NumericVector data, int max_lag) {
#ifdef RCPPXSIMD_XSIMD_HPP
    return autocorrelation_simd(data, max_lag);
#else
    return autocorrelation_scalar(data, max_lag);
#endif
}

// [[Rcpp::export(.autocorrelation_normalized)]]
NumericVector autocorrelation_normalized(NumericVector data, int max_lag) {
#ifdef RCPPXSIMD_XSIMD_HPP
    return autocorrelation_normalized_simd(data, max_lag);
#else
    return autocorrelation_normalized_scalar(data, max_lag);
#endif
}

// [[Rcpp::export(.cross_correlation)]]
double cross_correlation(NumericVector x, NumericVector y) {
#ifdef RCPPXSIMD_XSIMD_HPP
    return cross_correlation_simd(x, y);
#else
    return cross_correlation_scalar(x, y);
#endif
}

// [[Rcpp::export(.windowed_autocorrelation)]]
NumericMatrix windowed_autocorrelation(
    NumericVector data,
    int frame_length,
    int max_lag,
    int hop_size
) {
#ifdef RCPPXSIMD_XSIMD_HPP
    return windowed_autocorrelation_simd(data, frame_length, max_lag, hop_size);
#else
    return windowed_autocorrelation_scalar(data, frame_length, max_lag, hop_size);
#endif
}

// [[Rcpp::export(.lpc_autocorrelation)]]
NumericVector lpc_autocorrelation(NumericVector data, int num_coefficients) {
#ifdef RCPPXSIMD_XSIMD_HPP
    return lpc_autocorrelation_simd(data, num_coefficients);
#else
    return lpc_autocorrelation_scalar(data, num_coefficients);
#endif
}
