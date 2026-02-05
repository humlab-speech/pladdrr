// cepstrum_module.cpp
// Rcpp Module exposing Praat Cepstrum functionality (pladdrr 2.0)
//
// Cepstrum is a complex cepstrum preserving phase information.
// For magnitude-only analysis, use PowerCepstrum.

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/LPC/Cepstrum.h"
#include "praat.github.io/LPC/Cepstrum_and_Spectrum.h"
#include "praat.github.io/LPC/Sound_and_Cepstrum.h"
#include "praat.github.io/fon/Spectrum.h"

using namespace Rcpp;

class RCepstrum {
private:
    XPtr<structCepstrum> ptr;

public:
    RCepstrum() : ptr(R_NilValue) {}
    RCepstrum(XPtr<structCepstrum> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Quefrency domain properties
    double get_qmin() { VALIDATE_PTR(ptr, Cepstrum); return ptr->xmin; }
    double get_qmax() { VALIDATE_PTR(ptr, Cepstrum); return ptr->xmax; }
    double get_quefrency_range() { VALIDATE_PTR(ptr, Cepstrum); return ptr->xmax - ptr->xmin; }
    int get_n_coefficients() { VALIDATE_PTR(ptr, Cepstrum); return static_cast<int>(ptr->nx); }
    double get_dq() { VALIDATE_PTR(ptr, Cepstrum); return ptr->dx; }
    double get_q1() { VALIDATE_PTR(ptr, Cepstrum); return ptr->x1; }

    // Aliases
    int get_number_of_coefficients() { return get_n_coefficients(); }
    double get_quefrency_step() { return get_dq(); }

    // Query methods
    double get_value_at_quefrency(double quefrency) {
        VALIDATE_PTR(ptr, Cepstrum);
        integer bin = Melder_iround((quefrency - ptr->x1) / ptr->dx + 1);
        if (bin < 1 || bin > ptr->nx) {
            return NA_REAL;
        }
        return ptr->z[1][bin];
    }

    double get_quefrency_from_index(int index) {
        VALIDATE_PTR(ptr, Cepstrum);
        if (index < 1 || index > ptr->nx) {
            Rcpp::stop("Index out of range");
        }
        return ptr->x1 + (index - 1) * ptr->dx;
    }

    int get_index_from_quefrency(double quefrency) {
        VALIDATE_PTR(ptr, Cepstrum);
        return Melder_iround((quefrency - ptr->x1) / ptr->dx + 1);
    }

    // Conversion methods - return pointers for R-side wrapping
    XPtr<structSpectrum> to_spectrum_ptr() {
        VALIDATE_PTR(ptr, Cepstrum);
        try {
            autoSpectrum spectrum = Cepstrum_to_Spectrum(ptr.get());
            structSpectrum* raw = spectrum.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structSpectrum* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structSpectrum>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert Cepstrum to Spectrum");
        }
    }

    XPtr<structPowerCepstrum> to_powercepstrum_ptr() {
        VALIDATE_PTR(ptr, Cepstrum);
        try {
            autoPowerCepstrum powercepstrum = Cepstrum_downto_PowerCepstrum(ptr.get());
            structPowerCepstrum* raw = powercepstrum.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structPowerCepstrum* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structPowerCepstrum>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert Cepstrum to PowerCepstrum");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Cepstrum);
        std::vector<double> quefrencies, values;
        for (integer i = 1; i <= ptr->nx; i++) {
            quefrencies.push_back(ptr->x1 + (i - 1) * ptr->dx);
            values.push_back(ptr->z[1][i]);
        }
        return DataFrame::create(
            Named("quefrency") = quefrencies,
            Named("value") = values
        );
    }

    NumericVector as_vector() {
        VALIDATE_PTR(ptr, Cepstrum);
        NumericVector result(ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            result[i-1] = ptr->z[1][i];
        }
        return result;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Cepstrum);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Cepstrum");
        }
    }
};

// Factory functions (Sound/Spectrum -> Cepstrum)
XPtr<structCepstrum> sound_to_cepstrum(XPtr<structSound> sound) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoCepstrum cepstrum = Sound_to_Cepstrum(sound.get());
        structCepstrum* raw = cepstrum.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structCepstrum* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structCepstrum>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Cepstrum from Sound");
    }
}

XPtr<structCepstrum> sound_to_cepstrum_bw(XPtr<structSound> sound) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoCepstrum cepstrum = Sound_to_Cepstrum_bw(sound.get());
        structCepstrum* raw = cepstrum.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structCepstrum* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structCepstrum>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create bandwidth-weighted Cepstrum from Sound");
    }
}

XPtr<structCepstrum> spectrum_to_cepstrum_hillenbrand(XPtr<structSpectrum> spectrum) {
    if (!spectrum || !spectrum.get()) Rcpp::stop("Invalid Spectrum pointer");
    try {
        autoCepstrum cepstrum = Spectrum_to_Cepstrum_hillenbrand(spectrum.get());
        structCepstrum* raw = cepstrum.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structCepstrum* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structCepstrum>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Hillenbrand Cepstrum from Spectrum");
    }
}

RCPP_MODULE(cepstrum_module) {
    class_<RCepstrum>("RCepstrum")
        .constructor()
        .constructor<XPtr<structCepstrum>>()
        .method("is_valid", &RCepstrum::is_valid)
        // Quefrency domain
        .method("get_qmin", &RCepstrum::get_qmin)
        .method("get_qmax", &RCepstrum::get_qmax)
        .method("get_quefrency_range", &RCepstrum::get_quefrency_range)
        .method("get_n_coefficients", &RCepstrum::get_n_coefficients)
        .method("get_dq", &RCepstrum::get_dq)
        .method("get_q1", &RCepstrum::get_q1)
        .method("get_number_of_coefficients", &RCepstrum::get_number_of_coefficients)
        .method("get_quefrency_step", &RCepstrum::get_quefrency_step)
        // Query
        .method("get_value_at_quefrency", &RCepstrum::get_value_at_quefrency)
        .method("get_quefrency_from_index", &RCepstrum::get_quefrency_from_index)
        .method("get_index_from_quefrency", &RCepstrum::get_index_from_quefrency)
        // Conversion
        .method("to_spectrum_ptr", &RCepstrum::to_spectrum_ptr)
        .method("to_powercepstrum_ptr", &RCepstrum::to_powercepstrum_ptr)
        // Export
        .method("as_data_frame", &RCepstrum::as_data_frame)
        .method("as_vector", &RCepstrum::as_vector)
        .method("save", &RCepstrum::save)
    ;

    // Factory functions
    function("Sound_to_Cepstrum", &sound_to_cepstrum);
    function("Sound_to_Cepstrum_bw", &sound_to_cepstrum_bw);
    function("Spectrum_to_Cepstrum_hillenbrand", &spectrum_to_cepstrum_hillenbrand);
}
