/* textgrid_simd.cpp
 *
 * SIMD-accelerated TextGrid batch operations
 * Part of Phase 3 Task 3.3: TextGrid Batch Operations
 *
 * Optimizations:
 * 1. SIMD duration calculation (vectorized subtraction)
 * 2. Batch time extraction (contiguous memory access)
 * 3. SIMD statistics for interval features
 *
 * Copyright (C) 2026 pladdrr development team
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 */

#include "praat.github.io/melder/melder.h"

#ifdef HAVE_XSIMD
#include <xsimd/xsimd.hpp>
#endif

#include <cmath>
#include <algorithm>

namespace textgrid_simd {

// ============================================================================
// Runtime SIMD Control
// ============================================================================

// Global flag to enable/disable SIMD (controllable from R)
static bool g_simd_enabled = true;

extern "C" {

/**
 * Enable or disable SIMD for TextGrid operations
 *
 * @param enabled true to enable SIMD, false for scalar fallback
 */
void set_textgrid_simd_enabled(bool enabled) {
    g_simd_enabled = enabled;
}

/**
 * Check if SIMD should be used for TextGrid operations
 *
 * @return true if SIMD is available and enabled
 */
bool should_use_simd_for_textgrid() {
#ifdef HAVE_XSIMD
    return g_simd_enabled;
#else
    return false;
#endif
}

// ============================================================================
// SIMD Duration Calculation
// ============================================================================

/**
 * Calculate durations from start/end times using SIMD
 *
 * Computes: durations[i] = end_times[i] - start_times[i]
 *
 * @param start_times Array of start times (1-based indexing)
 * @param end_times Array of end times (1-based indexing)
 * @param durations Output array of durations (1-based indexing)
 * @param n Number of intervals
 */
void calculate_durations_simd(
    const double* start_times,
    const double* end_times,
    double* durations,
    integer n
) {
#ifdef HAVE_XSIMD
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    // Process SIMD-width chunks (1-based indexing)
    integer i = 1;
    for (; i + static_cast<integer>(simd_size) <= n + 1; i += simd_size) {
        batch end_batch = xsimd::load_unaligned(&end_times[i]);
        batch start_batch = xsimd::load_unaligned(&start_times[i]);
        batch result = end_batch - start_batch;
        result.store_unaligned(&durations[i]);
    }

    // Scalar remainder
    for (; i <= n; i++) {
        durations[i] = end_times[i] - start_times[i];
    }
#else
    // Scalar fallback
    for (integer i = 1; i <= n; i++) {
        durations[i] = end_times[i] - start_times[i];
    }
#endif
}

/**
 * Calculate durations with 0-based indexing
 *
 * @param start_times Array of start times (0-based)
 * @param end_times Array of end times (0-based)
 * @param durations Output array (0-based)
 * @param n Number of elements
 */
void calculate_durations_simd_0based(
    const double* start_times,
    const double* end_times,
    double* durations,
    size_t n
) {
#ifdef HAVE_XSIMD
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    size_t i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch end_batch = xsimd::load_unaligned(&end_times[i]);
        batch start_batch = xsimd::load_unaligned(&start_times[i]);
        batch result = end_batch - start_batch;
        result.store_unaligned(&durations[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        durations[i] = end_times[i] - start_times[i];
    }
#else
    for (size_t i = 0; i < n; i++) {
        durations[i] = end_times[i] - start_times[i];
    }
#endif
}

// ============================================================================
// SIMD Interval Statistics
// ============================================================================

/**
 * Calculate sum of durations using SIMD
 *
 * @param durations Array of durations (0-based)
 * @param n Number of durations
 * @return Sum of all durations
 */
double sum_durations_simd(const double* durations, size_t n) {
#ifdef HAVE_XSIMD
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    batch sum_batch(0.0);
    size_t i = 0;

    for (; i + simd_size <= n; i += simd_size) {
        batch dur_batch = xsimd::load_unaligned(&durations[i]);
        sum_batch += dur_batch;
    }

    double sum = xsimd::reduce_add(sum_batch);

    // Scalar remainder
    for (; i < n; i++) {
        sum += durations[i];
    }

    return sum;
#else
    double sum = 0.0;
    for (size_t i = 0; i < n; i++) {
        sum += durations[i];
    }
    return sum;
#endif
}

/**
 * Calculate mean and standard deviation of durations using SIMD
 *
 * Two-pass algorithm:
 * Pass 1: Calculate sum and mean
 * Pass 2: Calculate sum of squared differences
 *
 * @param durations Array of durations (0-based)
 * @param n Number of durations
 * @param[out] mean_out Mean duration
 * @param[out] stdev_out Standard deviation
 */
void duration_statistics_simd(
    const double* durations,
    size_t n,
    double* mean_out,
    double* stdev_out
) {
    if (n == 0) {
        *mean_out = 0.0;
        *stdev_out = 0.0;
        return;
    }

#ifdef HAVE_XSIMD
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    // Pass 1: Sum
    batch sum_batch(0.0);
    size_t i = 0;

    for (; i + simd_size <= n; i += simd_size) {
        batch dur_batch = xsimd::load_unaligned(&durations[i]);
        sum_batch += dur_batch;
    }

    double sum = xsimd::reduce_add(sum_batch);
    for (; i < n; i++) {
        sum += durations[i];
    }

    double mean = sum / static_cast<double>(n);
    *mean_out = mean;

    if (n < 2) {
        *stdev_out = 0.0;
        return;
    }

    // Pass 2: Sum of squared differences
    batch mean_batch(mean);
    batch sq_diff_sum(0.0);
    i = 0;

    for (; i + simd_size <= n; i += simd_size) {
        batch dur_batch = xsimd::load_unaligned(&durations[i]);
        batch diff = dur_batch - mean_batch;
        sq_diff_sum = xsimd::fma(diff, diff, sq_diff_sum);
    }

    double variance_sum = xsimd::reduce_add(sq_diff_sum);
    for (; i < n; i++) {
        double diff = durations[i] - mean;
        variance_sum += diff * diff;
    }

    *stdev_out = std::sqrt(variance_sum / static_cast<double>(n - 1));
#else
    // Scalar fallback
    double sum = 0.0;
    for (size_t i = 0; i < n; i++) {
        sum += durations[i];
    }
    double mean = sum / static_cast<double>(n);
    *mean_out = mean;

    if (n < 2) {
        *stdev_out = 0.0;
        return;
    }

    double variance_sum = 0.0;
    for (size_t i = 0; i < n; i++) {
        double diff = durations[i] - mean;
        variance_sum += diff * diff;
    }
    *stdev_out = std::sqrt(variance_sum / static_cast<double>(n - 1));
#endif
}

/**
 * Find min and max duration using SIMD
 *
 * @param durations Array of durations (0-based)
 * @param n Number of durations
 * @param[out] min_out Minimum duration
 * @param[out] max_out Maximum duration
 */
void duration_min_max_simd(
    const double* durations,
    size_t n,
    double* min_out,
    double* max_out
) {
    if (n == 0) {
        *min_out = 0.0;
        *max_out = 0.0;
        return;
    }

#ifdef HAVE_XSIMD
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    if (n < simd_size) {
        // Scalar for small arrays
        double min_val = durations[0];
        double max_val = durations[0];
        for (size_t i = 1; i < n; i++) {
            if (durations[i] < min_val) min_val = durations[i];
            if (durations[i] > max_val) max_val = durations[i];
        }
        *min_out = min_val;
        *max_out = max_val;
        return;
    }

    batch min_batch = xsimd::load_unaligned(&durations[0]);
    batch max_batch = min_batch;

    size_t i = simd_size;
    for (; i + simd_size <= n; i += simd_size) {
        batch dur_batch = xsimd::load_unaligned(&durations[i]);
        min_batch = xsimd::min(min_batch, dur_batch);
        max_batch = xsimd::max(max_batch, dur_batch);
    }

    // Reduce SIMD registers
    double min_val = xsimd::reduce_min(min_batch);
    double max_val = xsimd::reduce_max(max_batch);

    // Scalar remainder
    for (; i < n; i++) {
        if (durations[i] < min_val) min_val = durations[i];
        if (durations[i] > max_val) max_val = durations[i];
    }

    *min_out = min_val;
    *max_out = max_val;
#else
    double min_val = durations[0];
    double max_val = durations[0];
    for (size_t i = 1; i < n; i++) {
        if (durations[i] < min_val) min_val = durations[i];
        if (durations[i] > max_val) max_val = durations[i];
    }
    *min_out = min_val;
    *max_out = max_val;
#endif
}

// ============================================================================
// SIMD Interval Filtering
// ============================================================================

/**
 * Filter intervals by duration range using SIMD
 * Returns indices of intervals with duration in [min_dur, max_dur]
 *
 * @param durations Array of durations (0-based)
 * @param n Number of intervals
 * @param min_dur Minimum duration (inclusive)
 * @param max_dur Maximum duration (inclusive)
 * @param[out] indices Output array of matching indices (0-based)
 * @param[out] count Number of matching intervals
 *
 * Note: indices array must be pre-allocated with size n
 */
void filter_by_duration_simd(
    const double* durations,
    size_t n,
    double min_dur,
    double max_dur,
    int* indices,
    size_t* count
) {
    *count = 0;

#ifdef HAVE_XSIMD
    // SIMD comparison creates bitmask, but gathering indices is complex
    // For filtering with index extraction, scalar is often faster due to branching
    // Use SIMD only for the comparison, then extract indices
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    batch min_batch(min_dur);
    batch max_batch(max_dur);

    size_t i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch dur_batch = xsimd::load_unaligned(&durations[i]);

        // Check if durations[i] >= min_dur && durations[i] <= max_dur
        auto ge_min = dur_batch >= min_batch;
        auto le_max = dur_batch <= max_batch;
        auto in_range = ge_min && le_max;

        // Extract matching indices (scalar for simplicity)
        for (size_t j = 0; j < simd_size; j++) {
            if (in_range.get(j)) {
                indices[*count] = static_cast<int>(i + j);
                (*count)++;
            }
        }
    }

    // Scalar remainder
    for (; i < n; i++) {
        if (durations[i] >= min_dur && durations[i] <= max_dur) {
            indices[*count] = static_cast<int>(i);
            (*count)++;
        }
    }
#else
    for (size_t i = 0; i < n; i++) {
        if (durations[i] >= min_dur && durations[i] <= max_dur) {
            indices[*count] = static_cast<int>(i);
            (*count)++;
        }
    }
#endif
}

// ============================================================================
// SIMD Batch Time Point Processing
// ============================================================================

/**
 * Calculate midpoints of intervals using SIMD
 *
 * midpoints[i] = (start_times[i] + end_times[i]) / 2.0
 *
 * @param start_times Array of start times (0-based)
 * @param end_times Array of end times (0-based)
 * @param midpoints Output array of midpoints (0-based)
 * @param n Number of intervals
 */
void calculate_midpoints_simd(
    const double* start_times,
    const double* end_times,
    double* midpoints,
    size_t n
) {
#ifdef HAVE_XSIMD
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    batch half(0.5);

    size_t i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch start_batch = xsimd::load_unaligned(&start_times[i]);
        batch end_batch = xsimd::load_unaligned(&end_times[i]);
        batch result = (start_batch + end_batch) * half;
        result.store_unaligned(&midpoints[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        midpoints[i] = (start_times[i] + end_times[i]) * 0.5;
    }
#else
    for (size_t i = 0; i < n; i++) {
        midpoints[i] = (start_times[i] + end_times[i]) * 0.5;
    }
#endif
}

/**
 * Check if time points fall within intervals using SIMD
 *
 * For each interval [start, end], checks if query_time is within range
 * Results are stored in contains array (1.0 if contains, 0.0 if not)
 *
 * @param start_times Array of interval start times (0-based)
 * @param end_times Array of interval end times (0-based)
 * @param query_time Time point to check
 * @param contains Output array of containment flags (0-based)
 * @param n Number of intervals
 */
void check_time_containment_simd(
    const double* start_times,
    const double* end_times,
    double query_time,
    double* contains,
    size_t n
) {
#ifdef HAVE_XSIMD
    using batch = xsimd::batch<double>;
    constexpr size_t simd_size = batch::size;

    batch query_batch(query_time);
    batch one(1.0);
    batch zero(0.0);

    size_t i = 0;
    for (; i + simd_size <= n; i += simd_size) {
        batch start_batch = xsimd::load_unaligned(&start_times[i]);
        batch end_batch = xsimd::load_unaligned(&end_times[i]);

        // Check: start <= query && query <= end
        auto ge_start = query_batch >= start_batch;
        auto le_end = query_batch <= end_batch;
        auto in_range = ge_start && le_end;

        batch result = xsimd::select(in_range, one, zero);
        result.store_unaligned(&contains[i]);
    }

    // Scalar remainder
    for (; i < n; i++) {
        contains[i] = (query_time >= start_times[i] && query_time <= end_times[i]) ? 1.0 : 0.0;
    }
#else
    for (size_t i = 0; i < n; i++) {
        contains[i] = (query_time >= start_times[i] && query_time <= end_times[i]) ? 1.0 : 0.0;
    }
#endif
}

} // extern "C"

} // namespace textgrid_simd

/* End of file textgrid_simd.cpp */
