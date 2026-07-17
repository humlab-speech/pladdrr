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
// formantmodeler_module.cpp
// Rcpp Module for FormantModeler - robust formant tracking (pladdrr 2.0)
//
// FormantModeler provides polynomial modeling of formant trajectories,
// with automatic outlier detection and optimal ceiling estimation.

#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "module_common.h"
#include "../datatable_utils.h"

// Praat headers for FormantModeler
#include "praat.github.io/LPC/FormantModeler.h"
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Sound.h"

using namespace Rcpp;

// ============================================================================
// RFormantModeler Class
// ============================================================================

class RFormantModeler {
private:
    XPtr<structFormantModeler> ptr;

public:
    RFormantModeler() : ptr(R_NilValue) {}
    RFormantModeler(XPtr<structFormantModeler> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties
    double get_xmin() { VALIDATE_PTR(ptr, FormantModeler); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, FormantModeler); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, FormantModeler); return ptr->xmax - ptr->xmin; }

    // FormantModeler-specific properties
    int get_number_of_tracks() {
        VALIDATE_PTR(ptr, FormantModeler);
        return static_cast<int>(FormantModeler_getNumberOfTracks(ptr.get()));
    }

    int get_number_of_data_points() {
        VALIDATE_PTR(ptr, FormantModeler);
        return static_cast<int>(FormantModeler_getNumberOfDataPoints(ptr.get()));
    }

    int get_number_of_parameters(int track) {
        VALIDATE_PTR(ptr, FormantModeler);
        return static_cast<int>(FormantModeler_getNumberOfParameters(ptr.get(), track));
    }

    // Model quality metrics
    double get_coefficient_of_determination(int from_track, int to_track) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            return FormantModeler_getCoefficientOfDetermination(ptr.get(), from_track, to_track);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_standard_deviation(int track) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            return FormantModeler_getStandardDeviation(ptr.get(), track);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_residual_sum_of_squares(int track) {
        VALIDATE_PTR(ptr, FormantModeler);
        integer n_points;
        try {
            return FormantModeler_getResidualSumOfSquares(ptr.get(), track, &n_points);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_stress(int from_track, int to_track, int num_params_per_track, double power) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            return FormantModeler_getStress(ptr.get(), from_track, to_track, num_params_per_track, power);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Get estimated (modeled) formant value at time
    double get_model_value_at_time(int track, double time) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            return FormantModeler_getModelValueAtTime(ptr.get(), track, time);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_estimated_value_at_time(int track, double time) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            // Note: Using getModelValueAtTime instead of getEstimatedValueAtTime
            // because the latter is declared but not implemented in Praat source
            return FormantModeler_getModelValueAtTime(ptr.get(), track, time);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Get data point value (original measurement)
    double get_data_point_value(int track, int index) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            return FormantModeler_getDataPointValue(ptr.get(), track, index);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_data_point_sigma(int track, int index) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            return FormantModeler_getDataPointSigma(ptr.get(), track, index);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Model fitting
    void fit() {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            FormantModeler_fit(ptr.get());
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to fit FormantModeler");
        }
    }

    // Convert to Formant
    XPtr<structFormant> to_formant_ptr(bool estimate, bool estimate_undefined) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            autoFormant formant = FormantModeler_to_Formant(ptr.get(), estimate, estimate_undefined);
            structFormant* raw = formant.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert FormantModeler to Formant");
        }
    }

    // Process outliers
    XPtr<structFormantModeler> process_outliers_ptr(double num_sigmas) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            autoFormantModeler result = FormantModeler_processOutliers(ptr.get(), num_sigmas);
            structFormantModeler* raw = result.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to process outliers");
        }
    }

    // Get weighted mean for track
    double get_weighted_mean(int track) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            return FormantModeler_getWeightedMean(ptr.get(), track);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Get number of invalid data points
    int get_number_of_invalid_data_points(int track) {
        VALIDATE_PTR(ptr, FormantModeler);
        return static_cast<int>(FormantModeler_getNumberOfInvalidDataPoints(ptr.get(), track));
    }

    // Get all modeled values for a track
    NumericVector get_track_model_values(int track) {
        VALIDATE_PTR(ptr, FormantModeler);
        integer n = FormantModeler_getNumberOfDataPoints(ptr.get());
        NumericVector result(n);

        for (integer i = 1; i <= n; i++) {
            double time = FormantModeler_indexToTime(ptr.get(), i);
            result[i-1] = FormantModeler_getModelValueAtTime(ptr.get(), track, time);
        }
        return result;
    }

    // Export as data.frame with original and modeled values
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, FormantModeler);

        integer n = FormantModeler_getNumberOfDataPoints(ptr.get());
        integer n_tracks = FormantModeler_getNumberOfTracks(ptr.get());

        NumericVector times(n);
        for (integer i = 1; i <= n; i++) {
            times[i-1] = FormantModeler_indexToTime(ptr.get(), i);
        }

        List columns;
        CharacterVector col_names;

        columns.push_back(times);
        col_names.push_back("time");

        // Add original and modeled values for each track
        for (integer t = 1; t <= n_tracks; t++) {
            NumericVector original(n);
            NumericVector modeled(n);

            for (integer i = 1; i <= n; i++) {
                original[i-1] = FormantModeler_getDataPointValue(ptr.get(), t, i);
                modeled[i-1] = FormantModeler_getModelValueAtIndex(ptr.get(), t, i);
            }

            columns.push_back(original);
            col_names.push_back("F" + std::to_string(t) + "_original");
            columns.push_back(modeled);
            col_names.push_back("F" + std::to_string(t) + "_modeled");
        }

        return pladdrr::dt::create_datatable(
            columns,
            col_names,
            CharacterVector::create("time")
        );
    }

    List get_info() {
        VALIDATE_PTR(ptr, FormantModeler);
        integer n_tracks = FormantModeler_getNumberOfTracks(ptr.get());

        NumericVector track_r2(n_tracks);
        NumericVector track_sd(n_tracks);
        IntegerVector track_params(n_tracks);

        for (integer t = 1; t <= n_tracks; t++) {
            track_r2[t-1] = FormantModeler_getCoefficientOfDetermination(ptr.get(), t, t);
            track_sd[t-1] = FormantModeler_getStandardDeviation(ptr.get(), t);
            track_params[t-1] = static_cast<int>(FormantModeler_getNumberOfParameters(ptr.get(), t));
        }

        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("n_tracks") = n_tracks,
            Named("n_data_points") = FormantModeler_getNumberOfDataPoints(ptr.get()),
            Named("track_r2") = track_r2,
            Named("track_sd") = track_sd,
            Named("track_parameters") = track_params
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, FormantModeler);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save FormantModeler");
        }
    }
};

// ============================================================================
// Factory Functions
// ============================================================================

// Formant -> FormantModeler
static XPtr<structFormantModeler> Module_Formant_to_FormantModeler(
    XPtr<structFormant> formant,
    double tmin, double tmax,
    int num_tracks,
    int num_params_per_track
) {
    if (!formant || !formant.get()) Rcpp::stop("Invalid Formant pointer");
    try {
        autoFormantModeler fm = Formant_to_FormantModeler(
            formant.get(), tmin, tmax, num_tracks, num_params_per_track
        );
        structFormantModeler* raw = fm.releaseToAmbiguousOwner();
        return make_praat_xptr(raw);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create FormantModeler from Formant");
    }
}

// Sound -> Formant with optimal ceiling (interval method)
static List Module_Sound_to_Formant_interval(
    XPtr<structSound> sound,
    double start_time, double end_time,
    double window_length, double time_step,
    double min_freq, double max_freq, int num_freq_steps,
    double preemphasis_freq,
    int num_formant_tracks, int num_params_per_track,
    int weigh_formants,
    double num_sigmas, double power,
    bool use_constraints,
    double min_f1, double max_f1,
    double min_f2, double max_f2,
    double min_f3
) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        double optimal_ceiling = 0.0;
        autoFormant formant = Sound_to_Formant_interval(
            sound.get(), start_time, end_time,
            window_length, time_step,
            min_freq, max_freq, num_freq_steps,
            preemphasis_freq,
            num_formant_tracks, num_params_per_track,
            static_cast<kFormantModelerWeights>(weigh_formants),
            num_sigmas, power,
            use_constraints, min_f1, max_f1, min_f2, max_f2, min_f3,
            &optimal_ceiling
        );
        structFormant* raw = formant.releaseToAmbiguousOwner();
        return List::create(
            Named("formant_ptr") = make_praat_xptr(raw),
            Named("optimal_ceiling") = optimal_ceiling
        );
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract formants with optimal ceiling");
    }
}

// Sound -> Formant with robust interval method
static List Module_Sound_to_Formant_interval_robust(
    XPtr<structSound> sound,
    double start_time, double end_time,
    double window_length, double time_step,
    double min_freq, double max_freq, int num_freq_steps,
    double preemphasis_freq,
    int num_formant_tracks, int num_params_per_track,
    int weigh_formants,
    double num_sigmas, double power,
    bool use_constraints,
    double min_f1, double max_f1,
    double min_f2, double max_f2,
    double min_f3
) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        double optimal_ceiling = 0.0;
        autoFormant formant = Sound_to_Formant_interval_robust(
            sound.get(), start_time, end_time,
            window_length, time_step,
            min_freq, max_freq, num_freq_steps,
            preemphasis_freq,
            num_formant_tracks, num_params_per_track,
            static_cast<kFormantModelerWeights>(weigh_formants),
            num_sigmas, power,
            use_constraints, min_f1, max_f1, min_f2, max_f2, min_f3,
            &optimal_ceiling
        );
        structFormant* raw = formant.releaseToAmbiguousOwner();
        return List::create(
            Named("formant_ptr") = make_praat_xptr(raw),
            Named("optimal_ceiling") = optimal_ceiling
        );
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract robust formants with optimal ceiling");
    }
}

// Get optimal formant ceiling for sound
static double Module_Sound_get_optimal_formant_ceiling(
    XPtr<structSound> sound,
    double start_time, double end_time,
    double window_length, double time_step,
    double min_freq, double max_freq, int num_freq_steps,
    double preemphasis_freq,
    int num_formant_tracks, int num_params_per_track,
    int weigh_formants,
    double num_sigmas, double power
) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        return Sound_getOptimalFormantCeiling(
            sound.get(), start_time, end_time,
            window_length, time_step,
            min_freq, max_freq, num_freq_steps,
            preemphasis_freq,
            num_formant_tracks, num_params_per_track,
            static_cast<kFormantModelerWeights>(weigh_formants),
            num_sigmas, power
        );
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to calculate optimal formant ceiling");
    }
}

// ============================================================================
// Module Registration
// ============================================================================

RCPP_MODULE(formantmodeler_module) {
    class_<RFormantModeler>("RFormantModeler")
        .constructor()
        .constructor<XPtr<structFormantModeler>>()
        .method("is_valid", &RFormantModeler::is_valid)
        // Time domain
        .method("get_xmin", &RFormantModeler::get_xmin)
        .method("get_xmax", &RFormantModeler::get_xmax)
        .method("get_duration", &RFormantModeler::get_duration)
        // Properties
        .method("get_number_of_tracks", &RFormantModeler::get_number_of_tracks)
        .method("get_number_of_data_points", &RFormantModeler::get_number_of_data_points)
        .method("get_number_of_parameters", &RFormantModeler::get_number_of_parameters)
        .method("get_number_of_invalid_data_points", &RFormantModeler::get_number_of_invalid_data_points)
        // Quality metrics
        .method("get_coefficient_of_determination", &RFormantModeler::get_coefficient_of_determination)
        .method("get_standard_deviation", &RFormantModeler::get_standard_deviation)
        .method("get_residual_sum_of_squares", &RFormantModeler::get_residual_sum_of_squares)
        .method("get_stress", &RFormantModeler::get_stress)
        .method("get_weighted_mean", &RFormantModeler::get_weighted_mean)
        // Value queries
        .method("get_model_value_at_time", &RFormantModeler::get_model_value_at_time)
        .method("get_estimated_value_at_time", &RFormantModeler::get_estimated_value_at_time)
        .method("get_data_point_value", &RFormantModeler::get_data_point_value)
        .method("get_data_point_sigma", &RFormantModeler::get_data_point_sigma)
        .method("get_track_model_values", &RFormantModeler::get_track_model_values)
        // Operations
        .method("fit", &RFormantModeler::fit)
        .method("to_formant_ptr", &RFormantModeler::to_formant_ptr)
        .method("process_outliers_ptr", &RFormantModeler::process_outliers_ptr)
        // Export
        .method("as_data_frame", &RFormantModeler::as_data_frame)
        .method("get_info", &RFormantModeler::get_info)
        .method("save", &RFormantModeler::save)
    ;

    // Factory functions
    function("Formant_to_FormantModeler", &Module_Formant_to_FormantModeler);
    function("Sound_to_Formant_interval", &Module_Sound_to_Formant_interval);
    function("Sound_to_Formant_interval_robust", &Module_Sound_to_Formant_interval_robust);
    function("Sound_get_optimal_formant_ceiling", &Module_Sound_get_optimal_formant_ceiling);
}
