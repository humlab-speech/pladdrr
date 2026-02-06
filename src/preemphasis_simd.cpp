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
// preemphasis_simd.cpp - SIMD optimizations for pre-emphasis filtering
// Part of Phase 2, Task 2.2: Pre-emphasis Filter SIMD
// Created: 2026-01-22

#include "praat.github.io/melder/melder.h"
#include "praat.github.io/fon/Sound.h"
#include "simd_utils.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#include "xsimd_compat.h"
#endif

// Direct SIMD namespace for Praat integration (no Rcpp overhead)
namespace preemphasis_simd_direct {

#ifdef HAVE_XSIMD

/**
 * Apply pre-emphasis filter with SIMD
 *
 * Pre-emphasis is a first-order high-pass filter:
 * y[n] = x[n] - alpha * x[n-1]
 *
 * CRITICAL: Must process BACKWARD (nx to 2) to avoid loop-carried dependency.
 * When going forward, s[i-1] would already be modified, giving wrong results.
 * When going backward, s[i-1] is still the original value.
 *
 * Praat implementation:
 * for (i = nx; i >= 2; i--)
 *     s[i] -= emphasisFactor * s[i-1]
 *
 * @param s Signal data (1-based Praat VEC, actually &s[0] for pointer arithmetic)
 * @param nx Number of samples
 * @param emphasisFactor Pre-emphasis coefficient (alpha)
 */
void apply_preemphasis_simd(
    double* s,              // Actually s - 1 (for 1-based access)
    integer nx,
    double emphasisFactor
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    batch alpha_batch(emphasisFactor);

    // Process backward: nx to 2
    // Find starting point for SIMD (must be aligned to simd_size blocks from position 2)
    integer i = nx;

    // Scalar remainder at the end (high indices)
    integer simd_end = 2 + simd_size - 1;
    for (; i > nx - (nx - 2 + 1) % simd_size && i >= 2; i--) {
        s[i] -= emphasisFactor * s[i - 1];
    }

    // SIMD loop: process simd_size elements at a time, going backward
    for (; i >= simd_end; i -= simd_size) {
        // Load s[i-simd_size+1..i] into curr
        integer start_idx = i - static_cast<integer>(simd_size) + 1;
        batch curr = xsimd::load_unaligned(&s[start_idx]);

        // Load s[i-simd_size..i-1] into prev
        batch prev = xsimd::load_unaligned(&s[start_idx - 1]);

        // Compute: curr - alpha * prev
        batch result = xsimd::fnma(alpha_batch, prev, curr);

        // Store back
        result.store_unaligned(&s[start_idx]);
    }

    // Scalar remainder at the beginning (low indices)
    for (; i >= 2; i--) {
        s[i] -= emphasisFactor * s[i - 1];
    }
}

/**
 * Apply de-emphasis filter with SIMD (inverse of pre-emphasis)
 *
 * De-emphasis:
 * y[n] = x[n] + alpha * y[n-1]
 *
 * NOTE: De-emphasis HAS a loop-carried dependency even in forward direction:
 * s[i] depends on the MODIFIED s[i-1], not the original.
 * This is the inverse of pre-emphasis and reconstructs the signal progressively.
 *
 * Therefore, de-emphasis MUST be scalar - cannot be SIMD-ized without
 * changing the algorithm completely.
 *
 * @param s Signal data (1-based Praat VEC)
 * @param nx Number of samples
 * @param emphasisFactor De-emphasis coefficient (alpha)
 */
void apply_deemphasis_simd(
    double* s,              // Actually s - 1 (for 1-based access)
    integer nx,
    double emphasisFactor
) {
    // De-emphasis cannot be SIMD-ized - use scalar implementation
    // s[i] = s[i] + alpha * s[i-1], where s[i-1] is the already de-emphasized value
    for (integer i = 2; i <= nx; i++) {
        s[i] += emphasisFactor * s[i - 1];
    }
}

#endif // HAVE_XSIMD

} // namespace preemphasis_simd_direct

// C-linkage bridge functions for calling from Praat code
extern "C" {

/**
 * Bridge: Apply pre-emphasis with SIMD (factor-based interface)
 * Used by Sound.cpp which pre-calculates emphasisFactor
 *
 * @param s Praat VEC (1-based vector)
 * @param emphasisFactor Pre-emphasis coefficient
 */
void apply_preemphasis_factor_simd_bridge(
    VEC const& s,
    double emphasisFactor
) {
#ifdef HAVE_XSIMD
    // Pass pointer adjusted for 1-based indexing
    preemphasis_simd_direct::apply_preemphasis_simd(
        &s[0],           // Base pointer for 1-based access
        s.size,
        emphasisFactor
    );
#else
    // Scalar fallback (matches original Praat logic)
    for (integer i = s.size; i >= 2; i--) {
        s[i] -= emphasisFactor * s[i - 1];
    }
#endif
}

/**
 * Bridge: Apply de-emphasis with SIMD (factor-based interface)
 * Used by Sound.cpp which pre-calculates emphasisFactor
 *
 * @param s Praat VEC (1-based vector)
 * @param emphasisFactor De-emphasis coefficient
 */
void apply_deemphasis_factor_simd_bridge(
    VEC const& s,
    double emphasisFactor
) {
#ifdef HAVE_XSIMD
    preemphasis_simd_direct::apply_deemphasis_simd(
        &s[0],
        s.size,
        emphasisFactor
    );
#else
    // Scalar fallback (matches original Praat logic)
    for (integer i = 2; i <= s.size; i++) {
        s[i] += emphasisFactor * s[i - 1];
    }
#endif
}

/**
 * Check if SIMD should be used for pre-emphasis operations
 */
bool should_use_simd_for_preemphasis() {
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
