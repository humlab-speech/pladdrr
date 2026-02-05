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
// intensity_module.cpp
// Rcpp Module exposing Intensity functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/Intensity.h"
#include "praat.github.io/fon/IntensityTier.h"

using namespace Rcpp;

class RIntensity {
private:
    XPtr<structIntensity> ptr;

public:
    RIntensity() : ptr(R_NilValue) {}
    RIntensity(XPtr<structIntensity> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain
    double get_xmin() { VALIDATE_PTR(ptr, Intensity); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, Intensity); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, Intensity); return ptr->xmax - ptr->xmin; }

    // Frame properties
    int get_nx() { VALIDATE_PTR(ptr, Intensity); return static_cast<int>(ptr->nx); }
    double get_dx() { VALIDATE_PTR(ptr, Intensity); return ptr->dx; }
    double get_x1() { VALIDATE_PTR(ptr, Intensity); return ptr->x1; }
    int get_number_of_frames() { return get_nx(); }
    double get_time_step() { return get_dx(); }

    // Time/frame conversion
    double get_time_from_frame(int frame) {
        VALIDATE_PTR(ptr, Intensity);
        return Sampled_indexToX(ptr.get(), frame);
    }
    int get_frame_from_time(double time) {
        VALIDATE_PTR(ptr, Intensity);
        return static_cast<int>(Sampled_xToNearestIndex(ptr.get(), time));
    }

    // Query methods
    double get_value_at_time(double time, int interpolation) {
        VALIDATE_PTR(ptr, Intensity);
        return Sampled_getValueAtX(ptr.get(), time, 1, 0, interpolation);
    }

    double get_mean(double from_time, double to_time, int averaging_method) {
        VALIDATE_PTR(ptr, Intensity);
        return Intensity_getAverage(ptr.get(), from_time, to_time, averaging_method);
    }

    double get_minimum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Intensity);
        return Vector_getMinimum(ptr.get(), from_time, to_time, (kVector_peakInterpolation)interpolation);
    }

    double get_maximum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Intensity);
        return Vector_getMaximum(ptr.get(), from_time, to_time, (kVector_peakInterpolation)interpolation);
    }

    double get_time_of_minimum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Intensity);
        return Vector_getXOfMinimum(ptr.get(), from_time, to_time, (kVector_peakInterpolation)interpolation);
    }

    double get_time_of_maximum(double from_time, double to_time, int interpolation) {
        VALIDATE_PTR(ptr, Intensity);
        return Vector_getXOfMaximum(ptr.get(), from_time, to_time, (kVector_peakInterpolation)interpolation);
    }

    double get_standard_deviation(double from_time, double to_time) {
        VALIDATE_PTR(ptr, Intensity);
        return Vector_getStandardDeviation(ptr.get(), from_time, to_time, 1);
    }

    double get_quantile(double from_time, double to_time, double quantile) {
        VALIDATE_PTR(ptr, Intensity);
        return Intensity_getQuantile(ptr.get(), from_time, to_time, quantile);
    }

    // ========================================================================
    // Batch Statistics (NEW - Performance Enhancement)
    // ========================================================================

    List get_statistics(double from_time, double to_time, CharacterVector metrics) {
        VALIDATE_PTR(ptr, Intensity);
        
        if (from_time == 0 && to_time == 0) {
            from_time = ptr->xmin;
            to_time = ptr->xmax;
        }
        
        List result;
        
        try {
            for (int i = 0; i < metrics.size(); i++) {
                std::string metric = Rcpp::as<std::string>(metrics[i]);
                
                if (metric == "minimum" || metric == "min") {
                    double val = Vector_getMinimum(ptr.get(), from_time, to_time, 
                                                  kVector_peakInterpolation::PARABOLIC);
                    result[metric] = val;
                    
                } else if (metric == "maximum" || metric == "max") {
                    double val = Vector_getMaximum(ptr.get(), from_time, to_time, 
                                                  kVector_peakInterpolation::PARABOLIC);
                    result[metric] = val;
                    
                } else if (metric == "mean") {
                    double val = Intensity_getAverage(ptr.get(), from_time, to_time, 0);
                    result[metric] = val;
                    
                } else if (metric == "stdev" || metric == "standard_deviation" || metric == "sd") {
                    double val = Vector_getStandardDeviation(ptr.get(), from_time, to_time, 1);
                    result[metric] = val;
                    
                } else if (metric == "median") {
                    double val = Intensity_getQuantile(ptr.get(), from_time, to_time, 0.5);
                    result[metric] = val;
                    
                } else if (metric == "quantile25" || metric == "q25") {
                    double val = Intensity_getQuantile(ptr.get(), from_time, to_time, 0.25);
                    result[metric] = val;
                    
                } else if (metric == "quantile75" || metric == "q75") {
                    double val = Intensity_getQuantile(ptr.get(), from_time, to_time, 0.75);
                    result[metric] = val;
                    
                } else {
                    Rcpp::warning("Unknown metric: %s", metric.c_str());
                }
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to calculate intensity statistics");
        }
        
        return result;
    }

    // Transform
    XPtr<structIntensityTier> down_to_intensity_tier_ptr() {
        VALIDATE_PTR(ptr, Intensity);
        try {
            autoIntensityTier result = Intensity_downto_IntensityTier(ptr.get());
            IntensityTier raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structIntensityTier* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structIntensityTier>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to IntensityTier");
        }
    }

    // Export
    NumericVector get_times_vector() {
        VALIDATE_PTR(ptr, Intensity);
        NumericVector times(ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            times[i-1] = Sampled_indexToX(ptr.get(), i);
        }
        return times;
    }
    
    NumericVector get_values_vector() {
        VALIDATE_PTR(ptr, Intensity);
        NumericVector values(ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            values[i-1] = ptr->z[1][i];
        }
        return values;
    }
    
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Intensity);
        std::vector<double> times, values;
        for (integer i = 1; i <= ptr->nx; i++) {
            times.push_back(Sampled_indexToX(ptr.get(), i));
            values.push_back(ptr->z[1][i]);
        }
        return pladdrr::dt::create_datatable(
            List::create(
                Named("time") = times,
                Named("intensity") = values
            ),
            CharacterVector::create("time", "intensity"),
            CharacterVector::create("time")
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Intensity);
        NumericMatrix mat(ptr->nx, 2);
        for (integer i = 1; i <= ptr->nx; i++) {
            mat(i-1, 0) = Sampled_indexToX(ptr.get(), i);
            mat(i-1, 1) = ptr->z[1][i];
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Intensity);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Intensity");
        }
    }
};

RCPP_MODULE(intensity_module) {
    class_<RIntensity>("RIntensity")
        .constructor()
        .constructor<XPtr<structIntensity>>()
        .method("is_valid", &RIntensity::is_valid)
        
        // Properties for fast access (2-3x faster than method calls)
        .property("duration", &RIntensity::get_duration, "Duration in seconds")
        .property("xmin", &RIntensity::get_xmin, "Start time in seconds")
        .property("xmax", &RIntensity::get_xmax, "End time in seconds")
        .property("nx", &RIntensity::get_nx, "Number of frames")
        .property("dx", &RIntensity::get_dx, "Time step between frames")
        .property("x1", &RIntensity::get_x1, "Time of first frame")
        
        // Keep method names for backward compatibility
        .method("get_xmin", &RIntensity::get_xmin)
        .method("get_xmax", &RIntensity::get_xmax)
        .method("get_duration", &RIntensity::get_duration)
        .method("get_nx", &RIntensity::get_nx)
        .method("get_dx", &RIntensity::get_dx)
        .method("get_x1", &RIntensity::get_x1)
        .method("get_number_of_frames", &RIntensity::get_number_of_frames)
        .method("get_time_step", &RIntensity::get_time_step)
        .method("get_time_from_frame", &RIntensity::get_time_from_frame)
        .method("get_frame_from_time", &RIntensity::get_frame_from_time)
        .method("get_value_at_time", &RIntensity::get_value_at_time)
        .method("get_mean", &RIntensity::get_mean)
        .method("get_minimum", &RIntensity::get_minimum)
        .method("get_maximum", &RIntensity::get_maximum)
        .method("get_time_of_minimum", &RIntensity::get_time_of_minimum)
        .method("get_time_of_maximum", &RIntensity::get_time_of_maximum)
        .method("get_standard_deviation", &RIntensity::get_standard_deviation)
        .method("get_quantile", &RIntensity::get_quantile)
        .method("get_statistics", &RIntensity::get_statistics, "Get multiple statistics in one call")
        .method("get_times_vector", &RIntensity::get_times_vector, "Get all frame times as vector")
        .method("get_values_vector", &RIntensity::get_values_vector, "Get all intensity values as vector")
        .method("down_to_intensity_tier_ptr", &RIntensity::down_to_intensity_tier_ptr)
        .method("as_data_frame", &RIntensity::as_data_frame)
        .method("as_matrix", &RIntensity::as_matrix)
        .method("save", &RIntensity::save)
    ;
}
