/* mfcc_simd.cpp
 *
 * SIMD-optimized MFCC (Mel-Frequency Cepstral Coefficients) operations
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
#include <algorithm>
#include <atomic>

extern "C" {

// ============================================================================
// Triangular Mel Filter (SIMD)
// ============================================================================

/**
 * Apply triangular Mel filterbank with SIMD
 * Computes weighted sum: power = sum(amplitude * spectrum_power)
 * where amplitude = triangular filter response
 *
 * @param spectrum_power Power spectrum (1-based array)
 * @param frequencies Frequency for each bin in Hz (1-based array)
 * @param ifrom Starting bin index (1-based)
 * @param ito Ending bin index (1-based)
 * @param fl_hz Lower frequency bound
 * @param fc_hz Center frequency
 * @param fh_hz Upper frequency bound
 * @return Filtered power value
 */
#ifdef HAVE_XSIMD
double triangular_filter_simd(
    const double* spectrum_power,
    const double* frequencies,
    integer ifrom,
    integer ito,
    double fl_hz,
    double fc_hz,
    double fh_hz
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    const batch fl(fl_hz);
    const batch fc(fc_hz);
    const batch fh(fh_hz);
    const batch zero(0.0);
    const batch one(1.0);

    // Compute denominators for amplitude calculation
    const double rising_denom = (fc_hz > fl_hz) ? (fc_hz - fl_hz) : 1.0;
    const double falling_denom = (fh_hz > fc_hz) ? (fh_hz - fc_hz) : 1.0;

    const batch rising_inv(1.0 / rising_denom);
    const batch falling_inv(1.0 / falling_denom);

    batch power_sum(0.0);
    integer i = ifrom;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) - 1 <= ito; i += simd_size) {
        batch freq = xsimd::load_unaligned(&frequencies[i]);
        batch power = xsimd::load_unaligned(&spectrum_power[i]);

        // Triangular amplitude calculation
        // if (f < fl || f > fh) amplitude = 0
        // else if (f < fc) amplitude = (f - fl) / (fc - fl)
        // else amplitude = (fh - f) / (fh - fc)

        // Rising slope: (f - fl) / (fc - fl)
        batch rising = (freq - fl) * rising_inv;

        // Falling slope: (fh - f) / (fh - fc)
        batch falling = (fh - freq) * falling_inv;

        // Select based on frequency position
        auto below_fc = freq < fc;
        batch amplitude = xsimd::select(below_fc, rising, falling);

        // Clamp to [0, 1]
        amplitude = xsimd::max(zero, xsimd::min(one, amplitude));

        // Accumulate: power_sum += amplitude * power
        power_sum = xsimd::fma(amplitude, power, power_sum);
    }

    double result = xsimd_compat::reduce_add_compat(power_sum);

    // Scalar remainder
    for (; i <= ito; i++) {
        const double f = frequencies[i];
        double amplitude = 0.0;

        if (f >= fl_hz && f <= fh_hz) {
            if (f < fc_hz) {
                amplitude = (f - fl_hz) / rising_denom;
            } else {
                amplitude = (fh_hz - f) / falling_denom;
            }
            amplitude = std::max(0.0, std::min(1.0, amplitude));
        }

        result += amplitude * spectrum_power[i];
    }

    return result;
}
#else
double triangular_filter_simd(
    const double* spectrum_power,
    const double* frequencies,
    integer ifrom,
    integer ito,
    double fl_hz,
    double fc_hz,
    double fh_hz
) {
    double power = 0.0;
    const double rising_denom = (fc_hz > fl_hz) ? (fc_hz - fl_hz) : 1.0;
    const double falling_denom = (fh_hz > fc_hz) ? (fh_hz - fc_hz) : 1.0;

    for (integer i = ifrom; i <= ito; i++) {
        const double f = frequencies[i];
        double amplitude = 0.0;

        if (f >= fl_hz && f <= fh_hz) {
            if (f < fc_hz) {
                amplitude = (f - fl_hz) / rising_denom;
            } else {
                amplitude = (fh_hz - f) / falling_denom;
            }
            amplitude = std::max(0.0, std::min(1.0, amplitude));
        }

        power += amplitude * spectrum_power[i];
    }

    return power;
}
#endif

// ============================================================================
// DCT (Discrete Cosine Transform) SIMD
// ============================================================================

/**
 * Compute DCT using SIMD inner products
 * target[k] = sum(x[j] * cosinesTable[k][j])
 *
 * @param target Output DCT coefficients (1-based array)
 * @param x Input signal (1-based array)
 * @param cosinesTable Precomputed cosine table (1-based 2D array)
 * @param size Size of arrays
 */
#ifdef HAVE_XSIMD
void dct_simd(
    double* target,
    const double* x,
    const double* const* cosinesTable,
    integer size
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    for (integer k = 1; k <= size; k++) {
        const double* cosine_row = cosinesTable[k];
        batch sum(0.0);

        integer j = 1;

        // SIMD loop for inner product
        for (; j + static_cast<integer>(simd_size) - 1 <= size; j += simd_size) {
            batch x_val = xsimd::load_unaligned(&x[j]);
            batch cos_val = xsimd::load_unaligned(&cosine_row[j]);
            sum = xsimd::fma(x_val, cos_val, sum);  // sum += x * cos
        }

        double result = xsimd_compat::reduce_add_compat(sum);

        // Scalar remainder
        for (; j <= size; j++) {
            result += x[j] * cosine_row[j];
        }

        target[k] = result;
    }
}
#else
void dct_simd(
    double* target,
    const double* x,
    const double* const* cosinesTable,
    integer size
) {
    for (integer k = 1; k <= size; k++) {
        double sum = 0.0;
        const double* cosine_row = cosinesTable[k];
        for (integer j = 1; j <= size; j++) {
            sum += x[j] * cosine_row[j];
        }
        target[k] = sum;
    }
}
#endif

} // extern "C"

// ============================================================================
// Runtime Control
// ============================================================================

static std::atomic<bool> g_mfcc_simd_enabled(true);

extern "C" {

void set_mfcc_simd_enabled(bool enabled) {
    g_mfcc_simd_enabled.store(enabled, std::memory_order_relaxed);
}

bool get_mfcc_simd_enabled() {
    return g_mfcc_simd_enabled.load(std::memory_order_relaxed);
}

bool should_use_simd_for_mfcc() {
#ifdef HAVE_XSIMD
    return g_mfcc_simd_enabled.load(std::memory_order_relaxed);
#else
    return false;
#endif
}

} // extern "C"

/* End of file mfcc_simd.cpp */
