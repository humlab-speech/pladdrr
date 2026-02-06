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
// window_simd_bridge.cpp - Bridge between SIMD window functions and Praat code
// Part of Phase 1, Task 1.4: Window Function Integration
// Created: 2026-01-21

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat.github.io/melder/melder.h"
#include "praat.github.io/fon/Sound_and_Spectrogram_enums.h"
#include "simd_utils.h"
#include <cmath>

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include "xsimd_compat.h"
#endif

using namespace Rcpp;

// ============================================================================
// Direct SIMD window implementations (avoid Rcpp overhead)
// ============================================================================

namespace window_simd_direct {

#ifdef HAVE_XSIMD

// Direct SIMD Hamming window: w(n) = 0.54 - 0.46 * cos(2π * n / (N-1))
void apply_hamming_window_direct(
    double* data,
    int n
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    const double two_pi = 2.0 * M_PI;
    const double n_minus_1 = static_cast<double>(n - 1);

    const batch alpha(0.54);
    const batch beta(0.46);
    const batch two_pi_batch(two_pi);
    const batch n_minus_1_batch(n_minus_1);

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

        // Apply window to data (in-place)
        batch data_batch = xsimd::load_unaligned(&data[i]);
        batch windowed = data_batch * window;
        xsimd::store_unaligned(&data[i], windowed);
    }

    // Scalar remainder
    for (; i < n; ++i) {
        double window = 0.54 - 0.46 * std::cos(two_pi * i / n_minus_1);
        data[i] *= window;
    }
}

// Direct SIMD Hanning window: w(n) = 0.5 * (1 - cos(2π * n / (N-1)))
void apply_hanning_window_direct(
    double* data,
    int n
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    const double two_pi = 2.0 * M_PI;
    const double n_minus_1 = static_cast<double>(n - 1);

    const batch half(0.5);
    const batch one(1.0);
    const batch two_pi_batch(two_pi);
    const batch n_minus_1_batch(n_minus_1);

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

        // Apply window to data (in-place)
        batch data_batch = xsimd::load_unaligned(&data[i]);
        batch windowed = data_batch * window;
        xsimd::store_unaligned(&data[i], windowed);
    }

    // Scalar remainder
    for (; i < n; ++i) {
        double window = 0.5 * (1.0 - std::cos(two_pi * i / n_minus_1));
        data[i] *= window;
    }
}

// Direct SIMD Gaussian window: w(n) = exp(-0.5 * ((n - (N-1)/2) / (σ * (N-1)/2))^2)
// Using Praat's Gaussian formula: exp(-48.0 * phase^2) with edge correction
void apply_gaussian_window_direct(
    double* data,
    int n
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    const double nSamplesPerWindow_f = static_cast<double>(n);
    const double edge = std::exp(-12.0);
    const double imid = 0.5 * (n + 1.0);
    const double inv_edge_factor = 1.0 / (1.0 - edge);

    const batch minus_48(-48.0);
    const batch edge_batch(edge);
    const batch imid_batch(imid);
    const batch nsamp_batch(nSamplesPerWindow_f);
    const batch inv_edge_batch(inv_edge_factor);

    int i = 0;
    for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
        alignas(XSIMD_DEFAULT_ALIGNMENT) double indices[simd_size];
        for (size_t k = 0; k < simd_size; ++k) {
            indices[k] = static_cast<double>(i + k);
        }
        batch idx = xsimd::load_aligned(indices);

        // Compute window: (exp(-48 * phase^2) - edge) / (1 - edge)
        // phase = (i - imid) / nSamplesPerWindow_f
        batch phase = (idx - imid_batch) / nsamp_batch;
        batch exponent = minus_48 * phase * phase;
        batch window = (xsimd::exp(exponent) - edge_batch) * inv_edge_batch;

        // Apply window to data (in-place)
        batch data_batch = xsimd::load_unaligned(&data[i]);
        batch windowed = data_batch * window;
        xsimd::store_unaligned(&data[i], windowed);
    }

    // Scalar remainder
    for (; i < n; ++i) {
        double phase = ((i + 1.0) - imid) / nSamplesPerWindow_f;  // 1-based
        double window = (std::exp(-48.0 * phase * phase) - edge) * inv_edge_factor;
        data[i] *= window;
    }
}

// Direct SIMD Bartlett (triangular) window: w(n) = 1 - |2n/(N-1) - 1|
void apply_bartlett_window_direct(
    double* data,
    int n
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    const double n_minus_1 = static_cast<double>(n - 1);

    const batch one(1.0);
    const batch two(2.0);
    const batch n_minus_1_batch(n_minus_1);

    int i = 0;
    for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
        alignas(XSIMD_DEFAULT_ALIGNMENT) double indices[simd_size];
        for (size_t k = 0; k < simd_size; ++k) {
            indices[k] = static_cast<double>(i + k);
        }
        batch idx = xsimd::load_aligned(indices);

        // Compute window: 1 - |2*i/(N-1) - 1|
        batch phase = two * idx / n_minus_1_batch;
        batch window = one - xsimd::abs(phase - one);

        // Apply window to data (in-place)
        batch data_batch = xsimd::load_unaligned(&data[i]);
        batch windowed = data_batch * window;
        xsimd::store_unaligned(&data[i], windowed);
    }

    // Scalar remainder
    for (; i < n; ++i) {
        double phase = 2.0 * i / n_minus_1;
        double window = 1.0 - std::abs(phase - 1.0);
        data[i] *= window;
    }
}

// Direct SIMD Welch (parabolic) window: w(n) = 1 - ((2n/(N-1) - 1)^2)
void apply_welch_window_direct(
    double* data,
    int n
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    const double n_minus_1 = static_cast<double>(n - 1);

    const batch one(1.0);
    const batch two(2.0);
    const batch n_minus_1_batch(n_minus_1);

    int i = 0;
    for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
        alignas(XSIMD_DEFAULT_ALIGNMENT) double indices[simd_size];
        for (size_t k = 0; k < simd_size; ++k) {
            indices[k] = static_cast<double>(i + k);
        }
        batch idx = xsimd::load_aligned(indices);

        // Compute window: 1 - (2*i/(N-1) - 1)^2
        batch phase = two * idx / n_minus_1_batch;
        batch diff = phase - one;
        batch window = one - diff * diff;

        // Apply window to data (in-place)
        batch data_batch = xsimd::load_unaligned(&data[i]);
        batch windowed = data_batch * window;
        xsimd::store_unaligned(&data[i], windowed);
    }

    // Scalar remainder
    for (; i < n; ++i) {
        double phase = 2.0 * i / n_minus_1;
        double diff = phase - 1.0;
        double window = 1.0 - diff * diff;
        data[i] *= window;
    }
}

#endif // HAVE_XSIMD

} // namespace window_simd_direct

// ============================================================================
// Bridge functions for Praat integration
// ============================================================================

// Bridge function: Apply window to Praat VEC based on windowShape enum
// This is the unified interface that Praat code will call
extern "C" void apply_window_simd_bridge(
    VEC const& data,
    kSound_to_Spectrogram_windowShape windowShape
) {
#ifdef HAVE_XSIMD
    // Get direct pointer to data (skip 1-based index [0])
    // Praat VECs: data[1] is first element, data[n] is last
    double* data_ptr = &data[1];
    const int n = static_cast<int>(data.size);

    switch (windowShape) {
        case kSound_to_Spectrogram_windowShape::SQUARE:
            // No windowing needed (multiply by 1.0)
            break;

        case kSound_to_Spectrogram_windowShape::HAMMING:
            window_simd_direct::apply_hamming_window_direct(data_ptr, n);
            break;

        case kSound_to_Spectrogram_windowShape::HANNING:
            window_simd_direct::apply_hanning_window_direct(data_ptr, n);
            break;

        case kSound_to_Spectrogram_windowShape::GAUSSIAN:
            window_simd_direct::apply_gaussian_window_direct(data_ptr, n);
            break;

        case kSound_to_Spectrogram_windowShape::BARTLETT:
            window_simd_direct::apply_bartlett_window_direct(data_ptr, n);
            break;

        case kSound_to_Spectrogram_windowShape::WELCH:
            window_simd_direct::apply_welch_window_direct(data_ptr, n);
            break;

        default:
            Melder_throw(U"Unknown window shape in SIMD bridge");
    }
#else
    // Fallback: should not reach here if #ifdef guards are correct in caller
    Melder_throw(U"SIMD not available - should use scalar implementation");
#endif
}

// Bridge function: Compute window coefficients only (don't apply)
// Useful for pre-computing windows that will be reused
extern "C" void compute_window_simd_bridge(
    VEC const& window,
    kSound_to_Spectrogram_windowShape windowShape
) {
#ifdef HAVE_XSIMD
    const integer n = window.size;

    // Initialize window to 1.0 first
    for (integer i = 1; i <= n; i++) {
        window[i] = 1.0;
    }

    // Apply window function (modifies in-place)
    apply_window_simd_bridge(window, windowShape);
#else
    Melder_throw(U"SIMD not available - should use scalar implementation");
#endif
}

// Utility: Check if SIMD should be used for windowing
// This respects the R option speaker.use_simd
bool should_use_simd_for_windowing() {
#ifdef HAVE_XSIMD
    try {
        Rcpp::Environment base_env = Rcpp::Environment::namespace_env("base");
        Rcpp::Function getOption = base_env["getOption"];

        SEXP opt = getOption("speaker.use_simd", Rcpp::LogicalVector::create(true));

        if (Rcpp::is<Rcpp::LogicalVector>(opt)) {
            Rcpp::LogicalVector lv = Rcpp::as<Rcpp::LogicalVector>(opt);
            if (lv.size() > 0 && !Rcpp::LogicalVector::is_na(lv[0])) {
                return lv[0];
            }
        }
    } catch (...) {
        // If option check fails, default to true
    }
    return true;
#else
    return false;
#endif
}
