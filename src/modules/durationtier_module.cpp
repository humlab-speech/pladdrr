// durationtier_module.cpp
// Rcpp Module exposing DurationTier functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/DurationTier.h"
#include "praat.github.io/fon/PointProcess.h"

using namespace Rcpp;

class RDurationTier {
private:
    XPtr<structDurationTier> ptr;

public:
    RDurationTier() : ptr(R_NilValue) {}
    RDurationTier(XPtr<structDurationTier> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain
    double get_xmin() { VALIDATE_PTR(ptr, DurationTier); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, DurationTier); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, DurationTier); return ptr->xmax - ptr->xmin; }

    // Point access
    int get_number_of_points() {
        VALIDATE_PTR(ptr, DurationTier);
        return static_cast<int>(ptr->points.size);
    }

    double get_time(int point_number) {
        VALIDATE_PTR(ptr, DurationTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        return ptr->points.at[point_number]->number;
    }

    double get_value(int point_number) {
        VALIDATE_PTR(ptr, DurationTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        return ptr->points.at[point_number]->value;
    }

    // Query methods
    double get_value_at_time(double time) {
        VALIDATE_PTR(ptr, DurationTier);
        return RealTier_getValueAtTime(ptr.get(), time);
    }

    double get_minimum() {
        VALIDATE_PTR(ptr, DurationTier);
        return RealTier_getMinimumValue(ptr.get());
    }

    double get_maximum() {
        VALIDATE_PTR(ptr, DurationTier);
        return RealTier_getMaximumValue(ptr.get());
    }

    double get_area(double from_time, double to_time) {
        VALIDATE_PTR(ptr, DurationTier);
        return RealTier_getArea(ptr.get(), from_time, to_time);
    }

    double get_mean_curve(double from_time, double to_time) {
        VALIDATE_PTR(ptr, DurationTier);
        return RealTier_getMean_curve(ptr.get(), from_time, to_time);
    }

    double get_mean_points(double from_time, double to_time) {
        VALIDATE_PTR(ptr, DurationTier);
        return RealTier_getMean_points(ptr.get(), from_time, to_time);
    }

    double get_standard_deviation_curve(double from_time, double to_time) {
        VALIDATE_PTR(ptr, DurationTier);
        return RealTier_getStandardDeviation_curve(ptr.get(), from_time, to_time);
    }

    double get_standard_deviation_points(double from_time, double to_time) {
        VALIDATE_PTR(ptr, DurationTier);
        return RealTier_getStandardDeviation_points(ptr.get(), from_time, to_time);
    }

    // Modification
    void add_point(double time, double value) {
        VALIDATE_PTR(ptr, DurationTier);
        RealTier_addPoint(ptr.get(), time, value);
    }

    void remove_point(int point_number) {
        VALIDATE_PTR(ptr, DurationTier);
        if (point_number < 1 || point_number > ptr->points.size)
            Rcpp::stop("Point number out of range");
        AnyTier_removePoint(ptr.get()->asAnyTier(), point_number);
    }

    void remove_points_between(double from_time, double to_time) {
        VALIDATE_PTR(ptr, DurationTier);
        AnyTier_removePointsBetween(ptr.get()->asAnyTier(), from_time, to_time);
    }

    // DurationTier-specific: get target duration for time range
    double get_target_duration(double from_time, double to_time) {
        VALIDATE_PTR(ptr, DurationTier);
        return RealTier_getArea(ptr.get(), from_time, to_time);
    }

    // Transform
    XPtr<structPointProcess> down_to_point_process_ptr() {
        VALIDATE_PTR(ptr, DurationTier);
        try {
            autoPointProcess result = AnyTier_downto_PointProcess(ptr.get()->asConstAnyTier());
            PointProcess raw = result.releaseToAmbiguousOwner();
            return XPtr<structPointProcess>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to PointProcess");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, DurationTier);
        std::vector<double> times, values;
        for (integer i = 1; i <= ptr->points.size; i++) {
            times.push_back(ptr->points.at[i]->number);
            values.push_back(ptr->points.at[i]->value);
        }
        return DataFrame::create(
            Named("time") = times,
            Named("duration_factor") = values
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, DurationTier);
        NumericMatrix mat(ptr->points.size, 2);
        for (integer i = 1; i <= ptr->points.size; i++) {
            mat(i-1, 0) = ptr->points.at[i]->number;
            mat(i-1, 1) = ptr->points.at[i]->value;
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, DurationTier);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save DurationTier");
        }
    }
};

RCPP_MODULE(durationtier_module) {
    class_<RDurationTier>("RDurationTier")
        .constructor()
        .constructor<XPtr<structDurationTier>>()
        .method("is_valid", &RDurationTier::is_valid)
        .method("get_xmin", &RDurationTier::get_xmin)
        .method("get_xmax", &RDurationTier::get_xmax)
        .method("get_duration", &RDurationTier::get_duration)
        .method("get_number_of_points", &RDurationTier::get_number_of_points)
        .method("get_time", &RDurationTier::get_time)
        .method("get_value", &RDurationTier::get_value)
        .method("get_value_at_time", &RDurationTier::get_value_at_time)
        .method("get_minimum", &RDurationTier::get_minimum)
        .method("get_maximum", &RDurationTier::get_maximum)
        .method("get_area", &RDurationTier::get_area)
        .method("get_mean_curve", &RDurationTier::get_mean_curve)
        .method("get_mean_points", &RDurationTier::get_mean_points)
        .method("get_standard_deviation_curve", &RDurationTier::get_standard_deviation_curve)
        .method("get_standard_deviation_points", &RDurationTier::get_standard_deviation_points)
        .method("add_point", &RDurationTier::add_point)
        .method("remove_point", &RDurationTier::remove_point)
        .method("remove_points_between", &RDurationTier::remove_points_between)
        .method("get_target_duration", &RDurationTier::get_target_duration)
        .method("down_to_point_process_ptr", &RDurationTier::down_to_point_process_ptr)
        .method("as_data_frame", &RDurationTier::as_data_frame)
        .method("as_matrix", &RDurationTier::as_matrix)
        .method("save", &RDurationTier::save)
    ;
}
