// formant_module.cpp
// Rcpp Module exposing Formant functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"

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
    RFormant(XPtr<structFormant> xptr) : ptr(xptr) {}

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
        integer min_nFormants = 1000;
        for (integer i = 1; i <= ptr->nx; i++) {
            Formant_Frame frame = &ptr->frames[i];
            if (frame->numberOfFormants < min_nFormants) {
                min_nFormants = frame->numberOfFormants;
            }
        }
        return static_cast<int>(min_nFormants == 1000 ? 0 : min_nFormants);
    }

    int get_max_num_formants() {
        VALIDATE_PTR(ptr, Formant);
        integer max_nFormants = 0;
        for (integer i = 1; i <= ptr->nx; i++) {
            Formant_Frame frame = &ptr->frames[i];
            if (frame->numberOfFormants > max_nFormants) {
                max_nFormants = frame->numberOfFormants;
            }
        }
        return static_cast<int>(max_nFormants);
    }

    // =========================================================================
    // Query Methods
    // =========================================================================

    double get_value_at_time(int formant_number, double time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        return Formant_getValueAtTime(
            ptr.get(),
            formant_number,
            time,
            static_cast<kFormant_unit>(unit)
        );
    }

    double get_bandwidth_at_time(int formant_number, double time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        return Formant_getBandwidthAtTime(
            ptr.get(),
            formant_number,
            time,
            static_cast<kFormant_unit>(unit)
        );
    }

    double get_mean(int formant_number, double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        return Formant_getMean(
            ptr.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit)
        );
    }

    double get_standard_deviation(int formant_number, double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        return Formant_getStandardDeviation(
            ptr.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit)
        );
    }

    double get_quantile(int formant_number, double quantile, double from_time, double to_time, int unit) {
        VALIDATE_PTR(ptr, Formant);
        return Formant_getQuantile(
            ptr.get(),
            formant_number,
            quantile,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit)
        );
    }

    double get_minimum(int formant_number, double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Formant);
        return Formant_getMinimum(
            ptr.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit),
            interpolate
        );
    }

    double get_maximum(int formant_number, double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Formant);
        return Formant_getMaximum(
            ptr.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit),
            interpolate
        );
    }

    double get_time_of_minimum(int formant_number, double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Formant);
        return Formant_getTimeOfMinimum(
            ptr.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit),
            interpolate
        );
    }

    double get_time_of_maximum(int formant_number, double from_time, double to_time, int unit, bool interpolate) {
        VALIDATE_PTR(ptr, Formant);
        return Formant_getTimeOfMaximum(
            ptr.get(),
            formant_number,
            from_time,
            to_time,
            static_cast<kFormant_unit>(unit),
            interpolate
        );
    }

    // =========================================================================
    // Export Methods
    // =========================================================================

    DataFrame as_data_frame(int max_formants) {
        VALIDATE_PTR(ptr, Formant);

        std::vector<double> times;
        std::vector<int> formant_nums;
        std::vector<double> frequencies;
        std::vector<double> bandwidths;

        for (integer iframe = 1; iframe <= ptr->nx; iframe++) {
            double time = Sampled_indexToX(ptr.get(), iframe);
            Formant_Frame frame = &ptr->frames[iframe];

            integer nFormants = std::min(frame->numberOfFormants, (integer)max_formants);
            for (integer iformant = 1; iformant <= nFormants; iformant++) {
                times.push_back(time);
                formant_nums.push_back(iformant);
                frequencies.push_back(frame->formant[iformant].frequency);
                bandwidths.push_back(frame->formant[iformant].bandwidth);
            }
        }

        return DataFrame::create(
            Named("time") = times,
            Named("formant") = formant_nums,
            Named("frequency") = frequencies,
            Named("bandwidth") = bandwidths
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
            Rcpp::stop("Failed to save Formant to file: %s", path.c_str());
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

        // Export methods
        .method("as_data_frame", &RFormant::as_data_frame, "Export as data frame")
        .method("as_matrix", &RFormant::as_matrix, "Export as matrix")

        // Save method
        .method("save", &RFormant::save, "Save to Praat text file")
    ;
}
