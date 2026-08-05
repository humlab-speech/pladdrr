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

// Profiling note (2026-08-05): SIMD only covers the pairwise slope computation
// (step 1 of 5 in SlopeSelector_getQuantile). The remaining steps are random
// sampling, NUMsort2 (merge sort), dual-space line intersection counting,
// and interval narrowing — all scalar. Profile with Instruments/perf to
// confirm the bottleneck distribution. If sorting/dual-space sweep dominates,
// SIMD there would help more than further optimizing pairwise slopes.

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
 * Runtime SIMD gate (evaluated once at static init in SlopeSelector.cpp).
 *
 * Default OFF since 2026-08-05. The earlier "~25% faster" claim did not
 * survive measurement against the scalar path on the real CPPS workload.
 * Measured on M1 Pro, ppq1.wav (2.92 s), Praat-script parameter profile
 * (time_avg 0.02, quefrency_avg 0.0005, trend fit [0.001, 0.05],
 * exponential decay, Robust), pladdrr 4.9.20, -O3 -march=native:
 *
 *   calculate_cpps_ultra()  SIMD 4.06 s wall / 31.2 s CPU
 *                           scalar 2.35 s wall / 17.6 s CPU
 *   AVQI v2.03 (R)          SIMD 6.87 s wall / 35.3 s CPU
 *                           scalar 2.84 s wall / 20.3 s CPU
 *
 * Output is bit-identical either way (CPPS 19.36722538 dB, AVQI 3.471873),
 * so the SIMD path bought nothing and cost 1.7-2.4x.
 *
 * Why: `sample`-based profiling shows ~94% of getSlope_Siegel is the median
 * selection (num::NUMquantile_e -> adaptiveQuickselect), not the pairwise
 * slope divides these kernels vectorize. The kernels cover ~6% of the fit,
 * and as out-of-line extern "C" calls (no cross-TU inlining, NEON f64 divide
 * has no throughput edge over scalar fdiv on Apple silicon) they run far
 * slower than the inlined scalar loop they replace.
 *
 * Any future SIMD work here must target NUMquantile_e, not the slope loop.
 *
 * A/B overrides:
 *   PLADDRR_ENABLE_SLOPESELECTOR_SIMD=1   force SIMD (slower; A/B only)
 *   PLADDRR_DISABLE_SLOPESELECTOR_SIMD=1  force scalar (redundant with default)
 */
bool should_use_simd_for_slopeselector () {
#ifdef HAVE_XSIMD
    const char* disable_env = std::getenv ("PLADDRR_DISABLE_SLOPESELECTOR_SIMD");
    if (disable_env && std::atoi (disable_env) == 1)
        return false;
    const char* enable_env = std::getenv ("PLADDRR_ENABLE_SLOPESELECTOR_SIMD");
    if (enable_env && std::atoi (enable_env) == 1)
        return true;
    return false;
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
