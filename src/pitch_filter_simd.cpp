// pitch_filter_simd.cpp - SIMD optimizations for filtered pitch extraction
// Part of Phase 2, Task 2.3: Bandpass Filter SIMD
// Created: 2026-01-22

#include "praat.github.io/melder/melder.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

// Direct SIMD namespace for Praat integration (no Rcpp overhead)
namespace pitch_filter_simd_direct {

#ifdef HAVE_XSIMD

/**
 * Apply Gaussian low-pass filter to spectrum bins with SIMD
 *
 * Used by Sound_to_Pitch_filteredAc and Sound_to_Pitch_filteredCc
 * for spectral attenuation before pitch extraction.
 *
 * Filter: factor = exp(-0.5 * (frequency / cutoff)^2)
 *
 * @param spectrum_re Real part of spectrum (1-based Praat VEC)
 * @param spectrum_im Imaginary part of spectrum (1-based Praat VEC)
 * @param frequencies Frequency values for each bin (1-based Praat VEC)
 * @param nx Number of spectrum bins
 * @param lowPassCutoff Low-pass cutoff frequency (Hz)
 */
void apply_gaussian_lowpass_to_spectrum_simd(
    double* spectrum_re,        // &spectrum_re[0] for 1-based access
    double* spectrum_im,        // &spectrum_im[0] for 1-based access
    const double* frequencies,  // &frequencies[0] for 1-based access
    integer nx,
    double lowPassCutoff
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    // Precompute constants
    const double inv_cutoff_sq = -0.5 / (lowPassCutoff * lowPassCutoff);
    batch inv_cutoff_sq_batch(inv_cutoff_sq);

    // SIMD loop: process simd_size bins at a time
    integer i = 1;  // 1-based indexing

    for (; i + static_cast<integer>(simd_size) - 1 <= nx; i += simd_size) {
        // Load frequencies
        batch freq = xsimd::load_unaligned(&frequencies[i]);

        // Compute factor = exp(-0.5 * (freq / cutoff)^2)
        // = exp(inv_cutoff_sq * freq^2)
        batch freq_sq = freq * freq;
        batch exponent = inv_cutoff_sq_batch * freq_sq;
        batch factor = xsimd::exp(exponent);

        // Load spectrum real and imaginary parts
        batch re = xsimd::load_unaligned(&spectrum_re[i]);
        batch im = xsimd::load_unaligned(&spectrum_im[i]);

        // Apply filter: spectrum *= factor
        re *= factor;
        im *= factor;

        // Store back
        re.store_unaligned(&spectrum_re[i]);
        im.store_unaligned(&spectrum_im[i]);
    }

    // Scalar remainder
    for (; i <= nx; i++) {
        const double frequency = frequencies[i];
        const double factor = exp(-0.5 * (frequency / lowPassCutoff) * (frequency / lowPassCutoff));
        spectrum_re[i] *= factor;
        spectrum_im[i] *= factor;
    }
}

#endif // HAVE_XSIMD

} // namespace pitch_filter_simd_direct

// C-linkage bridge functions for calling from Praat code
extern "C" {

/**
 * Bridge: Apply Gaussian low-pass filter to spectrum with SIMD
 *
 * @param spectrum_re Real part (Praat VEC)
 * @param spectrum_im Imaginary part (Praat VEC)
 * @param frequencies Precomputed frequency for each bin (Praat VEC)
 * @param lowPassCutoff Cutoff frequency (Hz)
 */
void apply_gaussian_lowpass_to_spectrum_simd_bridge(
    VEC const& spectrum_re,
    VEC const& spectrum_im,
    constVEC const& frequencies,
    double lowPassCutoff
) {
#ifdef HAVE_XSIMD
    const integer nx = spectrum_re.size;

    // Apply SIMD filtering
    pitch_filter_simd_direct::apply_gaussian_lowpass_to_spectrum_simd(
        &spectrum_re[0],
        &spectrum_im[0],
        &frequencies[0],
        nx,
        lowPassCutoff
    );
#else
    // Scalar fallback (matches original Praat logic)
    for (integer ibin = 1; ibin <= spectrum_re.size; ibin++) {
        const double frequency = frequencies[ibin];
        const double factor = exp (-0.5 * (frequency / lowPassCutoff) * (frequency / lowPassCutoff));
        spectrum_re[ibin] *= factor;
        spectrum_im[ibin] *= factor;
    }
#endif
}

/**
 * Check if SIMD should be used for pitch filter operations
 */
bool should_use_simd_for_pitch_filter() {
#ifdef HAVE_XSIMD
    // Check R option for SIMD control (if available)
    // For now, default to true when SIMD is available
    // Can be extended with runtime option checking like spectrogram
    return true;
#else
    return false;
#endif
}

} // extern "C"
