// cochleagram_simd.cpp - SIMD-accelerated Cochleagram operations
// Part of pladdrr v1.1.0 expansion - Phase 3
// SIMD optimization for auditory modeling using RcppXsimd

#include <Rcpp.h>
#include "praat.github.io/fon/Cochleagram.h"
#include "praat.github.io/fon/Sound_to_Cochleagram.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>

namespace cochleagram_simd {

using batch = xsimd::batch<double>;
constexpr size_t simd_size = batch::size;

// SIMD-accelerated filter bank processing for auditory filters
void apply_filters_simd(
    const double* input,
    double* output,
    size_t n_samples,
    size_t n_filters,
    const double* center_freqs,
    const double* bandwidths,
    double sample_rate
) {
    // Process each filter
    for (size_t f = 0; f < n_filters; ++f) {
        double cf = center_freqs[f];
        double bw = bandwidths[f];
        
        // Filter coefficients for second-order gammatone-like filter
        double omega = 2.0 * NUMpi * cf / sample_rate;
        double alpha = exp(-2.0 * NUMpi * bw / sample_rate);
        
        // Biquad coefficients
        double b0 = (1.0 - alpha) * (1.0 - alpha);
        double a1 = 2.0 * alpha * cos(omega);
        double a2 = -alpha * alpha;
        
        // State variables
        double x1 = 0.0, x2 = 0.0;
        double y1 = 0.0, y2 = 0.0;
        
        // Process samples with SIMD
        size_t i = 0;
        double* filter_out = &output[f * n_samples];
        
        // SIMD processing (4-8 samples at once)
        for (; i + simd_size <= n_samples; i += simd_size) {
            batch x_batch = batch::load_unaligned(&input[i]);
            
            // For each sample in batch (must be done sequentially for IIR)
            alignas(32) double temp[simd_size];
            x_batch.store_aligned(temp);
            
            for (size_t j = 0; j < simd_size; ++j) {
                double x0 = temp[j];
                double y0 = b0 * x0 + a1 * y1 + a2 * y2;
                
                x2 = x1; x1 = x0;
                y2 = y1; y1 = y0;
                
                filter_out[i + j] = y0;
            }
        }
        
        // Scalar remainder
        for (; i < n_samples; ++i) {
            double x0 = input[i];
            double y0 = b0 * x0 + a1 * y1 + a2 * y2;
            
            x2 = x1; x1 = x0;
            y2 = y1; y1 = y0;
            
            filter_out[i] = y0;
        }
    }
}

// SIMD-accelerated forward masking (temporal integration)
void apply_forward_masking_simd(
    double* cochleagram,
    size_t n_times,
    size_t n_freqs,
    double masking_time,
    double dt
) {
    double decay = exp(-dt / masking_time);
    
    // Process each frequency channel
    for (size_t f = 0; f < n_freqs; ++f) {
        double* channel = &cochleagram[f * n_times];
        
        // Forward pass with temporal masking
        double mask_level = 0.0;
        size_t i = 0;
        
        // SIMD-accelerated processing
        batch decay_batch(decay);
        batch mask_batch(0.0);
        
        for (; i + simd_size <= n_times; i += simd_size) {
            batch signal = batch::load_unaligned(&channel[i]);
            
            // Process sequentially for temporal dependency
            alignas(32) double sig_temp[simd_size];
            signal.store_aligned(sig_temp);
            
            for (size_t j = 0; j < simd_size; ++j) {
                mask_level = mask_level * decay + sig_temp[j];
                sig_temp[j] = mask_level;
            }
            
            batch result = batch::load_aligned(sig_temp);
            result.store_unaligned(&channel[i]);
        }
        
        // Scalar remainder
        for (; i < n_times; ++i) {
            mask_level = mask_level * decay + channel[i];
            channel[i] = mask_level;
        }
    }
}

// SIMD-accelerated Bark scale conversion
void hertz_to_bark_simd(
    const double* freqs_hz,
    double* freqs_bark,
    size_t n
) {
    size_t i = 0;
    
    // SIMD processing
    batch c1(26.81);
    batch c2(1960.0);
    batch c3(7.0);
    
    for (; i + simd_size <= n; i += simd_size) {
        batch hz = batch::load_unaligned(&freqs_hz[i]);
        // Bark = 26.81 * hz / (1960 + hz) - 0.53
        // Approximation: 7 * asinh(hz / 650)
        batch bark = c3 * xsimd::asinh(hz / 650.0);
        bark.store_unaligned(&freqs_bark[i]);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        freqs_bark[i] = 7.0 * asinh(freqs_hz[i] / 650.0);
    }
}

// SIMD-accelerated loudness calculation (integration across Bark scale)
double calculate_loudness_simd(
    const double* excitation,
    size_t n_freqs,
    double df_bark
) {
    batch sum_batch(0.0);
    size_t i = 0;
    
    // SIMD sum
    for (; i + simd_size <= n_freqs; i += simd_size) {
        batch exc = batch::load_unaligned(&excitation[i]);
        sum_batch += exc;
    }
    
    double sum = xsimd::reduce_add(sum_batch);
    
    // Scalar remainder
    for (; i < n_freqs; ++i) {
        sum += excitation[i];
    }
    
    // Convert to sones (approximate)
    return sum * df_bark;
}

// SIMD-accelerated matrix operations for cochleagram
void cochleagram_difference_simd(
    const double* cochlea1,
    const double* cochlea2,
    double* diff,
    size_t n_elements
) {
    size_t i = 0;
    batch sum_sq_batch(0.0);
    
    // SIMD squared difference
    for (; i + simd_size <= n_elements; i += simd_size) {
        batch c1 = batch::load_unaligned(&cochlea1[i]);
        batch c2 = batch::load_unaligned(&cochlea2[i]);
        batch d = c1 - c2;
        sum_sq_batch += d * d;
    }
    
    double sum_sq = xsimd::reduce_add(sum_sq_batch);
    
    // Scalar remainder
    for (; i < n_elements; ++i) {
        double d = cochlea1[i] - cochlea2[i];
        sum_sq += d * d;
    }
    
    // Store result
    *diff = sqrt(sum_sq / n_elements);
}

} // namespace cochleagram_simd

#endif // HAVE_XSIMD
