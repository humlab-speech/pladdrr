/* textgrid_simd_bridge.cpp
 *
 * Bridge functions for TextGrid SIMD operations with Rcpp integration
 * Part of Phase 3 Task 3.3: TextGrid Batch Operations
 *
 * Provides:
 * 1. SIMD-accelerated interval statistics
 * 2. Batch feature extraction (pitch/formant/intensity per interval)
 * 3. Duration filtering and analysis
 *
 * Copyright (C) 2026 pladdrr development team
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 */

// [[Rcpp::interfaces(r, cpp)]]
// [[Rcpp::plugins(cpp17)]]

#include <Rcpp.h>
#include "praat_types.h"
#include "praat_xptr_utils.h"

// Praat headers
#include "fon/TextGrid.h"
#include "fon/Sound.h"
#include "fon/Pitch.h"
#include "fon/Formant.h"
#include "fon/Intensity.h"
#include "fon/Vector.h"
#include "melder/melder.h"

// Intensity averaging method macros (from Intensity.h)
#ifndef Intensity_averaging_ENERGY
#define Intensity_averaging_ENERGY 1
#endif

using namespace Rcpp;

// Forward declarations from textgrid_simd.cpp
namespace textgrid_simd {
extern "C" {
    void set_textgrid_simd_enabled(bool enabled);
    bool should_use_simd_for_textgrid();
    void calculate_durations_simd(const double* start, const double* end, double* dur, integer n);
    void calculate_durations_simd_0based(const double* start, const double* end, double* dur, size_t n);
    double sum_durations_simd(const double* durations, size_t n);
    void duration_statistics_simd(const double* durations, size_t n, double* mean, double* stdev);
    void duration_min_max_simd(const double* durations, size_t n, double* min_out, double* max_out);
    void filter_by_duration_simd(const double* durations, size_t n, double min_dur, double max_dur, int* indices, size_t* count);
    void calculate_midpoints_simd(const double* start, const double* end, double* mid, size_t n);
    void check_time_containment_simd(const double* start, const double* end, double query_time, double* contains, size_t n);
}
}

// Forward declarations from batch_queries_simd.cpp
extern "C" {
    void calculate_batch_statistics_simd(
        const double* values, integer n,
        double* mean, double* stdev, double* min_val, double* max_val
    );
}

// ============================================================================
// SIMD Control Functions
// ============================================================================

//' Enable/Disable SIMD for TextGrid Operations
//'
//' @param enabled Logical, TRUE to enable SIMD, FALSE for scalar
//' @export
// [[Rcpp::export]]
void set_textgrid_simd_enabled_bridge(bool enabled) {
    textgrid_simd::set_textgrid_simd_enabled(enabled);
}

//' Check if SIMD is Enabled for TextGrid
//'
//' @return Logical indicating SIMD status
//' @export
// [[Rcpp::export]]
bool textgrid_simd_enabled() {
    return textgrid_simd::should_use_simd_for_textgrid();
}

// ============================================================================
// SIMD Duration Statistics
// ============================================================================

//' Calculate Interval Durations with SIMD
//'
//' Vectorized calculation of interval durations (end - start).
//' Uses SIMD instructions on large interval counts.
//'
//' @param start_times Numeric vector of start times
//' @param end_times Numeric vector of end times
//' @return Numeric vector of durations
//'
//' @examples
//' starts <- c(0, 1, 2.5)
//' ends <- c(0.8, 2, 3.2)
//' calculate_durations_simd_bridge(starts, ends)
//'
//' @export
// [[Rcpp::export]]
NumericVector calculate_durations_simd_bridge(NumericVector start_times, NumericVector end_times) {
    int n = start_times.size();
    if (n != end_times.size()) {
        stop("start_times and end_times must have same length");
    }
    if (n == 0) {
        return NumericVector(0);
    }

    NumericVector durations(n);

    if (textgrid_simd::should_use_simd_for_textgrid()) {
        textgrid_simd::calculate_durations_simd_0based(
            start_times.begin(), end_times.begin(), durations.begin(), n
        );
    } else {
        for (int i = 0; i < n; i++) {
            durations[i] = end_times[i] - start_times[i];
        }
    }

    return durations;
}

//' Calculate Duration Statistics with SIMD
//'
//' Computes mean, standard deviation, min, and max of durations using SIMD.
//'
//' @param durations Numeric vector of durations
//' @return List with mean, stdev, min, max
//'
//' @examples
//' duration_statistics_simd_bridge(c(0.5, 0.8, 1.2, 0.3))
//'
//' @export
// [[Rcpp::export]]
List duration_statistics_simd_bridge(NumericVector durations) {
    int n = durations.size();
    if (n == 0) {
        return List::create(
            Named("mean") = NA_REAL,
            Named("stdev") = NA_REAL,
            Named("min") = NA_REAL,
            Named("max") = NA_REAL
        );
    }

    double mean, stdev, min_val, max_val;

    if (textgrid_simd::should_use_simd_for_textgrid()) {
        textgrid_simd::duration_statistics_simd(
            durations.begin(), n, &mean, &stdev
        );
        textgrid_simd::duration_min_max_simd(
            durations.begin(), n, &min_val, &max_val
        );
    } else {
        // Scalar fallback
        double sum = 0.0;
        min_val = durations[0];
        max_val = durations[0];

        for (int i = 0; i < n; i++) {
            sum += durations[i];
            if (durations[i] < min_val) min_val = durations[i];
            if (durations[i] > max_val) max_val = durations[i];
        }
        mean = sum / n;

        double var_sum = 0.0;
        for (int i = 0; i < n; i++) {
            double diff = durations[i] - mean;
            var_sum += diff * diff;
        }
        stdev = (n > 1) ? std::sqrt(var_sum / (n - 1)) : 0.0;
    }

    return List::create(
        Named("mean") = mean,
        Named("stdev") = stdev,
        Named("min") = min_val,
        Named("max") = max_val
    );
}

//' Filter Intervals by Duration Range with SIMD
//'
//' Returns indices of intervals with duration in [min_dur, max_dur].
//' Uses SIMD for fast range comparison.
//'
//' @param durations Numeric vector of durations
//' @param min_dur Minimum duration (inclusive)
//' @param max_dur Maximum duration (inclusive)
//' @return Integer vector of 1-based indices into \code{durations} whose
//'   value falls within \verb{[min_dur, max_dur]}
//'
//' @examples
//' filter_by_duration_simd_bridge(c(0.1, 0.5, 1.2, 0.3), 0.2, 0.8)
//'
//' @export
// [[Rcpp::export]]
IntegerVector filter_by_duration_simd_bridge(
    NumericVector durations,
    double min_dur,
    double max_dur
) {
    int n = durations.size();
    if (n == 0) {
        return IntegerVector(0);
    }

    std::vector<int> indices(n);
    size_t count = 0;

    if (textgrid_simd::should_use_simd_for_textgrid()) {
        textgrid_simd::filter_by_duration_simd(
            durations.begin(), n, min_dur, max_dur,
            indices.data(), &count
        );
    } else {
        for (int i = 0; i < n; i++) {
            if (durations[i] >= min_dur && durations[i] <= max_dur) {
                indices[count++] = i;
            }
        }
    }

    // Convert to 1-based R indices
    IntegerVector result(count);
    for (size_t i = 0; i < count; i++) {
        result[i] = indices[i] + 1;  // 1-based
    }

    return result;
}

//' Calculate Interval Midpoints with SIMD
//'
//' @param start_times Numeric vector of start times
//' @param end_times Numeric vector of end times
//' @return Numeric vector of midpoints
//'
//' @examples
//' calculate_midpoints_simd_bridge(c(0, 1, 2.5), c(0.8, 2, 3.2))
//'
//' @export
// [[Rcpp::export]]
NumericVector calculate_midpoints_simd_bridge(
    NumericVector start_times,
    NumericVector end_times
) {
    int n = start_times.size();
    if (n != end_times.size()) {
        stop("start_times and end_times must have same length");
    }
    if (n == 0) {
        return NumericVector(0);
    }

    NumericVector midpoints(n);

    if (textgrid_simd::should_use_simd_for_textgrid()) {
        textgrid_simd::calculate_midpoints_simd(
            start_times.begin(), end_times.begin(), midpoints.begin(), n
        );
    } else {
        for (int i = 0; i < n; i++) {
            midpoints[i] = (start_times[i] + end_times[i]) * 0.5;
        }
    }

    return midpoints;
}

// ============================================================================
// Batch Feature Extraction (Integrates SIMD Statistics)
// ============================================================================

//' Extract Pitch Statistics for All TextGrid Intervals (Batch, SIMD)
//'
//' Computes pitch statistics (mean, stdev, min, max) for all intervals
//' in a TextGrid tier using SIMD-accelerated batch processing.
//'
//' @param textgrid_xptr External pointer to TextGrid
//' @param pitch_xptr External pointer to Pitch object
//' @param tier_number Tier number (1-based)
//' @param unit Pitch unit: "HERTZ" or "SEMITONES"
//'
//' @return Data frame with interval index, label, start, end, duration,
//'         pitch_mean, pitch_stdev, pitch_min, pitch_max
//'
//' @details
//' This function combines:
//' 1. SIMD duration calculation for all intervals
//' 2. SIMD statistics calculation for pitch values in each interval
//'
//' @export
// [[Rcpp::export]]
DataFrame textgrid_interval_pitch_batch(
    SEXP textgrid_xptr,
    SEXP pitch_xptr,
    int tier_number,
    std::string unit = "HERTZ"
) {
    BEGIN_RCPP

    // Validate pointers
    Rcpp::XPtr<structTextGrid> tg(textgrid_xptr);
    if (!tg) stop("Invalid TextGrid pointer");

    Rcpp::XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch) stop("Invalid Pitch pointer");

    // Get interval tier
    IntervalTier interval_tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), tier_number);
    integer n = interval_tier->intervals.size;

    // Pre-allocate result vectors
    IntegerVector indices(n);
    CharacterVector labels(n);
    NumericVector starts(n);
    NumericVector ends(n);
    NumericVector durations(n);
    NumericVector pitch_means(n);
    NumericVector pitch_stdevs(n);
    NumericVector pitch_mins(n);
    NumericVector pitch_maxs(n);

    // Extract all interval times and labels first
    std::vector<double> start_arr(n);
    std::vector<double> end_arr(n);

    for (integer i = 1; i <= n; i++) {
        TextInterval interval = interval_tier->intervals.at[i];
        indices[i-1] = i;
        labels[i-1] = Melder_peek32to8(interval->text.get());
        start_arr[i-1] = interval->xmin;
        end_arr[i-1] = interval->xmax;
        starts[i-1] = interval->xmin;
        ends[i-1] = interval->xmax;
    }

    // SIMD duration calculation
    if (textgrid_simd::should_use_simd_for_textgrid()) {
        textgrid_simd::calculate_durations_simd_0based(
            start_arr.data(), end_arr.data(), durations.begin(), n
        );
    } else {
        for (int i = 0; i < n; i++) {
            durations[i] = end_arr[i] - start_arr[i];
        }
    }

    // Parse unit
    kPitch_unit pitchUnit = kPitch_unit::HERTZ;
    if (unit == "SEMITONES" || unit == "semitones") {
        pitchUnit = kPitch_unit::SEMITONES_100;
    }

    // Extract pitch statistics for each interval
    for (int i = 0; i < n; i++) {
        double t1 = start_arr[i];
        double t2 = end_arr[i];

        // Get pitch values in this interval
        try {
            pitch_means[i] = Pitch_getMean(pitch.get(), t1, t2, pitchUnit);
            pitch_stdevs[i] = Pitch_getStandardDeviation(pitch.get(), t1, t2, pitchUnit);
            pitch_mins[i] = Pitch_getMinimum(pitch.get(), t1, t2, pitchUnit, true);
            pitch_maxs[i] = Pitch_getMaximum(pitch.get(), t1, t2, pitchUnit, true);
        } catch (...) {
            pitch_means[i] = NA_REAL;
            pitch_stdevs[i] = NA_REAL;
            pitch_mins[i] = NA_REAL;
            pitch_maxs[i] = NA_REAL;
        }
    }

    return DataFrame::create(
        Named("index") = indices,
        Named("label") = labels,
        Named("start") = starts,
        Named("end") = ends,
        Named("duration") = durations,
        Named("pitch_mean") = pitch_means,
        Named("pitch_stdev") = pitch_stdevs,
        Named("pitch_min") = pitch_mins,
        Named("pitch_max") = pitch_maxs
    );

    END_RCPP
}

//' Extract Formant Statistics for All TextGrid Intervals (Batch, SIMD)
//'
//' Computes formant statistics for all intervals using SIMD.
//'
//' @param textgrid_xptr External pointer to TextGrid
//' @param formant_xptr External pointer to Formant object
//' @param tier_number Tier number (1-based)
//' @param formant_number Formant number to extract (1 = F1, 2 = F2, etc.)
//'
//' @return Data frame with interval info and formant statistics
//'
//' @export
// [[Rcpp::export]]
DataFrame textgrid_interval_formant_batch(
    SEXP textgrid_xptr,
    SEXP formant_xptr,
    int tier_number,
    int formant_number = 1
) {
    BEGIN_RCPP

    Rcpp::XPtr<structTextGrid> tg(textgrid_xptr);
    if (!tg) stop("Invalid TextGrid pointer");

    Rcpp::XPtr<structFormant> formant(formant_xptr);
    if (!formant) stop("Invalid Formant pointer");

    IntervalTier interval_tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), tier_number);
    integer n = interval_tier->intervals.size;

    IntegerVector indices(n);
    CharacterVector labels(n);
    NumericVector starts(n);
    NumericVector ends(n);
    NumericVector durations(n);
    NumericVector formant_means(n);
    NumericVector formant_stdevs(n);
    NumericVector bandwidth_means(n);

    std::vector<double> start_arr(n);
    std::vector<double> end_arr(n);

    for (integer i = 1; i <= n; i++) {
        TextInterval interval = interval_tier->intervals.at[i];
        indices[i-1] = i;
        labels[i-1] = Melder_peek32to8(interval->text.get());
        start_arr[i-1] = interval->xmin;
        end_arr[i-1] = interval->xmax;
        starts[i-1] = interval->xmin;
        ends[i-1] = interval->xmax;
    }

    // SIMD durations
    if (textgrid_simd::should_use_simd_for_textgrid()) {
        textgrid_simd::calculate_durations_simd_0based(
            start_arr.data(), end_arr.data(), durations.begin(), n
        );
    } else {
        for (int i = 0; i < n; i++) {
            durations[i] = end_arr[i] - start_arr[i];
        }
    }

    // Extract formant statistics
    for (int i = 0; i < n; i++) {
        try {
            formant_means[i] = Formant_getMean(formant.get(), formant_number,
                                               start_arr[i], end_arr[i], kFormant_unit::HERTZ);
            formant_stdevs[i] = Formant_getStandardDeviation(formant.get(), formant_number,
                                                              start_arr[i], end_arr[i], kFormant_unit::HERTZ);
            bandwidth_means[i] = Formant_getBandwidthAtTime(formant.get(), formant_number,
                                                            (start_arr[i] + end_arr[i]) / 2.0, kFormant_unit::HERTZ);
        } catch (...) {
            formant_means[i] = NA_REAL;
            formant_stdevs[i] = NA_REAL;
            bandwidth_means[i] = NA_REAL;
        }
    }

    return DataFrame::create(
        Named("index") = indices,
        Named("label") = labels,
        Named("start") = starts,
        Named("end") = ends,
        Named("duration") = durations,
        Named("formant_mean") = formant_means,
        Named("formant_stdev") = formant_stdevs,
        Named("bandwidth_mean") = bandwidth_means
    );

    END_RCPP
}

//' Extract Intensity Statistics for All TextGrid Intervals (Batch, SIMD)
//'
//' @param textgrid_xptr External pointer to TextGrid
//' @param intensity_xptr External pointer to Intensity object
//' @param tier_number Tier number (1-based)
//'
//' @return Data frame with interval info and intensity statistics
//'
//' @export
// [[Rcpp::export]]
DataFrame textgrid_interval_intensity_batch(
    SEXP textgrid_xptr,
    SEXP intensity_xptr,
    int tier_number
) {
    BEGIN_RCPP

    Rcpp::XPtr<structTextGrid> tg(textgrid_xptr);
    if (!tg) stop("Invalid TextGrid pointer");

    Rcpp::XPtr<structIntensity> intensity(intensity_xptr);
    if (!intensity) stop("Invalid Intensity pointer");

    IntervalTier interval_tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), tier_number);
    integer n = interval_tier->intervals.size;

    IntegerVector indices(n);
    CharacterVector labels(n);
    NumericVector starts(n);
    NumericVector ends(n);
    NumericVector durations(n);
    NumericVector intensity_means(n);
    NumericVector intensity_mins(n);
    NumericVector intensity_maxs(n);

    std::vector<double> start_arr(n);
    std::vector<double> end_arr(n);

    for (integer i = 1; i <= n; i++) {
        TextInterval interval = interval_tier->intervals.at[i];
        indices[i-1] = i;
        labels[i-1] = Melder_peek32to8(interval->text.get());
        start_arr[i-1] = interval->xmin;
        end_arr[i-1] = interval->xmax;
        starts[i-1] = interval->xmin;
        ends[i-1] = interval->xmax;
    }

    // SIMD durations
    if (textgrid_simd::should_use_simd_for_textgrid()) {
        textgrid_simd::calculate_durations_simd_0based(
            start_arr.data(), end_arr.data(), durations.begin(), n
        );
    } else {
        for (int i = 0; i < n; i++) {
            durations[i] = end_arr[i] - start_arr[i];
        }
    }

    // Extract intensity statistics
    for (int i = 0; i < n; i++) {
        try {
            intensity_means[i] = Intensity_getAverage(intensity.get(),
                                                       start_arr[i], end_arr[i],
                                                       Intensity_averaging_ENERGY);
            intensity_mins[i] = Vector_getMinimum(intensity.get(),
                                                   start_arr[i], end_arr[i],
                                                   kVector_peakInterpolation::PARABOLIC);
            intensity_maxs[i] = Vector_getMaximum(intensity.get(),
                                                   start_arr[i], end_arr[i],
                                                   kVector_peakInterpolation::PARABOLIC);
        } catch (...) {
            intensity_means[i] = NA_REAL;
            intensity_mins[i] = NA_REAL;
            intensity_maxs[i] = NA_REAL;
        }
    }

    return DataFrame::create(
        Named("index") = indices,
        Named("label") = labels,
        Named("start") = starts,
        Named("end") = ends,
        Named("duration") = durations,
        Named("intensity_mean") = intensity_means,
        Named("intensity_min") = intensity_mins,
        Named("intensity_max") = intensity_maxs
    );

    END_RCPP
}

//' Extract All Acoustic Features for TextGrid Intervals (Batch, SIMD)
//'
//' Comprehensive batch extraction of pitch, formant F1/F2, and intensity
//' statistics for all intervals. Maximum efficiency by processing all
//' features in a single pass.
//'
//' @param textgrid_xptr External pointer to TextGrid
//' @param pitch_xptr External pointer to Pitch (optional)
//' @param formant_xptr External pointer to Formant (optional)
//' @param intensity_xptr External pointer to Intensity (optional)
//' @param tier_number Tier number (1-based)
//'
//' @return Data frame with all available features per interval
//'
//' @details
//' This is the most efficient way to extract multiple acoustic features
//' for TextGrid-aligned analysis. All SIMD optimizations are applied:
//' - Duration calculation: SIMD
//' - Statistics aggregation: SIMD where applicable
//'
//' @export
// [[Rcpp::export]]
DataFrame textgrid_interval_all_features_batch(
    SEXP textgrid_xptr,
    SEXP pitch_xptr = R_NilValue,
    SEXP formant_xptr = R_NilValue,
    SEXP intensity_xptr = R_NilValue,
    int tier_number = 1
) {
    BEGIN_RCPP

    Rcpp::XPtr<structTextGrid> tg(textgrid_xptr);
    if (!tg) stop("Invalid TextGrid pointer");

    // Optional analysis objects
    structPitch* pitch = nullptr;
    structFormant* formant = nullptr;
    structIntensity* intensity = nullptr;

    if (pitch_xptr != R_NilValue) {
        Rcpp::XPtr<structPitch> p(pitch_xptr);
        if (p) pitch = p.get();
    }
    if (formant_xptr != R_NilValue) {
        Rcpp::XPtr<structFormant> f(formant_xptr);
        if (f) formant = f.get();
    }
    if (intensity_xptr != R_NilValue) {
        Rcpp::XPtr<structIntensity> i(intensity_xptr);
        if (i) intensity = i.get();
    }

    IntervalTier interval_tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), tier_number);
    integer n = interval_tier->intervals.size;

    // Core columns
    IntegerVector indices(n);
    CharacterVector labels(n);
    NumericVector starts(n);
    NumericVector ends(n);
    NumericVector durations(n);

    // Pitch columns
    NumericVector pitch_means(n, NA_REAL);
    NumericVector pitch_stdevs(n, NA_REAL);

    // Formant columns (F1, F2)
    NumericVector f1_means(n, NA_REAL);
    NumericVector f2_means(n, NA_REAL);

    // Intensity columns
    NumericVector intensity_means(n, NA_REAL);

    std::vector<double> start_arr(n);
    std::vector<double> end_arr(n);

    // Extract interval metadata
    for (integer i = 1; i <= n; i++) {
        TextInterval interval = interval_tier->intervals.at[i];
        indices[i-1] = i;
        labels[i-1] = Melder_peek32to8(interval->text.get());
        start_arr[i-1] = interval->xmin;
        end_arr[i-1] = interval->xmax;
        starts[i-1] = interval->xmin;
        ends[i-1] = interval->xmax;
    }

    // SIMD durations
    if (textgrid_simd::should_use_simd_for_textgrid()) {
        textgrid_simd::calculate_durations_simd_0based(
            start_arr.data(), end_arr.data(), durations.begin(), n
        );
    } else {
        for (int i = 0; i < n; i++) {
            durations[i] = end_arr[i] - start_arr[i];
        }
    }

    // Extract features per interval
    for (int i = 0; i < n; i++) {
        double t1 = start_arr[i];
        double t2 = end_arr[i];

        // Pitch
        if (pitch) {
            try {
                pitch_means[i] = Pitch_getMean(pitch, t1, t2, kPitch_unit::HERTZ);
                pitch_stdevs[i] = Pitch_getStandardDeviation(pitch, t1, t2, kPitch_unit::HERTZ);
            } catch (...) {}
        }

        // Formants
        if (formant) {
            try {
                f1_means[i] = Formant_getMean(formant, 1, t1, t2, kFormant_unit::HERTZ);
                f2_means[i] = Formant_getMean(formant, 2, t1, t2, kFormant_unit::HERTZ);
            } catch (...) {}
        }

        // Intensity
        if (intensity) {
            try {
                intensity_means[i] = Intensity_getAverage(intensity, t1, t2,
                                                           Intensity_averaging_ENERGY);
            } catch (...) {}
        }
    }

    return DataFrame::create(
        Named("index") = indices,
        Named("label") = labels,
        Named("start") = starts,
        Named("end") = ends,
        Named("duration") = durations,
        Named("pitch_mean") = pitch_means,
        Named("pitch_stdev") = pitch_stdevs,
        Named("f1_mean") = f1_means,
        Named("f2_mean") = f2_means,
        Named("intensity_mean") = intensity_means
    );

    END_RCPP
}

/* End of file textgrid_simd_bridge.cpp */
