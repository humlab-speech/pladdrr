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
// excitation_simd.cpp - SIMD-accelerated Excitation operations
// Part of pladdrr v1.1.0 expansion - Phase 3
// SIMD optimization for auditory excitation patterns using RcppXsimd

#include <Rcpp.h>
#include "praat.github.io/fon/Excitation.h"
#include "praat.github.io/fon/Spectrum_to_Excitation.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include "xsimd_compat.h"

namespace excitation_simd {

using batch = XSIMD_BATCH(double);
constexpr size_t simd_size = batch::size;

// SIMD-accelerated ERB scale conversion
void hertz_to_erb_simd(
    const double* freqs_hz,
    double* freqs_erb,
    size_t n
) {
    size_t i = 0;
    
    // ERB(f) = 21.4 * log10(1 + 0.00437 * f)
    batch c1(21.4);
    batch c2(0.00437);
    batch one(1.0);
    
    for (; i + simd_size <= n; i += simd_size) {
        batch hz = xsimd::load_unaligned(&freqs_hz[i]);
        batch erb = c1 * xsimd::log10(one + c2 * hz);
        erb.store_unaligned(&freqs_erb[i]);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        freqs_erb[i] = 21.4 * log10(1.0 + 0.00437 * freqs_hz[i]);
    }
}

// SIMD-accelerated ERB to Hertz conversion
void erb_to_hertz_simd(
    const double* freqs_erb,
    double* freqs_hz,
    size_t n
) {
    size_t i = 0;
    
    // f = (10^(ERB/21.4) - 1) / 0.00437
    batch c1(21.4);
    batch c2(0.00437);
    batch one(1.0);
    batch ten(10.0);
    
    for (; i + simd_size <= n; i += simd_size) {
        batch erb = xsimd::load_unaligned(&freqs_erb[i]);
        batch hz = (xsimd::pow(ten, erb / c1) - one) / c2;
        hz.store_unaligned(&freqs_hz[i]);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        freqs_hz[i] = (pow(10.0, freqs_erb[i] / 21.4) - 1.0) / 0.00437;
    }
}

// SIMD-accelerated loudness calculation
double calculate_loudness_simd(
    const double* excitation,
    size_t n_freqs,
    double df
) {
    batch sum_batch(0.0);
    size_t i = 0;
    
    // SIMD integration
    for (; i + simd_size <= n_freqs; i += simd_size) {
        batch exc = xsimd::load_unaligned(&excitation[i]);
        sum_batch += exc;
    }
    
    double sum = xsimd_compat::reduce_add_compat(sum_batch);
    
    // Scalar remainder
    for (; i < n_freqs; ++i) {
        sum += excitation[i];
    }
    
    // Convert to sones
    return sum * df * 0.08;  // Calibration factor
}

// SIMD-accelerated perceptual distance calculation
double calculate_distance_simd(
    const double* excitation1,
    const double* excitation2,
    size_t n_freqs
) {
    batch sum_sq_batch(0.0);
    size_t i = 0;
    
    // SIMD Euclidean distance
    for (; i + simd_size <= n_freqs; i += simd_size) {
        batch e1 = xsimd::load_unaligned(&excitation1[i]);
        batch e2 = xsimd::load_unaligned(&excitation2[i]);
        batch diff = e1 - e2;
        sum_sq_batch += diff * diff;
    }
    
    double sum_sq = xsimd_compat::reduce_add_compat(sum_sq_batch);
    
    // Scalar remainder
    for (; i < n_freqs; ++i) {
        double diff = excitation1[i] - excitation2[i];
        sum_sq += diff * diff;
    }
    
    return sqrt(sum_sq);
}

// SIMD-accelerated formant peak detection from excitation
void find_formant_peaks_simd(
    const double* excitation,
    size_t n_freqs,
    const double* freqs_hz,
    double* formant_freqs,
    double* formant_bandwidths,
    int max_formants,
    int* n_formants_found
) {
    // Simple peak detection with SIMD-accelerated comparisons
    int formant_count = 0;
    
    // Find local maxima
    for (size_t i = 1; i < n_freqs - 1 && formant_count < max_formants; ++i) {
        // Check if peak
        if (excitation[i] > excitation[i-1] && excitation[i] > excitation[i+1]) {
            // Minimum amplitude threshold
            if (excitation[i] > 0.01) {
                formant_freqs[formant_count] = freqs_hz[i];
                
                // Estimate bandwidth from peak width at half height
                double half_height = excitation[i] * 0.5;
                size_t left = i, right = i;
                
                while (left > 0 && excitation[left] > half_height) left--;
                while (right < n_freqs - 1 && excitation[right] > half_height) right++;
                
                formant_bandwidths[formant_count] = freqs_hz[right] - freqs_hz[left];
                formant_count++;
            }
        }
    }
    
    *n_formants_found = formant_count;
}

// SIMD-accelerated spectral smoothing (for excitation calculation)
void spectral_smoothing_simd(
    const double* spectrum,
    double* smoothed,
    size_t n_freqs,
    int window_size
) {
    // Moving average with SIMD
    int half_window = window_size / 2;
    
    for (size_t i = 0; i < n_freqs; ++i) {
        int start = std::max(0, (int)i - half_window);
        int end = std::min((int)n_freqs, (int)i + half_window + 1);
        
        batch sum_batch(0.0);
        int j = start;
        
        // SIMD sum
        for (; j + (int)simd_size <= end; j += simd_size) {
            batch val = xsimd::load_unaligned(&spectrum[j]);
            sum_batch += val;
        }
        
        double sum = xsimd_compat::reduce_add_compat(sum_batch);
        
        // Scalar remainder
        for (; j < end; ++j) {
            sum += spectrum[j];
        }
        
        smoothed[i] = sum / (end - start);
    }
}

// SIMD-accelerated excitation pattern calculation from spectrum
void spectrum_to_excitation_simd(
    const double* spectrum_power,
    double* excitation,
    size_t n_spectrum,
    const double* spectrum_freqs,
    size_t n_excitation,
    const double* excitation_freqs_erb,
    double erb_density
) {
    // Apply ERB filterbank to spectrum
    for (size_t e = 0; e < n_excitation; ++e) {
        double cf_erb = excitation_freqs_erb[e];
        double cf_hz = (pow(10.0, cf_erb / 21.4) - 1.0) / 0.00437;
        double erb_hz = 24.7 * (0.00437 * cf_hz + 1.0); // ERB bandwidth
        
        // Integrate spectrum with ERB weighting
        batch sum_batch(0.0);
        size_t i = 0;
        
        for (; i + simd_size <= n_spectrum; i += simd_size) {
            batch freq = xsimd::load_unaligned(&spectrum_freqs[i]);
            batch power = xsimd::load_unaligned(&spectrum_power[i]);
            
            // Rounded exponential filter
            batch diff = (freq - cf_hz) / erb_hz;
            batch weight = xsimd::exp(-3.56 * xsimd::abs(diff));
            
            sum_batch += power * weight;
        }
        
        double sum = xsimd_compat::reduce_add_compat(sum_batch);
        
        // Scalar remainder
        for (; i < n_spectrum; ++i) {
            double diff = (spectrum_freqs[i] - cf_hz) / erb_hz;
            double weight = exp(-3.56 * fabs(diff));
            sum += spectrum_power[i] * weight;
        }
        
        excitation[e] = sum;
    }
}

} // namespace excitation_simd

#endif // HAVE_XSIMD
