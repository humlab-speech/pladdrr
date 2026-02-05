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
// pitchtier_module.cpp
// Rcpp Module exposing PitchTier functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/PitchTier.h"
#include "praat.github.io/fon/PointProcess.h"

using namespace Rcpp;

class RPitchTier {
private:
    XPtr<structPitchTier> ptr;

public:
    RPitchTier() : ptr(R_NilValue) {}
    RPitchTier(XPtr<structPitchTier> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain
    double get_xmin() { VALIDATE_PTR(ptr, PitchTier); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, PitchTier); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, PitchTier); return ptr->xmax - ptr->xmin; }

    // Point access
    int get_number_of_points() {
        VALIDATE_PTR(ptr, PitchTier);
        return static_cast<int>(ptr->points.size);
    }

    double get_time(int point_number) {
        VALIDATE_PTR(ptr, PitchTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        return ptr->points.at[point_number]->number;
    }

    double get_value(int point_number) {
        VALIDATE_PTR(ptr, PitchTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        return ptr->points.at[point_number]->value;
    }

    // Query methods
    double get_value_at_time(double time) {
        VALIDATE_PTR(ptr, PitchTier);
        return RealTier_getValueAtTime(ptr.get(), time);
    }

    double get_minimum() {
        VALIDATE_PTR(ptr, PitchTier);
        return RealTier_getMinimumValue(ptr.get());
    }

    double get_maximum() {
        VALIDATE_PTR(ptr, PitchTier);
        return RealTier_getMaximumValue(ptr.get());
    }

    double get_area(double from_time, double to_time) {
        VALIDATE_PTR(ptr, PitchTier);
        return RealTier_getArea(ptr.get(), from_time, to_time);
    }

    double get_mean_curve(double from_time, double to_time) {
        VALIDATE_PTR(ptr, PitchTier);
        return RealTier_getMean_curve(ptr.get(), from_time, to_time);
    }

    double get_mean_points(double from_time, double to_time) {
        VALIDATE_PTR(ptr, PitchTier);
        return RealTier_getMean_points(ptr.get(), from_time, to_time);
    }

    double get_standard_deviation_curve(double from_time, double to_time) {
        VALIDATE_PTR(ptr, PitchTier);
        return RealTier_getStandardDeviation_curve(ptr.get(), from_time, to_time);
    }

    double get_standard_deviation_points(double from_time, double to_time) {
        VALIDATE_PTR(ptr, PitchTier);
        return RealTier_getStandardDeviation_points(ptr.get(), from_time, to_time);
    }

    // Modification
    void add_point(double time, double value) {
        VALIDATE_PTR(ptr, PitchTier);
        RealTier_addPoint(ptr.get(), time, value);
    }

    void remove_point(int point_number) {
        VALIDATE_PTR(ptr, PitchTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        AnyTier_removePoint(ptr.get()->asAnyTier(), point_number);
    }

    void remove_points_between(double from_time, double to_time) {
        VALIDATE_PTR(ptr, PitchTier);
        AnyTier_removePointsBetween(ptr.get()->asAnyTier(), from_time, to_time);
    }

    // PitchTier-specific
    void shift_frequencies(double from_time, double to_time, double shift, int unit) {
        VALIDATE_PTR(ptr, PitchTier);
        PitchTier_shiftFrequencies(ptr.get(), from_time, to_time, shift, (kPitch_unit)unit);
    }

    void multiply_frequencies(double from_time, double to_time, double factor) {
        VALIDATE_PTR(ptr, PitchTier);
        PitchTier_multiplyFrequencies(ptr.get(), from_time, to_time, factor);
    }

    void stylize(double frequency_resolution, bool use_semitones) {
        VALIDATE_PTR(ptr, PitchTier);
        PitchTier_stylize(ptr.get(), frequency_resolution, use_semitones);
    }

    // Transform
    XPtr<structPointProcess> down_to_point_process_ptr() {
        VALIDATE_PTR(ptr, PitchTier);
        try {
            autoPointProcess result = AnyTier_downto_PointProcess(ptr.get()->asConstAnyTier());
            PointProcess raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structPointProcess* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structPointProcess>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to PointProcess");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, PitchTier);
        std::vector<double> times, values;
        for (integer i = 1; i <= ptr->points.size; i++) {
            times.push_back(ptr->points.at[i]->number);
            values.push_back(ptr->points.at[i]->value);
        }
        return pladdrr::dt::create_datatable(
            List::create(
                Named("time") = times,
                Named("frequency") = values
            ),
            CharacterVector::create("time", "frequency"),
            CharacterVector::create("time")
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, PitchTier);
        NumericMatrix mat(ptr->points.size, 2);
        for (integer i = 1; i <= ptr->points.size; i++) {
            mat(i-1, 0) = ptr->points.at[i]->number;
            mat(i-1, 1) = ptr->points.at[i]->value;
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, PitchTier);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save PitchTier");
        }
    }
};

RCPP_MODULE(pitchtier_module) {
    class_<RPitchTier>("RPitchTier")
        .constructor()
        .constructor<XPtr<structPitchTier>>()
        .method("is_valid", &RPitchTier::is_valid)
        .method("get_xmin", &RPitchTier::get_xmin)
        .method("get_xmax", &RPitchTier::get_xmax)
        .method("get_duration", &RPitchTier::get_duration)
        .method("get_number_of_points", &RPitchTier::get_number_of_points)
        .method("get_time", &RPitchTier::get_time)
        .method("get_value", &RPitchTier::get_value)
        .method("get_value_at_time", &RPitchTier::get_value_at_time)
        .method("get_minimum", &RPitchTier::get_minimum)
        .method("get_maximum", &RPitchTier::get_maximum)
        .method("get_area", &RPitchTier::get_area)
        .method("get_mean_curve", &RPitchTier::get_mean_curve)
        .method("get_mean_points", &RPitchTier::get_mean_points)
        .method("get_standard_deviation_curve", &RPitchTier::get_standard_deviation_curve)
        .method("get_standard_deviation_points", &RPitchTier::get_standard_deviation_points)
        .method("add_point", &RPitchTier::add_point)
        .method("remove_point", &RPitchTier::remove_point)
        .method("remove_points_between", &RPitchTier::remove_points_between)
        .method("shift_frequencies", &RPitchTier::shift_frequencies)
        .method("multiply_frequencies", &RPitchTier::multiply_frequencies)
        .method("stylize", &RPitchTier::stylize)
        .method("down_to_point_process_ptr", &RPitchTier::down_to_point_process_ptr)
        .method("as_data_frame", &RPitchTier::as_data_frame)
        .method("as_matrix", &RPitchTier::as_matrix)
        .method("save", &RPitchTier::save)
    ;
}
