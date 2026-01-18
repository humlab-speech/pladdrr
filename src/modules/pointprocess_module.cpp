// pointprocess_module.cpp
// Rcpp Module exposing PointProcess functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/fon/PitchTier.h"
#include "praat.github.io/fon/IntensityTier.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/PointProcess_and_Sound.h"
#include "praat.github.io/fon/VoiceAnalysis.h"

using namespace Rcpp;

class RPointProcess {
private:
    XPtr<structPointProcess> ptr;

public:
    RPointProcess() : ptr(R_NilValue) {}
    RPointProcess(XPtr<structPointProcess> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain
    double get_xmin() { VALIDATE_PTR(ptr, PointProcess); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, PointProcess); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, PointProcess); return ptr->xmax - ptr->xmin; }

    // Point access
    int get_number_of_points() {
        VALIDATE_PTR(ptr, PointProcess);
        return static_cast<int>(ptr->nt);
    }

    double get_time(int point_number) {
        VALIDATE_PTR(ptr, PointProcess);
        if (point_number < 1 || point_number > ptr->nt)
            Rcpp::stop("Point number out of range");
        return ptr->t[point_number];
    }

    // Query methods
    int get_low_index(double time) {
        VALIDATE_PTR(ptr, PointProcess);
        return static_cast<int>(PointProcess_getLowIndex(ptr.get(), time));
    }

    int get_high_index(double time) {
        VALIDATE_PTR(ptr, PointProcess);
        return static_cast<int>(PointProcess_getHighIndex(ptr.get(), time));
    }

    int get_nearest_index(double time) {
        VALIDATE_PTR(ptr, PointProcess);
        return static_cast<int>(PointProcess_getNearestIndex(ptr.get(), time));
    }

    double get_interval(double time) {
        VALIDATE_PTR(ptr, PointProcess);
        return PointProcess_getInterval(ptr.get(), time);
    }

    // Period analysis
    int get_number_of_periods(double tmin, double tmax,
                              double minimum_period, double maximum_period,
                              double maximum_period_factor) {
        VALIDATE_PTR(ptr, PointProcess);
        return static_cast<int>(PointProcess_getNumberOfPeriods(
            ptr.get(), tmin, tmax, minimum_period, maximum_period, maximum_period_factor));
    }

    double get_mean_period(double tmin, double tmax,
                           double minimum_period, double maximum_period,
                           double maximum_period_factor) {
        VALIDATE_PTR(ptr, PointProcess);
        return PointProcess_getMeanPeriod(
            ptr.get(), tmin, tmax, minimum_period, maximum_period, maximum_period_factor);
    }

    double get_stdev_period(double tmin, double tmax,
                            double minimum_period, double maximum_period,
                            double maximum_period_factor) {
        VALIDATE_PTR(ptr, PointProcess);
        return PointProcess_getStdevPeriod(
            ptr.get(), tmin, tmax, minimum_period, maximum_period, maximum_period_factor);
    }

    List get_voice_breaks(double tmin, double tmax, double maximum_period) {
        VALIDATE_PTR(ptr, PointProcess);
        MelderCountAndFraction result = PointProcess_getCountAndFractionOfVoiceBreaks(
            ptr.get(), tmin, tmax, maximum_period);
        return List::create(
            Named("count") = static_cast<int>(result.count),
            Named("fraction") = result.getFraction()
        );
    }

    // Modification
    void add_point(double time) {
        VALIDATE_PTR(ptr, PointProcess);
        PointProcess_addPoint(ptr.get(), time);
    }

    void remove_point(int point_number) {
        VALIDATE_PTR(ptr, PointProcess);
        if (point_number < 1 || point_number > ptr->nt)
            Rcpp::stop("Point number out of range");
        PointProcess_removePoint(ptr.get(), point_number);
    }

    void remove_point_near(double time) {
        VALIDATE_PTR(ptr, PointProcess);
        PointProcess_removePointNear(ptr.get(), time);
    }

    void remove_points_between(double from_time, double to_time) {
        VALIDATE_PTR(ptr, PointProcess);
        PointProcess_removePointsBetween(ptr.get(), from_time, to_time);
    }

    void fill(double tmin, double tmax, double period) {
        VALIDATE_PTR(ptr, PointProcess);
        PointProcess_fill(ptr.get(), tmin, tmax, period);
    }

    void voice(double period, double max_t) {
        VALIDATE_PTR(ptr, PointProcess);
        PointProcess_voice(ptr.get(), period, max_t);
    }

    // Transforms
    XPtr<structPointProcess> union_with(XPtr<structPointProcess> other_ptr) {
        VALIDATE_PTR(ptr, PointProcess);
        if (!other_ptr || other_ptr.get() == nullptr)
            Rcpp::stop("Invalid other PointProcess pointer");
        try {
            autoPointProcess result = PointProcesses_union(ptr.get(), other_ptr.get());
            PointProcess raw = result.releaseToAmbiguousOwner();
            return XPtr<structPointProcess>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute union");
        }
    }

    XPtr<structPointProcess> intersection_with(XPtr<structPointProcess> other_ptr) {
        VALIDATE_PTR(ptr, PointProcess);
        if (!other_ptr || other_ptr.get() == nullptr)
            Rcpp::stop("Invalid other PointProcess pointer");
        try {
            autoPointProcess result = PointProcesses_intersection(ptr.get(), other_ptr.get());
            PointProcess raw = result.releaseToAmbiguousOwner();
            return XPtr<structPointProcess>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute intersection");
        }
    }

    XPtr<structPointProcess> difference_with(XPtr<structPointProcess> other_ptr) {
        VALIDATE_PTR(ptr, PointProcess);
        if (!other_ptr || other_ptr.get() == nullptr)
            Rcpp::stop("Invalid other PointProcess pointer");
        try {
            autoPointProcess result = PointProcesses_difference(ptr.get(), other_ptr.get());
            PointProcess raw = result.releaseToAmbiguousOwner();
            return XPtr<structPointProcess>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute difference");
        }
    }

    XPtr<structPitchTier> upto_pitch_tier_ptr(double frequency) {
        VALIDATE_PTR(ptr, PointProcess);
        try {
            autoPitchTier result = PointProcess_upto_PitchTier(ptr.get(), frequency);
            PitchTier raw = result.releaseToAmbiguousOwner();
            return XPtr<structPitchTier>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to PitchTier");
        }
    }

    XPtr<structIntensityTier> upto_intensity_tier_ptr(double intensity) {
        VALIDATE_PTR(ptr, PointProcess);
        try {
            autoIntensityTier result = PointProcess_upto_IntensityTier(ptr.get(), intensity);
            IntensityTier raw = result.releaseToAmbiguousOwner();
            return XPtr<structIntensityTier>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to IntensityTier");
        }
    }

    // ========================================================================
    // Batch Operations (Phase 3: DSI/Shimmer speedup)
    // ========================================================================

    // Get Sound values at all point times in a single call
    // This is 10-20x faster than individual queries for shimmer analysis
    NumericVector get_values_from_sound(XPtr<structSound> sound_ptr, int channel, int interpolation) {
        VALIDATE_PTR(ptr, PointProcess);
        if (!sound_ptr || sound_ptr.get() == nullptr) {
            Rcpp::stop("Invalid Sound pointer");
        }

        integer n = ptr->nt;
        NumericVector values(n);
        kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation);

        try {
            for (integer i = 1; i <= n; i++) {
                double t = ptr->t[i];
                values[i-1] = Vector_getValueAtX(sound_ptr.get(), t, channel, interp);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get values from sound at point times");
        }

        return values;
    }

    // Get periods (inter-point intervals) as vector
    NumericVector get_periods_vector() {
        VALIDATE_PTR(ptr, PointProcess);

        integer n = ptr->nt;
        if (n < 2) {
            return NumericVector(0);
        }

        NumericVector periods(n - 1);
        for (integer i = 1; i < n; i++) {
            periods[i-1] = ptr->t[i+1] - ptr->t[i];
        }

        return periods;
    }

    // Get filtered periods (only those within specified range)
    NumericVector get_periods_filtered(double min_period, double max_period) {
        VALIDATE_PTR(ptr, PointProcess);

        integer n = ptr->nt;
        if (n < 2) {
            return NumericVector(0);
        }

        // First pass: count valid periods
        integer count = 0;
        for (integer i = 1; i < n; i++) {
            double p = ptr->t[i+1] - ptr->t[i];
            if (p >= min_period && p <= max_period) {
                count++;
            }
        }

        NumericVector periods(count);
        integer idx = 0;
        for (integer i = 1; i < n; i++) {
            double p = ptr->t[i+1] - ptr->t[i];
            if (p >= min_period && p <= max_period) {
                periods[idx++] = p;
            }
        }

        return periods;
    }

    // Get jitter measures in a single call (local, local_absolute, rap, ppq5, ddp)
    List get_jitter_batch(double tmin, double tmax,
                          double min_period, double max_period,
                          double max_period_factor) {
        VALIDATE_PTR(ptr, PointProcess);

        try {
            double local = PointProcess_getJitter_local(
                ptr.get(), tmin, tmax, min_period, max_period, max_period_factor);
            double local_abs = PointProcess_getJitter_local_absolute(
                ptr.get(), tmin, tmax, min_period, max_period, max_period_factor);
            double rap = PointProcess_getJitter_rap(
                ptr.get(), tmin, tmax, min_period, max_period, max_period_factor);
            double ppq5 = PointProcess_getJitter_ppq5(
                ptr.get(), tmin, tmax, min_period, max_period, max_period_factor);
            double ddp = PointProcess_getJitter_ddp(
                ptr.get(), tmin, tmax, min_period, max_period, max_period_factor);

            return List::create(
                Named("local") = local,
                Named("local_absolute") = local_abs,
                Named("rap") = rap,
                Named("ppq5") = ppq5,
                Named("ddp") = ddp
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute jitter measures");
        }
    }

    // Export
    NumericVector as_vector() {
        VALIDATE_PTR(ptr, PointProcess);
        NumericVector times(ptr->nt);
        for (integer i = 1; i <= ptr->nt; i++) {
            times[i-1] = ptr->t[i];
        }
        return times;
    }

    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, PointProcess);
        std::vector<double> times;
        std::vector<int> indices;
        for (integer i = 1; i <= ptr->nt; i++) {
            indices.push_back(static_cast<int>(i));
            times.push_back(ptr->t[i]);
        }
        return pladdrr::dt::create_datatable(
            List::create(
                Named("index") = indices,
                Named("time") = times
            ),
            CharacterVector::create("index", "time"),
            CharacterVector::create("time")
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, PointProcess);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save PointProcess");
        }
    }
};

RCPP_MODULE(pointprocess_module) {
    class_<RPointProcess>("RPointProcess")
        .constructor()
        .constructor<XPtr<structPointProcess>>()
        .method("is_valid", &RPointProcess::is_valid)
        
        // Properties for fast access
        .property("xmin", &RPointProcess::get_xmin, "Start time (s)")
        .property("xmax", &RPointProcess::get_xmax, "End time (s)")
        .property("duration", &RPointProcess::get_duration, "Duration (s)")
        .property("nt", &RPointProcess::get_number_of_points, "Number of points")
        
        // Keep methods for backward compatibility
        .method("get_xmin", &RPointProcess::get_xmin)
        .method("get_xmax", &RPointProcess::get_xmax)
        .method("get_duration", &RPointProcess::get_duration)
        .method("get_number_of_points", &RPointProcess::get_number_of_points)
        .method("get_time", &RPointProcess::get_time)
        .method("get_low_index", &RPointProcess::get_low_index)
        .method("get_high_index", &RPointProcess::get_high_index)
        .method("get_nearest_index", &RPointProcess::get_nearest_index)
        .method("get_interval", &RPointProcess::get_interval)
        .method("get_number_of_periods", &RPointProcess::get_number_of_periods)
        .method("get_mean_period", &RPointProcess::get_mean_period)
        .method("get_stdev_period", &RPointProcess::get_stdev_period)
        .method("get_voice_breaks", &RPointProcess::get_voice_breaks)
        .method("add_point", &RPointProcess::add_point)
        .method("remove_point", &RPointProcess::remove_point)
        .method("remove_point_near", &RPointProcess::remove_point_near)
        .method("remove_points_between", &RPointProcess::remove_points_between)
        .method("fill", &RPointProcess::fill)
        .method("voice", &RPointProcess::voice)
        .method("union_with", &RPointProcess::union_with)
        .method("intersection_with", &RPointProcess::intersection_with)
        .method("difference_with", &RPointProcess::difference_with)
        .method("upto_pitch_tier_ptr", &RPointProcess::upto_pitch_tier_ptr)
        .method("upto_intensity_tier_ptr", &RPointProcess::upto_intensity_tier_ptr)

        // Batch operations (10-20x speedup for shimmer/DSI analysis)
        .method("get_values_from_sound", &RPointProcess::get_values_from_sound, "Get Sound values at all point times")
        .method("get_periods_vector", &RPointProcess::get_periods_vector, "Get all periods as vector")
        .method("get_periods_filtered", &RPointProcess::get_periods_filtered, "Get periods within range")
        .method("get_jitter_batch", &RPointProcess::get_jitter_batch, "Get all jitter measures in one call")

        .method("as_vector", &RPointProcess::as_vector)
        .method("as_data_frame", &RPointProcess::as_data_frame)
        .method("save", &RPointProcess::save)
    ;
}
