// fft_simd.cpp - SIMD-accelerated FFT operations
// Part of pladdrr v1.1.0 expansion - Phase 4.1
// SIMD optimization for FFT using RcppXsimd

#include <Rcpp.h>
#include <complex>
#include <cmath>

#ifdef RCPPXSIMD_XSIMD_HPP
#include <xsimd/xsimd.hpp>

namespace fft_simd {

using batch = xsimd::batch<double>;
constexpr size_t simd_size = batch::size;

// SIMD-accelerated twiddle factor computation
void compute_twiddle_factors_simd(
    std::complex<double>* twiddles,
    size_t n,
    bool inverse
) {
    double sign = inverse ? 1.0 : -1.0;
    size_t i = 0;
    
    batch two_pi(2.0 * M_PI * sign);
    batch n_batch((double)n);
    
    for (; i + simd_size <= n; i += simd_size) {
        // Create index batch
        alignas(32) double indices[simd_size];
        for (size_t j = 0; j < simd_size; ++j) {
            indices[j] = (double)(i + j);
        }
        batch idx = batch::load_aligned(indices);
        
        // Compute angles: -2π*k/n
        batch angles = two_pi * idx / n_batch;
        
        // Compute cos and sin
        batch cos_vals = xsimd::cos(angles);
        batch sin_vals = xsimd::sin(angles);
        
        // Store as complex numbers
        alignas(32) double cos_out[simd_size];
        alignas(32) double sin_out[simd_size];
        cos_vals.store_aligned(cos_out);
        sin_vals.store_aligned(sin_out);
        
        for (size_t j = 0; j < simd_size; ++j) {
            twiddles[i + j] = std::complex<double>(cos_out[j], sin_out[j]);
        }
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        double angle = sign * 2.0 * M_PI * i / n;
        twiddles[i] = std::complex<double>(cos(angle), sin(angle));
    }
}

// SIMD-accelerated complex multiplication
void complex_multiply_simd(
    const std::complex<double>* a,
    const std::complex<double>* b,
    std::complex<double>* result,
    size_t n
) {
    size_t i = 0;
    
    // Process pairs with SIMD
    for (; i + simd_size <= n * 2; i += simd_size) {
        batch a_batch = batch::load_unaligned((const double*)&a[i/2]);
        batch b_batch = batch::load_unaligned((const double*)&b[i/2]);
        
        // For now, scalar complex multiply (true SIMD complex needs more work)
        alignas(32) double a_vals[simd_size];
        alignas(32) double b_vals[simd_size];
        a_batch.store_aligned(a_vals);
        b_batch.store_aligned(b_vals);
        
        for (size_t j = 0; j < simd_size/2; ++j) {
            double ar = a_vals[2*j];
            double ai = a_vals[2*j+1];
            double br = b_vals[2*j];
            double bi = b_vals[2*j+1];
            
            ((double*)&result[i/2])[2*j] = ar * br - ai * bi;
            ((double*)&result[i/2])[2*j+1] = ar * bi + ai * br;
        }
    }
    
    // Scalar remainder
    for (; i < n * 2; i += 2) {
        size_t idx = i / 2;
        result[idx] = a[idx] * b[idx];
    }
}

// SIMD-accelerated windowing + FFT preparation
void apply_window_and_prepare_simd(
    const double* signal,
    double* windowed,
    const double* window,
    size_t n
) {
    size_t i = 0;
    
    // SIMD window application
    for (; i + simd_size <= n; i += simd_size) {
        batch sig = batch::load_unaligned(&signal[i]);
        batch win = batch::load_unaligned(&window[i]);
        batch result = sig * win;
        result.store_unaligned(&windowed[i]);
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        windowed[i] = signal[i] * window[i];
    }
}

// SIMD-accelerated real FFT (optimized for real-valued signals)
void rfft_simd(
    const double* input,
    std::complex<double>* output,
    size_t n,
    const std::complex<double>* twiddles
) {
    // For real FFT, we only need n/2+1 output values
    // This is 2x faster than complex FFT for real signals
    
    size_t n_out = n / 2 + 1;
    
    // Pack real input as complex (real part only)
    std::vector<std::complex<double>> complex_input(n);
    size_t i = 0;
    
    batch zero(0.0);
    for (; i + simd_size <= n; i += simd_size) {
        batch real_part = batch::load_unaligned(&input[i]);
        
        alignas(32) double real_vals[simd_size];
        real_part.store_aligned(real_vals);
        
        for (size_t j = 0; j < simd_size; ++j) {
            complex_input[i + j] = std::complex<double>(real_vals[j], 0.0);
        }
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        complex_input[i] = std::complex<double>(input[i], 0.0);
    }
    
    // Perform FFT (would call optimized FFT here)
    // For now, this is a placeholder - full radix-2 FFT implementation
    // would be more complex
    
    // Copy to output (simplified)
    for (size_t i = 0; i < n_out; ++i) {
        output[i] = complex_input[i];
    }
}

// SIMD-accelerated power spectrum calculation
void power_spectrum_simd(
    const std::complex<double>* fft_output,
    double* power,
    size_t n
) {
    size_t i = 0;
    
    // SIMD magnitude squared calculation
    for (; i + simd_size/2 <= n; i += simd_size/2) {
        // Load real and imaginary parts
        alignas(32) double vals[simd_size];
        for (size_t j = 0; j < simd_size/2; ++j) {
            vals[2*j] = fft_output[i+j].real();
            vals[2*j+1] = fft_output[i+j].imag();
        }
        
        batch vals_batch = batch::load_aligned(vals);
        batch squared = vals_batch * vals_batch;
        
        alignas(32) double sq_vals[simd_size];
        squared.store_aligned(sq_vals);
        
        // Sum pairs (real^2 + imag^2)
        for (size_t j = 0; j < simd_size/2; ++j) {
            power[i+j] = sq_vals[2*j] + sq_vals[2*j+1];
        }
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        double re = fft_output[i].real();
        double im = fft_output[i].imag();
        power[i] = re * re + im * im;
    }
}

// SIMD-accelerated inverse FFT scaling
void scale_ifft_simd(
    std::complex<double>* data,
    size_t n
) {
    batch scale(1.0 / n);
    size_t i = 0;
    
    // Scale both real and imaginary parts
    for (; i + simd_size/2 <= n; i += simd_size/2) {
        alignas(32) double vals[simd_size];
        for (size_t j = 0; j < simd_size/2; ++j) {
            vals[2*j] = data[i+j].real();
            vals[2*j+1] = data[i+j].imag();
        }
        
        batch vals_batch = batch::load_aligned(vals);
        batch scaled = vals_batch * scale;
        
        alignas(32) double scaled_vals[simd_size];
        scaled.store_aligned(scaled_vals);
        
        for (size_t j = 0; j < simd_size/2; ++j) {
            data[i+j] = std::complex<double>(scaled_vals[2*j], scaled_vals[2*j+1]);
        }
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        data[i] /= n;
    }
}

// SIMD-accelerated spectral magnitude
void spectral_magnitude_simd(
    const std::complex<double>* fft_output,
    double* magnitude,
    size_t n
) {
    size_t i = 0;
    
    for (; i + simd_size/2 <= n; i += simd_size/2) {
        alignas(32) double vals[simd_size];
        for (size_t j = 0; j < simd_size/2; ++j) {
            vals[2*j] = fft_output[i+j].real();
            vals[2*j+1] = fft_output[i+j].imag();
        }
        
        batch vals_batch = batch::load_aligned(vals);
        batch squared = vals_batch * vals_batch;
        
        alignas(32) double sq_vals[simd_size];
        squared.store_aligned(sq_vals);
        
        // sqrt(real^2 + imag^2)
        for (size_t j = 0; j < simd_size/2; ++j) {
            magnitude[i+j] = sqrt(sq_vals[2*j] + sq_vals[2*j+1]);
        }
    }
    
    // Scalar remainder
    for (; i < n; ++i) {
        double re = fft_output[i].real();
        double im = fft_output[i].imag();
        magnitude[i] = sqrt(re * re + im * im);
    }
}

} // namespace fft_simd

#endif // RCPPXSIMD_XSIMD_HPP
