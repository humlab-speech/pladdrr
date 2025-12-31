// formantgrid_module.cpp
// Rcpp Module exposing Praat FormantGrid functionality (pladdrr 2.0)
//
// FormantGrid: time-varying formant trajectories for synthesis/modification

#include <Rcpp.h>
#include "module_common.h"
#include "praat.github.io/fon/FormantGrid.h"
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Sound.h"

using namespace Rcpp;

class RFormantGrid {
private:
    XPtr<structFormantGrid> ptr;

public:
    RFormantGrid() : ptr(R_NilValue) {}
    RFormantGrid(XPtr<structFormantGrid> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties
    double get_xmin() { VALIDATE_PTR(ptr, FormantGrid); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, FormantGrid); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, FormantGrid); return ptr->xmax - ptr->xmin; }

    // Formant count
    int get_number_of_formants() {
        VALIDATE_PTR(ptr, FormantGrid);
        return static_cast<int>(ptr->formants.size);
    }

    // Query formant values
    double get_formant_at_time(int formant_number, double time) {
        VALIDATE_PTR(ptr, FormantGrid);
        try {
            double value = FormantGrid_getFormantAtTime(ptr.get(), formant_number, time);
            if (isundef(value)) return NA_REAL;
            return value;
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_bandwidth_at_time(int formant_number, double time) {
        VALIDATE_PTR(ptr, FormantGrid);
        try {
            double value = FormantGrid_getBandwidthAtTime(ptr.get(), formant_number, time);
            if (isundef(value)) return NA_REAL;
            return value;
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Modification - add points
    void add_formant_point(int formant_number, double time, double value) {
        VALIDATE_PTR(ptr, FormantGrid);
        try {
            FormantGrid_addFormantPoint(ptr.get(), formant_number, time, value);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to add formant point");
        }
    }

    void add_bandwidth_point(int formant_number, double time, double value) {
        VALIDATE_PTR(ptr, FormantGrid);
        try {
            FormantGrid_addBandwidthPoint(ptr.get(), formant_number, time, value);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to add bandwidth point");
        }
    }

    // Modification - remove points
    void remove_formant_points_between(int formant_number, double tmin, double tmax) {
        VALIDATE_PTR(ptr, FormantGrid);
        try {
            FormantGrid_removeFormantPointsBetween(ptr.get(), formant_number, tmin, tmax);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to remove formant points");
        }
    }

    void remove_bandwidth_points_between(int formant_number, double tmin, double tmax) {
        VALIDATE_PTR(ptr, FormantGrid);
        try {
            FormantGrid_removeBandwidthPointsBetween(ptr.get(), formant_number, tmin, tmax);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to remove bandwidth points");
        }
    }

    // Conversion to Formant
    XPtr<structFormant> to_formant_ptr(double time_step, double intensity) {
        VALIDATE_PTR(ptr, FormantGrid);
        try {
            autoFormant formant = FormantGrid_to_Formant(ptr.get(), time_step, intensity);
            structFormant* raw = formant.releaseToAmbiguousOwner();
            return XPtr<structFormant>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert FormantGrid to Formant");
        }
    }

    // Synthesis
    XPtr<structSound> to_sound_ptr(
        double sampling_frequency,
        double t_start, double f0_start,
        double t_mid, double f0_mid,
        double t_end, double f0_end,
        double adapt_factor, double maximum_period,
        double open_phase, double collision_phase,
        double power1, double power2) {
        VALIDATE_PTR(ptr, FormantGrid);
        try {
            autoSound sound = FormantGrid_to_Sound(
                ptr.get(), sampling_frequency,
                t_start, f0_start, t_mid, f0_mid, t_end, f0_end,
                adapt_factor, maximum_period, open_phase, collision_phase,
                power1, power2
            );
            structSound* raw = sound.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to synthesize sound from FormantGrid");
        }
    }

    // Filter sound with this FormantGrid
    XPtr<structSound> filter_sound_ptr(XPtr<structSound> sound) {
        VALIDATE_PTR(ptr, FormantGrid);
        if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
        try {
            autoSound filtered = Sound_FormantGrid_filter(sound.get(), ptr.get());
            structSound* raw = filtered.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to filter sound with FormantGrid");
        }
    }

    XPtr<structSound> filter_sound_noscale_ptr(XPtr<structSound> sound) {
        VALIDATE_PTR(ptr, FormantGrid);
        if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
        try {
            autoSound filtered = Sound_FormantGrid_filter_noscale(sound.get(), ptr.get());
            structSound* raw = filtered.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to filter sound with FormantGrid (no scale)");
        }
    }

    // Export formant trajectory as data frame
    DataFrame as_data_frame(double time_step) {
        VALIDATE_PTR(ptr, FormantGrid);
        int n_formants = ptr->formants.size;
        double tmin = ptr->xmin;
        double tmax = ptr->xmax;
        int n_frames = static_cast<int>((tmax - tmin) / time_step) + 1;

        std::vector<double> times;
        std::vector<int> formant_nums;
        std::vector<double> frequencies;
        std::vector<double> bandwidths;

        for (int frame = 0; frame < n_frames; frame++) {
            double t = tmin + frame * time_step;
            for (int f = 1; f <= n_formants; f++) {
                times.push_back(t);
                formant_nums.push_back(f);
                double freq = FormantGrid_getFormantAtTime(ptr.get(), f, t);
                double bw = FormantGrid_getBandwidthAtTime(ptr.get(), f, t);
                frequencies.push_back(isundef(freq) ? NA_REAL : freq);
                bandwidths.push_back(isundef(bw) ? NA_REAL : bw);
            }
        }

        return DataFrame::create(
            Named("time") = times,
            Named("formant") = formant_nums,
            Named("frequency") = frequencies,
            Named("bandwidth") = bandwidths
        );
    }

    List get_info() {
        VALIDATE_PTR(ptr, FormantGrid);
        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("n_formants") = ptr->formants.size
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, FormantGrid);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save FormantGrid");
        }
    }
};

// Factory functions (Module_ prefix to avoid collision with legacy wrappers)
static XPtr<structFormantGrid> Module_FormantGrid_create(
    double tmin, double tmax, int number_of_formants,
    double initial_first_formant, double initial_formant_spacing,
    double initial_first_bandwidth, double initial_bandwidth_spacing) {
    try {
        autoFormantGrid grid = FormantGrid_create(
            tmin, tmax, number_of_formants,
            initial_first_formant, initial_formant_spacing,
            initial_first_bandwidth, initial_bandwidth_spacing
        );
        structFormantGrid* raw = grid.releaseToAmbiguousOwner();
        return XPtr<structFormantGrid>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create FormantGrid");
    }
}

static XPtr<structFormantGrid> Module_FormantGrid_create_empty(
    double tmin, double tmax, int number_of_formants) {
    try {
        autoFormantGrid grid = FormantGrid_createEmpty(tmin, tmax, number_of_formants);
        structFormantGrid* raw = grid.releaseToAmbiguousOwner();
        return XPtr<structFormantGrid>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create empty FormantGrid");
    }
}

static XPtr<structFormantGrid> Module_Formant_to_FormantGrid(XPtr<structFormant> formant) {
    if (!formant || !formant.get()) Rcpp::stop("Invalid Formant pointer");
    try {
        autoFormantGrid grid = Formant_downto_FormantGrid(formant.get());
        structFormantGrid* raw = grid.releaseToAmbiguousOwner();
        return XPtr<structFormantGrid>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert Formant to FormantGrid");
    }
}

RCPP_MODULE(formantgrid_module) {
    class_<RFormantGrid>("RFormantGrid")
        .constructor()
        .constructor<XPtr<structFormantGrid>>()
        .method("is_valid", &RFormantGrid::is_valid)
        // Time domain
        .method("get_xmin", &RFormantGrid::get_xmin)
        .method("get_xmax", &RFormantGrid::get_xmax)
        .method("get_duration", &RFormantGrid::get_duration)
        // Formant count
        .method("get_number_of_formants", &RFormantGrid::get_number_of_formants)
        // Query
        .method("get_formant_at_time", &RFormantGrid::get_formant_at_time)
        .method("get_bandwidth_at_time", &RFormantGrid::get_bandwidth_at_time)
        // Modification
        .method("add_formant_point", &RFormantGrid::add_formant_point)
        .method("add_bandwidth_point", &RFormantGrid::add_bandwidth_point)
        .method("remove_formant_points_between", &RFormantGrid::remove_formant_points_between)
        .method("remove_bandwidth_points_between", &RFormantGrid::remove_bandwidth_points_between)
        // Conversion
        .method("to_formant_ptr", &RFormantGrid::to_formant_ptr)
        .method("to_sound_ptr", &RFormantGrid::to_sound_ptr)
        // Filtering
        .method("filter_sound_ptr", &RFormantGrid::filter_sound_ptr)
        .method("filter_sound_noscale_ptr", &RFormantGrid::filter_sound_noscale_ptr)
        // Export
        .method("as_data_frame", &RFormantGrid::as_data_frame)
        .method("get_info", &RFormantGrid::get_info)
        .method("save", &RFormantGrid::save)
    ;

    // Factory functions
    function("FormantGrid_create", &Module_FormantGrid_create);
    function("FormantGrid_create_empty", &Module_FormantGrid_create_empty);
    function("Formant_to_FormantGrid", &Module_Formant_to_FormantGrid);
}
