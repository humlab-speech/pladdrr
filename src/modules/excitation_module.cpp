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
// excitation_module.cpp
// Rcpp Module exposing Praat Excitation functionality (pladdrr 2.0)
//
// Excitation: auditory excitation pattern at a single time point

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/Excitation.h"
#include "praat.github.io/fon/Spectrum_to_Excitation.h"
#include "praat.github.io/fon/Excitation_to_Formant.h"
#include "praat.github.io/fon/Cochleagram_and_Excitation.h"

using namespace Rcpp;

class RExcitation {
private:
    XPtr<structExcitation> ptr;

public:
    RExcitation() : ptr(R_NilValue) {}
    RExcitation(XPtr<structExcitation> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Frequency domain properties (Bark scale)
    double get_fmin() { VALIDATE_PTR(ptr, Excitation); return ptr->xmin; }
    double get_fmax() { VALIDATE_PTR(ptr, Excitation); return ptr->xmax; }
    double get_frequency_range() { VALIDATE_PTR(ptr, Excitation); return ptr->xmax - ptr->xmin; }
    int get_n_bins() { VALIDATE_PTR(ptr, Excitation); return static_cast<int>(ptr->nx); }
    double get_df() { VALIDATE_PTR(ptr, Excitation); return ptr->dx; }
    double get_f1() { VALIDATE_PTR(ptr, Excitation); return ptr->x1; }

    // Aliases
    int get_number_of_bins() { return get_n_bins(); }
    double get_frequency_step() { return get_df(); }

    // Query methods
    double get_value_at_frequency(double freq_bark) {
        VALIDATE_PTR(ptr, Excitation);
        integer i = Melder_iround((freq_bark - ptr->x1) / ptr->dx + 1);
        if (i < 1 || i > ptr->nx) {
            return 0.0;  // Outside range
        }
        return ptr->z[1][i];
    }

    double get_frequency_from_index(int index) {
        VALIDATE_PTR(ptr, Excitation);
        if (index < 1 || index > ptr->nx) Rcpp::stop("Index out of range");
        return ptr->x1 + (index - 1) * ptr->dx;
    }

    int get_index_from_frequency(double freq_bark) {
        VALIDATE_PTR(ptr, Excitation);
        return Melder_iround((freq_bark - ptr->x1) / ptr->dx + 1);
    }

    // Loudness
    double get_loudness() {
        VALIDATE_PTR(ptr, Excitation);
        try {
            return Excitation_getLoudness(ptr.get());
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Distance between excitation patterns
    double get_distance(XPtr<structExcitation> other) {
        VALIDATE_PTR(ptr, Excitation);
        if (!other || !other.get()) Rcpp::stop("Invalid Excitation for comparison");
        try {
            return Excitation_getDistance(ptr.get(), other.get());
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Conversion to Formant
    XPtr<structFormant> to_formant_ptr(int max_formants) {
        VALIDATE_PTR(ptr, Excitation);
        try {
            autoFormant result = Excitation_to_Formant(ptr.get(), max_formants);
            structFormant* raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structFormant* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structFormant>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract formants from Excitation");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Excitation);
        int n = ptr->nx;
        NumericVector freqs(n);
        NumericVector values(n);

        for (int i = 1; i <= n; i++) {
            freqs(i-1) = ptr->x1 + (i - 1) * ptr->dx;
            values(i-1) = ptr->z[1][i];
        }

        return DataFrame::create(
            Named("frequency_bark") = freqs,
            Named("excitation") = values
        );
    }

    NumericVector as_vector() {
        VALIDATE_PTR(ptr, Excitation);
        NumericVector result(ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            result[i-1] = ptr->z[1][i];
        }
        return result;
    }

    List get_info() {
        VALIDATE_PTR(ptr, Excitation);
        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("nx") = ptr->nx,
            Named("dx") = ptr->dx,
            Named("x1") = ptr->x1
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Excitation);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Excitation");
        }
    }
};

// Factory functions (Module_ prefix to avoid collision with legacy wrappers)
static XPtr<structExcitation> Module_Excitation_create(double freq_step, int n_freqs) {
    try {
        autoExcitation result = Excitation_create(freq_step, n_freqs);
        structExcitation* raw = result.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structExcitation* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structExcitation>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Excitation");
    }
}

static XPtr<structExcitation> Module_Spectrum_to_Excitation(XPtr<structSpectrum> spectrum, double erb_density) {
    if (!spectrum || !spectrum.get()) Rcpp::stop("Invalid Spectrum pointer");
    try {
        autoExcitation result = Spectrum_to_Excitation(spectrum.get(), erb_density);
        structExcitation* raw = result.releaseToAmbiguousOwner();
        // Use proper deleter for Praat objects (calls forget() instead of delete)
        auto deleter = [](structExcitation* thing) {
            if (thing != nullptr) forget(thing);
        };
        return XPtr<structExcitation>(raw, deleter);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Excitation from Spectrum");
    }
}

RCPP_MODULE(excitation_module) {
    class_<RExcitation>("RExcitation")
        .constructor()
        .constructor<XPtr<structExcitation>>()
        .method("is_valid", &RExcitation::is_valid)
        // Frequency domain
        .method("get_fmin", &RExcitation::get_fmin)
        .method("get_fmax", &RExcitation::get_fmax)
        .method("get_frequency_range", &RExcitation::get_frequency_range)
        .method("get_n_bins", &RExcitation::get_n_bins)
        .method("get_df", &RExcitation::get_df)
        .method("get_f1", &RExcitation::get_f1)
        .method("get_number_of_bins", &RExcitation::get_number_of_bins)
        .method("get_frequency_step", &RExcitation::get_frequency_step)
        // Query
        .method("get_value_at_frequency", &RExcitation::get_value_at_frequency)
        .method("get_frequency_from_index", &RExcitation::get_frequency_from_index)
        .method("get_index_from_frequency", &RExcitation::get_index_from_frequency)
        // Loudness
        .method("get_loudness", &RExcitation::get_loudness)
        // Distance
        .method("get_distance", &RExcitation::get_distance)
        // Conversion
        .method("to_formant_ptr", &RExcitation::to_formant_ptr)
        // Export
        .method("as_data_frame", &RExcitation::as_data_frame)
        .method("as_vector", &RExcitation::as_vector)
        .method("get_info", &RExcitation::get_info)
        .method("save", &RExcitation::save)
    ;

    // Factory functions
    function("Excitation_create", &Module_Excitation_create);
    function("Spectrum_to_Excitation", &Module_Spectrum_to_Excitation);
}
