// formanttier_module.cpp
// Rcpp Module exposing FormantTier functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "praat.github.io/fon/FormantTier.h"
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Sound.h"

using namespace Rcpp;

class RFormantTier {
private:
    XPtr<structFormantTier> ptr;

public:
    RFormantTier() : ptr(R_NilValue) {}
    RFormantTier(XPtr<structFormantTier> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain
    double get_xmin() { VALIDATE_PTR(ptr, FormantTier); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, FormantTier); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, FormantTier); return ptr->xmax - ptr->xmin; }

    // Point access
    int get_number_of_points() {
        VALIDATE_PTR(ptr, FormantTier);
        return static_cast<int>(ptr->points.size);
    }

    // Formant info
    int get_min_num_formants() {
        VALIDATE_PTR(ptr, FormantTier);
        return static_cast<int>(FormantTier_getMinNumFormants(ptr.get()));
    }

    int get_max_num_formants() {
        VALIDATE_PTR(ptr, FormantTier);
        return static_cast<int>(FormantTier_getMaxNumFormants(ptr.get()));
    }

    // Query methods
    double get_value_at_time(int formant_number, double time) {
        VALIDATE_PTR(ptr, FormantTier);
        return FormantTier_getValueAtTime(ptr.get(), static_cast<integer>(formant_number), time);
    }

    double get_bandwidth_at_time(int formant_number, double time) {
        VALIDATE_PTR(ptr, FormantTier);
        return FormantTier_getBandwidthAtTime(ptr.get(), static_cast<integer>(formant_number), time);
    }

    // Transform - filter sound through formant tier
    XPtr<structSound> filter_sound_ptr(XPtr<structSound> sound_ptr, bool scale) {
        VALIDATE_PTR(ptr, FormantTier);
        if (sound_ptr.get() == nullptr) {
            Rcpp::stop("Invalid Sound pointer");
        }
        try {
            autoSound result;
            if (scale) {
                result = Sound_FormantTier_filter(sound_ptr.get(), ptr.get());
            } else {
                result = Sound_FormantTier_filter_noscale(sound_ptr.get(), ptr.get());
            }
            Sound raw = result.releaseToAmbiguousOwner();
            return XPtr<structSound>(raw, true);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to filter Sound through FormantTier");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, FormantTier);
        std::vector<double> times;
        std::vector<int> num_formants;
        
        for (integer i = 1; i <= ptr->points.size; i++) {
            FormantPoint point = static_cast<FormantPoint>(ptr->points.at[i]);
            times.push_back(point->number);
            num_formants.push_back(static_cast<int>(point->formants.size));
        }
        
        return DataFrame::create(
            Named("time") = times,
            Named("num_formants") = num_formants
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, FormantTier);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save FormantTier");
        }
    }
};

RCPP_MODULE(formanttier_module) {
    class_<RFormantTier>("RFormantTier")
        .constructor()
        .constructor<XPtr<structFormantTier>>()
        .method("is_valid", &RFormantTier::is_valid)
        .method("get_xmin", &RFormantTier::get_xmin)
        .method("get_xmax", &RFormantTier::get_xmax)
        .method("get_duration", &RFormantTier::get_duration)
        .method("get_number_of_points", &RFormantTier::get_number_of_points)
        .method("get_min_num_formants", &RFormantTier::get_min_num_formants)
        .method("get_max_num_formants", &RFormantTier::get_max_num_formants)
        .method("get_value_at_time", &RFormantTier::get_value_at_time)
        .method("get_bandwidth_at_time", &RFormantTier::get_bandwidth_at_time)
        .method("filter_sound_ptr", &RFormantTier::filter_sound_ptr)
        .method("as_data_frame", &RFormantTier::as_data_frame)
        .method("save", &RFormantTier::save)
    ;
}
