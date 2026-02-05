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
// spectrogram_simd.cpp - SIMD optimizations for spectrogram generation
// Part of Phase 2, Task 2.1: Spectrogram SIMD
// Created: 2026-01-21

#include <Rcpp.h>
#include "praat.github.io/melder/melder.h"
#include "praat.github.io/fon/Sound.h"
#include "simd_utils.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

// Direct SIMD namespace for Praat integration (no Rcpp overhead)
namespace spectrogram_simd_direct {

#ifdef HAVE_XSIMD

/**
 * Extract frame from signal and apply window in single pass (SIMD)
 *
 * Combines frame extraction and windowing for better cache utilization:
 * output[j] = signal[startSample + j] * window[j]
 *
 * @param signal Praat sound channel data (1-based indexed)
 * @param window Window coefficients (1-based indexed, precomputed)
 * @param output Output windowed frame (1-based indexed)
 * @param startSample Starting position in signal (1-based Praat index)
 * @param nsamp_window Number of samples in window
 */
void extract_and_window_frame_simd(
    const double* signal,     // Actually signal - 1 (for 1-based access)
    const double* window,     // Actually window - 1 (for 1-based access)
    double* output,           // Actually output - 1 (for 1-based access)
    integer startSample,      // Praat 1-based index
    integer nsamp_window
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    // Convert to 0-based pointers for SIMD loop
    const double* sig_ptr = &signal[startSample];  // Points to first sample
    const double* win_ptr = &window[1];            // Points to first window coefficient
    double* out_ptr = &output[1];                  // Points to first output

    integer i = 0;

    // SIMD loop: process simd_size elements at a time
    for (; i + static_cast<integer>(simd_size) <= nsamp_window; i += simd_size) {
        batch sig = xsimd::load_unaligned(&sig_ptr[i]);
        batch win = xsimd::load_unaligned(&win_ptr[i]);
        batch result = sig * win;
        result.store_unaligned(&out_ptr[i]);
    }

    // Scalar remainder
    for (; i < nsamp_window; i++) {
        out_ptr[i] = sig_ptr[i] * win_ptr[i];
    }
}

/**
 * Compute power spectrum from complex FFT output (SIMD)
 *
 * Praat FFT output format:
 * - data[1]: DC component (real)
 * - data[2..nsampFFT-1]: Re/Im pairs: [Re2, Im2, Re3, Im3, ...]
 * - data[nsampFFT]: Nyquist frequency (real)
 *
 * Power spectrum:
 * - spectrum[1] = data[1]^2 (DC)
 * - spectrum[i] = Re^2 + Im^2 for i=2..half_nsampFFT
 * - spectrum[half_nsampFFT+1] = data[nsampFFT]^2 (Nyquist)
 *
 * This function accumulates power across multiple channels.
 *
 * @param data Complex FFT output from NUMfft_forward (1-based)
 * @param spectrum Accumulated power spectrum (1-based)
 * @param half_nsampFFT Half of FFT size
 * @param nsampFFT Full FFT size
 */
void accumulate_power_spectrum_simd(
    const double* data,       // Actually data - 1 (for 1-based access)
    double* spectrum,         // Actually spectrum - 1 (for 1-based access)
    integer half_nsampFFT,
    integer nsampFFT
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    // DC component (line 183 in original)
    spectrum[1] += data[1] * data[1];

    // Process Re/Im pairs for frequencies 2..half_nsampFFT (lines 184-185)
    // data layout: [Re2, Im2, Re3, Im3, ...] starting at data[2]
    // spectrum[i] += data[2*(i-1)]^2 + data[2*(i-1)+1]^2

    integer i = 2;

    // SIMD loop - process multiple frequency bins
    // Note: Each frequency bin needs 2 values (Re, Im) from data
    for (; i + static_cast<integer>(simd_size) <= half_nsampFFT; i += simd_size) {
        // For each SIMD lane, compute power for one frequency bin
        alignas(32) double powers[8];  // Max batch size is 8 (AVX-512)

        for (size_t lane = 0; lane < simd_size && i + lane <= half_nsampFFT; ++lane) {
            integer idx = i + lane;
            integer data_idx = idx + idx - 2;  // Maps spectrum[i] to data[2*(i-1)]
            double re = data[data_idx];
            double im = data[data_idx + 1];
            powers[lane] = re * re + im * im;
        }

        // Load current spectrum values
        batch spec_vals = xsimd::load_unaligned(&spectrum[i]);
        // Add computed powers
        batch new_powers = xsimd::load_unaligned(powers);
        spec_vals = spec_vals + new_powers;
        // Store back
        spec_vals.store_unaligned(&spectrum[i]);
    }

    // Scalar remainder
    for (; i <= half_nsampFFT; i++) {
        integer data_idx = i + i - 2;
        spectrum[i] += data[data_idx] * data[data_idx] +
                       data[data_idx + 1] * data[data_idx + 1];
    }

    // Nyquist frequency (line 186 in original)
    spectrum[half_nsampFFT + 1] += data[nsampFFT] * data[nsampFFT];
}

/**
 * Zero-fill the tail of FFT input after windowed frame (SIMD)
 *
 * @param data FFT input buffer (1-based)
 * @param start_index Starting index for zeroing (1-based)
 * @param nsampFFT Total FFT size
 */
void zero_fft_tail_simd(
    double* data,             // Actually data - 1
    integer start_index,      // Praat 1-based index
    integer nsampFFT
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    const integer count = nsampFFT - start_index + 1;
    if (count <= 0) return;

    double* ptr = &data[start_index];
    batch zero(0.0);

    integer i = 0;
    for (; i + static_cast<integer>(simd_size) <= count; i += simd_size) {
        zero.store_unaligned(&ptr[i]);
    }

    // Scalar remainder
    for (; i < count; i++) {
        ptr[i] = 0.0;
    }
}

#endif // HAVE_XSIMD

} // namespace spectrogram_simd_direct

// C-linkage bridge functions for calling from Praat code
extern "C" {

/**
 * Bridge: Extract and window frame with SIMD
 *
 * @param signal VEC (Praat 1-based vector)
 * @param window VEC (Praat 1-based vector)
 * @param output VEC (Praat 1-based vector)
 * @param startSample Starting sample in signal (1-based)
 * @param nsamp_window Window size
 */
void extract_and_window_frame_simd_bridge(
    constVEC const& signal,
    autoVEC const& window,
    autoVEC const& output,
    integer startSample,
    integer nsamp_window
) {
#ifdef HAVE_XSIMD
    // Pass pointers adjusted for 1-based indexing
    spectrogram_simd_direct::extract_and_window_frame_simd(
        &signal[0],    // signal - 1 (VEC base pointer)
        &window.get()[0],    // window - 1
        &output.get()[0],    // output - 1
        startSample,
        nsamp_window
    );
#else
    // Scalar fallback
    for (integer j = 1, i = startSample; j <= nsamp_window; j++, i++) {
        output.get()[j] = signal[i] * window.get()[j];
    }
#endif
}

/**
 * Bridge: Accumulate power spectrum with SIMD
 *
 * @param data VEC containing complex FFT output (1-based)
 * @param spectrum VEC for accumulated power spectrum (1-based)
 * @param half_nsampFFT Half of FFT size
 * @param nsampFFT Full FFT size
 */
void accumulate_power_spectrum_simd_bridge(
    autoVEC const& data,
    autoVEC const& spectrum,
    integer half_nsampFFT,
    integer nsampFFT
) {
#ifdef HAVE_XSIMD
    spectrogram_simd_direct::accumulate_power_spectrum_simd(
        &data.get()[0],       // data - 1
        &spectrum.get()[0],   // spectrum - 1
        half_nsampFFT,
        nsampFFT
    );
#else
    // Scalar fallback (from Sound_and_Spectrogram.cpp lines 183-186)
    VEC d = data.get();
    VEC s = spectrum.get();
    s[1] += d[1] * d[1];   // DC component
    for (integer i = 2; i <= half_nsampFFT; i++)
        s[i] += d[i + i - 2] * d[i + i - 2] +
                d[i + i - 1] * d[i + i - 1];
    s[half_nsampFFT + 1] += d[nsampFFT] * d[nsampFFT];   // Nyquist
#endif
}

/**
 * Bridge: Zero-fill FFT tail with SIMD
 */
void zero_fft_tail_simd_bridge(
    autoVEC const& data,
    integer start_index,
    integer nsampFFT
) {
#ifdef HAVE_XSIMD
    spectrogram_simd_direct::zero_fft_tail_simd(
        &data.get()[0],
        start_index,
        nsampFFT
    );
#else
    // Scalar fallback
    VEC d = data.get();
    for (integer j = start_index; j <= nsampFFT; j++)
        d[j] = 0.0;
#endif
}

/**
 * Check if SIMD should be used for spectrogram operations
 */
bool should_use_simd_for_spectrogram() {
#ifdef HAVE_XSIMD
    // Check R option for SIMD control
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
        // Default to true on error
    }
    return true;
#else
    return false;
#endif
}

} // extern "C"
