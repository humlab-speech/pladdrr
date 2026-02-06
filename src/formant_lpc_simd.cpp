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
// formant_lpc_simd.cpp - SIMD-accelerated Formant/LPC operations
// Part of pladdrr v1.1.0 expansion - Phase 4.2
// SIMD optimization for formant extraction and LPC using RcppXsimd

#include <Rcpp.h>
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Sound_to_Formant.h"
#include "praat.github.io/LPC/LPC.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include "xsimd_compat.h"

namespace formant_lpc_simd {

using batch = XSIMD_BATCH(double);
constexpr size_t simd_size = batch::size;

// SIMD-accelerated autocorrelation for LPC (Burg's algorithm prerequisite)
void autocorrelation_simd(
    const double* signal,
    size_t n,
    double* autocorr,
    int max_lag
) {
    for (int lag = 0; lag <= max_lag; ++lag) {
        batch sum_batch(0.0);
        size_t i = 0;
        
        // SIMD processing
        for (; i + simd_size <= n - lag; i += simd_size) {
            batch x1 = batch::load_unaligned(&signal[i]);
            batch x2 = batch::load_unaligned(&signal[i + lag]);
            sum_batch += x1 * x2;
        }
        
        double sum = xsimd_compat::reduce_add_compat(sum_batch);
        
        // Scalar remainder
        for (; i < n - lag; ++i) {
            sum += signal[i] * signal[i + lag];
        }
        
        autocorr[lag] = sum;
    }
}

// SIMD-accelerated Burg's algorithm for LPC coefficients
void lpc_burg_simd(
    const double* signal,
    size_t n,
    int order,
    double* lpc_coeffs,
    double* reflection_coeffs,
    double* prediction_error
) {
    // Initialize forward and backward prediction errors
    std::vector<double> f(n), b(n);
    
    // Initialize with signal
    size_t i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch sig = batch::load_unaligned(&signal[i]);
        sig.store_unaligned(&f[i]);
        sig.store_unaligned(&b[i]);
    }
    for (; i < n; ++i) {
        f[i] = b[i] = signal[i];
    }
    
    // Burg recursion
    std::vector<double> a(order + 1, 0.0);
    a[0] = 1.0;
    
    double error = 0.0;
    i = 0;
    batch sum_batch(0.0);
    for (; i + simd_size <= n; i += simd_size) {
        batch sig = batch::load_unaligned(&signal[i]);
        sum_batch += sig * sig;
    }
    error = xsimd_compat::reduce_add_compat(sum_batch);
    for (; i < n; ++i) {
        error += signal[i] * signal[i];
    }
    
    for (int m = 0; m < order; ++m) {
        // Calculate reflection coefficient
        batch num_batch(0.0), den_batch(0.0);
        i = m + 1;
        
        for (; i + simd_size <= n; i += simd_size) {
            batch f_batch = batch::load_unaligned(&f[i]);
            batch b_batch = batch::load_unaligned(&b[i - 1]);
            num_batch += f_batch * b_batch;
            den_batch += f_batch * f_batch + b_batch * b_batch;
        }
        
        double num = xsimd_compat::reduce_add_compat(num_batch);
        double den = xsimd_compat::reduce_add_compat(den_batch);
        
        for (; i < n; ++i) {
            num += f[i] * b[i - 1];
            den += f[i] * f[i] + b[i - 1] * b[i - 1];
        }
        
        double k = -2.0 * num / den;
        reflection_coeffs[m] = k;
        
        // Update LPC coefficients
        std::vector<double> a_new(order + 1);
        a_new[0] = 1.0;
        for (int j = 1; j <= m + 1; ++j) {
            a_new[j] = a[j] + k * a[m + 1 - j];
        }
        a = a_new;
        
        // Update prediction errors with SIMD
        if (m < order - 1) {
            batch k_batch(k);
            i = m + 1;
            
            for (; i + simd_size <= n; i += simd_size) {
                batch f_old = batch::load_unaligned(&f[i]);
                batch b_old = batch::load_unaligned(&b[i - 1]);
                
                batch f_new = f_old + k_batch * b_old;
                batch b_new = b_old + k_batch * f_old;
                
                f_new.store_unaligned(&f[i]);
                b_new.store_unaligned(&b[i]);
            }
            
            for (; i < n; ++i) {
                double f_old = f[i];
                double b_old = b[i - 1];
                f[i] = f_old + k * b_old;
                b[i] = b_old + k * f_old;
            }
        }
        
        error *= (1.0 - k * k);
    }
    
    // Copy coefficients (skip a[0] = 1)
    for (int i = 1; i <= order; ++i) {
        lpc_coeffs[i - 1] = -a[i];
    }
    
    *prediction_error = error;
}

// Helper: Evaluate polynomial and its derivatives at a point
// Used by Laguerre's method
static void eval_polynomial_and_derivatives(
    const std::vector<std::complex<double>>& coeffs,
    std::complex<double> x,
    std::complex<double>& p,
    std::complex<double>& p_prime,
    std::complex<double>& p_double_prime
) {
    int n = coeffs.size() - 1;
    p = coeffs[n];
    p_prime = std::complex<double>(0.0, 0.0);
    p_double_prime = std::complex<double>(0.0, 0.0);
    
    for (int i = n - 1; i >= 0; --i) {
        p_double_prime = p_double_prime * x + 2.0 * p_prime;
        p_prime = p_prime * x + p;
        p = p * x + coeffs[i];
    }
}

// Laguerre's method for finding a single polynomial root
// Robust and converges to the nearest root from initial guess
static std::complex<double> laguerre_method(
    const std::vector<std::complex<double>>& coeffs,
    std::complex<double> x0,
    int max_iter = 100,
    double tol = 1e-10
) {
    std::complex<double> x = x0;
    int n = coeffs.size() - 1;
    
    for (int iter = 0; iter < max_iter; ++iter) {
        std::complex<double> p, p_prime, p_double_prime;
        eval_polynomial_and_derivatives(coeffs, x, p, p_prime, p_double_prime);
        
        if (std::abs(p) < tol) {
            return x;  // Converged
        }
        
        // Laguerre's formula
        std::complex<double> G = p_prime / p;
        std::complex<double> H = G * G - p_double_prime / p;
        
        std::complex<double> denom1 = G + std::sqrt(std::complex<double>(n - 1) * (std::complex<double>(n) * H - G * G));
        std::complex<double> denom2 = G - std::sqrt(std::complex<double>(n - 1) * (std::complex<double>(n) * H - G * G));
        
        std::complex<double> denom = (std::abs(denom1) > std::abs(denom2)) ? denom1 : denom2;
        
        if (std::abs(denom) < 1e-14) {
            break;  // Avoid division by zero
        }
        
        std::complex<double> dx = std::complex<double>(n) / denom;
        x = x - dx;
        
        if (std::abs(dx) < tol) {
            return x;  // Converged
        }
    }
    
    return x;
}

// Deflate polynomial by dividing out a root
static void deflate_polynomial(
    std::vector<std::complex<double>>& coeffs,
    std::complex<double> root
) {
    int n = coeffs.size() - 1;
    std::vector<std::complex<double>> new_coeffs(n);
    
    new_coeffs[n - 1] = coeffs[n];
    for (int i = n - 2; i >= 0; --i) {
        new_coeffs[i] = coeffs[i + 1] + root * new_coeffs[i + 1];
    }
    
    coeffs = new_coeffs;
}

// SIMD-accelerated polynomial root finding for formant extraction
// Implements Laguerre's method with polynomial deflation
//
// FIXED (PLADDRR_PERFORMANCE_REQUESTS.md - Issue 2):
// Complete LPC polynomial root finding implementation to fix F1/F2/F3 values
// that were 35-55% too low. Uses Laguerre's method which is robust and accurate.
void find_polynomial_roots_simd(
    const double* lpc_coeffs,
    int order,
    std::complex<double>* roots
) {
    // Build polynomial: 1 + lpc_coeffs[0]*z^-1 + lpc_coeffs[1]*z^-2 + ...
    // Convert to standard form: z^n + a_{n-1}*z^{n-1} + ... + a_0
    std::vector<std::complex<double>> coeffs(order + 1);
    
    // Reverse and negate LPC coefficients
    for (int i = 0; i < order; ++i) {
        coeffs[i] = std::complex<double>(lpc_coeffs[order - 1 - i], 0.0);
    }
    coeffs[order] = std::complex<double>(1.0, 0.0);  // Leading coefficient
    
    // Find all roots using Laguerre's method with deflation
    for (int i = 0; i < order; ++i) {
        // Initial guess on unit circle
        double angle = 2.0 * M_PI * (i + 0.5) / order;
        std::complex<double> x0(std::cos(angle), std::sin(angle));
        
        // Find root using Laguerre's method
        std::complex<double> root = laguerre_method(coeffs, x0);
        roots[i] = root;
        
        // Deflate polynomial to find remaining roots
        if (i < order - 1) {
            deflate_polynomial(coeffs, root);
        }
    }
}

// SIMD-accelerated formant bandwidth estimation
void estimate_bandwidths_simd(
    const std::complex<double>* roots,
    int n_roots,
    double* formant_freqs,
    double* bandwidths,
    int max_formants,
    double sampling_rate,
    int* n_formants
) {
    *n_formants = 0;
    
    // Extract formants from roots in upper half plane
    for (int i = 0; i < n_roots && *n_formants < max_formants; ++i) {
        if (roots[i].imag() > 0) {
            double angle = atan2(roots[i].imag(), roots[i].real());
            double radius = abs(roots[i]);
            
            formant_freqs[*n_formants] = angle * sampling_rate / (2.0 * M_PI);
            bandwidths[*n_formants] = -log(radius) * sampling_rate / M_PI;
            
            (*n_formants)++;
        }
    }
}

// SIMD-accelerated formant tracking (dynamic programming)
void track_formants_simd(
    const double* formant_matrix,  // [n_frames][max_formants]
    int n_frames,
    int max_formants,
    double* tracked_formants,      // Output: [n_frames][max_formants]
    double max_jump_hz
) {
    // Cost matrix for dynamic programming
    std::vector<double> cost(n_frames * max_formants, 0.0);
    std::vector<int> backtrack(n_frames * max_formants, -1);
    
    // Forward pass: compute costs with SIMD
    for (int t = 1; t < n_frames; ++t) {
        for (int f = 0; f < max_formants; ++f) {
            double min_cost = INFINITY;
            int best_prev = -1;
            
            // Find best previous formant
            for (int pf = 0; pf < max_formants; ++pf) {
                double freq_diff = formant_matrix[t * max_formants + f] - 
                                 formant_matrix[(t-1) * max_formants + pf];
                
                // Penalize large jumps
                double jump_penalty = fabs(freq_diff) / max_jump_hz;
                double total_cost = cost[(t-1) * max_formants + pf] + jump_penalty;
                
                if (total_cost < min_cost) {
                    min_cost = total_cost;
                    best_prev = pf;
                }
            }
            
            cost[t * max_formants + f] = min_cost;
            backtrack[t * max_formants + f] = best_prev;
        }
    }
    
    // Backward pass: extract optimal path
    std::vector<int> path(n_frames);
    
    // Find best final formant
    double min_final_cost = INFINITY;
    int best_final = 0;
    for (int f = 0; f < max_formants; ++f) {
        if (cost[(n_frames - 1) * max_formants + f] < min_final_cost) {
            min_final_cost = cost[(n_frames - 1) * max_formants + f];
            best_final = f;
        }
    }
    
    path[n_frames - 1] = best_final;
    for (int t = n_frames - 2; t >= 0; --t) {
        path[t] = backtrack[(t + 1) * max_formants + path[t + 1]];
    }
    
    // Copy tracked formants
    for (int t = 0; t < n_frames; ++t) {
        for (int f = 0; f < max_formants; ++f) {
            if (f == path[t]) {
                tracked_formants[t * max_formants + f] = 
                    formant_matrix[t * max_formants + f];
            } else {
                tracked_formants[t * max_formants + f] = 0.0;
            }
        }
    }
}

// SIMD-accelerated median filter for formant smoothing
void median_filter_formants_simd(
    const double* formants,
    double* smoothed,
    int n_frames,
    int max_formants,
    int window_size
) {
    int half_window = window_size / 2;
    
    for (int f = 0; f < max_formants; ++f) {
        for (int t = 0; t < n_frames; ++t) {
            int start = std::max(0, t - half_window);
            int end = std::min(n_frames, t + half_window + 1);
            
            // Collect window values
            std::vector<double> window_vals;
            for (int i = start; i < end; ++i) {
                double val = formants[i * max_formants + f];
                if (val > 0) {  // Ignore zeros (unvoiced)
                    window_vals.push_back(val);
                }
            }
            
            // Compute median
            if (!window_vals.empty()) {
                std::sort(window_vals.begin(), window_vals.end());
                smoothed[t * max_formants + f] = 
                    window_vals[window_vals.size() / 2];
            } else {
                smoothed[t * max_formants + f] = 0.0;
            }
        }
    }
}

// SIMD-accelerated formant jump detection
void detect_formant_jumps_simd(
    const double* formants,
    int n_frames,
    int max_formants,
    double max_jump_hz,
    bool* jump_detected  // Output: [n_frames-1][max_formants]
) {
    batch max_jump_batch(max_jump_hz);
    
    for (int f = 0; f < max_formants; ++f) {
        int t = 0;
        
        // SIMD processing
        for (; t + (int)simd_size < n_frames - 1; t += simd_size) {
            alignas(32) double curr[simd_size], next[simd_size];
            for (size_t i = 0; i < simd_size; ++i) {
                curr[i] = formants[(t + i) * max_formants + f];
                next[i] = formants[(t + i + 1) * max_formants + f];
            }
            
            batch curr_batch = batch::load_aligned(curr);
            batch next_batch = batch::load_aligned(next);
            batch diff = xsimd::abs(next_batch - curr_batch);
            
            auto mask = diff > max_jump_batch;
            
            // Convert boolean mask to double (true->1.0, false->0.0) then check
            batch mask_as_double = xsimd::select(mask, batch(1.0), batch(0.0));
            alignas(32) double mask_vals[simd_size];
            mask_as_double.store_aligned(mask_vals);
            
            for (size_t i = 0; i < simd_size; ++i) {
                jump_detected[(t + i) * max_formants + f] = (mask_vals[i] != 0.0);
            }
        }
        
        // Scalar remainder
        for (; t < n_frames - 1; ++t) {
            double curr_val = formants[t * max_formants + f];
            double next_val = formants[(t + 1) * max_formants + f];
            jump_detected[t * max_formants + f] = 
                (fabs(next_val - curr_val) > max_jump_hz);
        }
    }
}

} // namespace formant_lpc_simd

#endif // HAVE_XSIMD
