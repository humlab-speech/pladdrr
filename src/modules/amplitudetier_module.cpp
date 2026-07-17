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
// amplitudetier_module.cpp
// Rcpp Module exposing AmplitudeTier functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/AmplitudeTier.h"
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/fon/IntensityTier.h"

using namespace Rcpp;

class RAmplitudeTier {
private:
    XPtr<structAmplitudeTier> ptr;

public:
    RAmplitudeTier() : ptr(R_NilValue) {}
    RAmplitudeTier(XPtr<structAmplitudeTier> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain
    double get_xmin() { VALIDATE_PTR(ptr, AmplitudeTier); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, AmplitudeTier); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, AmplitudeTier); return ptr->xmax - ptr->xmin; }

    // Point access
    int get_number_of_points() {
        VALIDATE_PTR(ptr, AmplitudeTier);
        return static_cast<int>(ptr->points.size);
    }

    double get_time(int point_number) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        return ptr->points.at[point_number]->number;
    }

    double get_value(int point_number) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        return ptr->points.at[point_number]->value;
    }

    // Query methods
    double get_value_at_time(double time) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        return RealTier_getValueAtTime(ptr.get(), time);
    }

    double get_minimum() {
        VALIDATE_PTR(ptr, AmplitudeTier);
        return RealTier_getMinimumValue(ptr.get());
    }

    double get_maximum() {
        VALIDATE_PTR(ptr, AmplitudeTier);
        return RealTier_getMaximumValue(ptr.get());
    }

    double get_area(double from_time, double to_time) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        return RealTier_getArea(ptr.get(), from_time, to_time);
    }

    double get_mean_curve(double from_time, double to_time) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        return RealTier_getMean_curve(ptr.get(), from_time, to_time);
    }

    double get_mean_points(double from_time, double to_time) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        return RealTier_getMean_points(ptr.get(), from_time, to_time);
    }

    double get_standard_deviation_curve(double from_time, double to_time) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        return RealTier_getStandardDeviation_curve(ptr.get(), from_time, to_time);
    }

    double get_standard_deviation_points(double from_time, double to_time) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        return RealTier_getStandardDeviation_points(ptr.get(), from_time, to_time);
    }

    // Modification
    void add_point(double time, double value) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        RealTier_addPoint(ptr.get(), time, value);
    }

    void remove_point(int point_number) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        AnyTier_removePoint(ptr.get()->asAnyTier(), point_number);
    }

    void remove_points_between(double from_time, double to_time) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        AnyTier_removePointsBetween(ptr.get()->asAnyTier(), from_time, to_time);
    }

    // AmplitudeTier-specific: convert to IntensityTier
    XPtr<structIntensityTier> to_intensity_tier_ptr(double threshold) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        try {
            autoIntensityTier result = AmplitudeTier_to_IntensityTier(ptr.get(), threshold);
            IntensityTier raw = result.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to IntensityTier");
        }
    }

    // Transform
    XPtr<structPointProcess> down_to_point_process_ptr() {
        VALIDATE_PTR(ptr, AmplitudeTier);
        try {
            autoPointProcess result = AnyTier_downto_PointProcess(ptr.get()->asConstAnyTier());
            PointProcess raw = result.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to PointProcess");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, AmplitudeTier);
        std::vector<double> times, values;
        for (integer i = 1; i <= ptr->points.size; i++) {
            times.push_back(ptr->points.at[i]->number);
            values.push_back(ptr->points.at[i]->value);
        }
        return DataFrame::create(
            Named("time") = times,
            Named("amplitude") = values
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, AmplitudeTier);
        NumericMatrix mat(ptr->points.size, 2);
        for (integer i = 1; i <= ptr->points.size; i++) {
            mat(i-1, 0) = ptr->points.at[i]->number;
            mat(i-1, 1) = ptr->points.at[i]->value;
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, AmplitudeTier);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save AmplitudeTier");
        }
    }
};

RCPP_MODULE(amplitudetier_module) {
    class_<RAmplitudeTier>("RAmplitudeTier")
        .constructor()
        .constructor<XPtr<structAmplitudeTier>>()
        .method("is_valid", &RAmplitudeTier::is_valid)
        .method("get_xmin", &RAmplitudeTier::get_xmin)
        .method("get_xmax", &RAmplitudeTier::get_xmax)
        .method("get_duration", &RAmplitudeTier::get_duration)
        .method("get_number_of_points", &RAmplitudeTier::get_number_of_points)
        .method("get_time", &RAmplitudeTier::get_time)
        .method("get_value", &RAmplitudeTier::get_value)
        .method("get_value_at_time", &RAmplitudeTier::get_value_at_time)
        .method("get_minimum", &RAmplitudeTier::get_minimum)
        .method("get_maximum", &RAmplitudeTier::get_maximum)
        .method("get_area", &RAmplitudeTier::get_area)
        .method("get_mean_curve", &RAmplitudeTier::get_mean_curve)
        .method("get_mean_points", &RAmplitudeTier::get_mean_points)
        .method("get_standard_deviation_curve", &RAmplitudeTier::get_standard_deviation_curve)
        .method("get_standard_deviation_points", &RAmplitudeTier::get_standard_deviation_points)
        .method("add_point", &RAmplitudeTier::add_point)
        .method("remove_point", &RAmplitudeTier::remove_point)
        .method("remove_points_between", &RAmplitudeTier::remove_points_between)
        .method("to_intensity_tier_ptr", &RAmplitudeTier::to_intensity_tier_ptr)
        .method("down_to_point_process_ptr", &RAmplitudeTier::down_to_point_process_ptr)
        .method("as_data_frame", &RAmplitudeTier::as_data_frame)
        .method("as_matrix", &RAmplitudeTier::as_matrix)
        .method("save", &RAmplitudeTier::save)
    ;
}
