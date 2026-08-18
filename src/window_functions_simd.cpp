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
// window_functions_simd.cpp
// SIMD-optimized window functions for spectral analysis
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
// SIMD Window Functions (always defined, conditionally implemented)
// ============================================================================

// Hamming window: w(n) = 0.54 - 0.46 * cos(2π * n / (N-1))
// [[Rcpp::export(.apply_hamming_window_simd)]]
NumericVector apply_hamming_window_simd(NumericVector data) {
    const int n = data.size();
    NumericVector result(n);
    
    const double* src = REAL(data);
    double* dst = REAL(result);
    const double two_pi = 2.0 * M_PI;
    const double n_minus_1 = static_cast<double>(n - 1);
    
#ifdef HAVE_XSIMD
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;
    
    const batch alpha(0.54);
    const batch beta(0.46);
    const batch two_pi_batch(two_pi);
    const batch n_minus_1_batch(n_minus_1);
    
    // Vectorized loop
    int i = 0;
    for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
        // Create index vector [i, i+1, i+2, ...]
        alignas(XSIMD_DEFAULT_ALIGNMENT) double indices[simd_size];
        for (size_t k = 0; k < simd_size; ++k) {
            indices[k] = static_cast<double>(i + k);
        }
        batch idx = xsimd::load_aligned(indices);
        
        // Compute window: 0.54 - 0.46 * cos(2π * i / (N-1))
        batch angle = two_pi_batch * idx / n_minus_1_batch;
        batch window = alpha - beta * xsimd::cos(angle);
        
        // Apply window to data
        batch data_batch = xsimd::load_unaligned(&src[i]);
        batch windowed = data_batch * window;
        xsimd::store_unaligned(&dst[i], windowed);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        double window = 0.54 - 0.46 * std::cos(two_pi * i / n_minus_1);
        dst[i] = src[i] * window;
    }
#else
    // Scalar fallback
    for (int i = 0; i < n; ++i) {
        double window = 0.54 - 0.46 * std::cos(two_pi * i / n_minus_1);
        dst[i] = src[i] * window;
    }
#endif
    
    return result;
}

// Hanning window: w(n) = 0.5 * (1 - cos(2π * n / (N-1)))
// [[Rcpp::export(.apply_hanning_window_simd)]]
NumericVector apply_hanning_window_simd(NumericVector data) {
    const int n = data.size();
    NumericVector result(n);
    
    const double* src = REAL(data);
    double* dst = REAL(result);
    const double two_pi = 2.0 * M_PI;
    const double n_minus_1 = static_cast<double>(n - 1);
    
#ifdef HAVE_XSIMD
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;
    
    const batch half(0.5);
    const batch one(1.0);
    const batch two_pi_batch(two_pi);
    const batch n_minus_1_batch(n_minus_1);
    
    // Vectorized loop
    int i = 0;
    for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
        alignas(XSIMD_DEFAULT_ALIGNMENT) double indices[simd_size];
        for (size_t k = 0; k < simd_size; ++k) {
            indices[k] = static_cast<double>(i + k);
        }
        batch idx = xsimd::load_aligned(indices);
        
        // Compute window: 0.5 * (1 - cos(2π * i / (N-1)))
        batch angle = two_pi_batch * idx / n_minus_1_batch;
        batch window = half * (one - xsimd::cos(angle));
        
        // Apply window to data
        batch data_batch = xsimd::load_unaligned(&src[i]);
        batch windowed = data_batch * window;
        xsimd::store_unaligned(&dst[i], windowed);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        double window = 0.5 * (1.0 - std::cos(two_pi * i / n_minus_1));
        dst[i] = src[i] * window;
    }
#else
    // Scalar fallback
    for (int i = 0; i < n; ++i) {
        double window = 0.5 * (1.0 - std::cos(two_pi * i / n_minus_1));
        dst[i] = src[i] * window;
    }
#endif
    
    return result;
}

// Gaussian window: w(n) = exp(-0.5 * ((n - (N-1)/2) / (σ * (N-1)/2))^2)
// [[Rcpp::export(.apply_gaussian_window_simd)]]
NumericVector apply_gaussian_window_simd(NumericVector data, double sigma = 0.4) {
    const int n = data.size();
    NumericVector result(n);
    
    const double* src = REAL(data);
    double* dst = REAL(result);
    const double center = (n - 1) / 2.0;
    const double denominator = sigma * center;
    
#ifdef HAVE_XSIMD
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;
    
    const batch minus_half(-0.5);
    const batch center_batch(center);
    const batch denom_batch(denominator);
    
    // Vectorized loop
    int i = 0;
    for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
        alignas(XSIMD_DEFAULT_ALIGNMENT) double indices[simd_size];
        for (size_t k = 0; k < simd_size; ++k) {
            indices[k] = static_cast<double>(i + k);
        }
        batch idx = xsimd::load_aligned(indices);
        
        // Compute window: exp(-0.5 * ((i - center) / denominator)^2)
        batch diff = idx - center_batch;
        batch normalized = diff / denom_batch;
        batch exponent = minus_half * normalized * normalized;
        batch window = xsimd::exp(exponent);
        
        // Apply window to data
        batch data_batch = xsimd::load_unaligned(&src[i]);
        batch windowed = data_batch * window;
        xsimd::store_unaligned(&dst[i], windowed);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        double diff = i - center;
        double normalized = diff / denominator;
        double window = std::exp(-0.5 * normalized * normalized);
        dst[i] = src[i] * window;
    }
#else
    // Scalar fallback
    for (int i = 0; i < n; ++i) {
        double diff = i - center;
        double normalized = diff / denominator;
        double window = std::exp(-0.5 * normalized * normalized);
        dst[i] = src[i] * window;
    }
#endif
    
    return result;
}

// ============================================================================
// Explicit Scalar Versions (for benchmarking)
// ============================================================================

// [[Rcpp::export(.apply_hamming_window_scalar)]]
NumericVector apply_hamming_window_scalar(NumericVector data) {
    const int n = data.size();
    NumericVector result(n);
    
    const double* src = REAL(data);
    double* dst = REAL(result);
    const double two_pi = 2.0 * M_PI;
    const double n_minus_1 = static_cast<double>(n - 1);
    
    for (int i = 0; i < n; ++i) {
        double window = 0.54 - 0.46 * std::cos(two_pi * i / n_minus_1);
        dst[i] = src[i] * window;
    }
    
    return result;
}

// [[Rcpp::export(.apply_hanning_window_scalar)]]
NumericVector apply_hanning_window_scalar(NumericVector data) {
    const int n = data.size();
    NumericVector result(n);
    
    const double* src = REAL(data);
    double* dst = REAL(result);
    const double two_pi = 2.0 * M_PI;
    const double n_minus_1 = static_cast<double>(n - 1);
    
    for (int i = 0; i < n; ++i) {
        double window = 0.5 * (1.0 - std::cos(two_pi * i / n_minus_1));
        dst[i] = src[i] * window;
    }
    
    return result;
}

// [[Rcpp::export(.apply_gaussian_window_scalar)]]
NumericVector apply_gaussian_window_scalar(NumericVector data, double sigma = 0.4) {
    const int n = data.size();
    NumericVector result(n);
    
    const double* src = REAL(data);
    double* dst = REAL(result);
    const double center = (n - 1) / 2.0;
    const double denominator = sigma * center;
    
    for (int i = 0; i < n; ++i) {
        double diff = i - center;
        double normalized = diff / denominator;
        double window = std::exp(-0.5 * normalized * normalized);
        dst[i] = src[i] * window;
    }
    
    return result;
}

// ============================================================================
// Dispatcher functions (choose SIMD or scalar at runtime)
// ============================================================================

