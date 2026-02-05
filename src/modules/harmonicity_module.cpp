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
// harmonicity_module.cpp
// Rcpp Module exposing Harmonicity (HNR) functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/Harmonicity.h"

using namespace Rcpp;

class RHarmonicity {
private:
    XPtr<structHarmonicity> ptr;

public:
    RHarmonicity() : ptr(R_NilValue) {}
    RHarmonicity(XPtr<structHarmonicity> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain
    double get_xmin() { VALIDATE_PTR(ptr, Harmonicity); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, Harmonicity); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, Harmonicity); return ptr->xmax - ptr->xmin; }

    // Frame properties
    int get_nx() { VALIDATE_PTR(ptr, Harmonicity); return static_cast<int>(ptr->nx); }
    double get_dx() { VALIDATE_PTR(ptr, Harmonicity); return ptr->dx; }
    double get_x1() { VALIDATE_PTR(ptr, Harmonicity); return ptr->x1; }
    int get_number_of_frames() { return get_nx(); }
    double get_time_step() { return get_dx(); }

    // Time/frame conversion
    double get_time_from_frame(int frame) {
        VALIDATE_PTR(ptr, Harmonicity);
        return Sampled_indexToX(ptr.get(), frame);
    }
    int get_frame_from_time(double time) {
        VALIDATE_PTR(ptr, Harmonicity);
        return static_cast<int>(Sampled_xToNearestIndex(ptr.get(), time));
    }

    // Query methods
    double get_value_at_time(double time, int interpolation) {
        VALIDATE_PTR(ptr, Harmonicity);
        return Vector_getValueAtX(ptr.get(), time, 1, (kVector_valueInterpolation)interpolation);
    }

    double get_mean(double from_time, double to_time) {
        VALIDATE_PTR(ptr, Harmonicity);
        return Harmonicity_getMean(ptr.get(), from_time, to_time);
    }

    double get_minimum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Harmonicity);
        return Vector_getMinimum(ptr.get(), from_time, to_time, (kVector_peakInterpolation)interpolation);
    }

    double get_maximum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Harmonicity);
        return Vector_getMaximum(ptr.get(), from_time, to_time, (kVector_peakInterpolation)interpolation);
    }

    double get_time_of_minimum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Harmonicity);
        return Vector_getXOfMinimum(ptr.get(), from_time, to_time, (kVector_peakInterpolation)interpolation);
    }

    double get_time_of_maximum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Harmonicity);
        return Vector_getXOfMaximum(ptr.get(), from_time, to_time, (kVector_peakInterpolation)interpolation);
    }

    double get_standard_deviation(double from_time, double to_time) {
        VALIDATE_PTR(ptr, Harmonicity);
        return Harmonicity_getStandardDeviation(ptr.get(), from_time, to_time);
    }

    // =========================================================================
    // Batch/Vectorized Operations (Phase 4: VQ multi-band HNR - 10x speedup)
    // =========================================================================

    // Get statistics for multiple time windows in a single call
    NumericMatrix get_statistics_batch(NumericVector from_times, NumericVector to_times,
                                       CharacterVector metrics) {
        VALIDATE_PTR(ptr, Harmonicity);

        int n_windows = from_times.size();
        if (n_windows != to_times.size()) {
            Rcpp::stop("from_times and to_times must have same length");
        }

        int n_metrics = metrics.size();
        NumericMatrix result(n_windows, n_metrics);

        try {
            for (int i = 0; i < n_windows; i++) {
                double from = from_times[i];
                double to = to_times[i];
                if (from == 0 && to == 0) {
                    from = ptr->xmin;
                    to = ptr->xmax;
                }

                for (int j = 0; j < n_metrics; j++) {
                    std::string metric = Rcpp::as<std::string>(metrics[j]);

                    if (metric == "mean") {
                        result(i, j) = Harmonicity_getMean(ptr.get(), from, to);
                    } else if (metric == "min" || metric == "minimum") {
                        result(i, j) = Vector_getMinimum(ptr.get(), from, to, kVector_peakInterpolation::PARABOLIC);
                    } else if (metric == "max" || metric == "maximum") {
                        result(i, j) = Vector_getMaximum(ptr.get(), from, to, kVector_peakInterpolation::PARABOLIC);
                    } else if (metric == "stdev" || metric == "sd" || metric == "standard_deviation") {
                        result(i, j) = Harmonicity_getStandardDeviation(ptr.get(), from, to);
                    } else {
                        Rcpp::warning("Unknown metric: %s", metric.c_str());
                        result(i, j) = NA_REAL;
                    }
                }
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute harmonicity statistics batch");
        }

        colnames(result) = metrics;
        return result;
    }

    // Get all HNR values as vector (fast extraction)
    NumericVector get_values_vector() {
        VALIDATE_PTR(ptr, Harmonicity);
        integer nx = ptr->nx;
        NumericVector values(nx);

        for (integer i = 1; i <= nx; i++) {
            values[i-1] = ptr->z[1][i];
        }

        return values;
    }

    // Get all frame times as vector
    NumericVector get_times_vector() {
        VALIDATE_PTR(ptr, Harmonicity);
        integer nx = ptr->nx;
        NumericVector times(nx);

        for (integer i = 1; i <= nx; i++) {
            times[i-1] = Sampled_indexToX(ptr.get(), i);
        }

        return times;
    }

    // Get HNR values at multiple specific times
    NumericVector get_values_at_times(NumericVector times, int interpolation = 2) {
        VALIDATE_PTR(ptr, Harmonicity);
        int n = times.size();
        NumericVector values(n);
        kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation);

        try {
            for (int i = 0; i < n; i++) {
                values[i] = Vector_getValueAtX(ptr.get(), times[i], 1, interp);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get HNR values at times");
        }

        return values;
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Harmonicity);
        std::vector<double> times, values;
        std::vector<bool> voiced;
        for (integer i = 1; i <= ptr->nx; i++) {
            times.push_back(Sampled_indexToX(ptr.get(), i));
            double val = ptr->z[1][i];
            values.push_back(val);
            voiced.push_back(val > -200);  // -200 dB indicates unvoiced
        }
        return pladdrr::dt::create_datatable(
            List::create(
                Named("time") = times,
                Named("hnr") = values,
                Named("voiced") = voiced
            ),
            CharacterVector::create("time", "hnr", "voiced"),
            CharacterVector::create("time")
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Harmonicity);
        NumericMatrix mat(ptr->nx, 2);
        for (integer i = 1; i <= ptr->nx; i++) {
            mat(i-1, 0) = Sampled_indexToX(ptr.get(), i);
            mat(i-1, 1) = ptr->z[1][i];
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Harmonicity);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Harmonicity");
        }
    }
};

RCPP_MODULE(harmonicity_module) {
    class_<RHarmonicity>("RHarmonicity")
        .constructor()
        .constructor<XPtr<structHarmonicity>>()
        .method("is_valid", &RHarmonicity::is_valid)
        
        // Properties for fast access (2-3x faster)
        .property("duration", &RHarmonicity::get_duration, "Duration in seconds")
        .property("xmin", &RHarmonicity::get_xmin, "Start time in seconds")
        .property("xmax", &RHarmonicity::get_xmax, "End time in seconds")
        .property("nx", &RHarmonicity::get_nx, "Number of frames")
        .property("dx", &RHarmonicity::get_dx, "Time step between frames")
        .property("x1", &RHarmonicity::get_x1, "Time of first frame")
        
        // Keep methods for backward compatibility
        .method("get_xmin", &RHarmonicity::get_xmin)
        .method("get_xmax", &RHarmonicity::get_xmax)
        .method("get_duration", &RHarmonicity::get_duration)
        .method("get_nx", &RHarmonicity::get_nx)
        .method("get_dx", &RHarmonicity::get_dx)
        .method("get_x1", &RHarmonicity::get_x1)
        .method("get_number_of_frames", &RHarmonicity::get_number_of_frames)
        .method("get_time_step", &RHarmonicity::get_time_step)
        .method("get_time_from_frame", &RHarmonicity::get_time_from_frame)
        .method("get_frame_from_time", &RHarmonicity::get_frame_from_time)
        .method("get_value_at_time", &RHarmonicity::get_value_at_time)
        .method("get_mean", &RHarmonicity::get_mean)
        .method("get_minimum", &RHarmonicity::get_minimum)
        .method("get_maximum", &RHarmonicity::get_maximum)
        .method("get_time_of_minimum", &RHarmonicity::get_time_of_minimum)
        .method("get_time_of_maximum", &RHarmonicity::get_time_of_maximum)
        .method("get_standard_deviation", &RHarmonicity::get_standard_deviation)

        // Batch/Vectorized operations (10x speedup for VQ multi-band HNR)
        .method("get_statistics_batch", &RHarmonicity::get_statistics_batch, "Get stats for multiple windows")
        .method("get_values_vector", &RHarmonicity::get_values_vector, "Get all HNR values as vector")
        .method("get_times_vector", &RHarmonicity::get_times_vector, "Get all frame times as vector")
        .method("get_values_at_times", &RHarmonicity::get_values_at_times, "Get HNR at multiple times")

        .method("as_data_frame", &RHarmonicity::as_data_frame)
        .method("as_matrix", &RHarmonicity::as_matrix)
        .method("save", &RHarmonicity::save)
    ;
}
