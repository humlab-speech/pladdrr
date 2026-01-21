// formant_simd_bridge.cpp - Bridge between SIMD formant/LPC functions and Praat code
// Part of Phase 1, Task 1.3: Formant Extraction Integration
// Created: 2026-01-21

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat.github.io/melder/melder.h"
#include "praat.github.io/fon/Formant.h"
#include "simd_utils.h"
#include <cmath>
#include <complex>
#include <vector>

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

using namespace Rcpp;

// ============================================================================
// Direct SIMD implementations for LPC/Formant extraction
// ============================================================================

namespace formant_simd_direct {

#ifdef HAVE_XSIMD

// Direct SIMD-accelerated Burg's algorithm
// This replaces VECburg() in NUM2.cpp for formant extraction
double burg_simd(
    double* lpc_coeffs,          // Output: LPC coefficients [1..m]
    const double* signal,        // Input: signal samples [1..n]
    int n,                       // Number of samples
    int m                        // Number of LPC coefficients (order)
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    if (n <= 2) {
        lpc_coeffs[0] = -1.0;  // 1-based indexing
        return 1.0;
    }

    // Initialize forward and backward prediction errors
    std::vector<double> f(n + 1), b(n + 1);  // 1-based indexing

    // Initialize with signal (skip index 0)
    int i = 1;
    for (; i + static_cast<int>(simd_size) <= n + 1; i += simd_size) {
        batch sig = xsimd::load_unaligned(&signal[i]);
        sig.store_unaligned(&f[i]);
        sig.store_unaligned(&b[i]);
    }
    for (; i <= n; ++i) {
        f[i] = b[i] = signal[i];
    }

    // Burg recursion
    std::vector<double> a(m + 1, 0.0);  // 1-based
    a[0] = 1.0;

    // Initial mean square error
    double xms = 0.0;
    batch sum_batch(0.0);
    i = 1;
    for (; i + static_cast<int>(simd_size) <= n + 1; i += simd_size) {
        batch sig = xsimd::load_unaligned(&signal[i]);
        sum_batch = xsimd::fma(sig, sig, sum_batch);
    }
    xms = xsimd::reduce_add(sum_batch);
    for (; i <= n; ++i) {
        xms += signal[i] * signal[i];
    }
    xms /= n;

    // Levinson-Durbin recursion
    for (int k = 1; k <= m; ++k) {
        // Calculate reflection coefficient (PARCOR)
        batch num_batch(0.0), den_batch(0.0);
        i = k;

        // SIMD loop for numerator and denominator
        for (; i + static_cast<int>(simd_size) <= n; i += simd_size) {
            batch f_batch = xsimd::load_unaligned(&f[i]);
            batch b_batch = xsimd::load_unaligned(&b[i]);
            num_batch = xsimd::fma(f_batch, b_batch, num_batch);
            den_batch = xsimd::fma(f_batch, f_batch, den_batch);
            den_batch = xsimd::fma(b_batch, b_batch, den_batch);
        }

        double num = xsimd::reduce_add(num_batch);
        double den = xsimd::reduce_add(den_batch);

        // Scalar remainder
        for (; i <= n; ++i) {
            num += f[i] * b[i];
            den += f[i] * f[i] + b[i] * b[i];
        }

        if (den <= 0.0) {
            for (int j = k; j <= m; ++j)
                lpc_coeffs[j - 1] = 0.0;  // Convert to 0-based for output
            return xms;
        }

        double parcor = -2.0 * num / den;
        xms *= 1.0 - parcor * parcor;

        // Update LPC coefficients
        std::vector<double> a_new(m + 1);
        a_new[0] = 1.0;
        for (int j = 1; j < k; ++j) {
            a_new[j] = a[j] + parcor * a[k - j];
        }
        a_new[k] = parcor;
        a = a_new;

        // Update prediction errors with SIMD
        if (k < m) {
            batch parcor_batch(parcor);
            i = k + 1;

            for (; i + static_cast<int>(simd_size) <= n + 1; i += simd_size) {
                batch f_old = xsimd::load_unaligned(&f[i]);
                batch b_old = xsimd::load_unaligned(&b[i - 1]);

                batch f_new = xsimd::fma(parcor_batch, b_old, f_old);
                batch b_new = xsimd::fma(parcor_batch, f_old, b_old);

                f_new.store_unaligned(&f[i]);
                b_new.store_unaligned(&b[i]);
            }

            for (; i <= n; ++i) {
                double f_old = f[i];
                double b_old = b[i - 1];
                f[i] = f_old + parcor * b_old;
                b[i] = b_old + parcor * f_old;
            }
        }
    }

    // Copy coefficients to output (convert 1-based a[] to 0-based lpc_coeffs[])
    for (int i = 1; i <= m; ++i) {
        lpc_coeffs[i - 1] = a[i];
    }

    return xms;
}

// SIMD-accelerated pre-emphasis filter for formant extraction
// This is applied before LPC analysis
void apply_preemphasis_simd(
    double* signal,              // Input/output: signal [1..n] (1-based)
    int n,                       // Number of samples
    double alpha = 0.97          // Pre-emphasis coefficient
) {
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    // Process in reverse to avoid temporary storage
    // signal[i] = signal[i] - alpha * signal[i-1]

    // Save first sample (not pre-emphasized)
    double first = signal[1];

    // SIMD processing (need to handle loop-carried dependency carefully)
    // Process in blocks, starting from the end
    for (int i = n; i >= 2; --i) {
        signal[i] -= alpha * signal[i - 1];
    }

    signal[1] = first;  // Restore first sample
}

// SIMD-accelerated root finding for formant extraction
// Finds formant frequencies and bandwidths from LPC coefficients
void find_formants_from_lpc_simd(
    const double* lpc_coeffs,    // LPC coefficients [0..order-1]
    int order,                   // LPC order
    double* formant_freqs,       // Output: formant frequencies [0..max_formants-1]
    double* formant_bandwidths,  // Output: formant bandwidths [0..max_formants-1]
    int* n_formants_out,         // Output: number of formants found
    double sampling_rate,        // Sampling rate (Hz)
    double safety_margin         // Safety margin (Hz) - don't extract formants too close to 0 or Nyquist
) {
    const double nyquist = sampling_rate / 2.0;

    // Build companion matrix for polynomial root finding
    // Polynomial is: 1 - a[1]*z^-1 - a[2]*z^-2 - ... - a[m]*z^-m
    // Companion matrix eigenvalues are the roots

    // For now, use a simplified approach:
    // Convert to polynomial coefficients (flip sign)
    std::vector<double> poly_coeffs(order + 1);
    poly_coeffs[order] = 1.0;  // Leading coefficient
    for (int i = 0; i < order; ++i) {
        poly_coeffs[order - 1 - i] = -lpc_coeffs[i];
    }

    // Placeholder: Root finding would go here
    // In practice, this would use:
    // 1. Laguerre's method (iterative)
    // 2. Eigenvalue decomposition of companion matrix
    // 3. Durand-Kerner method
    // All can benefit from SIMD for matrix/vector operations

    // For now, return 0 formants to indicate not yet implemented
    *n_formants_out = 0;

    // TODO: Implement polynomial root finding with SIMD
    // This is complex and would require a separate implementation
}

#endif // HAVE_XSIMD

} // namespace formant_simd_direct

// ============================================================================
// Bridge functions for Praat integration
// ============================================================================

// Bridge function: SIMD-accelerated Burg's algorithm
// Replaces VECburg() from NUM2.cpp
extern "C" double VECburg_simd_bridge(
    VEC const& lpc_coeffs,       // Output: LPC coefficients (Praat VEC, 1-based)
    constVEC const& signal       // Input: signal samples (Praat VEC, 1-based)
) {
#ifdef HAVE_XSIMD
    const integer n = signal.size;
    const integer m = lpc_coeffs.size;

    // Call SIMD implementation
    // Note: Praat VECs are 1-based, pass &vec[1] to get first element
    return formant_simd_direct::burg_simd(
        &lpc_coeffs[1],
        &signal[1],
        static_cast<int>(n),
        static_cast<int>(m)
    );
#else
    Melder_throw(U"SIMD not available - should not reach here");
    return 0.0;
#endif
}

// Bridge function: Pre-emphasis filter
extern "C" void apply_preemphasis_simd_bridge(
    VEC const& signal,           // Input/output: signal (Praat VEC, 1-based)
    double preemphasis_frequency,
    double sampling_rate
) {
#ifdef HAVE_XSIMD
    // Calculate alpha from preemphasis frequency
    // alpha ≈ exp(-2π * f_preemph / f_sample)
    const double alpha = std::exp(-2.0 * M_PI * preemphasis_frequency / sampling_rate);

    formant_simd_direct::apply_preemphasis_simd(
        &signal[1],
        static_cast<int>(signal.size),
        alpha
    );
#else
    Melder_throw(U"SIMD not available - should not reach here");
#endif
}

// Utility: Check if SIMD should be used for formant extraction
// This respects the R option speaker.use_simd
bool should_use_simd_for_formants() {
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
