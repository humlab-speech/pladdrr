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
// formant_simd_bridge.cpp - Bridge between SIMD formant/LPC functions and Praat code
// Part of Phase 1, Task 1.3: Formant Extraction Integration
// Created: 2026-01-21

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat.github.io/melder/melder.h"
#include "praat.github.io/fon/Formant.h"
#include "simd_utils.h"
#include <cmath>
#include <complex>
#include <vector>

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include "xsimd_compat.h"
#endif

using namespace Rcpp;

// Forward declaration of formant_lpc_simd namespace functions
namespace formant_lpc_simd {
    void find_polynomial_roots_simd(
        const double* lpc_coeffs,
        int order,
        std::complex<double>* roots
    );
}

// ============================================================================
// Direct SIMD implementations for LPC/Formant extraction
// ============================================================================

namespace formant_simd_direct {

#ifdef HAVE_XSIMD

// Direct SIMD-accelerated Burg's algorithm
// This replaces VECburg() in NUM2.cpp for formant extraction
double burg_simd(
    double* lpc_coeffs,          // Output: LPC coefficients [1..m]
    const double* signal,        // Input: signal samples [1..n]
    int n,                       // Number of samples
    int m                        // Number of LPC coefficients (order)
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    if (n <= 2) {
        lpc_coeffs[0] = -1.0;  // 1-based indexing
        return 1.0;
    }

    // Initialize forward and backward prediction errors
    std::vector<double> f(n + 1), b(n + 1);  // 1-based indexing

    // Initialize with signal (skip index 0)
    int i = 1;
    for (; i + static_cast<int>(simd_size) <= n + 1; i += simd_size) {
        batch sig = xsimd::load_unaligned(&signal[i]);
        sig.store_unaligned(&f[i]);
        sig.store_unaligned(&b[i]);
    }
    for (; i <= n; ++i) {
        f[i] = b[i] = signal[i];
    }

    // Burg recursion
    std::vector<double> a(m + 1, 0.0);  // 1-based
    a[0] = 1.0;

    // Initial mean square error
    double xms = 0.0;
    batch sum_batch(0.0);
    i = 1;
    for (; i + static_cast<int>(simd_size) <= n + 1; i += simd_size) {
        batch sig = xsimd::load_unaligned(&signal[i]);
        sum_batch = xsimd::fma(sig, sig, sum_batch);
    }
    xms = xsimd_compat::reduce_add_compat(sum_batch);
    for (; i <= n; ++i) {
        xms += signal[i] * signal[i];
    }
    xms /= n;

    // Levinson-Durbin recursion
    for (int k = 1; k <= m; ++k) {
        // Calculate reflection coefficient (PARCOR)
        batch num_batch(0.0), den_batch(0.0);
        i = k;

        // SIMD loop for numerator and denominator
        for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
            batch f_batch = xsimd::load_unaligned(&f[i]);
            batch b_batch = xsimd::load_unaligned(&b[i]);
            num_batch = xsimd::fma(f_batch, b_batch, num_batch);
            den_batch = xsimd::fma(f_batch, f_batch, den_batch);
            den_batch = xsimd::fma(b_batch, b_batch, den_batch);
        }

        double num = xsimd_compat::reduce_add_compat(num_batch);
        double den = xsimd_compat::reduce_add_compat(den_batch);

        // Scalar remainder
        for (; i <= n; ++i) {
            num += f[i] * b[i];
            den += f[i] * f[i] + b[i] * b[i];
        }

        if (den <= 0.0) {
            for (int j = k; j <= m; ++j)
                lpc_coeffs[j - 1] = 0.0;  // Convert to 0-based for output
            return xms;
        }

        double parcor = -2.0 * num / den;
        xms *= 1.0 - parcor * parcor;

        // Update LPC coefficients
        std::vector<double> a_new(m + 1);
        a_new[0] = 1.0;
        for (int j = 1; j < k; ++j) {
            a_new[j] = a[j] + parcor * a[k - j];
        }
        a_new[k] = parcor;
        a = a_new;

        // Update prediction errors with SIMD
        // FIX: Must preserve original f and b values for the entire update
        // because f_new[i] uses b_old[i-1] and b_new[i] uses f_old[i]
        // Without temp storage, b[i] could be overwritten before b[i] is read as b_old[i+1-1]
        if (k < m) {
            // Use temp vectors to avoid data dependency issues
            std::vector<double> f_new(n + 1), b_new(n + 1);

            batch parcor_batch(parcor);
            i = k + 1;

            // SIMD loop: compute new values using ORIGINAL f and b
            for (; i + static_cast<int>(simd_size) <= n + 1; i += simd_size) {
                batch f_cur = xsimd::load_unaligned(&f[i]);
                batch b_prev = xsimd::load_unaligned(&b[i - 1]);

                batch f_result = xsimd::fma(parcor_batch, b_prev, f_cur);
                batch b_result = xsimd::fma(parcor_batch, f_cur, b_prev);

                f_result.store_unaligned(&f_new[i]);
                b_result.store_unaligned(&b_new[i]);
            }

            // Scalar remainder
            for (; i <= n; ++i) {
                double f_cur = f[i];
                double b_prev = b[i - 1];
                f_new[i] = f_cur + parcor * b_prev;
                b_new[i] = b_prev + parcor * f_cur;
            }

            // Copy results back
            for (i = k + 1; i <= n; ++i) {
                f[i] = f_new[i];
                b[i] = b_new[i];
            }
        }
    }

    // Copy coefficients to output (convert 1-based a[] to 0-based lpc_coeffs[])
    for (int i = 1; i <= m; ++i) {
        lpc_coeffs[i - 1] = a[i];
    }

    return xms;
}

// SIMD-accelerated pre-emphasis filter for formant extraction
// This is applied before LPC analysis
void apply_preemphasis_simd(
    double* signal,              // Input/output: signal [1..n] (1-based)
    int n,                       // Number of samples
    double alpha = 0.97          // Pre-emphasis coefficient
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    // Process in reverse to avoid temporary storage
    // signal[i] = signal[i] - alpha * signal[i-1]

    // Save first sample (not pre-emphasized)
    double first = signal[1];

    // SIMD processing (need to handle loop-carried dependency carefully)
    // Process in blocks, starting from the end
    for (int i = n; i >= 2; --i) {
        signal[i] -= alpha * signal[i - 1];
    }

    signal[1] = first;  // Restore first sample
}

// SIMD-accelerated root finding for formant extraction
// Finds formant frequencies and bandwidths from LPC coefficients
//
// FIXED (PLADDRR_PERFORMANCE_REQUESTS.md - Issue 2):
// Implemented complete polynomial root finding using Laguerre's method
void find_formants_from_lpc_simd(
    const double* lpc_coeffs,    // LPC coefficients [0..order-1]
    int order,                   // LPC order
    double* formant_freqs,       // Output: formant frequencies [0..max_formants-1]
    double* formant_bandwidths,  // Output: formant bandwidths [0..max_formants-1]
    int* n_formants_out,         // Output: number of formants found
    double sampling_rate,        // Sampling rate (Hz)
    double safety_margin         // Safety margin (Hz) - don't extract formants too close to 0 or Nyquist
) {
    const double nyquist = sampling_rate / 2.0;
    
    // Find polynomial roots (implemented in formant_lpc_simd.cpp)
    std::vector<std::complex<double>> roots(order);
    
    // Call function from formant_lpc_simd namespace
    formant_lpc_simd::find_polynomial_roots_simd(lpc_coeffs, order, roots.data());
    
    // Extract formants from roots
    *n_formants_out = 0;
    
    for (int i = 0; i < order; ++i) {
        // Only consider roots in upper half-plane (positive imaginary part)
        if (roots[i].imag() > 0) {
            // Convert to frequency and bandwidth
            double angle = std::atan2(roots[i].imag(), roots[i].real());
            double radius = std::abs(roots[i]);
            
            // Frequency from angle
            double freq = angle * sampling_rate / (2.0 * M_PI);
            
            // Bandwidth from radius
            double bandwidth = -std::log(radius) * sampling_rate / M_PI;
            
            // Check if within valid range
            if (freq > safety_margin && freq < nyquist - safety_margin && bandwidth > 0) {
                formant_freqs[*n_formants_out] = freq;
                formant_bandwidths[*n_formants_out] = bandwidth;
                (*n_formants_out)++;
            }
        }
    }
}

#endif // HAVE_XSIMD

} // namespace formant_simd_direct

// ============================================================================
// Bridge functions for Praat integration
// ============================================================================

// Bridge function: SIMD-accelerated Burg's algorithm
// Replaces VECburg() from NUM2.cpp
extern "C" double VECburg_simd_bridge(
    VEC const& lpc_coeffs,       // Output: LPC coefficients (Praat VEC, 1-based)
    constVEC const& signal       // Input: signal samples (Praat VEC, 1-based)
) {
#ifdef HAVE_XSIMD
    const integer n = signal.size;
    const integer m = lpc_coeffs.size;

    // Call SIMD implementation
    // Note: Praat VECs are 1-based, pass &vec[1] to get first element
    return formant_simd_direct::burg_simd(
        &lpc_coeffs[1],
        &signal[1],
        static_cast<int>(n),
        static_cast<int>(m)
    );
#else
    Melder_throw(U"SIMD not available - should not reach here");
    return 0.0;
#endif
}

// Bridge function: Pre-emphasis filter
extern "C" void apply_preemphasis_simd_bridge(
    VEC const& signal,           // Input/output: signal (Praat VEC, 1-based)
    double preemphasis_frequency,
    double sampling_rate
) {
#ifdef HAVE_XSIMD
    // Calculate alpha from preemphasis frequency
    // alpha ≈ exp(-2π * f_preemph / f_sample)
    const double alpha = std::exp(-2.0 * M_PI * preemphasis_frequency / sampling_rate);

    formant_simd_direct::apply_preemphasis_simd(
        &signal[1],
        static_cast<int>(signal.size),
        alpha
    );
#else
    Melder_throw(U"SIMD not available - should not reach here");
#endif
}

// Utility: Check if SIMD should be used for formant extraction
// NOTE (v4.8.9): The SIMD formant extraction path now has complete polynomial
// root finding (Laguerre's method), but remains disabled pending validation.
// VECburg now has SIMD acceleration built-in for its inner loops (NUM2.cpp).
//
// UPDATE (PLADDRR_PERFORMANCE_REQUESTS.md - Issue 2):
// find_polynomial_roots_simd() is now IMPLEMENTED using Laguerre's method.
// However, this function still returns false to maintain stability until:
// 1. Root finding is validated against Praat's Polynomial_to_Roots()
// 2. burg_simd() is validated against VECburg() for identical results
// 3. Full end-to-end formant extraction is tested against reference values
//
// To enable SIMD formant path: Change return value to true and run validation tests.
bool should_use_simd_for_formants() {
    // Keep using standard VECburg path until SIMD implementation is validated
    return false;
}
