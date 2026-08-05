/* batch_queries_simd.cpp
 *
 * SIMD-optimized batch query operations for formant, pitch, and intensity
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

// ============================================================================
// Vectorized Statistics Calculations
// ============================================================================

extern "C" {

/**
 * Calculate mean of array with SIMD
 * Used for computing mean across multiple values efficiently
 *
 * @param values Input values (1-based array)
 * @param n Number of values
 * @return Mean value
 */
#ifdef HAVE_XSIMD
double calculate_mean_simd(const double* values, integer n) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    batch sum(0.0);
    integer i = 1;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) - 1 <= n; i += simd_size) {
        batch val = xsimd::load_unaligned(&values[i]);
        sum = sum + val;
    }

    double result = xsimd_compat::reduce_add_compat(sum);

    // Scalar remainder
    for (; i <= n; i++) {
        result += values[i];
    }

    return (n > 0) ? (result / n) : 0.0;
}
#else
double calculate_mean_simd(const double* values, integer n) {
    double sum = 0.0;
    for (integer i = 1; i <= n; i++) {
        sum += values[i];
    }
    return (n > 0) ? (sum / n) : 0.0;
}
#endif

/**
 * Calculate standard deviation with SIMD
 * Two-pass algorithm: mean first, then squared deviations
 *
 * @param values Input values (1-based array)
 * @param n Number of values
 * @param mean Pre-computed mean (pass 0.0 to compute it)
 * @return Standard deviation
 */
#ifdef HAVE_XSIMD
double calculate_stdev_simd(const double* values, integer n, double mean) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    if (n < 2) return 0.0;

    // Compute mean if not provided
    if (mean == 0.0) {
        mean = calculate_mean_simd(values, n);
    }

    const batch mean_batch(mean);
    batch sum_sq(0.0);
    integer i = 1;

    // SIMD loop for squared deviations
    for (; i + static_cast<integer>(simd_size) - 1 <= n; i += simd_size) {
        batch val = xsimd::load_unaligned(&values[i]);
        batch diff = val - mean_batch;
        sum_sq = xsimd::fma(diff, diff, sum_sq);  // sum_sq += diff^2
    }

    double result = xsimd_compat::reduce_add_compat(sum_sq);

    // Scalar remainder
    for (; i <= n; i++) {
        double diff = values[i] - mean;
        result += diff * diff;
    }

    return std::sqrt(result / (n - 1));
}
#else
double calculate_stdev_simd(const double* values, integer n, double mean) {
    if (n < 2) return 0.0;

    if (mean == 0.0) {
        mean = calculate_mean_simd(values, n);
    }

    double sum_sq = 0.0;
    for (integer i = 1; i <= n; i++) {
        double diff = values[i] - mean;
        sum_sq += diff * diff;
    }

    return std::sqrt(sum_sq / (n - 1));
}
#endif

/**
 * Calculate min and max with SIMD
 * Single-pass min/max computation
 *
 * @param values Input values (1-based array)
 * @param n Number of values
 * @param min_val Output: minimum value
 * @param max_val Output: maximum value
 */
#ifdef HAVE_XSIMD
void calculate_min_max_simd(const double* values, integer n, double* min_val, double* max_val) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    if (n <= 0) {
        *min_val = NAN;
        *max_val = NAN;
        return;
    }

    // Initialize with first value
    batch min_batch(values[1]);
    batch max_batch(values[1]);
    integer i = 1;

    // SIMD loop
    for (; i + static_cast<integer>(simd_size) - 1 <= n; i += simd_size) {
        batch val = xsimd::load_unaligned(&values[i]);
        min_batch = xsimd::min(min_batch, val);
        max_batch = xsimd::max(max_batch, val);
    }

    *min_val = xsimd_compat::reduce_min_compat(min_batch);
    *max_val = xsimd_compat::reduce_max_compat(max_batch);

    // Scalar remainder
    for (; i <= n; i++) {
        *min_val = std::min(*min_val, values[i]);
        *max_val = std::max(*max_val, values[i]);
    }
}
#else
void calculate_min_max_simd(const double* values, integer n, double* min_val, double* max_val) {
    if (n <= 0) {
        *min_val = NAN;
        *max_val = NAN;
        return;
    }

    *min_val = values[1];
    *max_val = values[1];

    for (integer i = 2; i <= n; i++) {
        *min_val = std::min(*min_val, values[i]);
        *max_val = std::max(*max_val, values[i]);
    }
}
#endif

// ============================================================================
// Vectorized Interval Processing
// ============================================================================

/**
 * Calculate quantile with vectorized sorting
 * Uses SIMD for comparisons during sorting
 *
 * @param values Input values (1-based array)
 * @param n Number of values
 * @param quantile Quantile value (0.0 to 1.0)
 * @return Quantile value
 */
double calculate_quantile_simd(const double* values, integer n, double quantile) {
    if (n <= 0) return NAN;
    if (quantile < 0.0 || quantile > 1.0) return NAN;

    // Copy values to a mutable temporary (kernel takes a const 1-based array)
    std::vector<double> work(n);
    for (integer i = 0; i < n; i++) {
        work[i] = values[i + 1];
    }

    // Calculate quantile position (type-7, as in R's quantile())
    double pos = quantile * (n - 1);
    integer lower = static_cast<integer>(std::floor(pos));
    integer upper = static_cast<integer>(std::ceil(pos));

    // Only the `lower` and `upper` order statistics are needed, so select them
    // instead of fully sorting (v4.9.19). std::nth_element leaves every element
    // after `lower` >= work[lower], so the second selection only has to search
    // the tail, and both values are identical to what std::sort would have put
    // at those positions.
    std::nth_element(work.begin(), work.begin() + lower, work.end());
    const double lowerValue = work[lower];

    if (lower == upper || upper >= n) {
        return lowerValue;
    }

    const double upperValue = *std::min_element(work.begin() + lower + 1, work.end());

    // Linear interpolation
    double fraction = pos - lower;
    return lowerValue * (1.0 - fraction) + upperValue * fraction;
}

// ============================================================================
// Batch Statistics Computation
// ============================================================================

/**
 * Calculate multiple statistics in one pass with SIMD
 * Computes mean, stdev, min, max in a single pass over data
 *
 * @param values Input values (1-based array)
 * @param n Number of values
 * @param mean Output: mean value
 * @param stdev Output: standard deviation
 * @param min_val Output: minimum value
 * @param max_val Output: maximum value
 */
#ifdef HAVE_XSIMD
void calculate_batch_statistics_simd(
    const double* values,
    integer n,
    double* mean,
    double* stdev,
    double* min_val,
    double* max_val
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    if (n <= 0) {
        *mean = NAN;
        *stdev = NAN;
        *min_val = NAN;
        *max_val = NAN;
        return;
    }

    // Pass 1: Mean, Min, Max
    batch sum(0.0);
    batch min_batch(values[1]);
    batch max_batch(values[1]);
    integer i = 1;

    for (; i + static_cast<integer>(simd_size) - 1 <= n; i += simd_size) {
        batch val = xsimd::load_unaligned(&values[i]);
        sum = sum + val;
        min_batch = xsimd::min(min_batch, val);
        max_batch = xsimd::max(max_batch, val);
    }

    double sum_scalar = xsimd_compat::reduce_add_compat(sum);
    *min_val = xsimd_compat::reduce_min_compat(min_batch);
    *max_val = xsimd_compat::reduce_max_compat(max_batch);

    // Scalar remainder
    for (; i <= n; i++) {
        sum_scalar += values[i];
        *min_val = std::min(*min_val, values[i]);
        *max_val = std::max(*max_val, values[i]);
    }

    *mean = sum_scalar / n;

    // Pass 2: Standard deviation
    if (n < 2) {
        *stdev = 0.0;
        return;
    }

    const batch mean_batch(*mean);
    batch sum_sq(0.0);
    i = 1;

    for (; i + static_cast<integer>(simd_size) - 1 <= n; i += simd_size) {
        batch val = xsimd::load_unaligned(&values[i]);
        batch diff = val - mean_batch;
        sum_sq = xsimd::fma(diff, diff, sum_sq);
    }

    double sum_sq_scalar = xsimd_compat::reduce_add_compat(sum_sq);

    for (; i <= n; i++) {
        double diff = values[i] - *mean;
        sum_sq_scalar += diff * diff;
    }

    *stdev = std::sqrt(sum_sq_scalar / (n - 1));
}
#else
void calculate_batch_statistics_simd(
    const double* values,
    integer n,
    double* mean,
    double* stdev,
    double* min_val,
    double* max_val
) {
    if (n <= 0) {
        *mean = NAN;
        *stdev = NAN;
        *min_val = NAN;
        *max_val = NAN;
        return;
    }

    // Pass 1: Mean, min, max
    double sum = 0.0;
    *min_val = values[1];
    *max_val = values[1];

    for (integer i = 1; i <= n; i++) {
        sum += values[i];
        *min_val = std::min(*min_val, values[i]);
        *max_val = std::max(*max_val, values[i]);
    }

    *mean = sum / n;

    // Pass 2: Stdev
    if (n < 2) {
        *stdev = 0.0;
        return;
    }

    double sum_sq = 0.0;
    for (integer i = 1; i <= n; i++) {
        double diff = values[i] - *mean;
        sum_sq += diff * diff;
    }

    *stdev = std::sqrt(sum_sq / (n - 1));
}
#endif

// ============================================================================
// Parallel Frame Value Extraction
// ============================================================================

/**
 * Extract values from multiple frames in parallel with SIMD
 * Processes frames in batches for better cache locality
 *
 * @param frame_values Pre-extracted frame values (1-based 2D: [frame][value])
 * @param n_frames Number of frames
 * @param n_values_per_frame Number of values per frame
 * @param output Output array for statistics (1-based)
 * @param stat_type 0=mean, 1=min, 2=max, 3=stdev
 */
#ifdef HAVE_XSIMD
void process_frames_simd(
    const double* const* frame_values,
    integer n_frames,
    integer n_values_per_frame,
    double* output,
    int stat_type
) {
    using batch = XSIMD_BATCH(double);
    constexpr size_t simd_size = batch::size;

    // Process each frame
    for (integer f = 1; f <= n_frames; f++) {
        const double* values = frame_values[f];

        if (stat_type == 0) {
            // Mean
            output[f] = calculate_mean_simd(values, n_values_per_frame);
        } else if (stat_type == 1 || stat_type == 2) {
            // Min or Max
            double min_val, max_val;
            calculate_min_max_simd(values, n_values_per_frame, &min_val, &max_val);
            output[f] = (stat_type == 1) ? min_val : max_val;
        } else if (stat_type == 3) {
            // Stdev
            double mean = calculate_mean_simd(values, n_values_per_frame);
            output[f] = calculate_stdev_simd(values, n_values_per_frame, mean);
        }
    }
}
#else
void process_frames_simd(
    const double* const* frame_values,
    integer n_frames,
    integer n_values_per_frame,
    double* output,
    int stat_type
) {
    for (integer f = 1; f <= n_frames; f++) {
        const double* values = frame_values[f];

        if (stat_type == 0) {
            output[f] = calculate_mean_simd(values, n_values_per_frame);
        } else if (stat_type == 1 || stat_type == 2) {
            double min_val, max_val;
            calculate_min_max_simd(values, n_values_per_frame, &min_val, &max_val);
            output[f] = (stat_type == 1) ? min_val : max_val;
        } else if (stat_type == 3) {
            double mean = calculate_mean_simd(values, n_values_per_frame);
            output[f] = calculate_stdev_simd(values, n_values_per_frame, mean);
        }
    }
}
#endif

} // extern "C"

// ============================================================================
// Runtime Control
// ============================================================================

static bool g_batch_queries_simd_enabled = true;

extern "C" {

void set_batch_queries_simd_enabled(bool enabled) {
    g_batch_queries_simd_enabled = enabled;
}

bool get_batch_queries_simd_enabled() {
    return g_batch_queries_simd_enabled;
}

bool should_use_simd_for_batch_queries() {
#ifdef HAVE_XSIMD
    return g_batch_queries_simd_enabled;
#else
    return false;
#endif
}

} // extern "C"

/* End of file batch_queries_simd.cpp */
