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
// pitch_simd_bridge.cpp - Bridge between SIMD autocorrelation and Praat pitch extraction
// Part of Phase 1, Task 1.1: Pitch Extraction Integration
// Updated: 2026-01-20 - Direct memory access for Sound_to_Pitch integration

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat.github.io/melder/melder.h"
#include "praat.github.io/fon/Sound.h"
#include "simd_utils.h"

using namespace Rcpp;

// Forward declarations of SIMD functions from autocorrelation_simd.cpp
#ifdef HAVE_XSIMD
extern NumericVector autocorrelation_simd(NumericVector data, int max_lag);
extern NumericVector autocorrelation_normalized_simd(NumericVector data, int max_lag);
extern double cross_correlation_simd(NumericVector x, NumericVector y);
#endif

// Bridge function 1: Autocorrelation for Praat VEC format
// Converts Praat's VEC to Rcpp NumericVector, calls SIMD, converts back
extern "C" void NUMautocorrelation_simd_bridge(
    constVEC const& signal,
    VEC const& autocorr_result,
    integer lag_min,
    integer lag_max
) {
#ifdef HAVE_XSIMD
    const integer n = signal.size;
    const int max_lag = static_cast<int>(lag_max - lag_min);
    
    // Convert Praat VEC to Rcpp NumericVector
    // Note: Praat uses 1-based indexing, Rcpp uses 0-based
    NumericVector rcpp_signal(n);
    for (integer i = 1; i <= n; i++) {
        rcpp_signal[i-1] = signal[i];
    }
    
    // Call SIMD autocorrelation
    NumericVector rcpp_result = autocorrelation_simd(rcpp_signal, max_lag);
    
    // Convert back to Praat VEC
    for (integer lag = lag_min; lag <= lag_max; lag++) {
        autocorr_result[lag] = rcpp_result[lag - lag_min];
    }
#else
    // Fallback to Praat's scalar implementation
    // This would be called from NUM.cpp if SIMD not available
    Melder_throw(U"SIMD not available - should not reach here");
#endif
}

// Bridge function 2: Normalized autocorrelation for pitch detection
// Used in Sound_to_Pitch_ac
extern "C" void NUMautocorrelation_normalized_simd_bridge(
    constVEC const& signal,
    VEC const& autocorr_result,
    integer max_lag
) {
#ifdef HAVE_XSIMD
    const integer n = signal.size;
    
    // Convert to Rcpp
    NumericVector rcpp_signal(n);
    for (integer i = 1; i <= n; i++) {
        rcpp_signal[i-1] = signal[i];
    }
    
    // Call SIMD
    NumericVector rcpp_result = autocorrelation_normalized_simd(
        rcpp_signal, 
        static_cast<int>(max_lag)
    );
    
    // Convert back (0-lag to max_lag)
    for (integer lag = 0; lag <= max_lag; lag++) {
        autocorr_result[lag] = rcpp_result[lag];
    }
#else
    Melder_throw(U"SIMD not available - should not reach here");
#endif
}

// Bridge function 3: Cross-correlation for pitch detection
// Used in Sound_to_Pitch_cc
extern "C" double NUMcrosscorrelation_simd_bridge(
    constVEC const& x,
    constVEC const& y
) {
#ifdef HAVE_XSIMD
    if (x.size != y.size) {
        Melder_throw(U"Vectors must have same size for cross-correlation");
    }
    
    const integer n = x.size;
    
    // Convert to Rcpp
    NumericVector rcpp_x(n), rcpp_y(n);
    for (integer i = 1; i <= n; i++) {
        rcpp_x[i-1] = x[i];
        rcpp_y[i-1] = y[i];
    }
    
    // Call SIMD
    return cross_correlation_simd(rcpp_x, rcpp_y);
#else
    Melder_throw(U"SIMD not available - should not reach here");
    return 0.0;  // Unreachable
#endif
}

// Bridge function 4: Frame-based autocorrelation for efficient pitch tracking
// Processes multiple frames at once - more efficient than per-frame calls
extern "C" void NUMautocorrelation_frames_simd_bridge(
    constMAT const& frames,        // [n_frames][frame_length]
    MAT const& autocorr_results,   // [n_frames][max_lag+1]
    integer max_lag
) {
#ifdef HAVE_XSIMD
    const integer n_frames = frames.nrow;
    const integer frame_length = frames.ncol;
    
    // Process each frame
    for (integer iframe = 1; iframe <= n_frames; iframe++) {
        constVEC frame = frames.row(iframe);
        VEC result = autocorr_results.row(iframe);
        
        // Convert to Rcpp
        NumericVector rcpp_frame(frame_length);
        for (integer i = 1; i <= frame_length; i++) {
            rcpp_frame[i-1] = frame[i];
        }
        
        // Call SIMD
        NumericVector rcpp_result = autocorrelation_simd(
            rcpp_frame, 
            static_cast<int>(max_lag)
        );
        
        // Convert back
        for (integer lag = 0; lag <= max_lag; lag++) {
            result[lag] = rcpp_result[lag];
        }
    }
#else
    Melder_throw(U"SIMD not available - should not reach here");
#endif
}

// Utility: Check if SIMD should be used
// This respects the R option speaker.use_simd
bool should_use_simd_for_pitch() {
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

// ============================================================================
// Direct SIMD implementation for Sound_to_Pitch integration
// This avoids Rcpp overhead for maximum performance
// ============================================================================

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

namespace simd_bridge_direct {

#ifdef HAVE_XSIMD

// Direct SIMD autocorrelation without Rcpp conversion overhead
void autocorrelation_direct(
    const double* signal,
    double* result,
    int n,
    int max_lag
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    // Compute autocorrelation for each lag
    for (int lag = 0; lag <= max_lag; lag++) {
        const double* x1 = signal;
        const double* x2 = signal + lag;
        int count = n - lag;
        
        // SIMD accumulation
        batch acc(0.0);
        int i = 0;
        
        for (; i + static_cast<int>(simd_size) <= count; i += simd_size) {
            batch a = xsimd::load_unaligned(&x1[i]);
            batch b = xsimd::load_unaligned(&x2[i]);
            acc = xsimd::fma(a, b, acc);  // acc += a * b
        }
        
        double sum = xsimd::reduce_add(acc);
        
        // Scalar remainder
        for (; i < count; i++) {
            sum += x1[i] * x2[i];
        }
        
        result[lag] = sum;
    }
}

// SIMD-accelerated power spectrum accumulation for AC method
// This replaces lines 154-157 in Sound_to_Pitch.cpp
void accumulate_power_spectrum_simd(
    constMAT const& frame,    // FFT result [channels][nsampFFT]
    VEC const& ac,            // Output power spectrum accumulator
    integer nsampFFT,
    integer ny                // Number of channels
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    // DC component (line 154)
    ac[1] = 0.0;
    for (integer channel = 1; channel <= ny; channel++) {
        ac[1] += frame[channel][1] * frame[channel][1];
    }
    
    // Power spectrum: sum Re^2 + Im^2 across channels (lines 155-156)
    // Complex pairs are stored as [Re, Im, Re, Im, ...]
    integer i = 2;
    for (; i + static_cast<integer>(simd_size * 2) <= nsampFFT; i += simd_size * 2) {
        // Accumulate power for each lane using scalar approach
        alignas(32) double sum_array[8] = {0.0};
        
        for (integer channel = 1; channel <= ny; channel++) {
            // Load real and imaginary parts
            for (size_t k = 0; k < simd_size; ++k) {
                integer idx = i + k * 2;
                double re = frame[channel][idx];
                double im = frame[channel][idx + 1];
                sum_array[k] += re * re + im * im;
            }
        }
        
        // Store power spectrum values (only even indices hold power)
        for (size_t k = 0; k < simd_size; ++k) {
            ac[i + k * 2] = sum_array[k];
        }
    }
    
    // Scalar remainder for remaining complex pairs
    for (; i < nsampFFT; i += 2) {
        ac[i] = 0.0;
        for (integer channel = 1; channel <= ny; channel++) {
            ac[i] += frame[channel][i] * frame[channel][i] + 
                     frame[channel][i+1] * frame[channel][i+1];
        }
    }
    
    // Nyquist frequency (line 157)
    ac[nsampFFT] = 0.0;
    for (integer channel = 1; channel <= ny; channel++) {
        ac[nsampFFT] += frame[channel][nsampFFT] * frame[channel][nsampFFT];
    }
}

// SIMD-accelerated FCC cross-correlation inner loop
// This accelerates the innermost loop in Sound_to_Pitch.cpp lines 137-141
void compute_fcc_product_simd(
    const double* amp,        // Signal pointer (already offset)
    double localMean,         // Mean to subtract
    integer lag,              // Current lag
    integer nsamp_window,     // Window length
    longdouble& product       // Output accumulator
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;
    
    batch mean_batch(localMean);
    batch prod_acc(0.0);
    
    integer j = 1;
    for (; j + static_cast<integer>(simd_size) <= nsamp_window; j += simd_size) {
        batch x = xsimd::load_unaligned(&amp[j]);
        batch y = xsimd::load_unaligned(&amp[lag + j]);
        
        x = x - mean_batch;
        y = y - mean_batch;
        
        prod_acc = xsimd::fma(x, y, prod_acc);
    }
    
    product += xsimd::reduce_add(prod_acc);
    
    // Scalar remainder
    for (; j <= nsamp_window; j++) {
        double x = amp[j] - localMean;
        double y = amp[lag + j] - localMean;
        product += x * y;
    }
}

#endif // HAVE_XSIMD

} // namespace simd_bridge_direct

// High-performance bridge using direct memory access
extern "C" void NUMautocorrelation_simd_bridge_fast(
    constVEC const& signal,
    VEC const& autocorr_result,
    integer lag_min,
    integer lag_max
) {
#ifdef HAVE_XSIMD
    const integer n = signal.size;
    const int max_lag = static_cast<int>(lag_max - lag_min);
    
    // Use direct memory access (Praat VECs are contiguous)
    // Note: Praat uses 1-based indexing, so &signal[1] is first element
    const double* signal_ptr = &signal[1];
    double* result_ptr = &autocorr_result[lag_min];
    
    simd_bridge_direct::autocorrelation_direct(
        signal_ptr,
        result_ptr,
        static_cast<int>(n),
        max_lag
    );
#else
    Melder_throw(U"SIMD not available - should not reach here");
#endif
}
