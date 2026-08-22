/*
 * Part of pladdrr: R interface to Praat
 *
 * Copyright (C) 2025 Fredrik Nylén
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */
// autocorrelation_simd.cpp
// SIMD-optimized autocorrelation for pitch detection and LPC
// Part of speaker package SIMD Phase 3

#include <Rcpp.h>

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include "xsimd_compat.h"
#endif

#include "../praat_xptr_utils.h"
#include "../praat.github.io/melder/melder.h"

using namespace Rcpp;

// ============================================================================
// Helper Functions
// ============================================================================

// Scalar autocorrelation at a single lag (fallback)
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

#ifdef HAVE_XSIMD
// SIMD autocorrelation at a single lag
inline double autocorr_at_lag_simd_impl(const double* data, int n, int lag) {
    using batch = XSIMD_BATCH(double);
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
    
    double sum = xsimd_compat::reduce_add_compat(acc);
    
    // Scalar remainder
    for (; i < count; ++i) {
        sum += x1[i] * x2[i];
    }
    
    return sum;
}
#endif

// ============================================================================
// Exported SIMD Functions (always defined, conditionally implemented)
// ============================================================================

// Full autocorrelation sequence (for pitch detection)
// [[Rcpp::export(.autocorrelation_simd)]]
NumericVector autocorrelation_simd(NumericVector data, int max_lag) {
    const int n = data.size();
    if (max_lag >= n) max_lag = n - 1;
    
    NumericVector result(max_lag + 1);
    const double* src = REAL(data);
    double* dst = REAL(result);
    
#ifdef HAVE_XSIMD
    // Use SIMD implementation
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_simd_impl(src, n, lag);
    }
#else
    // Fallback to scalar
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_scalar(src, n, lag);
    }
#endif
    
    return result;
}

// Normalized autocorrelation (ACF)
// [[Rcpp::export(.autocorrelation_normalized_simd)]]
NumericVector autocorrelation_normalized_simd(NumericVector data, int max_lag) {
    const int n = data.size();
    if (max_lag >= n) max_lag = n - 1;
    
    const double* src = REAL(data);
    
#ifdef HAVE_XSIMD
    double var = autocorr_at_lag_simd_impl(src, n, 0);
#else
    double var = autocorr_at_lag_scalar(src, n, 0);
#endif
    
    if (var == 0.0) {
        return NumericVector(max_lag + 1, 0.0);
    }
    
    NumericVector result(max_lag + 1);
    double* dst = REAL(result);
    
#ifdef HAVE_XSIMD
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_simd_impl(src, n, lag) / var;
    }
#else
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_scalar(src, n, lag) / var;
    }
#endif
    
    return result;
}

// Cross-correlation (used in pitch detection)
double cross_correlation_simd(NumericVector x, NumericVector y) {
    if (x.size() != y.size()) {
        Rcpp::stop("Vectors must have same length for cross-correlation");
    }
    
    const int n = x.size();
    const double* x_ptr = REAL(x);
    const double* y_ptr = REAL(y);
    
#ifdef HAVE_XSIMD
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;
    
    batch acc(0.0);
    int i = 0;
    
    for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
        batch a = xsimd::load_unaligned(&x_ptr[i]);
        batch b = xsimd::load_unaligned(&y_ptr[i]);
        acc = xsimd::fma(a, b, acc);
    }
    
    double sum = xsimd_compat::reduce_add_compat(acc);
    
    // Remainder
    for (; i < n; ++i) {
        sum += x_ptr[i] * y_ptr[i];
    }
    
    return sum;
#else
    double sum = 0.0;
    for (int i = 0; i < n; ++i) {
        sum += x_ptr[i] * y_ptr[i];
    }
    return sum;
#endif
}

// Windowed autocorrelation (for pitch detection with frames)
// Confirmed-orphaned: zero callers anywhere in src/ — not covered, not excluded.
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

#ifdef HAVE_XSIMD
    for (int frame = 0; frame < num_frames; ++frame) {
        int start = frame * hop_size;
        const double* frame_data = src + start;

        for (int lag = 0; lag <= max_lag; ++lag) {
            result(frame, lag) = autocorr_at_lag_simd_impl(frame_data, frame_length, lag);
        }
    }
#else
    for (int frame = 0; frame < num_frames; ++frame) {
        int start = frame * hop_size;
        const double* frame_data = src + start;

        for (int lag = 0; lag <= max_lag; ++lag) {
            result(frame, lag) = autocorr_at_lag_scalar(frame_data, frame_length, lag);
        }
    }
#endif

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
    
#ifdef HAVE_XSIMD
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_simd_impl(src, n, lag);
    }
#else
    for (int lag = 0; lag <= max_lag; ++lag) {
        dst[lag] = autocorr_at_lag_scalar(src, n, lag);
    }
#endif
    
    return result;
}

// ============================================================================
// Explicit Scalar Versions (for benchmarking)
// ============================================================================

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

// Confirmed-orphaned: zero callers anywhere in src/ — not covered, not excluded.
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

// Confirmed-orphaned: zero callers anywhere in src/ — not covered, not excluded.
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

