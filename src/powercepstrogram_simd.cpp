/* powercepstrogram_simd.cpp
 *
 * SIMD-optimized PowerCepstrogram operations for CPPS calculation
 * Part of v4.8.10 performance optimization (PLADDRR_PERFORMANCE_REQUESTS.md Issue 4)
 * Created: 2026-02-04
 *
 * Copyright (C) 2026 pladdrr development team
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 */

#include "praat.github.io/melder/melder.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include "xsimd_compat.h"
#endif

#include <Rcpp.h>
#include <cmath>

// ============================================================================
// SIMD Namespace for PowerCepstrogram Operations
// ============================================================================

namespace powercepstrogram_simd_direct {

#ifdef HAVE_XSIMD

/**
 * Extract frame from signal with zero-padding (SIMD)
 *
 * Extracts a frame from the input signal, handling boundary conditions:
 * output[j] = (start + j > 0 && start + j <= nx) ? input[start + j] : 0.0
 *
 * This replaces lines 75-76 in Sound_to_PowerCepstrogram.cpp
 *
 * @param input_signal Sound data (1-based indexed, passed as ptr-1)
 * @param output_frame Output frame buffer (1-based indexed, passed as ptr-1)
 * @param start_sample Starting position in signal (1-based Praat index)
 * @param frame_size Number of samples to extract
 * @param input_nx Total length of input signal
 */
void extract_frame_simd(
    const double* input_signal,    // Actually signal - 1 (for 1-based access)
    double* output_frame,          // Actually frame - 1 (for 1-based access)
    integer start_sample,          // Praat 1-based index
    integer frame_size,            // Number of samples
    integer input_nx               // Input signal length
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    // Process each sample with boundary checking
    integer i = 1;

    // SIMD loop - check if samples are within bounds
    for (; i + static_cast<integer>(simd_size) - 1 <= frame_size; i += simd_size) {
        alignas(32) double result_vals[simd_size];
        
        // Check each element in the batch
        for (size_t j = 0; j < simd_size; j++) {
            integer sample_idx = start_sample + i - 1 + static_cast<integer>(j);
            if (sample_idx > 0 && sample_idx <= input_nx) {
                result_vals[j] = input_signal[sample_idx];
            } else {
                result_vals[j] = 0.0;
            }
        }
        
        batch result = xsimd::load_aligned(result_vals);
        result.store_unaligned(&output_frame[i]);
    }

    // Scalar remainder
    for (; i <= frame_size; i++) {
        integer sample_idx = start_sample + i - 1;
        output_frame[i] = (sample_idx > 0 && sample_idx <= input_nx) 
                          ? input_signal[sample_idx] : 0.0;
    }
}

/**
 * Multiply frame by window function in-place (SIMD)
 *
 * Applies window function to frame: frame[i] *= window[i]
 * This replaces line 80 in Sound_to_PowerCepstrogram.cpp
 *
 * @param frame Frame data (1-based indexed, modified in place)
 * @param window Window coefficients (1-based indexed)
 * @param frame_size Number of samples
 */
void window_multiply_inplace_simd(
    double* frame,                 // Actually frame - 1 (for 1-based access)
    const double* window,          // Actually window - 1 (for 1-based access)
    integer frame_size
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    integer i = 1;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) - 1 <= frame_size; i += simd_size) {
        batch f = xsimd::load_unaligned(&frame[i]);
        batch w = xsimd::load_unaligned(&window[i]);
        batch result = f * w;
        result.store_unaligned(&frame[i]);
    }

    // Scalar remainder
    for (; i <= frame_size; i++) {
        frame[i] *= window[i];
    }
}

/**
 * Compute log power spectrum from interleaved FFT output (SIMD)
 *
 * PRIMARY OPTIMIZATION TARGET - Most compute-intensive operation
 *
 * Computes: fourier[2i] = log(re^2 + im^2 + 1e-300) for i=1..n/2
 * Sets:     fourier[2i+1] = 0.0
 * Special:  fourier[1] = log(fourier[1]^2 + 1e-300) (DC component)
 *           fourier[n] = log(fourier[n]^2 + 1e-300) (Nyquist)
 *
 * This replaces lines 128-134 in Sound_to_PowerCepstrogram.cpp
 *
 * @param fourier_samples FFT data (1-based indexed, modified in place)
 * @param num_fourier_samples FFT size
 */
void compute_log_power_spectrum_simd(
    double* fourier_samples,       // Actually samples - 1 (for 1-based access)
    integer num_fourier_samples
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;
    const batch epsilon(1e-300);

    // DC component (fourier[1])
    const double dc = fourier_samples[1];
    fourier_samples[1] = std::log(dc * dc + 1e-300);

    // Process Re/Im pairs: fourier[2], fourier[3], fourier[4], fourier[5], ...
    // For i=1 to n/2-1: fourier[2*i] = Re, fourier[2*i+1] = Im
    const integer half_size = num_fourier_samples / 2;
    
    integer i = 1;

    // SIMD loop - process multiple Re/Im pairs
    // Load Re and Im separately, compute log(re^2 + im^2 + eps)
    for (; i + static_cast<integer>(simd_size) - 1 <= half_size - 1; i += simd_size) {
        // Load Re values: fourier[2], fourier[4], fourier[6], ...
        alignas(32) double re_vals[simd_size];
        alignas(32) double im_vals[simd_size];
        
        for (size_t j = 0; j < simd_size; j++) {
            integer idx = i + static_cast<integer>(j);
            re_vals[j] = fourier_samples[2 * idx];
            im_vals[j] = fourier_samples[2 * idx + 1];
        }
        
        batch re = xsimd::load_aligned(re_vals);
        batch im = xsimd::load_aligned(im_vals);
        
        // Compute re^2 + im^2 + epsilon
        batch re2 = re * re;
        batch im2 = im * im;
        batch power = re2 + im2 + epsilon;
        
        // Compute log
        batch log_power = xsimd::log(power);
        
        // Store results: replace Re with log_power, set Im to 0
        log_power.store_aligned(re_vals);
        
        for (size_t j = 0; j < simd_size; j++) {
            integer idx = i + static_cast<integer>(j);
            fourier_samples[2 * idx] = re_vals[j];
            fourier_samples[2 * idx + 1] = 0.0;
        }
    }

    // Scalar remainder for Re/Im pairs
    for (; i < half_size; i++) {
        const double re = fourier_samples[2 * i];
        const double im = fourier_samples[2 * i + 1];
        fourier_samples[2 * i] = std::log(re * re + im * im + 1e-300);
        fourier_samples[2 * i + 1] = 0.0;
    }

    // Nyquist component (fourier[num_fourier_samples])
    const double nyquist = fourier_samples[num_fourier_samples];
    fourier_samples[num_fourier_samples] = std::log(nyquist * nyquist + 1e-300);
}

/**
 * Compute final power cepstrum values (SIMD)
 *
 * Computes: power[i] = (fourier[i] * df)^2
 * This replaces lines 140-142 in Sound_to_PowerCepstrogram.cpp
 *
 * @param fourier_samples Inverse FFT result (1-based indexed)
 * @param power_cepstrum Output power cepstrum (1-based indexed)
 * @param nx Number of cepstral bins
 * @param df Frequency step scaling factor
 */
void compute_final_power_simd(
    const double* fourier_samples, // Actually samples - 1 (for 1-based access)
    double* power_cepstrum,        // Actually cepstrum - 1 (for 1-based access)
    integer nx,
    double df
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;
    const batch df_batch(df);

    integer i = 1;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) - 1 <= nx; i += simd_size) {
        batch fourier = xsimd::load_unaligned(&fourier_samples[i]);
        batch val = fourier * df_batch;
        batch result = val * val;
        result.store_unaligned(&power_cepstrum[i]);
    }

    // Scalar remainder
    for (; i <= nx; i++) {
        const double val = fourier_samples[i] * df;
        power_cepstrum[i] = val * val;
    }
}

#else  // !HAVE_XSIMD

// Scalar fallbacks when SIMD is not available

void extract_frame_simd(
    const double* input_signal,
    double* output_frame,
    integer start_sample,
    integer frame_size,
    integer input_nx
) {
    for (integer i = 1; i <= frame_size; i++) {
        integer sample_idx = start_sample + i - 1;
        output_frame[i] = (sample_idx > 0 && sample_idx <= input_nx) 
                          ? input_signal[sample_idx] : 0.0;
    }
}

void window_multiply_inplace_simd(
    double* frame,
    const double* window,
    integer frame_size
) {
    for (integer i = 1; i <= frame_size; i++) {
        frame[i] *= window[i];
    }
}

void compute_log_power_spectrum_simd(
    double* fourier_samples,
    integer num_fourier_samples
) {
    // DC component
    const double dc = fourier_samples[1];
    fourier_samples[1] = std::log(dc * dc + 1e-300);

    // Re/Im pairs
    const integer half_size = num_fourier_samples / 2;
    for (integer i = 1; i < half_size; i++) {
        const double re = fourier_samples[2 * i];
        const double im = fourier_samples[2 * i + 1];
        fourier_samples[2 * i] = std::log(re * re + im * im + 1e-300);
        fourier_samples[2 * i + 1] = 0.0;
    }

    // Nyquist component
    const double nyquist = fourier_samples[num_fourier_samples];
    fourier_samples[num_fourier_samples] = std::log(nyquist * nyquist + 1e-300);
}

void compute_final_power_simd(
    const double* fourier_samples,
    double* power_cepstrum,
    integer nx,
    double df
) {
    for (integer i = 1; i <= nx; i++) {
        const double val = fourier_samples[i] * df;
        power_cepstrum[i] = val * val;
    }
}

#endif  // HAVE_XSIMD

}  // namespace powercepstrogram_simd_direct

// ============================================================================
// C API Bridge Functions
// ============================================================================

extern "C" {

/**
 * Runtime SIMD detection for PowerCepstrogram operations
 *
 * Returns true if:
 * 1. Compiled with HAVE_XSIMD
 * 2. Running on hardware with SIMD support
 * 3. SIMD is not explicitly disabled
 *
 * Can be disabled by setting environment variable:
 * PLADDRR_DISABLE_POWERCEPSTROGRAM_SIMD=1
 */
bool should_use_simd_for_powercepstrogram() {
#ifdef HAVE_XSIMD
    // Check for explicit disable via environment variable
    const char* disable_env = std::getenv("PLADDRR_DISABLE_POWERCEPSTROGRAM_SIMD");
    if (disable_env && std::atoi(disable_env) == 1) {
        return false;
    }
    
    // SIMD is compiled and available
    return true;
#else
    return false;
#endif
}

// Export SIMD functions for Praat integration
void extract_frame_simd(
    const double* input_signal,
    double* output_frame,
    integer start_sample,
    integer frame_size,
    integer input_nx
) {
    powercepstrogram_simd_direct::extract_frame_simd(
        input_signal, output_frame, start_sample, frame_size, input_nx
    );
}

void window_multiply_inplace_simd(
    double* frame,
    const double* window,
    integer frame_size
) {
    powercepstrogram_simd_direct::window_multiply_inplace_simd(
        frame, window, frame_size
    );
}

void compute_log_power_spectrum_simd(
    double* fourier_samples,
    integer num_fourier_samples
) {
    powercepstrogram_simd_direct::compute_log_power_spectrum_simd(
        fourier_samples, num_fourier_samples
    );
}

void compute_final_power_simd(
    const double* fourier_samples,
    double* power_cepstrum,
    integer nx,
    double df
) {
    powercepstrogram_simd_direct::compute_final_power_simd(
        fourier_samples, power_cepstrum, nx, df
    );
}

}  // extern "C"

// ============================================================================
// R Bridge for Testing (Optional)
// ============================================================================

// [[Rcpp::export(.should_use_simd_for_powercepstrogram_bridge)]]
bool should_use_simd_for_powercepstrogram_bridge() {
    return should_use_simd_for_powercepstrogram();
}
