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
// complexspectrogram_simd.cpp - SIMD optimizations for ComplexSpectrogram
// Part of Phase 4, Task 4.3: ComplexSpectrogram SIMD
// Created: 2026-01-24

#include <Rcpp.h>
#include "praat.github.io/melder/melder.h"
#include "simd_utils.h"
#include <cmath>

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include "xsimd_compat.h"
#endif

// =============================================================================
// ComplexSpectrogram SIMD Functions
// =============================================================================
// Key operations:
// 1. Power spectrum: power = re^2 + im^2
// 2. Phase calculation: phase = atan2(im, re)
// 3. Polar to rectangular: re = mag*cos(phase), im = mag*sin(phase)
// 4. Hanning window generation
// =============================================================================

namespace complexspectrogram_simd {

#ifdef HAVE_XSIMD

using batch_double = XSIMD_BATCH(double);
constexpr size_t simd_size = batch_double::size;

/**
 * Compute power and phase from complex spectrum (SIMD)
 *
 * For ComplexSpectrogram, we need both power (magnitude squared) and phase.
 * This is the inner loop of Sound_to_ComplexSpectrogram.
 *
 * @param re_vals Real parts of spectrum (array)
 * @param im_vals Imaginary parts of spectrum (array)
 * @param power_out Power output (re^2 + im^2)
 * @param phase_out Phase output (atan2(im, re))
 * @param n Number of frequency bins
 */
void compute_power_and_phase_simd(
    const double* re_vals,
    const double* im_vals,
    double* power_out,
    double* phase_out,
    integer n
) {
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double re = xsimd::load_unaligned(&re_vals[i]);
        batch_double im = xsimd::load_unaligned(&im_vals[i]);

        // Power: re^2 + im^2
        batch_double power = xsimd::fma(re, re, im * im);
        power.store_unaligned(&power_out[i]);

        // Phase: atan2(im, re)
        batch_double phase = xsimd::atan2(im, re);
        phase.store_unaligned(&phase_out[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        power_out[i] = re_vals[i] * re_vals[i] + im_vals[i] * im_vals[i];
        phase_out[i] = std::atan2(im_vals[i], re_vals[i]);
    }
}

/**
 * Convert polar (magnitude, phase) to rectangular (re, im) - SIMD
 *
 * Used in ComplexSpectrogram_to_Sound and ComplexSpectrogram_to_Spectrum.
 * re = magnitude * cos(phase)
 * im = magnitude * sin(phase)
 *
 * @param magnitudes Input magnitudes (already sqrt'd from power)
 * @param phases Input phases
 * @param re_out Output real parts
 * @param im_out Output imaginary parts
 * @param n Number of elements
 */
void polar_to_rectangular_simd(
    const double* magnitudes,
    const double* phases,
    double* re_out,
    double* im_out,
    integer n
) {
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double mag = xsimd::load_unaligned(&magnitudes[i]);
        batch_double phi = xsimd::load_unaligned(&phases[i]);

        // Compute sin and cos separately
        batch_double sin_phi = xsimd::sin(phi);
        batch_double cos_phi = xsimd::cos(phi);

        batch_double re = mag * cos_phi;
        batch_double im = mag * sin_phi;

        re.store_unaligned(&re_out[i]);
        im.store_unaligned(&im_out[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        re_out[i] = magnitudes[i] * std::cos(phases[i]);
        im_out[i] = magnitudes[i] * std::sin(phases[i]);
    }
}

/**
 * Compute sqrt of power values (SIMD)
 *
 * Used to convert power spectrum to magnitude for resynthesis.
 *
 * @param power Input power values
 * @param magnitude Output magnitude values (sqrt of power)
 * @param n Number of elements
 */
void sqrt_power_to_magnitude_simd(
    const double* power,
    double* magnitude,
    integer n
) {
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double p = xsimd::load_unaligned(&power[i]);
        batch_double m = xsimd::sqrt(p);
        m.store_unaligned(&magnitude[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        magnitude[i] = std::sqrt(power[i]);
    }
}

/**
 * Generate Hanning window coefficients (SIMD)
 *
 * window[i] = 0.5 * (1.0 - cos(2*pi * (i - 0.5) / size))
 *
 * @param window Output window coefficients (0-based array)
 * @param size Window size
 */
void generate_hanning_window_simd(
    double* window,
    integer size
) {
    const double scale = NUM2pi / static_cast<double>(size);
    batch_double half(0.5);
    batch_double one(1.0);

    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= size; i += simd_size) {
        // Create batch of indices: [i+0.5, i+1.5, i+2.5, ...]
        alignas(32) double indices[8];
        for (size_t j = 0; j < simd_size; ++j) {
            indices[j] = (static_cast<double>(i + j) + 0.5) * scale;
        }

        batch_double theta = xsimd::load_aligned(indices);
        batch_double cos_theta = xsimd::cos(theta);
        batch_double w = half * (one - cos_theta);
        w.store_unaligned(&window[i]);
    }

    // Scalar remainder
    for (; i < size; i++) {
        double theta = (static_cast<double>(i) + 0.5) * scale;
        window[i] = 0.5 * (1.0 - std::cos(theta));
    }
}

/**
 * Apply window to signal frame (multiply element-wise) - SIMD
 *
 * @param signal Input signal frame
 * @param window Window coefficients
 * @param output Windowed output
 * @param n Number of samples
 */
void apply_window_simd(
    const double* signal,
    const double* window,
    double* output,
    integer n
) {
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double s = xsimd::load_unaligned(&signal[i]);
        batch_double w = xsimd::load_unaligned(&window[i]);
        batch_double result = s * w;
        result.store_unaligned(&output[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        output[i] = signal[i] * window[i];
    }
}

/**
 * Add scaled synthesis window to output (overlap-add) - SIMD
 *
 * output[i] += scale * synthesis[i]
 *
 * @param output Accumulator buffer
 * @param synthesis Synthesis window to add
 * @param scale Scaling factor (typically 0.5 for overlap-add)
 * @param n Number of samples
 */
void overlap_add_simd(
    double* output,
    const double* synthesis,
    double scale,
    integer n
) {
    batch_double scale_batch(scale);
    integer i = 0;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch_double out = xsimd::load_unaligned(&output[i]);
        batch_double syn = xsimd::load_unaligned(&synthesis[i]);
        out = xsimd::fma(scale_batch, syn, out);
        out.store_unaligned(&output[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        output[i] += scale * synthesis[i];
    }
}

#endif // HAVE_XSIMD

} // namespace complexspectrogram_simd

// =============================================================================
// C-linkage Bridge Functions for Praat Code Integration
// =============================================================================

extern "C" {

/**
 * Check if SIMD should be used for ComplexSpectrogram operations
 */
static bool g_complexspectrogram_simd_enabled = true;

void set_complexspectrogram_simd_enabled(bool enabled) {
    g_complexspectrogram_simd_enabled = enabled;
}

bool get_complexspectrogram_simd_enabled() {
    return g_complexspectrogram_simd_enabled;
}

bool should_use_simd_for_complexspectrogram() {
#ifdef HAVE_XSIMD
    return g_complexspectrogram_simd_enabled;
#else
    return false;
#endif
}

/**
 * Bridge: Compute power and phase from Praat Spectrum z matrix
 *
 * Praat Spectrum format:
 * - z[1][ifreq] = real part
 * - z[2][ifreq] = imaginary part
 *
 * @param spec_re Real part row (z[1])
 * @param spec_im Imaginary part row (z[2])
 * @param power_col Power output column for this frame
 * @param phase_col Phase output column for this frame
 * @param start_freq Starting frequency bin (usually 2)
 * @param end_freq Ending frequency bin (usually numberOfFrequencies-1)
 */
void compute_power_phase_frame_simd_bridge(
    const double* spec_re,    // spec->z[1] - 1 (1-based access)
    const double* spec_im,    // spec->z[2] - 1 (1-based access)
    double* power_col,        // thy z column for this frame
    double* phase_col,        // thy phase column for this frame
    integer start_freq,
    integer end_freq
) {
#ifdef HAVE_XSIMD
    if (!should_use_simd_for_complexspectrogram()) {
        // Scalar fallback
        for (integer ifreq = start_freq; ifreq <= end_freq; ifreq++) {
            double x = spec_re[ifreq];
            double y = spec_im[ifreq];
            power_col[ifreq] = x * x + y * y;
            phase_col[ifreq] = std::atan2(y, x);
        }
        return;
    }

    integer n = end_freq - start_freq + 1;
    if (n <= 0) return;

    // Process with SIMD (adjusting for 1-based indexing)
    complexspectrogram_simd::compute_power_and_phase_simd(
        &spec_re[start_freq],
        &spec_im[start_freq],
        &power_col[start_freq],
        &phase_col[start_freq],
        n
    );
#else
    // Scalar fallback
    for (integer ifreq = start_freq; ifreq <= end_freq; ifreq++) {
        double x = spec_re[ifreq];
        double y = spec_im[ifreq];
        power_col[ifreq] = x * x + y * y;
        phase_col[ifreq] = std::atan2(y, x);
    }
#endif
}

/**
 * Bridge: Convert polar to rectangular for spectrum reconstruction
 *
 * @param power Power values (will sqrt internally)
 * @param phase Phase values
 * @param spec_re Output real parts
 * @param spec_im Output imaginary parts
 * @param start_freq Starting frequency bin
 * @param end_freq Ending frequency bin
 */
void polar_to_rect_spectrum_simd_bridge(
    const double* power,      // power values (1-based)
    const double* phase,      // phase values (1-based)
    double* spec_re,          // output real (1-based)
    double* spec_im,          // output imag (1-based)
    integer start_freq,
    integer end_freq
) {
#ifdef HAVE_XSIMD
    if (!should_use_simd_for_complexspectrogram()) {
        // Scalar fallback
        for (integer ifreq = start_freq; ifreq <= end_freq; ifreq++) {
            double a = std::sqrt(power[ifreq]);
            double phi = phase[ifreq];
            spec_re[ifreq] = a * std::cos(phi);
            spec_im[ifreq] = a * std::sin(phi);
        }
        return;
    }

    integer n = end_freq - start_freq + 1;
    if (n <= 0) return;

    // First compute magnitudes (sqrt of power)
    std::vector<double> magnitudes(n);
    complexspectrogram_simd::sqrt_power_to_magnitude_simd(
        &power[start_freq],
        magnitudes.data(),
        n
    );

    // Then convert polar to rectangular
    complexspectrogram_simd::polar_to_rectangular_simd(
        magnitudes.data(),
        &phase[start_freq],
        &spec_re[start_freq],
        &spec_im[start_freq],
        n
    );
#else
    // Scalar fallback
    for (integer ifreq = start_freq; ifreq <= end_freq; ifreq++) {
        double a = std::sqrt(power[ifreq]);
        double phi = phase[ifreq];
        spec_re[ifreq] = a * std::cos(phi);
        spec_im[ifreq] = a * std::sin(phi);
    }
#endif
}

/**
 * Bridge: Generate Hanning window
 */
void generate_hanning_window_simd_bridge(
    double* window,   // 1-based array (window - 1)
    integer size
) {
#ifdef HAVE_XSIMD
    if (!should_use_simd_for_complexspectrogram()) {
        // Scalar fallback
        for (integer i = 1; i <= size; i++) {
            window[i] = 0.5 * (1.0 - std::cos(NUM2pi * (i - 0.5) / size));
        }
        return;
    }

    // SIMD version (0-based internally, then copy to 1-based)
    std::vector<double> temp(size);
    complexspectrogram_simd::generate_hanning_window_simd(temp.data(), size);

    // Copy to 1-based array
    for (integer i = 0; i < size; i++) {
        window[i + 1] = temp[i];
    }
#else
    // Scalar fallback
    for (integer i = 1; i <= size; i++) {
        window[i] = 0.5 * (1.0 - std::cos(NUM2pi * (i - 0.5) / size));
    }
#endif
}

/**
 * Bridge: Overlap-add for synthesis
 */
void overlap_add_simd_bridge(
    double* output,           // 1-based output buffer
    const double* synthesis,  // 1-based synthesis buffer
    double scale,
    integer start_sample,     // 1-based start
    integer end_sample        // 1-based end
) {
#ifdef HAVE_XSIMD
    if (!should_use_simd_for_complexspectrogram()) {
        // Scalar fallback
        for (integer i = start_sample; i <= end_sample; i++) {
            output[i] += scale * synthesis[i - start_sample + 1];
        }
        return;
    }

    integer n = end_sample - start_sample + 1;
    if (n <= 0) return;

    complexspectrogram_simd::overlap_add_simd(
        &output[start_sample],
        &synthesis[1],
        scale,
        n
    );
#else
    // Scalar fallback
    for (integer i = start_sample; i <= end_sample; i++) {
        output[i] += scale * synthesis[i - start_sample + 1];
    }
#endif
}

} // extern "C"

// =============================================================================
// R-accessible diagnostic function
// =============================================================================

//' Get ComplexSpectrogram SIMD implementation info
//'
//' @return List with SIMD availability and batch size
//' @keywords internal
// [[Rcpp::export(.complexspectrogram_simd_info)]]
Rcpp::List complexspectrogram_simd_info() {
#ifdef HAVE_XSIMD
    return Rcpp::List::create(
        Rcpp::Named("simd_available") = true,
        Rcpp::Named("batch_size") = static_cast<int>(complexspectrogram_simd::batch_double::size),
        Rcpp::Named("architecture") = get_simd_arch(),
        Rcpp::Named("functions") = Rcpp::CharacterVector::create(
            "compute_power_and_phase_simd",
            "polar_to_rectangular_simd",
            "sqrt_power_to_magnitude_simd",
            "generate_hanning_window_simd",
            "apply_window_simd",
            "overlap_add_simd"
        )
    );
#else
    return Rcpp::List::create(
        Rcpp::Named("simd_available") = false,
        Rcpp::Named("batch_size") = 1,
        Rcpp::Named("architecture") = "scalar",
        Rcpp::Named("functions") = Rcpp::CharacterVector()
    );
#endif
}
