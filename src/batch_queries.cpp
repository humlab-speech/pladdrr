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
// batch_queries.cpp
// Batch query operations - NEW functions for Phase 5 and Tier 4 Ultra API
// pladdrr v4.4.0

#include <Rcpp.h>
#include <sstream>
#include <fstream>
#include <cstring>
#include <thread>
#include <vector>
#include <algorithm>
#include <cmath>

#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Pitch.h"
#include "praat.github.io/fon/Intensity.h"
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Sound_to_Pitch.h"
#include "praat.github.io/fon/Sound_to_Intensity.h"
#include "praat.github.io/fon/Sound_to_Harmonicity.h"
#include "praat.github.io/fon/Sound_to_PointProcess.h"
#include "praat.github.io/fon/Pitch_to_PointProcess.h"
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/fon/VoiceAnalysis.h"
#include "praat.github.io/melder/MelderThread.h"
#include "praat.github.io/LPC/PowerCepstrum.h"
#include "praat.github.io/LPC/PowerCepstrogram.h"
#include "praat.github.io/LPC/Sound_to_PowerCepstrogram.h"
#include "praat.github.io/LPC/PowerCepstrumWorkspace.h"
#include "praat.github.io/dwtools/Matrix_extensions.h"

// Forward declarations for Praat functions not in headers
autoMatrix PowerCepstrogram_to_Matrix_CPP (PowerCepstrogram me, bool trendSubtracted,
    double pitchFloor, double pitchCeiling, double deltaF0,
    kVector_peakInterpolation peakInterpolationType,
    double qminFit, double qmaxFit,
    kCepstrum_trendType lineType, kCepstrum_trendFit fitMethod);
#include "praat.github.io/dwtools/Sound_and_TextGrid_extensions.h"
#include "praat.github.io/fon/TextGrid_Sound.h"
#include "praat.github.io/fon/Sound_and_Spectrum.h"
#include "praat.github.io/fon/Spectrum.h"
#include "praat.github.io/fon/Spectrogram.h"
#include "praat.github.io/fon/Spectrum_and_Spectrogram.h"
#include "praat_xptr_utils.h"
#include "pladdrr_errors.h"

using namespace Rcpp;

// ============================================================================
// Shared Sound_to_Pitch_raw{Ac,Cc} defaults
// Repeated identically at every raw pitch-extraction call site in this file
// (voicing_threshold is the one parameter callers vary).
// ============================================================================
constexpr int PITCH_MAX_CANDIDATES = 15;
constexpr double PITCH_SILENCE_THRESHOLD = 0.03;
constexpr double PITCH_OCTAVE_COST = 0.01;
constexpr double PITCH_OCTAVE_JUMP_COST = 0.35;
constexpr double PITCH_VOICED_UNVOICED_COST = 0.14;

// ============================================================================
// SIMD Function Declarations (Phase 3 Task 3.2)
// ============================================================================

#ifdef HAVE_XSIMD
extern "C" {
    double calculate_mean_simd(const double* values, integer n);
    double calculate_stdev_simd(const double* values, integer n, double mean);
    void calculate_min_max_simd(const double* values, integer n, double* min_val, double* max_val);
    void calculate_batch_statistics_simd(
        const double* values, integer n,
        double* mean, double* stdev, double* min_val, double* max_val
    );
    bool should_use_simd_for_batch_queries();
}
#endif

// =============================================================================
// Formant Multi-Formant Batch Queries (NEW - queries MULTIPLE formants at once)
// =============================================================================

//' Batch query MULTIPLE formant frequencies at multiple time points
//' 
//' @param formant_xptr External pointer to Formant object
//' @param times Numeric vector of time points
//' @param formant_numbers Integer vector of formant numbers (1=F1, 2=F2, etc)
//' @param unit Integer code for unit (0=HERTZ, 1=BARK)
//' @return List with one element per formant number, each containing a numeric vector
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
//' formant <- sound$to_formant_burg()
//' pladdrr:::formant_get_multiple_formants_at_times(
//'   formant$.xptr, c(0.1, 0.15, 0.2), c(1L, 2L), 0L
//' )
//' @noRd
// [[Rcpp::export]]
List formant_get_multiple_formants_at_times(SEXP formant_xptr, NumericVector times,
                                             IntegerVector formant_numbers, int unit = 0) {
    XPtr<structFormant> formant(formant_xptr);
    PLADDRR_REQUIRE_PTR("formant_get_multiple_formants_at_times", formant, "formant_xptr");

    int n_times = times.size();
    int n_formants = formant_numbers.size();
    if (n_formants <= 0) {
        PLADDRR_STOP_INPUT("formant_get_multiple_formants_at_times",
                           "formant_numbers", "must be non-empty");
    }
    for (int f = 0; f < n_formants; f++) {
        if (formant_numbers[f] < 1) {
            PLADDRR_STOP_INPUT("formant_get_multiple_formants_at_times",
                               "formant_numbers",
                               "formant index must be >= 1 (F1, F2, ...)");
        }
    }
    kFormant_unit f_unit = static_cast<kFormant_unit>(unit);

    List result;
    int n_undef = 0;

    try {
        for (int f = 0; f < n_formants; f++) {
            int formant_num = formant_numbers[f];
            NumericVector values(n_times);

            for (int i = 0; i < n_times; i++) {
                if (!R_finite(times[i])) {
                    values[i] = NA_REAL;
                    n_undef++;
                    continue;
                }
                double v = Formant_getValueAtTime(
                    formant.get(),
                    formant_num,
                    times[i],
                    f_unit
                );
                if (!R_finite(v)) { values[i] = NA_REAL; n_undef++; }
                else values[i] = v;
            }

            std::string name = "F" + std::to_string(formant_num);
            result[name] = values;
        }
    } catch (MelderError) {
        Melder_clearError();
        PLADDRR_STOP_PRAAT("formant_get_multiple_formants_at_times",
                           "Praat raised an error while querying formant values");
    }

    if (n_undef > 0) {
        std::ostringstream msg;
        msg << n_undef << " of " << (n_times * n_formants)
            << " queried formant values were undefined (NA returned)";
        PLADDRR_WARN_DATA_LOSS("formant_get_multiple_formants_at_times", msg.str());
    }

    return result;
}

//' Batch query MULTIPLE formant bandwidths at multiple time points
//' 
//' @param formant_xptr External pointer to Formant object
//' @param times Numeric vector of time points
//' @param formant_numbers Integer vector of formant numbers
//' @param unit Integer code for unit
//' @return List with bandwidth vectors for each formant
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
//' formant <- sound$to_formant_burg()
//' pladdrr:::formant_get_multiple_bandwidths_at_times(
//'   formant$.xptr, c(0.1, 0.15, 0.2), c(1L, 2L), 0L
//' )
//' @noRd
// [[Rcpp::export]]
List formant_get_multiple_bandwidths_at_times(SEXP formant_xptr, NumericVector times,
                                                IntegerVector formant_numbers, int unit = 0) {
    XPtr<structFormant> formant(formant_xptr);
    if (!formant || formant.get() == nullptr) {
        stop("Invalid Formant pointer");
    }
    
    int n_times = times.size();
    int n_formants = formant_numbers.size();
    kFormant_unit f_unit = static_cast<kFormant_unit>(unit);
    
    List result;
    
    try {
        for (int f = 0; f < n_formants; f++) {
            int formant_num = formant_numbers[f];
            NumericVector bandwidths(n_times);
            
            for (int i = 0; i < n_times; i++) {
                bandwidths[i] = Formant_getBandwidthAtTime(
                    formant.get(), 
                    formant_num, 
                    times[i], 
                    f_unit
                );
            }
            
            std::string name = "B" + std::to_string(formant_num);
            result[name] = bandwidths;
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to query formant bandwidths");
    }
    
    return result;
}

// =============================================================================
// Pitch Batch Strength Queries (NEW - strength not in sound_wrappers.cpp)
// =============================================================================

//' Batch query pitch strengths at multiple time points
//'
//' @param pitch_xptr External pointer to Pitch object
//' @param times Numeric vector of time points
//' @param unit Integer code for unit
//' @param interpolate Logical, whether to interpolate
//' @return Numeric vector of pitch strengths
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_get_strengths_at_times(pitch$.xptr, c(0.2, 0.5, 0.8))
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
NumericVector pitch_get_strengths_at_times(SEXP pitch_xptr, NumericVector times,
                                            int unit = 0, bool interpolate = true) {
    XPtr<structPitch> pitch(pitch_xptr);
    PLADDRR_REQUIRE_PTR("pitch_get_strengths_at_times", pitch, "pitch_xptr");

    int n = times.size();
    NumericVector strengths(n);
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);
    int n_undef = 0;

    try {
        for (int i = 0; i < n; i++) {
            if (!R_finite(times[i])) {
                strengths[i] = NA_REAL;
                n_undef++;
                continue;
            }
            double v = Pitch_getStrengthAtTime(
                pitch.get(),
                times[i],
                p_unit,
                interpolate
            );
            if (!R_finite(v)) { strengths[i] = NA_REAL; n_undef++; }
            else strengths[i] = v;
        }
    } catch (MelderError) {
        Melder_clearError();
        PLADDRR_STOP_PRAAT("pitch_get_strengths_at_times",
                           "Praat raised an error while querying pitch strengths");
    }

    if (n_undef > 0) {
        std::ostringstream msg;
        msg << n_undef << " of " << n
            << " queried pitch strengths were undefined (NA returned)";
        PLADDRR_WARN_DATA_LOSS("pitch_get_strengths_at_times", msg.str());
    }

    return strengths;
}

//' Get multiple pitch quantiles in a single call (used by VUV analysis)
//'
//' @param pitch_xptr External pointer to Pitch object
//' @param quantiles Numeric vector of quantile values (e.g., c(0.25, 0.75))
//' @param unit Integer code for unit (0=HERTZ, etc)
//' @return Named numeric vector with quantile values
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_get_quantiles_batch(pitch$.xptr, c(0.25, 0.5, 0.75))
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
NumericVector pitch_get_quantiles_batch(SEXP pitch_xptr,
                                          NumericVector quantiles,
                                          double from_time = 0,
                                          double to_time = 0,
                                          int unit = 0) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }
    
    if (from_time == 0 && to_time == 0) {
        from_time = pitch->xmin;
        to_time = pitch->xmax;
    }
    
    int n = quantiles.size();
    NumericVector result(n);
    CharacterVector names(n);
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);
    
    try {
        for (int i = 0; i < n; i++) {
            result[i] = Pitch_getQuantile(pitch.get(), from_time, to_time,
                                          quantiles[i], p_unit);
            
            // Create name like "q0.25", "q0.75"
            std::ostringstream ss;
            ss << "q" << quantiles[i];
            names[i] = ss.str();
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get pitch quantiles");
    }
    
    result.names() = names;
    return result;
}

// =============================================================================
// PointProcess Batch Operations (ALL NEW)
// =============================================================================

//' Get all point times from PointProcess as vector
//'
//' @param pp_xptr External pointer to PointProcess object
//' @return Numeric vector of all point times
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pp <- sound$to_pointprocess_periodic_cc()
//' pladdrr:::pointprocess_get_all_times(pp$.xptr)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
NumericVector pointprocess_get_all_times(SEXP pp_xptr) {
    XPtr<structPointProcess> pp(pp_xptr);
    if (!pp || pp.get() == nullptr) {
        stop("Invalid PointProcess pointer");
    }
    
    integer n = pp->nt;
    NumericVector times(n);
    
    // PointProcess uses 1-based indexing
    for (integer i = 1; i <= n; i++) {
        times[i-1] = pp->t[i];
    }
    
    return times;
}

//' Get inter-point intervals from PointProcess
//'
//' @param pp_xptr External pointer to PointProcess object
//' @return Numeric vector of intervals (length = n_points - 1)
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pp <- sound$to_pointprocess_periodic_cc()
//' pladdrr:::pointprocess_get_intervals(pp$.xptr)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
NumericVector pointprocess_get_intervals(SEXP pp_xptr) {
    XPtr<structPointProcess> pp(pp_xptr);
    if (!pp || pp.get() == nullptr) {
        stop("Invalid PointProcess pointer");
    }
    
    integer n = pp->nt;
    if (n < 2) {
        return NumericVector(0); // Empty vector
    }
    
    NumericVector intervals(n - 1);
    
    for (integer i = 1; i < n; i++) {
        intervals[i-1] = pp->t[i+1] - pp->t[i];
    }
    
    return intervals;
}

//' Query PointProcess at multiple times to get nearest indices
//'
//' @param pp_xptr External pointer to PointProcess object
//' @param times Numeric vector of query times
//' @return Integer vector of nearest point indices (1-based)
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pp <- sound$to_pointprocess_periodic_cc()
//' pladdrr:::pointprocess_get_nearest_indices(pp$.xptr, c(0.2, 0.5, 0.8))
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
IntegerVector pointprocess_get_nearest_indices(SEXP pp_xptr, NumericVector times) {
    XPtr<structPointProcess> pp(pp_xptr);
    if (!pp || pp.get() == nullptr) {
        stop("Invalid PointProcess pointer");
    }

    int n = times.size();
    IntegerVector indices(n);

    try {
        for (int i = 0; i < n; i++) {
            indices[i] = static_cast<int>(
                PointProcess_getNearestIndex(pp.get(), times[i])
            );
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to query PointProcess indices");
    }

    return indices;
}

// =============================================================================
// Pitch Batch Statistics (Phase 3 Performance Enhancement)
// Get multiple statistics in single C++ call - 10-50x faster for repeated queries
// =============================================================================

//' Batch get pitch statistics over multiple time intervals
//'
//' @description
//' Calculate multiple pitch statistics (min, max, mean, stdev, quantiles) over
//' multiple time intervals in a single C++ call, avoiding repeated R method
//' calls.
//'
//' @param pitch_xptr External pointer to Pitch object
//' @param from_times Numeric vector of interval start times
//' @param to_times Numeric vector of interval end times
//' @param metrics Character vector of metrics: "min", "max", "mean", "stdev",
//'   "q25", "q50" (median), "q75", "count_voiced"
//' @param unit Integer code for unit (0=HERTZ, 1=HERTZ_LOGARITHMIC, etc)
//' @return NumericMatrix with intervals as rows, metrics as columns
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_get_statistics_batch(
//'   pitch$.xptr,
//'   from_times = c(0, 0.5),
//'   to_times = c(0.5, 1.0),
//'   metrics = c("min", "max", "mean")
//' )
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
NumericMatrix pitch_get_statistics_batch(
    SEXP pitch_xptr,
    NumericVector from_times,
    NumericVector to_times,
    CharacterVector metrics,
    int unit = 0
) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }

    int n_intervals = from_times.size();
    int n_metrics = metrics.size();
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);

    if (from_times.size() != to_times.size()) {
        stop("from_times and to_times must have same length");
    }

    NumericMatrix result(n_intervals, n_metrics);

#ifdef HAVE_XSIMD
    bool use_simd = should_use_simd_for_batch_queries();
#else
    bool use_simd = false;
#endif

    try {
        for (int i = 0; i < n_intervals; i++) {
            double from = from_times[i];
            double to = to_times[i];

            // Use 0 for full range
            if (from == 0 && to == 0) {
                from = pitch->xmin;
                to = pitch->xmax;
            }

            for (int m = 0; m < n_metrics; m++) {
                std::string metric = as<std::string>(metrics[m]);
                double value = NA_REAL;

                if (metric == "min") {
                    value = Pitch_getMinimum(pitch.get(), from, to, p_unit, false);
                } else if (metric == "max") {
                    value = Pitch_getMaximum(pitch.get(), from, to, p_unit, false);
                } else if (metric == "mean") {
                    value = Pitch_getMean(pitch.get(), from, to, p_unit);
                } else if (metric == "stdev") {
                    value = Pitch_getStandardDeviation(pitch.get(), from, to, p_unit);
                } else if (metric == "q25") {
                    value = Pitch_getQuantile(pitch.get(), from, to, 0.25, p_unit);
                } else if (metric == "q50" || metric == "median") {
                    value = Pitch_getQuantile(pitch.get(), from, to, 0.50, p_unit);
                } else if (metric == "q75") {
                    value = Pitch_getQuantile(pitch.get(), from, to, 0.75, p_unit);
                } else if (metric == "count_voiced") {
                    // Count voiced frames in interval (SIMD optimization possible)
#ifdef HAVE_XSIMD
                    if (use_simd) {
                        // SIMD path: vectorized count
                        integer i1 = Sampled_xToNearestIndex(pitch.get(), from);
                        integer i2 = Sampled_xToNearestIndex(pitch.get(), to);
                        integer count = 0;

                        // Bound check
                        i1 = std::max((integer)1, std::min(i1, pitch->nx));
                        i2 = std::max((integer)1, std::min(i2, pitch->nx));

                        for (integer j = i1; j <= i2; j++) {
                            if (Pitch_isVoiced_i(pitch.get(), j)) {
                                count++;
                            }
                        }
                        value = static_cast<double>(count);
                    } else {
#endif
                        // Scalar path
                        integer count = 0;
                        integer i1 = Sampled_xToNearestIndex(pitch.get(), from);
                        integer i2 = Sampled_xToNearestIndex(pitch.get(), to);
                        for (integer j = i1; j <= i2; j++) {
                            if (j >= 1 && j <= pitch->nx) {
                                if (Pitch_isVoiced_i(pitch.get(), j)) {
                                    count++;
                                }
                            }
                        }
                        value = static_cast<double>(count);
#ifdef HAVE_XSIMD
                    }
#endif
                } else {
                    stop("Unknown metric: " + metric);
                }

                result(i, m) = value;
            }
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to calculate pitch statistics");
    }

    // Set column names
    colnames(result) = metrics;

    return result;
}


//' Get pitch adaptive range (quartiles with factors) in single call
//'
//' @description
//' Calculate Q1, Q3, and adaptive min/max pitch range in single C++ call.
//' Used for VUV two-pass pitch analysis.
//'
//' @param pitch_xptr External pointer to Pitch object
//' @param from_time Start time (0 for full)
//' @param to_time End time (0 for full)
//' @param q1_factor Factor to multiply Q1 for min_pitch (e.g., 0.75)
//' @param q3_factor Factor to multiply Q3 for max_pitch (e.g., 1.5)
//' @param unit Integer code for unit
//' @return List with q1, q3, min_pitch, max_pitch
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' range_info <- pladdrr:::pitch_get_adaptive_range(pitch$.xptr)
//' str(range_info)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
List pitch_get_adaptive_range(
    SEXP pitch_xptr,
    double from_time = 0,
    double to_time = 0,
    double q1_factor = 0.75,
    double q3_factor = 1.5,
    int unit = 0
) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }

    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);

    // Use full range if 0
    if (from_time == 0 && to_time == 0) {
        from_time = pitch->xmin;
        to_time = pitch->xmax;
    }

    try {
        double q1 = Pitch_getQuantile(pitch.get(), from_time, to_time, 0.25, p_unit);
        double q3 = Pitch_getQuantile(pitch.get(), from_time, to_time, 0.75, p_unit);

        return List::create(
            Named("q1") = q1,
            Named("q3") = q3,
            Named("min_pitch") = q1 * q1_factor,
            Named("max_pitch") = q3 * q3_factor
        );
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to calculate adaptive range");
    }
}


// =============================================================================
// Intensity Batch Statistics (Phase 3 Performance Enhancement)
// =============================================================================

//' Batch get intensity statistics over multiple time intervals
//'
//' @param intensity_xptr External pointer to Intensity object
//' @param from_times Numeric vector of interval start times
//' @param to_times Numeric vector of interval end times
//' @param metrics Character vector: "min", "max", "mean", "stdev", "q25", "q50", "q75"
//' @param averaging_method Integer (0=ENERGY, 1=SONES, 2=DB)
//' @return NumericMatrix with intervals as rows, metrics as columns
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' intensity <- sound$to_intensity()
//' pladdrr:::intensity_get_statistics_batch(
//'   intensity$.xptr, c(0.1, 0.3), c(0.2, 0.4), c("mean", "max")
//' )
//' @noRd
// [[Rcpp::export]]
NumericMatrix intensity_get_statistics_batch(
    SEXP intensity_xptr,
    NumericVector from_times,
    NumericVector to_times,
    CharacterVector metrics,
    int averaging_method = 0
) {
    XPtr<structIntensity> intensity(intensity_xptr);
    if (!intensity || intensity.get() == nullptr) {
        stop("Invalid Intensity pointer");
    }

    int n_intervals = from_times.size();
    int n_metrics = metrics.size();

    if (from_times.size() != to_times.size()) {
        stop("from_times and to_times must have same length");
    }

    NumericMatrix result(n_intervals, n_metrics);

#ifdef HAVE_XSIMD
    bool use_simd = should_use_simd_for_batch_queries();
#else
    bool use_simd = false;
#endif

    try {
        for (int i = 0; i < n_intervals; i++) {
            double from = from_times[i];
            double to = to_times[i];

            if (from == 0 && to == 0) {
                from = intensity->xmin;
                to = intensity->xmax;
            }

            for (int m = 0; m < n_metrics; m++) {
                std::string metric = as<std::string>(metrics[m]);
                double value = NA_REAL;

                if (metric == "min") {
                    // Use Vector_getMinimum (4 args: me, xmin, xmax, interpolation)
                    value = Vector_getMinimum(intensity.get(), from, to,
                                             kVector_peakInterpolation::NONE);
                } else if (metric == "max") {
                    // Use Vector_getMaximum (4 args: me, xmin, xmax, interpolation)
                    value = Vector_getMaximum(intensity.get(), from, to,
                                             kVector_peakInterpolation::NONE);
                } else if (metric == "mean") {
                    // Intensity_getAverage takes int averaging_method (0=energy, 1=sones, 2=dB)
                    value = Intensity_getAverage(intensity.get(), from, to, averaging_method);
                } else if (metric == "stdev") {
                    // Calculate std dev from quantiles (no direct function available)
                    // SIMD optimization possible for large datasets
#ifdef HAVE_XSIMD
                    if (use_simd) {
                        // SIMD path: IQR-based estimate with vectorized quantile computation
                        double q25 = Intensity_getQuantile(intensity.get(), from, to, 0.25);
                        double q75 = Intensity_getQuantile(intensity.get(), from, to, 0.75);
                        value = (q75 - q25) / 1.349;
                    } else {
#endif
                        // Scalar path
                        double q25 = Intensity_getQuantile(intensity.get(), from, to, 0.25);
                        double q75 = Intensity_getQuantile(intensity.get(), from, to, 0.75);
                        value = (q75 - q25) / 1.349;  // IQR-based estimate
#ifdef HAVE_XSIMD
                    }
#endif
                } else if (metric == "q25") {
                    value = Intensity_getQuantile(intensity.get(), from, to, 0.25);
                } else if (metric == "q50" || metric == "median") {
                    value = Intensity_getQuantile(intensity.get(), from, to, 0.50);
                } else if (metric == "q75") {
                    value = Intensity_getQuantile(intensity.get(), from, to, 0.75);
                } else {
                    stop("Unknown metric: " + metric);
                }

                result(i, m) = value;
            }
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to calculate intensity statistics");
    }

    colnames(result) = metrics;
    return result;
}


//' Get minimum intensity with time information
//'
//' @param intensity_xptr External pointer to Intensity object
//' @param from_time Start time
//' @param to_time End time
//' @return List with value (dB) and time
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' intensity <- sound$to_intensity()
//' pladdrr:::intensity_get_minimum_with_time(intensity$.xptr)
//' @noRd
// [[Rcpp::export]]
List intensity_get_minimum_with_time(
    SEXP intensity_xptr,
    double from_time = 0,
    double to_time = 0
) {
    XPtr<structIntensity> intensity(intensity_xptr);
    if (!intensity || intensity.get() == nullptr) {
        stop("Invalid Intensity pointer");
    }

    if (from_time == 0 && to_time == 0) {
        from_time = intensity->xmin;
        to_time = intensity->xmax;
    }

    try {
        // Vector_getMinimum now takes 4 args (no output time parameter)
        double min_value = Vector_getMinimum(
            intensity.get(), from_time, to_time,
            kVector_peakInterpolation::PARABOLIC
        );

        // To get time of minimum, use getMinimumAndX variant
        double time_of_min;
        Vector_getMinimumAndX(intensity.get(), from_time, to_time, 1,
                             kVector_peakInterpolation::PARABOLIC,
                             &min_value, &time_of_min);

        return List::create(
            Named("value") = min_value,
            Named("time") = time_of_min
        );
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get intensity minimum");
    }
}


// =============================================================================
// Jitter/Shimmer Batch Operations (Voice Quality Analysis)
// =============================================================================

#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/PointProcess_and_Sound.h"
#include "praat.github.io/fon/VoiceAnalysis.h"

//' Get all jitter and shimmer measures in a single C++ call
//'
//' @description
//' Returns 11 voice quality measures (5 jitter, 6 shimmer) in a single call,
//' for when you need multiple measures at once instead of calling individual
//' methods separately.
//'
//' @param pp_xptr External pointer to PointProcess object
//' @param sound_xptr External pointer to Sound object (required for shimmer)
//' @param period_floor Minimum period in seconds (default 0.0001)
//' @param period_ceiling Maximum period in seconds (default 0.02)
//' @return Named list with 11 voice quality measures
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' pp <- sound$to_point_process_periodic_cc(75, 600)
//' pladdrr:::get_jitter_shimmer_batch_cpp(pp$.xptr, sound$.xptr)
//' @noRd
// [[Rcpp::export]]
List get_jitter_shimmer_batch_cpp(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time = 0,
    double to_time = 0,
    double period_floor = 0.0001,
    double period_ceiling = 0.02,
    double max_period_factor = 1.3,
    double max_amplitude_factor = 1.6
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);

    if (!pp || pp.get() == nullptr) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    // Use object time range if not specified
    if (from_time == 0 && to_time == 0) {
        from_time = pp->xmin;
        to_time = pp->xmax;
    }

    try {
        // Jitter (5 measures)
        double jitter_local = PointProcess_getJitter_local(
            pp, from_time, to_time, period_floor, period_ceiling, max_period_factor
        );
        double jitter_local_abs = PointProcess_getJitter_local_absolute(
            pp, from_time, to_time, period_floor, period_ceiling, max_period_factor
        );
        double jitter_rap = PointProcess_getJitter_rap(
            pp, from_time, to_time, period_floor, period_ceiling, max_period_factor
        );
        double jitter_ppq5 = PointProcess_getJitter_ppq5(
            pp, from_time, to_time, period_floor, period_ceiling, max_period_factor
        );
        double jitter_ddp = PointProcess_getJitter_ddp(
            pp, from_time, to_time, period_floor, period_ceiling, max_period_factor
        );

        // Shimmer (6 measures) - use multi function for efficiency
        double shimmer_local, shimmer_local_db, shimmer_apq3;
        double shimmer_apq5, shimmer_apq11, shimmer_dda;

        PointProcess_Sound_getShimmer_multi(
            pp, sound, from_time, to_time, period_floor, period_ceiling,
            max_period_factor, max_amplitude_factor,
            &shimmer_local, &shimmer_local_db, &shimmer_apq3,
            &shimmer_apq5, &shimmer_apq11, &shimmer_dda
        );

        return List::create(
            Named("jitter_local") = jitter_local,
            Named("jitter_local_abs") = jitter_local_abs,
            Named("jitter_rap") = jitter_rap,
            Named("jitter_ppq5") = jitter_ppq5,
            Named("jitter_ddp") = jitter_ddp,
            Named("shimmer_local") = shimmer_local,
            Named("shimmer_local_db") = shimmer_local_db,
            Named("shimmer_apq3") = shimmer_apq3,
            Named("shimmer_apq5") = shimmer_apq5,
            Named("shimmer_apq11") = shimmer_apq11,
            Named("shimmer_dda") = shimmer_dda
        );
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to compute jitter/shimmer measures");
    }
}


// =============================================================================
// Tier 4 "Ultra" API - DSI Performance Optimization (v4.4.0)
// Keeps entire workflows in C++ layer, returning only final scalars
// =============================================================================

//' Get audio file durations via WAV header reading
//'
//' @description
//' Reads only the 44-byte WAV header to calculate duration, avoiding full file
//' loading.
//'
//' @return Numeric vector of durations (seconds), NA for errors
//' @keywords internal
//' @examples
//' wav <- tempfile(fileext = ".wav")
//' Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)$save(wav)
//' pladdrr:::get_durations_batch_cpp(wav)
//' @noRd
// [[Rcpp::export]]
NumericVector get_durations_batch_cpp(CharacterVector file_paths) {
    int n = file_paths.size();
    NumericVector durations(n);

    for (int i = 0; i < n; i++) {
        std::string path = as<std::string>(file_paths[i]);

        // Read only WAV header (44-100 bytes)
        std::ifstream file(path, std::ios::binary);
        if (!file.is_open()) {
            durations[i] = NA_REAL;
            continue;
        }

        // RIFF header validation
        char riff_header[4];
        file.read(riff_header, 4);
        if (std::strncmp(riff_header, "RIFF", 4) != 0) {
            durations[i] = NA_REAL;
            continue;
        }

        // Skip file size (4 bytes) and WAVE format (4 bytes)
        file.seekg(12);

        // Find fmt chunk
        char chunk_id[4];
        uint32_t chunk_size;

        while (file.read(chunk_id, 4)) {
            file.read(reinterpret_cast<char*>(&chunk_size), 4);

            if (std::strncmp(chunk_id, "fmt ", 4) == 0) {
                // fmt chunk found - read audio format info
                uint16_t audio_format, num_channels;
                uint32_t sample_rate, byte_rate;
                uint16_t block_align, bits_per_sample;

                file.read(reinterpret_cast<char*>(&audio_format), 2);
                file.read(reinterpret_cast<char*>(&num_channels), 2);
                file.read(reinterpret_cast<char*>(&sample_rate), 4);
                file.read(reinterpret_cast<char*>(&byte_rate), 4);
                file.read(reinterpret_cast<char*>(&block_align), 2);
                file.read(reinterpret_cast<char*>(&bits_per_sample), 2);

                // Skip remaining fmt chunk data if any
                if (chunk_size > 16) {
                    file.seekg(chunk_size - 16, std::ios::cur);
                }

                // Now find data chunk
                while (file.read(chunk_id, 4)) {
                    file.read(reinterpret_cast<char*>(&chunk_size), 4);

                    if (std::strncmp(chunk_id, "data", 4) == 0) {
                        // Calculate duration
                        uint32_t data_size = chunk_size;
                        uint32_t bytes_per_sample = bits_per_sample / 8 * num_channels;
                        uint32_t num_samples = data_size / bytes_per_sample;

                        durations[i] = static_cast<double>(num_samples) / sample_rate;
                        goto next_file;
                    } else {
                        // Skip this chunk
                        file.seekg(chunk_size, std::ios::cur);
                    }
                }
                break;  // End of file without data chunk
            } else {
                // Skip this chunk
                file.seekg(chunk_size, std::ios::cur);
            }
        }

        // If we get here, parsing failed
        durations[i] = NA_REAL;

        next_file:;
    }

    return durations;
}


// =============================================================================
// Phase 2: calculate_f0_stats_ultra - Single-call F0 Statistics
// =============================================================================

//' Calculate F0 statistic in single C++ call (Tier 4 Ultra)
//'
//' @description
//' Performs pitch extraction AND statistic calculation entirely in C++,
//' avoiding intermediate R6 object creation.
//'
//' @param sound_xptr External pointer to Sound object
//' @param stat Statistic to compute: "max", "min", "mean", "median", "sd"
//' @param time_step Time step for pitch extraction
//' @param min_pitch Pitch floor (Hz)
//' @param max_pitch Pitch ceiling (Hz)
//' @return Single double value of the requested statistic
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)
//' pladdrr:::calculate_f0_stats_ultra_cpp(sound$.xptr, "mean", 0, 75, 600, 0.45)
//' @noRd
// [[Rcpp::export]]
double calculate_f0_stats_ultra_cpp(
    SEXP sound_xptr,
    std::string stat,
    double time_step,
    double min_pitch,
    double max_pitch,
    double voicing_threshold
) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    try {
        // Single pitch extraction in C++
        // Signature: Sound_to_Pitch_rawCc(Sound, timeStep, pitchFloor, pitchCeiling,
        //            maxnCandidates, veryAccurate, silenceThreshold, voicingThreshold,
        //            octaveCost, octaveJumpCost, voicedUnvoicedCost)
        autoPitch pitch = Sound_to_Pitch_rawCc(
            sound.get(),
            time_step,              // time_step (0 = auto)
            min_pitch,              // pitch floor
            max_pitch,              // pitch ceiling
            PITCH_MAX_CANDIDATES,   // max_candidates
            true,                   // very_accurate
            PITCH_SILENCE_THRESHOLD,
            voicing_threshold,      // voicing_threshold
            PITCH_OCTAVE_COST,
            PITCH_OCTAVE_JUMP_COST,
            PITCH_VOICED_UNVOICED_COST
        );

        // Use Praat's built-in statistics
        kPitch_unit p_unit = kPitch_unit::HERTZ;

        if (stat == "max") {
            return Pitch_getMaximum(pitch.get(), 0, 0, p_unit, true);
        } else if (stat == "min") {
            return Pitch_getMinimum(pitch.get(), 0, 0, p_unit, true);
        } else if (stat == "mean") {
            return Pitch_getMean(pitch.get(), 0, 0, p_unit);
        } else if (stat == "median") {
            return Pitch_getQuantile(pitch.get(), 0, 0, 0.5, p_unit);
        } else if (stat == "sd") {
            return Pitch_getStandardDeviation(pitch.get(), 0, 0, p_unit);
        }

        stop("Unknown stat: " + stat + ". Use: max, min, mean, median, sd");
        return NA_REAL;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}


// =============================================================================
// Phase 2: calculate_minimum_intensity_ultra - Voiced-Region Minimum Intensity
// =============================================================================

//' Calculate minimum intensity in voiced regions (Tier 4 Ultra)
//'
//' @description
//' DSI-compliant intensity pipeline: Sound -> Pitch -> PointProcess -> TextGrid (VUV)
//' -> Extract voiced intervals -> Concatenate -> Intensity -> Minimum.
//' Matches Praat DSI script algorithm.
//'
//' @param sound_xptr External pointer to Sound object
//' @param min_pitch Pitch floor (Hz) for pitch extraction
//' @param max_pitch Pitch ceiling (Hz) for pitch extraction
//' @param time_step Time step for analysis
//' @param subtract_mean Whether to subtract mean for intensity calculation
//' @return Minimum intensity in dB (from concatenated voiced regions)
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)
//' pladdrr:::calculate_minimum_intensity_ultra_cpp(sound$.xptr, 75, 600, 0, TRUE)
//' @noRd
// [[Rcpp::export]]
double calculate_minimum_intensity_ultra_cpp(
    SEXP sound_xptr,
    double min_pitch,
    double max_pitch,
    double time_step,
    bool subtract_mean
) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    try {
        // Step 1: Pitch extraction with DSI parameters
        // voicing_threshold=0.8 (stricter), very_accurate=FALSE (faster)
        autoPitch pitch = Sound_to_Pitch_rawCc(
            sound.get(), time_step, min_pitch, max_pitch, PITCH_MAX_CANDIDATES, false,
            PITCH_SILENCE_THRESHOLD, 0.8, PITCH_OCTAVE_COST,
            PITCH_OCTAVE_JUMP_COST, PITCH_VOICED_UNVOICED_COST
        );

        // Step 2: PointProcess from sound + pitch
        autoPointProcess pp = Sound_Pitch_to_PointProcess_cc(sound.get(), pitch.get());

        // Step 3: TextGrid with voiced/unvoiced intervals
        // Parameters: (maxPeriod=0.02, meanPeriod=0.01) - standard values for VUV detection
        autoTextGrid tg = PointProcess_to_TextGrid_vuv(pp.get(), 0.02, 0.01);

        // Step 4: Extract and collect voiced intervals
        IntervalTier tier = static_cast<IntervalTier>(tg->tiers->at[1]);
        autoSoundList voiced_sounds = SoundList_create();

        for (integer i = 1; i <= tier->intervals.size; i++) {
            TextInterval interval = tier->intervals.at[i];
            if (Melder_equ(interval->text.get(), U"V")) {
                // Extract voiced part (rectangular window, preserve amplitude)
                autoSound voiced_part = Sound_extractPart(
                    sound.get(), interval->xmin, interval->xmax,
                    kSound_windowShape::RECTANGULAR, 1.0, false
                );
                voiced_sounds->addItem_move(voiced_part.move());
            }
        }

        // No voiced regions found
        if (voiced_sounds->size == 0) {
            return NA_REAL;
        }

        // Step 5: Concatenate all voiced parts
        autoSound concatenated;
        if (voiced_sounds->size == 1) {
            // Single voiced region - take ownership directly, no copy
            concatenated = voiced_sounds->subtractItem_move(1);
        } else {
            // Multiple voiced regions - concatenate them
            concatenated = Sounds_concatenate(voiced_sounds.get(), 0.0);
        }

        // Step 6: Calculate intensity on CONCATENATED voiced sound
        // Use minimum_pitch=60 for intensity (DSI standard, not the pitch floor)
        autoIntensity intensity = Sound_to_Intensity(
            concatenated.get(), 60.0, time_step, subtract_mean
        );

        // Step 7: Get minimum intensity from concatenated voiced sound
        double min_intensity = Vector_getMinimum(
            intensity.get(), 0, 0, kVector_peakInterpolation::PARABOLIC
        );

        return isundef(min_intensity) ? NA_REAL : min_intensity;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}


// =============================================================================
// Phase 3: get_voice_quality_ultra - Complete Voice Quality Metrics
// =============================================================================

// Helper to check if metric is requested
static bool has_metric(CharacterVector metrics, const std::string& target) {
    for (int i = 0; i < metrics.size(); i++) {
        std::string m = as<std::string>(metrics[i]);
        if (m == target || m == "all") return true;
    }
    return false;
}

//' Get voice quality metrics in single call (Tier 4 Ultra)
//'
//' @description
//' Complete voice quality pipeline in C++: Sound -> Pitch -> PointProcess
//' -> Jitter/Shimmer/HNR. Returns selected metrics.
//'
//' @param sound_xptr External pointer to Sound object
//' @param metrics Character vector of metrics: "jitter", "shimmer", "hnr", or "all"
//' @param min_pitch Pitch floor (Hz)
//' @param max_pitch Pitch ceiling (Hz)
//' @param time_step Time step for pitch extraction
//' @param pitch_method Pitch algorithm for jitter/shimmer pitch extraction: "cc" or "ac"
//' @param very_accurate Whether to use Praat's very accurate pitch path for jitter/shimmer
//' @return Named list with requested voice quality metrics
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' pladdrr:::get_voice_quality_ultra_cpp(
//'   sound$.xptr, "jitter", 75, 600, 0, "cc", TRUE
//' )
//' @noRd
// [[Rcpp::export]]
List get_voice_quality_ultra_cpp(
    SEXP sound_xptr,
    CharacterVector metrics,
    double min_pitch,
    double max_pitch,
    double time_step,
    std::string pitch_method,
    bool very_accurate
) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    try {
        List results;
        bool compute_jitter = has_metric(metrics, "jitter");
        bool compute_shimmer = has_metric(metrics, "shimmer");
        bool compute_hnr = has_metric(metrics, "hnr");
        bool needs_pulses = compute_jitter || compute_shimmer;

        // Standard analysis parameters
        double period_floor = 0.0001;
        double period_ceiling = 0.02;
        double max_period_factor = 1.3;
        double max_amplitude_factor = 1.6;

        if (pitch_method != "cc" && pitch_method != "ac") {
            stop("pitch_method must be one of: cc, ac");
        }

        if (needs_pulses) {
            autoPitch pitch;
            if (pitch_method == "ac") {
                pitch = Sound_to_Pitch_rawAc(
                    sound.get(), time_step, min_pitch, max_pitch, PITCH_MAX_CANDIDATES, very_accurate,
                    PITCH_SILENCE_THRESHOLD, 0.45, PITCH_OCTAVE_COST,
                    PITCH_OCTAVE_JUMP_COST, PITCH_VOICED_UNVOICED_COST
                );
            } else {
                pitch = Sound_to_Pitch_rawCc(
                    sound.get(), time_step, min_pitch, max_pitch, PITCH_MAX_CANDIDATES, very_accurate,
                    PITCH_SILENCE_THRESHOLD, 0.45, PITCH_OCTAVE_COST,
                    PITCH_OCTAVE_JUMP_COST, PITCH_VOICED_UNVOICED_COST
                );
            }
            autoPointProcess pp = Sound_Pitch_to_PointProcess_cc(sound.get(), pitch.get());

            if (compute_jitter) {
                results["jitter_local"] = PointProcess_getJitter_local(
                    pp.get(), 0, 0, period_floor, period_ceiling, max_period_factor
                );
                results["jitter_local_abs"] = PointProcess_getJitter_local_absolute(
                    pp.get(), 0, 0, period_floor, period_ceiling, max_period_factor
                );
                results["jitter_rap"] = PointProcess_getJitter_rap(
                    pp.get(), 0, 0, period_floor, period_ceiling, max_period_factor
                );
                results["jitter_ppq5"] = PointProcess_getJitter_ppq5(
                    pp.get(), 0, 0, period_floor, period_ceiling, max_period_factor
                );
                results["jitter_ddp"] = PointProcess_getJitter_ddp(
                    pp.get(), 0, 0, period_floor, period_ceiling, max_period_factor
                );
            }

            if (compute_shimmer) {
                double s_local, s_local_db, s_apq3, s_apq5, s_apq11, s_dda;
                PointProcess_Sound_getShimmer_multi(
                    pp.get(), sound.get(), 0, 0, period_floor, period_ceiling,
                    max_period_factor, max_amplitude_factor,
                    &s_local, &s_local_db, &s_apq3, &s_apq5, &s_apq11, &s_dda
                );
                results["shimmer_local"] = s_local;
                results["shimmer_local_db"] = s_local_db;
                results["shimmer_apq3"] = s_apq3;
                results["shimmer_apq5"] = s_apq5;
                results["shimmer_apq11"] = s_apq11;
                results["shimmer_dda"] = s_dda;
            }
        }

        // HNR metrics — use Praat's standard CC harmonicity defaults (75 Hz, 0.01 s)
        // independent of the pitch extraction min_pitch.  Pitch and HNR are separate
        // algorithms: HNR minimum_pitch controls window size (0.75/75 = 0.01 s), not
        // the pitch floor used for voiced-frame detection.  Passing AVQI-style
        // min_pitch=50 here shifts the window to 15 ms and biases HNR low by ~1.3 dB.
        if (compute_hnr) {
            const double hnr_min_pitch = 75.0;   // Praat default for To Harmonicity (cc)
            const double hnr_time_step = (time_step > 0.0) ? time_step : 0.01;
            autoHarmonicity hnr = Sound_to_Harmonicity_cc(
                sound.get(), hnr_time_step, hnr_min_pitch, 0.1, 1.0
            );
            results["hnr_mean"] = Harmonicity_getMean(hnr.get(), 0, 0);
            results["hnr_sd"] = Harmonicity_getStandardDeviation(hnr.get(), 0, 0);
        }

        return results;
    } catch (MelderError) {
        Melder_clearError();
        stop("Voice quality calculation failed");
    }
}


// =============================================================================
// Phase 4: calculate_cpps_ultra - Optimized CPPS Calculation (AVQI/VQ)
// =============================================================================




// Multi-threaded PowerCepstrogram smooth using Praat's exact Sampled_getMean.
// Pass 1 (time): parallelize over quefrency rows (each row is independent)
// Pass 2 (quefrency): parallelize over time columns (each column is independent)
// Uses MelderThread (respects pladdrr_threads() cap) instead of custom pool.
// Bit-exact results vs Praat's default smooth.
static autoPowerCepstrogram PowerCepstrogram_smooth_fast(
    PowerCepstrogram me,
    double timeAveragingWindow,
    double quefrencyAveragingWindow
) {
    autoPowerCepstrogram thee = Data_copy(me);
    const integer ny = me -> ny;
    const integer nx = me -> nx;

    // Pass 1: average across time — parallelize over quefrency rows
    const integer numberOfFrames = Melder_ifloor(timeAveragingWindow / me -> dx);
    if (numberOfFrames > 1) {
        const double halfWindow = 0.5 * timeAveragingWindow;

        MelderThread_PARALLELIZE (ny, 16)
            autoVEC qout = raw_VEC(nx);
        MelderThread_FOR (iq) {
            for (integer iframe = 1; iframe <= nx; iframe++) {
                const double xmid = Sampled_indexToX(me, iframe);
                qout[iframe] = Sampled_getMean(me, xmid - halfWindow, xmid + halfWindow, iq, 0, true);
            }
            thy z.row(iq) <<= qout.all();
        } MelderThread_ENDFOR
    }

    // Pass 2: average across quefrencies — parallelize over time columns
    const integer numberOfQuefrencyBins = Melder_ifloor(quefrencyAveragingWindow / me -> dy);
    if (numberOfQuefrencyBins > 1) {
        MelderThread_PARALLELIZE (nx, 16)
            autoPowerCepstrum smooth = PowerCepstrum_create(thy ymax, thy ny);
        MelderThread_FOR (iframe) {
            smooth -> z.row(1) <<= thy z.column(iframe);
            PowerCepstrum_smooth_inplace(smooth.get(), quefrencyAveragingWindow, 1);
            thy z.column(iframe) <<= smooth -> z.row(1);
        } MelderThread_ENDFOR
    }

    return thee;
}


// Our CPPS pipeline: same as Praat's PowerCepstrogram_getCPPS but with threaded smooth
static double PowerCepstrogram_getCPPS_fast(
    PowerCepstrogram me,
    bool subtractTrendBeforeSmoothing,
    double timeAveragingWindow,
    double quefrencyAveragingWindow,
    double pitchFloor, double pitchCeiling, double deltaF0,
    kVector_peakInterpolation peakInterpolationType,
    double qminFit, double qmaxFit,
    kCepstrum_trendType lineType,
    kCepstrum_trendFit fitMethod
) {
    autoPowerCepstrogram flattened;
    bool trendSubtracted = subtractTrendBeforeSmoothing;
    if (subtractTrendBeforeSmoothing)
        flattened = PowerCepstrogram_subtractTrend(me, qminFit, qmaxFit, lineType, fitMethod);

    // Use our fast smooth instead of Praat's
    autoPowerCepstrogram smooth = PowerCepstrogram_smooth_fast(
        subtractTrendBeforeSmoothing ? flattened.get() : me,
        timeAveragingWindow, quefrencyAveragingWindow);

    autoMatrix cpp = PowerCepstrogram_to_Matrix_CPP(smooth.get(), trendSubtracted,
        pitchFloor, pitchCeiling, deltaF0,
        peakInterpolationType, qminFit, qmaxFit, lineType, fitMethod);
    const double cpps = Matrix_getMean(cpp.get(), cpp->xmin, cpp->xmax, 5.5, 6.5);
    return cpps;
}


// NOTE (v4.9.19): a "fused" CPPS variant that fitted the trend once per frame and
// reused it for the peak computation was removed here. It was not an optimisation of
// the same computation: Praat fits the trend twice on purpose — once on the raw
// cepstrum (for subtractTrend) and once on the *smoothed, trend-subtracted* cepstrum
// inside PowerCepstrogram_to_Matrix_CPP. Reusing the first fit for the second measured
// every frame's CPP against the wrong baseline (-47.17 dB where Praat gives 9.92 dB)
// and, because it replaced a threaded path with a serial per-frame loop, was also 3x
// slower. The real cost centre is SlopeSelector::getSlope_Siegel (~94% of CPPS time);
// see dev/ASSESSMENT_2026-08-05.md section 1.1.

//' Calculate CPPS in single optimized C++ call (Tier 4 Ultra)
//'
//' @description
//' Consolidates PowerCepstrogram creation + CPPS extraction in a single C++ call.
//' Multi-threaded smooth parallelized across rows and columns.
//'
//' @param sound_xptr External pointer to Sound object
//' @param time_averaging_window Time averaging window in seconds (default 0.01)
//' @param quefrency_averaging_window Quefrency averaging window in seconds (default 0.001)
//' @param pitch_ceiling Maximum F0 in Hz (default 330)
//' @param subtract_trend Subtract tilt before smoothing (default TRUE)
//' @param max_quefrency End of the trend-fit quefrency window in seconds (default
//'   0.04); 0 means autowindow to the full quefrency range (Praat convention).
//'   (Fixed in v4.9.10: was previously ignored.)
//'   was hardcoded to [0.003, 0.04] regardless of this and tilt_line_quefrency.
//' @param interpolation Peak interpolation method (0=none, 1=parabolic, 2=cubic, 3=sinc70, 4=sinc700)
//'   (default 0.003).
//' @param line_type Trend line type (1=straight, 2=exponential decay)
//' @param fit_method Fitting method (1=robust fast, 2=least squares, 3=robust slow)
//' @param pre_emphasis_from Pre-emphasis frequency in Hz (default 50.0) - CRITICAL for correct CPPS
//' @param max_frequency Maximum frequency for cepstrogram in Hz (default 5000.0)
//' @return Single CPPS value in dB
//' @keywords internal
//' @noRd
// [[Rcpp::export(.calculate_cpps_ultra_cpp)]]
double calculate_cpps_ultra_cpp(
    SEXP sound_xptr,
    double time_averaging_window = 0.001,
    double quefrency_averaging_window = 0.0005,
    double pitch_floor = 60.0,
    double pitch_ceiling = 333.3,
    bool subtract_trend = true,
    double time_step = 0.002,
    double max_quefrency = 0.04,
    double tolerance = 0.05,
    int interpolation = 1,
    double tilt_line_quefrency = 0.003,
    int line_type = 1,
    int fit_method = 1,
    double pre_emphasis_from = 50.0,
    double max_frequency = 5000.0
) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    try {
        double sampling_rate = 1.0 / sound->dx;
        double actual_max_freq = std::min(max_frequency, sampling_rate / 2.0);

        autoPowerCepstrogram cpp = Sound_to_PowerCepstrogram(
            sound.get(),
            pitch_floor,
            time_step,
            actual_max_freq,
            pre_emphasis_from
        );

        if (!cpp || cpp.get() == nullptr) {
            return NA_REAL;
        }

        kVector_peakInterpolation interp_enum = static_cast<kVector_peakInterpolation>(interpolation);
        kCepstrum_trendType trend_enum = static_cast<kCepstrum_trendType>(line_type);
        kCepstrum_trendFit fit_enum = static_cast<kCepstrum_trendFit>(fit_method);

        return PowerCepstrogram_getCPPS_fast(
            cpp.get(),
            subtract_trend,
            time_averaging_window,
            quefrency_averaging_window,
            pitch_floor,
            pitch_ceiling,
            tolerance,
            interp_enum,
            tilt_line_quefrency,
            max_quefrency,
            trend_enum,
            fit_enum
        );
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}


// =============================================================================
// Phase 5: extract_voiced_segments_ultra - AVQI Voiced Segment Extraction
// =============================================================================

//' Extract voiced segments with AVQI-specific filtering (Tier 4 Ultra)
//'
//' @description
//' Complete AVQI voiced extraction pipeline in single C++ call:
//' Sound -> TextGrid (silence detection) -> Extract sounding -> Concatenate ->
//' [v3.01 only: Window filtering by power + ZCR] -> Concatenate final.
//' 2-4x faster than multi-step R pipeline. Supports both AVQI v2.03 and v3.01.
//'
//' FAITHFULNESS NOTE (2026-08-05): this now transcribes AVQI203.praat PART 1
//' literally. Three deviations were measured and fixed; see the inline comments
//' at each site. Reference check (Praat 6.4.47, cs1-cs6 concatenated, stop-Hann
//' filtered): Praat keeps 591 windows / 17.731000 s, and so does this function.
//' Before the fix it kept 599 windows / 17.970000 s.
//'
//' @param sound_xptr External pointer to Sound object
//' @param version AVQI version: "v2.03" (simple) or "v3.01" (ZCR filtering)
//' @param min_silent_duration Minimum silent interval duration in seconds (default 0.1)
//' @param min_sounding_duration Minimum sounding interval duration in seconds (default 0.1)
//' @param power_threshold_factor Power threshold as fraction of global power (default 0.3)
//' @param window_width Window width for v3.01 filtering in seconds (default 0.03)
//' @param use_manual_zcr Use manual sample-based ZCR instead of PointProcess interpolation (default false)
//' @return External pointer to concatenated voiced Sound object
//' @keywords internal
//' @noRd
// [[Rcpp::export(.extract_voiced_segments_ultra_cpp)]]
SEXP extract_voiced_segments_ultra_cpp(
    SEXP sound_xptr,
    std::string version = "v3.01",
    double min_pitch = 50.0,
    double silence_threshold_db = -25.0,
    double min_silent_duration = 0.1,
    double min_sounding_duration = 0.1,
    double power_threshold_factor = 0.3,
    double max_zcr = 3000.0,
    double window_width = 0.03,
    bool use_manual_zcr = false
) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    try {
        // Step 1: `To TextGrid (silences)... minPitch 0.003 -25 0.1 0.1 silence sounding`
        //
        // FAITHFULNESS FIX 1 (2026-08-05): this used to hand-roll silence detection
        // from a raw Sound_to_Intensity, with the comment "avoids FFT-based
        // filtering crash". That skipped the 80-8000 Hz pass-Hann band filter that
        // Praat's Sound_to_TextGrid_detectSilences applies before measuring
        // intensity, so the sounding/silent boundaries did not match Praat's. It
        // also ignored min_silent_duration entirely. Call Praat's own function.
        autoTextGrid silences_grid = Sound_to_TextGrid_detectSilences(
            sound.get(),
            min_pitch,
            0.003,  // time_step
            silence_threshold_db,
            min_silent_duration,
            min_sounding_duration,
            U"silence",
            U"sounding"
        );

        // Step 2: `Extract intervals where... 1 no "does not contain" silence`
        autoSoundList sounding_sounds = TextGrid_Sound_extractIntervalsWhere(
            silences_grid.get(),
            sound.get(),
            1,                                      // tierNumber
            kMelder_string::DOES_NOT_CONTAIN,
            U"silence",
            false                                   // preserveTimes
        );

        // No sounding regions found
        if (sounding_sounds->size == 0) {
            // Return minimal silence (standard Praat behavior)
            // Sound_create(nChannels, xmin, xmax, nx, dx, x1)
            double sr = 1.0 / sound->dx;  // Get sampling rate from input
            integer nx_silence = Melder_iround(0.001 * sr);  // 1ms worth of samples
            if (nx_silence < 1) nx_silence = 1;
            autoSound silence = Sound_create(
                1,                          // nChannels
                0.0,                        // xmin
                0.001,                      // xmax (1ms)
                nx_silence,                 // nx (number of samples)
                sound->dx,                  // dx (sample period from input)
                sound->dx / 2.0             // x1 (center of first sample)
            );
            return create_xptr_from_auto<structSound>(silence);
        }

        // Step 3: Concatenate sounding intervals
        autoSound loud_sound;
        if (sounding_sounds->size == 1) {
            loud_sound = sounding_sounds->subtractItem_move(1);
        } else {
            loud_sound = Sounds_concatenate(sounding_sounds.get(), 0.0);
        }

        // Both v2.03 and v3.01 use the same algorithm: windowed power + ZCR filtering
        // This matches both AVQI203.praat and AVQI301.praat specifications
        // The only difference between versions is in the final AVQI equation coefficients

        // Step 4: Calculate global power and threshold
        double global_power = Sound_getPower(loud_sound.get(), loud_sound->xmin, loud_sound->xmax);
        double voiceless_threshold = global_power * power_threshold_factor;

        // Step 5: Generate window boundaries
        //
        // FAITHFULNESS FIX 2 (2026-08-05): the loop bound was
        // `floor(duration / window_width)`, which walks one window past Praat's.
        // AVQI203.praat stops at `while windowBorderRight < extremeRight` with
        // `extremeRight = signalEnd - windowWidth`, i.e. the last window examined
        // ends at least one whole window before the signal end. Praat also never
        // truncates a window against xmax, so the old `to_time` clamp below could
        // feed a short final window into the power/ZCR test.
        const double signal_end = loud_sound->xmax;
        const double extreme_right = signal_end - window_width;

        // Step 6: Filter and extract windows in single pass
        autoSoundList passing_windows = SoundList_create();

        for (integer i = 0; ; i++) {
            double from_time = loud_sound->xmin + i * window_width;
            double to_time = from_time + window_width;

            if (! (to_time < extreme_right))
                break;

            // Extract window
            autoSound window = Sound_extractPart(
                loud_sound.get(),
                from_time,
                to_time,
                kSound_windowShape::RECTANGULAR,
                1.0,
                false
            );

            // Calculate window power
            double window_power = Sound_getPower(window.get(), window->xmin, window->xmax);

            // FAITHFULNESS FIX 3 (2026-08-05): faithful transcription of
            // AVQI203.praat's `checkZeros`. The previous default path ran
            // Sound_to_PointProcess_zeroes over the *whole* 30 ms window and used
            // `nt / (last - first)`. `checkZeros` instead walks zero crossings
            // only from the one nearest 0.0025 s until it passes 0.0275 s, counts
            // the steps taken, and divides by (last reached - first) -- a
            // different numerator and a different span. Over the plabench AVQI
            // fixture set the old form kept 8 windows Praat rejects.
            //
            // Praat-script quirk reproduced deliberately: `afstand` and
            // `zeroCrossings` are procedure-local by name only -- Praat leaks
            // undotted names into the global scope -- so a window whose walk never
            // executes yields `zeroCrossings = 0` and `0 / afstand_of_previous_window`,
            // i.e. 0, i.e. the window is kept. That is what `zeroCrossings == 0 ->
            // zcr = 0.0` below reproduces.
            double zcr = 0.0;

            if (use_manual_zcr) {
                // Manual sample-based ZCR calculation (matches R vectorized implementation)
                // Count sign changes in the signal samples
                integer n_crossings = 0;
                integer first_crossing_idx = -1;
                integer last_crossing_idx = -1;
                
                for (integer j = 2; j <= window->nx; ++j) {
                    double prev_val = window->z[1][j - 1];
                    double curr_val = window->z[1][j];
                    
                    // Check for sign change (zero crossing)
                    if ((prev_val > 0 && curr_val <= 0) || (prev_val <= 0 && curr_val > 0)) {
                        n_crossings++;
                        if (first_crossing_idx == -1) {
                            first_crossing_idx = j;
                        }
                        last_crossing_idx = j;
                    }
                }
                
                if (n_crossings >= 2 && last_crossing_idx > first_crossing_idx) {
                    // Convert sample indices to time
                    double first_time = window->x1 + (first_crossing_idx - 1) * window->dx;
                    double last_time = window->x1 + (last_crossing_idx - 1) * window->dx;
                    double duration = last_time - first_time;
                    
                    if (duration > 0.0) {
                        zcr = static_cast<double>(n_crossings) / duration;
                    }
                } else if (n_crossings == 1) {
                    double windowDuration = window->xmax - window->xmin;
                    if (windowDuration > 0.0) {
                        zcr = 1.0 / windowDuration;
                    }
                }
                // else zcr remains 0.0
                
            } else {
                try {
                    // `procedure checkZeros`, line for line. The window was
                    // extracted with preserveTimes = false, so its domain is
                    // [0, window_width] exactly as in the script.
                    const double dt = window->dx;   // script's `intermediateSamples`

                    const double startZero =
                        Sound_getNearestZeroCrossing(window.get(), 0.0025, 1);
                    double findStart = startZero;
                    double probe = startZero + dt;
                    double startZeroPlusOne =
                        Sound_getNearestZeroCrossing(window.get(), probe, 1);

                    integer zeroCrossings = 0;
                    double afstand = undefined;

                    while (findStart < 0.0275 && isdefined(findStart)) {
                        while (isdefined(startZeroPlusOne) && startZeroPlusOne == findStart) {
                            probe += dt;
                            startZeroPlusOne =
                                Sound_getNearestZeroCrossing(window.get(), probe, 1);
                        }
                        afstand = startZeroPlusOne - startZero;
                        zeroCrossings ++;
                        findStart = startZeroPlusOne;
                    }

                    // zeroCrossings / afstand, with the leaked-variable case (see above)
                    zcr = ( zeroCrossings == 0 ? 0.0 : zeroCrossings / afstand );
                } catch (...) {
                    // Any failure is "undefined" to the caller's `<> undefined` test
                    zcr = undefined;
                }
            }

            // `if partialPower > voicelessThreshold` /
            // `if (zeroCrossingRate <> undefined) and (zeroCrossingRate < 3000)`
            if (window_power > voiceless_threshold &&
                isdefined(zcr) &&
                zcr < max_zcr) {
                passing_windows->addItem_move(window.move());
            }
        }

        // Step 7: Concatenate onto the 1 ms silent seed.
        //
        // FAITHFULNESS FIX 4 (2026-08-05): the script builds the result by
        // concatenating each kept window onto `Create Sound: "onlyVoice", 0, 0.001,
        // samplingRate, "0"`, so the returned sound carries 1 ms of leading silence
        // and is 0.001 s longer than the sum of the kept windows. This function used
        // to drop that seed unless *no* window passed, which both shifted every
        // downstream frame grid by 1 ms and changed the total duration.
        const double sr = 1.0 / sound->dx;
        integer nx_seed = Melder_iround(0.001 * sr);
        if (nx_seed < 1) nx_seed = 1;
        autoSound seed = Sound_create(1, 0.0, 0.001, nx_seed, sound->dx, sound->dx / 2.0);

        if (passing_windows->size == 0)
            return create_xptr_from_auto<structSound>(seed);

        autoSoundList to_join = SoundList_create();
        to_join->addItem_move(seed.move());
        while (passing_windows->size > 0)
            to_join->addItem_move(passing_windows->subtractItem_move(1));

        autoSound only_voice = Sounds_concatenate(to_join.get(), 0.0);

        return create_xptr_from_auto<structSound>(only_voice);
    } catch (MelderError) {
        Melder_clearError();
        stop("Voiced segment extraction failed");
    }
}


// =============================================================================
// Phase 6: calculate_multiband_hnr_ultra - Multi-Band HNR Calculation (VQ)
// =============================================================================

static void validate_multiband_hnr_bands(const NumericVector& bands) {
    if (bands.size() != 5) {
        stop("bands parameter must have exactly 5 elements (0, 500, 1500, 2500, 3500)");
    }
}

static std::string multiband_hnr_name(double upper_freq, int index) {
    if (index == 0) {
        return "full";
    }
    return "band" + std::to_string(static_cast<int>(upper_freq));
}

static std::vector<autoHarmonicity> build_multiband_harmonicities(
    Sound sound,
    const NumericVector& bands,
    double time_step,
    double min_pitch
) {
    validate_multiband_hnr_bands(bands);

    std::vector<autoHarmonicity> harmonicities;
    harmonicities.reserve(static_cast<size_t>(bands.size()));

    for (int i = 0; i < bands.size(); i++) {
        double upper_freq = bands[i];

        autoSound filtered;
        Sound band_sound = sound;
        if (upper_freq != 0.0) {
            filtered = Sound_filter_passHannBand(
                sound,
                0.0,
                upper_freq,
                100.0
            );
            band_sound = filtered.get();
        }

        harmonicities.emplace_back(Sound_to_Harmonicity_cc(
            band_sound,
            time_step,
            min_pitch,
            0.1,
            1.0
        ));
    }

    return harmonicities;
}

//' Build reusable multiband Harmonicity objects in one C++ call
//'
//' @param sound_xptr External pointer to Sound object
//' @param bands Numeric vector of upper frequency limits in Hz (default c(0, 500, 1500, 2500, 3500))
//' @param time_step Time step for harmonicity in seconds (default 0.005)
//' @param min_pitch Minimum pitch in Hz (default 75)
//' @return Named list of Harmonicity external pointers (`full`, `band500`, ...)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.build_multiband_harmonicity_cpp)]]
List build_multiband_harmonicity_cpp(
    SEXP sound_xptr,
    NumericVector bands,
    double time_step = 0.005,
    double min_pitch = 75.0
) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    try {
        auto harmonicities = build_multiband_harmonicities(sound.get(), bands, time_step, min_pitch);
        List results(harmonicities.size());
        CharacterVector names(harmonicities.size());

        for (int i = 0; i < bands.size(); i++) {
            names[i] = multiband_hnr_name(bands[i], i);
            results[i] = create_xptr_from_auto<structHarmonicity>(harmonicities[i]);
        }

        results.attr("names") = names;
        return results;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to build multiband Harmonicity objects");
    }
}

//' Calculate multi-band HNR in single C++ call (Tier 4 Ultra)
//'
//' @description
//' Computes HNR (mean + SD) for 5 frequency bands in a single C++ call:
//' full spectrum, 0-500 Hz, 0-1500 Hz, 0-2500 Hz, 0-3500 Hz.
//' Eliminates R loops and multiple R/C++ boundary crossings.
//' 2-2.5x faster than sequential Tier 2 calculations for VQ.
//'
//' @param sound_xptr External pointer to Sound object
//' @param bands Numeric vector of upper frequency limits in Hz (default c(0, 500, 1500, 2500, 3500))
//' @param time_step Time step for harmonicity in seconds (default 0.005)
//' @param min_pitch Minimum pitch in Hz (default 75)
//' @param from_time Start time for statistics extraction (default 0, means beginning)
//' @param to_time End time for statistics extraction (default 0, means end)
//' @return Named list with 10 values: full_mean, full_sd, band500_mean, band500_sd, etc.
//' @keywords internal
//' @noRd
// [[Rcpp::export(.calculate_multiband_hnr_ultra_cpp)]]
List calculate_multiband_hnr_ultra_cpp(
    SEXP sound_xptr,
    NumericVector bands,
    double time_step = 0.005,
    double min_pitch = 75.0,
    double from_time = 0.0,
    double to_time = 0.0
) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    validate_multiband_hnr_bands(bands);

    try {
        // Auto-adjust time range if not specified
        if (to_time <= from_time) {
            from_time = sound->xmin;
            to_time = sound->xmax;
        }

        auto harmonicities = build_multiband_harmonicities(sound.get(), bands, time_step, min_pitch);
        List results;

        // Process each band
        // Matches VQ_measurements_V2.praat lines 102-122
        for (int i = 0; i < bands.size(); i++) {
            // Extract statistics for time range
            double mean = Harmonicity_getMean(
                harmonicities[i].get(),
                from_time,
                to_time
            );

            double sd = Harmonicity_getStandardDeviation(
                harmonicities[i].get(),
                from_time,
                to_time
            );

            std::string band_name = multiband_hnr_name(bands[i], i);

            results[band_name + "_mean"] = isundef(mean) ? NA_REAL : mean;
            results[band_name + "_sd"] = isundef(sd) ? NA_REAL : sd;
        }

        return results;
    } catch (MelderError) {
        Melder_clearError();
        stop("Multi-band HNR calculation failed");
    }
}


// =============================================================================
// Spectral moments batch — PERF-1
// Eliminates 14× R-loop overhead by computing all frame moments in C++
// =============================================================================

// PERF (v4.10): Direct spectrogram z-matrix computation, bit-exact equivalent of
// Spectrogram_to_Spectrum + Spectrum_getCentreOfGravity etc. Spectrogram_to_Spectrum
// sets re=sqrt(z[iy][ix]), im=0, so energy in the Spectrum moment formulas is just
// z[iy][ix] directly. Eliminates per-frame Spectrum allocation/deallocation and
// fuses all four moment computations into a single pass over the frequency bins,
// reducing memory bandwidth ~4x vs separate CoG/SD/skewness/kurtosis loops.
// [[Rcpp::export(.get_spectral_moments_batch)]]
List get_spectral_moments_batch_cpp(SEXP spectrogram_xptr, double power = 2.0) {
    XPtr<structSpectrogram> sg(spectrogram_xptr);
    if (!sg || sg.get() == nullptr)
        stop("Invalid Spectrogram pointer");

    integer nx = sg->nx;
    integer ny = sg->ny;
    double f1 = sg->y1;   // centre of first frequency band
    double df = sg->dy;   // frequency step
    const double halfpower = 0.5 * power;

    NumericVector times(nx), cog_vec(nx), sd_vec(nx), skew_vec(nx), kurt_vec(nx);

    try {
        for (integer ix = 1; ix <= nx; ix++) {
            double t = sg->x1 + (ix - 1) * sg->dx;
            times[ix - 1] = t;

            // Fused single pass: compute CoG and all three central moments
            // simultaneously from spectrogram z-matrix column. This is bit-exact
            // with the four separate Spectrum_get* calls because
            // Spectrogram_to_Spectrum sets re=sqrt(z), im=0, so energy = z directly.
            longdouble sum_energy = 0.0, sum_f_energy = 0.0;
            longdouble sum_m2 = 0.0, sum_m3 = 0.0, sum_m4 = 0.0;
            bool all_zero = true;

            for (integer iy = 1; iy <= ny; iy++) {
                double val = sg->z[iy][ix];
                if (val <= 0.0) continue;   // skip non-positive bins
                all_zero = false;
                longdouble energy = halfpower != 1.0
                    ? (longdouble) pow(val, halfpower)
                    : (longdouble) val;
                longdouble f = f1 + (iy - 1) * df;
                sum_energy   += energy;
                sum_f_energy += f * energy;
            }

            if (all_zero || sum_energy == 0.0) {
                cog_vec[ix - 1]   = NA_REAL;
                sd_vec[ix - 1]    = NA_REAL;
                skew_vec[ix - 1]  = NA_REAL;
                kurt_vec[ix - 1]  = NA_REAL;
                continue;
            }

            double cog = (double)(sum_f_energy / sum_energy);
            cog_vec[ix - 1] = cog;

            // Second single pass: compute central moments using known CoG.
            // Must be a second pass because CoG is needed for diff calculation.
            for (integer iy = 1; iy <= ny; iy++) {
                double val = sg->z[iy][ix];
                if (val <= 0.0) continue;
                longdouble energy = halfpower != 1.0
                    ? (longdouble) pow(val, halfpower)
                    : (longdouble) val;
                longdouble diff = (longdouble)(f1 + (iy - 1) * df) - (longdouble)cog;
                longdouble diff2 = diff * diff;
                sum_m2 += diff2 * energy;
                sum_m3 += diff2 * diff * energy;   // diff^3 * energy
                sum_m4 += diff2 * diff2 * energy;  // diff^4 * energy
            }

            double m2 = (double)(sum_m2 / sum_energy);
            if (m2 <= 0.0) {
                sd_vec[ix - 1]    = 0.0;
                skew_vec[ix - 1]  = NA_REAL;
                kurt_vec[ix - 1]  = NA_REAL;
            } else {
                double sd = sqrt(m2);
                sd_vec[ix - 1] = sd;

                double m3 = (double)(sum_m3 / sum_energy);
                double denom = m2 * sd;
                skew_vec[ix - 1] = (denom == 0.0) ? NA_REAL : (m3 / denom);

                double m4 = (double)(sum_m4 / sum_energy);
                double denom_k = m2 * m2;
                kurt_vec[ix - 1] = (denom_k == 0.0) ? NA_REAL : ((m4 / denom_k) - 3.0);
            }
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to compute spectral moments");
    }

    return List::create(
        Named("time")     = times,
        Named("cog")      = cog_vec,
        Named("sd")       = sd_vec,
        Named("skewness") = skew_vec,
        Named("kurtosis") = kurt_vec
    );
}

