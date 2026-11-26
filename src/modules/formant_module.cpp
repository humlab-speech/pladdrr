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
// formant_module.cpp
// Rcpp Module exposing Formant functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "module_common.h"
#include "../datatable_utils.h"

// Praat headers
#include "praat.github.io/fon/Formant.h"

using namespace Rcpp;

// =============================================================================
// RFormant Class - Wraps Formant XPtr with methods
// =============================================================================

class RFormant {
private:
    XPtr<structFormant> ptr;

public:
    // Default constructor (empty)
    RFormant() : ptr(R_NilValue) {}

    // Constructor from XPtr
    RFormant(XPtr<structFormant> xptr) : ptr(xptr) {
        require_praat_class(ptr.get(), classFormant, "Not a Formant", "Formant", ".xptr");
    }

    // =========================================================================
    // Validation
    // =========================================================================

    bool is_valid() {
        return ptr.get() != nullptr;
    }

    // =========================================================================
    // Time Domain Properties
    // =========================================================================

    double get_xmin() {
        VALIDATE_PTR(ptr, Formant);
        return ptr->xmin;
    }

    double get_xmax() {
        VALIDATE_PTR(ptr, Formant);
        return ptr->xmax;
    }

    double get_duration() {
        VALIDATE_PTR(ptr, Formant);
        return ptr->xmax - ptr->xmin;
    }

    // =========================================================================
    // Frame Properties
    // =========================================================================

    int get_nx() {
        VALIDATE_PTR(ptr, Formant);
        return static_cast<int>(ptr->nx);
    }

    double get_dx() {
        VALIDATE_PTR(ptr, Formant);
        return ptr->dx;
    }

    double get_x1() {
        VALIDATE_PTR(ptr, Formant);
        return ptr->x1;
    }

    int get_number_of_frames() {
        return get_nx();
    }

    double get_time_step() {
        return get_dx();
    }

    // =========================================================================
    // Time/Frame Conversion
    // =========================================================================

    double get_time_from_frame(int frame_number) {
        VALIDATE_PTR(ptr, Formant);
        VALIDATE_FRAME_RANGE(ptr, frame_number);
        return Sampled_indexToX(ptr.get(), frame_number);
    }

    int get_frame_from_time(double time) {
        VALIDATE_PTR(ptr, Formant);
        return static_cast<int>(Sampled_xToNearestIndex(ptr.get(), time));
    }

    // =========================================================================
    // Formant-specific Properties
    // =========================================================================

    int get_min_num_formants() {
        VALIDATE_PTR(ptr, Formant);
        return praat_try_return([&] { return static_cast<int>(Formant_getMinNumFormants(ptr.get())); },
                                "Failed to get minimum number of formants");
    }

    int get_max_num_formants() {
        VALIDATE_PTR(ptr, Formant);
        return praat_try_return([&] { return static_cast<int>(Formant_getMaxNumFormants(ptr.get())); },
                                "Failed to get maximum number of formants");
    }

    // =========================================================================
    // Query Methods
    // =========================================================================
    //
    // Single implementation of the Formant getters; the R6 layer calls them via
    // .cpp$ (there is no Rcpp::export twin -- do not add one). Praat errors
    // surface as R errors, and a non-finite query time is a missing value
    // (Praat's Sampled_getValueAtX throws on it).

    double get_value_at_time(int formant_number, double time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        if (!R_finite(time)) return NA_REAL;
        double value = praat_try_return([&] {
            return Formant_getValueAtTime(ptr.get(), formant_number, time,
                                          static_cast<kFormant_unit>(unit));
        }, "Failed to get formant value at time");
        return isdefined(value) ? value : NA_REAL;
    }

    double get_bandwidth_at_time(int formant_number, double time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        if (!R_finite(time)) return NA_REAL;
        return praat_try_return([&] {
            return Formant_getBandwidthAtTime(ptr.get(), formant_number, time,
                                              static_cast<kFormant_unit>(unit));
        }, "Failed to get formant bandwidth at time");
    }

    double get_mean(int formant_number, double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        return praat_try_return([&] { return Formant_getMean(ptr.get(), formant_number, from_time, to_time, static_cast<kFormant_unit>(unit)); },
                                "Failed to get mean formant");
    }

    double get_standard_deviation(int formant_number, double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        return praat_try_return([&] { return Formant_getStandardDeviation(ptr.get(), formant_number, from_time, to_time, static_cast<kFormant_unit>(unit)); },
                                "Failed to get formant standard deviation");
    }

    double get_quantile(int formant_number, double quantile, double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        return praat_try_return([&] { return Formant_getQuantile(ptr.get(), formant_number, quantile, from_time, to_time, static_cast<kFormant_unit>(unit)); },
                                "Failed to get formant quantile");
    }

    double get_minimum(int formant_number, double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Formant);
        return praat_try_return([&] { return Formant_getMinimum(ptr.get(), formant_number, from_time, to_time, static_cast<kFormant_unit>(unit), interpolate ? 1 : 0); },
                                "Failed to get minimum formant");
    }

    double get_maximum(int formant_number, double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Formant);
        return praat_try_return([&] { return Formant_getMaximum(ptr.get(), formant_number, from_time, to_time, static_cast<kFormant_unit>(unit), interpolate ? 1 : 0); },
                                "Failed to get maximum formant");
    }

    double get_time_of_minimum(int formant_number, double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Formant);
        return praat_try_return([&] { return Formant_getTimeOfMinimum(ptr.get(), formant_number, from_time, to_time, static_cast<kFormant_unit>(unit), interpolate ? 1 : 0); },
                                "Failed to get time of minimum formant");
    }

    double get_time_of_maximum(int formant_number, double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Formant);
        return praat_try_return([&] { return Formant_getTimeOfMaximum(ptr.get(), formant_number, from_time, to_time, static_cast<kFormant_unit>(unit), interpolate ? 1 : 0); },
                                "Failed to get time of maximum formant");
    }

    // =========================================================================
    // Batch/Vectorized Operations (20x speedup for formant analysis)
    // =========================================================================

    // Get all frame times as vector
    NumericVector get_times_vector() {
        VALIDATE_PTR(ptr, Formant);
        integer nx = ptr->nx;
        NumericVector times(nx);

        for (integer i = 1; i <= nx; i++) {
            times[i-1] = Sampled_indexToX(ptr.get(), i);
        }

        return times;
    }

    // Get formant track (all values for a specific formant across all frames)
    NumericVector get_formant_track(int formant_number, int unit = 0) {
        VALIDATE_PTR(ptr, Formant);
        integer nx = ptr->nx;
        NumericVector values(nx);
        kFormant_unit formant_unit = static_cast<kFormant_unit>(unit);

        for (integer i = 1; i <= nx; i++) {
            double t = Sampled_indexToX(ptr.get(), i);
            double val = Formant_getValueAtTime(ptr.get(), formant_number, t, formant_unit);
            values[i-1] = isdefined(val) ? val : NA_REAL;
        }

        return values;
    }

    // Get bandwidth track (all bandwidths for a specific formant across all frames)
    NumericVector get_bandwidth_track(int formant_number, int unit = 0) {
        VALIDATE_PTR(ptr, Formant);
        integer nx = ptr->nx;
        NumericVector values(nx);
        kFormant_unit formant_unit = static_cast<kFormant_unit>(unit);

        for (integer i = 1; i <= nx; i++) {
            double t = Sampled_indexToX(ptr.get(), i);
            double val = Formant_getBandwidthAtTime(ptr.get(), formant_number, t, formant_unit);
            values[i-1] = isdefined(val) ? val : NA_REAL;
        }

        return values;
    }

    // Get formant values at multiple specific times
    NumericVector get_values_at_times(int formant_number, NumericVector times, int unit = 0) {
        VALIDATE_PTR(ptr, Formant);
        int n = times.size();
        NumericVector values(n);
        kFormant_unit formant_unit = static_cast<kFormant_unit>(unit);

        for (int i = 0; i < n; i++) {
            if (ISNAN(times[i])) { values[i] = NA_REAL; continue; }
            double val = Formant_getValueAtTime(ptr.get(), formant_number, times[i], formant_unit);
            values[i] = isdefined(val) ? val : NA_REAL;
        }

        return values;
    }

    // Get all formant tracks at once (F1, F2, F3, ...) as a matrix
    NumericMatrix get_all_formant_tracks(int max_formants, int unit = 0) {
        VALIDATE_PTR(ptr, Formant);
        integer nx = ptr->nx;
        NumericMatrix tracks(nx, max_formants);
        kFormant_unit formant_unit = static_cast<kFormant_unit>(unit);

        for (integer i = 1; i <= nx; i++) {
            double t = Sampled_indexToX(ptr.get(), i);
            for (int f = 1; f <= max_formants; f++) {
                double val = Formant_getValueAtTime(ptr.get(), f, t, formant_unit);
                tracks(i-1, f-1) = isdefined(val) ? val : NA_REAL;
            }
        }

        return tracks;
    }

    // =========================================================================
    // Export Methods
    // =========================================================================

    DataFrame as_data_frame(int max_formants) {
        VALIDATE_PTR(ptr, Formant);

        // Long format: one row per (frame, formant number). Pre-count rows and
        // fill Rcpp vectors directly (no std::vector push_back + copy).
        integer total_rows = 0;
        for (integer iframe = 1; iframe <= ptr->nx; iframe++) {
            total_rows += std::min(ptr->frames[iframe].numberOfFormants, (integer)max_formants);
        }

        NumericVector times(total_rows);
        IntegerVector formant_nums(total_rows);
        NumericVector frequencies(total_rows);
        NumericVector bandwidths(total_rows);

        integer row = 0;
        for (integer iframe = 1; iframe <= ptr->nx; iframe++) {
            double time = Sampled_indexToX(ptr.get(), iframe);
            Formant_Frame frame = &ptr->frames[iframe];

            integer nFormants = std::min(frame->numberOfFormants, (integer)max_formants);
            for (integer iformant = 1; iformant <= nFormants; iformant++) {
                times[row] = time;
                formant_nums[row] = static_cast<int>(iformant);
                frequencies[row] = frame->formant[iformant].frequency;
                bandwidths[row] = frame->formant[iformant].bandwidth;
                row++;
            }
        }

        return pladdrr::dt::create_datatable(
            List::create(
                Named("time") = times,
                Named("formant") = formant_nums,
                Named("frequency") = frequencies,
                Named("bandwidth") = bandwidths
            ),
            CharacterVector::create("time", "formant", "frequency", "bandwidth"),
            CharacterVector::create("time", "formant")  // Key for fast lookups
        );
    }

    NumericMatrix as_matrix(int max_formants, bool include_bandwidth) {
        VALIDATE_PTR(ptr, Formant);

        integer ncols = include_bandwidth ? max_formants * 2 : max_formants;
        NumericMatrix mat(ptr->nx, ncols + 1);  // +1 for time column

        for (integer iframe = 1; iframe <= ptr->nx; iframe++) {
            double time = Sampled_indexToX(ptr.get(), iframe);
            mat(iframe - 1, 0) = time;

            Formant_Frame frame = &ptr->frames[iframe];
            for (integer iformant = 1; iformant <= max_formants; iformant++) {
                if (iformant <= frame->numberOfFormants) {
                    mat(iframe - 1, iformant) = frame->formant[iformant].frequency;
                    if (include_bandwidth) {
                        mat(iframe - 1, max_formants + iformant) = frame->formant[iformant].bandwidth;
                    }
                } else {
                    mat(iframe - 1, iformant) = NA_REAL;
                    if (include_bandwidth) {
                        mat(iframe - 1, max_formants + iformant) = NA_REAL;
                    }
                }
            }
        }

        return mat;
    }

    // =========================================================================
    // Save Method
    // =========================================================================

    void save(std::string path) {
        VALIDATE_PTR(ptr, Formant);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save formant to file: %s", path.c_str());
        }
    }
};

// =============================================================================
// Module Registration
// =============================================================================

RCPP_MODULE(formant_module) {
    using namespace Rcpp;

    class_<RFormant>("RFormant")
        // Constructors
        .constructor()
        .constructor<XPtr<structFormant>>()

        // Validation
        .method("is_valid", &RFormant::is_valid, "Check if pointer is valid")

        // Properties for fast access (2-3x faster than method calls)
        .property("duration", &RFormant::get_duration, "Duration in seconds")
        .property("xmin", &RFormant::get_xmin, "Start time in seconds")
        .property("xmax", &RFormant::get_xmax, "End time in seconds")
        .property("nx", &RFormant::get_nx, "Number of frames")
        .property("dx", &RFormant::get_dx, "Time step between frames")
        .property("x1", &RFormant::get_x1, "Time of first frame")
        .property("min_num_formants", &RFormant::get_min_num_formants, "Min formants per frame")
        .property("max_num_formants", &RFormant::get_max_num_formants, "Max formants per frame")

        // Time domain methods (keep for backward compatibility)
        .method("get_xmin", &RFormant::get_xmin, "Get start time")
        .method("get_xmax", &RFormant::get_xmax, "Get end time")
        .method("get_duration", &RFormant::get_duration, "Get duration")

        // Frame methods
        .method("get_nx", &RFormant::get_nx, "Get number of frames")
        .method("get_dx", &RFormant::get_dx, "Get time step")
        .method("get_x1", &RFormant::get_x1, "Get time of first frame")
        .method("get_number_of_frames", &RFormant::get_number_of_frames, "Get number of frames")
        .method("get_time_step", &RFormant::get_time_step, "Get time step")

        // Time/frame conversion
        .method("get_time_from_frame", &RFormant::get_time_from_frame, "Convert frame to time")
        .method("get_frame_from_time", &RFormant::get_frame_from_time, "Convert time to frame")

        // Formant-specific
        .method("get_min_num_formants", &RFormant::get_min_num_formants, "Get min formants per frame")
        .method("get_max_num_formants", &RFormant::get_max_num_formants, "Get max formants per frame")

        // Query methods
        .method("get_value_at_time", &RFormant::get_value_at_time, "Get formant frequency at time")
        .method("get_bandwidth_at_time", &RFormant::get_bandwidth_at_time, "Get formant bandwidth at time")
        .method("get_mean", &RFormant::get_mean, "Get mean formant frequency")
        .method("get_standard_deviation", &RFormant::get_standard_deviation, "Get standard deviation")
        .method("get_quantile", &RFormant::get_quantile, "Get quantile")
        .method("get_minimum", &RFormant::get_minimum, "Get minimum frequency")
        .method("get_maximum", &RFormant::get_maximum, "Get maximum frequency")
        .method("get_time_of_minimum", &RFormant::get_time_of_minimum, "Get time of minimum")
        .method("get_time_of_maximum", &RFormant::get_time_of_maximum, "Get time of maximum")

        // Batch/Vectorized operations (20x speedup for formant analysis)
        .method("get_times_vector", &RFormant::get_times_vector, "Get all frame times as vector")
        .method("get_formant_track", &RFormant::get_formant_track, "Get formant track")
        .method("get_bandwidth_track", &RFormant::get_bandwidth_track, "Get bandwidth track")
        .method("get_values_at_times", &RFormant::get_values_at_times, "Get formant at multiple times")
        .method("get_all_formant_tracks", &RFormant::get_all_formant_tracks, "Get all formant tracks as matrix")

        // Export methods
        .method("as_data_frame", &RFormant::as_data_frame, "Export as data frame")
        .method("as_matrix", &RFormant::as_matrix, "Export as matrix")

        // Save method
        .method("save", &RFormant::save, "Save to Praat text file")
    ;
}
