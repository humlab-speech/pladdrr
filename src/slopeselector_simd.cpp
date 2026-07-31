/* slopeselector_simd.cpp
 *
 * SIMD-optimized SlopeSelector operations for CPPS trend-fit (Siegel repeated
 * median slope + intercept). These are the two hottest per-frame loops in
 * PowerCepstrum's robust trend fit (kCepstrum_trendFit::ROBUST_FAST, the
 * default for calculate_cpps_ultra()).
 *
 * Every division/multiply here is computed independently (no running sum),
 * so vectorizing or reordering the elements does not change any individual
 * IEEE-754 result bit-for-bit, and NUMquantile_e's median selection is
 * value-based (order-invariant) - so the final slope/intercept are identical
 * to the scalar path.
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

#include <cstdlib>

namespace slopeselector_simd_direct {

#ifdef HAVE_XSIMD

/*
 * Computes, for row `irow` (1-based), the n-1 pairwise Siegel slopes
 *   (yp[irow] - yp[j]) / (xp[irow] - xp[j])   for all j != irow, j = 1..n
 * in the same order the scalar loop produces them (j ascending, irow
 * skipped) - split into two contiguous, branch-free ranges [1, irow-1] and
 * [irow+1, n] instead of a per-element skip test.
 *
 * xp/yp/out use Melder's "zero-based array" convention
 * (asArgumentToFunctionThatExpectsZeroBasedArray): xp[0] is Praat's xp[1].
 */
void siegel_row_slopes_simd(
    const double* xp,
    const double* yp,
    integer n,
    integer irow,          // 1-based
    double* out             // zero-based, size n-1
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    const integer irow0 = irow - 1;   // zero-based
    const batch xi (xp [irow0]);
    const batch yi (yp [irow0]);
    const double xi_s = xp [irow0];
    const double yi_s = yp [irow0];

    integer outIdx = 0;

    auto processRange = [&] (integer j0begin, integer j0end) {
        // half-open [j0begin, j0end)
        integer j0 = j0begin;
        for (; j0 + static_cast<integer>(simd_size) <= j0end; j0 += simd_size) {
            batch xj = xsimd::load_unaligned (&xp [j0]);
            batch yj = xsimd::load_unaligned (&yp [j0]);
            batch result = (yi - yj) / (xi - xj);
            result.store_unaligned (&out [outIdx]);
            outIdx += simd_size;
        }
        for (; j0 < j0end; j0 ++) {
            out [outIdx] = (yi_s - yp [j0]) / (xi_s - xp [j0]);
            outIdx ++;
        }
    };

    processRange (0, irow0);
    processRange (irow0 + 1, n);
}

/*
 * Computes out[k] = yp[k] - slope * xp[k] for k = 0..n-1 (zero-based),
 * matching structSlopeSelector::getIntercept's scalar loop exactly
 * (single multiply, single subtract - no FMA fusion, per -ffp-contract=off).
 */
void intercept_terms_simd(
    const double* xp,
    const double* yp,
    double slope,
    integer n,
    double* out              // zero-based, size n
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;
    const batch slope_b (slope);

    integer i = 0;
    for (; i + static_cast<integer>(simd_size) <= n; i += simd_size) {
        batch xv = xsimd::load_unaligned (&xp [i]);
        batch yv = xsimd::load_unaligned (&yp [i]);
        batch prod = slope_b * xv;
        batch result = yv - prod;
        result.store_unaligned (&out [i]);
    }
    for (; i < n; i ++) {
        const double prod = slope * xp [i];
        out [i] = yp [i] - prod;
    }
}

#endif  // HAVE_XSIMD

}  // namespace slopeselector_simd_direct

extern "C" {

/*
 * Runtime SIMD gate. Can be disabled via PLADDRR_DISABLE_SLOPESELECTOR_SIMD=1
 * for A/B diagnostics, matching the convention of the other _simd.cpp files.
 */
bool should_use_simd_for_slopeselector () {
#ifdef HAVE_XSIMD
    const char* disable_env = std::getenv ("PLADDRR_DISABLE_SLOPESELECTOR_SIMD");
    if (disable_env && std::atoi (disable_env) == 1)
        return false;
    return true;
#else
    return false;
#endif
}

#ifdef HAVE_XSIMD
void siegel_row_slopes_simd (
    const double* xp, const double* yp, integer n, integer irow, double* out
) {
    slopeselector_simd_direct::siegel_row_slopes_simd (xp, yp, n, irow, out);
}

void intercept_terms_simd (
    const double* xp, const double* yp, double slope, integer n, double* out
) {
    slopeselector_simd_direct::intercept_terms_simd (xp, yp, slope, n, out);
}
#endif

}  // extern "C"
