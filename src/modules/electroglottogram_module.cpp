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
// electroglottogram_module.cpp
// Rcpp Module exposing Praat Electroglottogram functionality (pladdrr 2.0)
//
// Electroglottogram (EGG): measurement of vocal fold contact area during phonation

#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/sensors/Electroglottogram.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/fon/AmplitudeTier.h"

using namespace Rcpp;

class RElectroglottogram {
private:
    XPtr<structElectroglottogram> ptr;

public:
    RElectroglottogram() : ptr(R_NilValue) {}
    RElectroglottogram(XPtr<structElectroglottogram> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties
    double get_xmin() { VALIDATE_PTR(ptr, Electroglottogram); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, Electroglottogram); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, Electroglottogram); return ptr->xmax - ptr->xmin; }
    int get_nx() { VALIDATE_PTR(ptr, Electroglottogram); return static_cast<int>(ptr->nx); }
    double get_dx() { VALIDATE_PTR(ptr, Electroglottogram); return ptr->dx; }
    double get_x1() { VALIDATE_PTR(ptr, Electroglottogram); return ptr->x1; }

    // Aliases for Sound-like interface
    int get_number_of_samples() { return get_nx(); }
    double get_sample_period() { return get_dx(); }
    double get_sample_rate() { VALIDATE_PTR(ptr, Electroglottogram); return 1.0 / ptr->dx; }

    // Query methods
    double get_value_at_sample(int sample) {
        VALIDATE_PTR(ptr, Electroglottogram);
        if (sample < 1 || sample > ptr->nx) return NA_REAL;
        return ptr->z[1][sample];
    }

    double get_value_at_time(double time) {
        VALIDATE_PTR(ptr, Electroglottogram);
        integer sample = Melder_iround((time - ptr->x1) / ptr->dx + 1);
        if (sample < 1 || sample > ptr->nx) return NA_REAL;
        return ptr->z[1][sample];
    }

    double get_time_from_sample(int sample) {
        VALIDATE_PTR(ptr, Electroglottogram);
        if (sample < 1 || sample > ptr->nx) Rcpp::stop("Sample index out of range");
        return ptr->x1 + (sample - 1) * ptr->dx;
    }

    int get_sample_from_time(double time) {
        VALIDATE_PTR(ptr, Electroglottogram);
        return Melder_iround((time - ptr->x1) / ptr->dx + 1);
    }

    // Derivative (dEGG)
    XPtr<structSound> derivative_ptr(double lowpass_freq, double smoothing, double peak_amplitude) {
        VALIDATE_PTR(ptr, Electroglottogram);
        try {
            autoSound degg = Electroglottogram_derivative(
                ptr.get(), lowpass_freq, smoothing, peak_amplitude
            );
            structSound* raw = degg.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to calculate EGG derivative");
        }
    }

    XPtr<structSound> first_central_difference_ptr(double peak_amplitude) {
        VALIDATE_PTR(ptr, Electroglottogram);
        try {
            autoSound degg = Electroglottogram_firstCentralDifference(ptr.get(), peak_amplitude);
            structSound* raw = degg.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to calculate first central difference");
        }
    }

    // Filtering
    XPtr<structElectroglottogram> high_pass_filter_ptr(double from_freq, double smoothing) {
        VALIDATE_PTR(ptr, Electroglottogram);
        try {
            autoElectroglottogram filtered = Electroglottogram_highPassFilter(
                ptr.get(), from_freq, smoothing
            );
            structElectroglottogram* raw = filtered.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to high-pass filter Electroglottogram");
        }
    }

    // TextGrid extraction for closed glottis analysis
    XPtr<structTextGrid> to_textgrid_closed_glottis_ptr(
        double pitch_floor, double pitch_ceiling,
        double closing_threshold, double peak_threshold) {
        VALIDATE_PTR(ptr, Electroglottogram);
        try {
            autoTextGrid tg = Electroglottogram_to_TextGrid_closedGlottis(
                ptr.get(), pitch_floor, pitch_ceiling, closing_threshold, peak_threshold
            );
            structTextGrid* raw = tg.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract closed glottis TextGrid");
        }
    }

    // Amplitude tier extraction
    List to_amplitude_tier_levels(
        double pitch_floor, double pitch_ceiling, double closing_threshold) {
        VALIDATE_PTR(ptr, Electroglottogram);
        try {
            autoAmplitudeTier peaks, valleys;
            autoAmplitudeTier levels = Electroglottogram_to_AmplitudeTier_levels(
                ptr.get(), pitch_floor, pitch_ceiling, closing_threshold,
                &peaks, &valleys
            );
            return List::create(
                Named("levels") = make_praat_xptr(levels.releaseToAmbiguousOwner()),
                Named("peaks") = make_praat_xptr(peaks.releaseToAmbiguousOwner()),
                Named("valleys") = make_praat_xptr(valleys.releaseToAmbiguousOwner())
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to extract amplitude tier levels");
        }
    }

    // Convert to Sound
    XPtr<structSound> to_sound_ptr() {
        VALIDATE_PTR(ptr, Electroglottogram);
        try {
            autoSound sound = Electroglottogram_to_Sound(ptr.get());
            structSound* raw = sound.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert Electroglottogram to Sound");
        }
    }

    // Export
    NumericVector as_vector() {
        VALIDATE_PTR(ptr, Electroglottogram);
        NumericVector result(ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            result[i-1] = ptr->z[1][i];
        }
        return result;
    }

    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Electroglottogram);
        std::vector<double> times, values;
        for (integer i = 1; i <= ptr->nx; i++) {
            times.push_back(ptr->x1 + (i - 1) * ptr->dx);
            values.push_back(ptr->z[1][i]);
        }
        return DataFrame::create(
            Named("time") = times,
            Named("amplitude") = values
        );
    }

    List get_info() {
        VALIDATE_PTR(ptr, Electroglottogram);
        return List::create(
            Named("xmin") = ptr->xmin,
            Named("xmax") = ptr->xmax,
            Named("nx") = ptr->nx,
            Named("dx") = ptr->dx,
            Named("x1") = ptr->x1,
            Named("sample_rate") = 1.0 / ptr->dx
        );
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Electroglottogram);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Electroglottogram");
        }
    }
};

// Factory functions
XPtr<structElectroglottogram> electroglottogram_create(
    double xmin, double xmax, int nx, double dx, double x1) {
    try {
        autoElectroglottogram egg = Electroglottogram_create(xmin, xmax, nx, dx, x1);
        structElectroglottogram* raw = egg.releaseToAmbiguousOwner();
        return make_praat_xptr(raw);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create Electroglottogram");
    }
}

XPtr<structElectroglottogram> sound_extract_electroglottogram(
    XPtr<structSound> sound, int channel, bool invert) {
    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");
    try {
        autoElectroglottogram egg = Sound_extractElectroglottogram(
            sound.get(), channel, invert
        );
        structElectroglottogram* raw = egg.releaseToAmbiguousOwner();
        return make_praat_xptr(raw);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract Electroglottogram from Sound");
    }
}

RCPP_MODULE(electroglottogram_module) {
    class_<RElectroglottogram>("RElectroglottogram")
        .constructor()
        .constructor<XPtr<structElectroglottogram>>()
        .method("is_valid", &RElectroglottogram::is_valid)
        // Time domain
        .method("get_xmin", &RElectroglottogram::get_xmin)
        .method("get_xmax", &RElectroglottogram::get_xmax)
        .method("get_duration", &RElectroglottogram::get_duration)
        .method("get_nx", &RElectroglottogram::get_nx)
        .method("get_dx", &RElectroglottogram::get_dx)
        .method("get_x1", &RElectroglottogram::get_x1)
        // Sound-like aliases
        .method("get_number_of_samples", &RElectroglottogram::get_number_of_samples)
        .method("get_sample_period", &RElectroglottogram::get_sample_period)
        .method("get_sample_rate", &RElectroglottogram::get_sample_rate)
        // Query
        .method("get_value_at_sample", &RElectroglottogram::get_value_at_sample)
        .method("get_value_at_time", &RElectroglottogram::get_value_at_time)
        .method("get_time_from_sample", &RElectroglottogram::get_time_from_sample)
        .method("get_sample_from_time", &RElectroglottogram::get_sample_from_time)
        // Derivative
        .method("derivative_ptr", &RElectroglottogram::derivative_ptr)
        .method("first_central_difference_ptr", &RElectroglottogram::first_central_difference_ptr)
        // Filtering
        .method("high_pass_filter_ptr", &RElectroglottogram::high_pass_filter_ptr)
        // Analysis
        .method("to_textgrid_closed_glottis_ptr", &RElectroglottogram::to_textgrid_closed_glottis_ptr)
        .method("to_amplitude_tier_levels", &RElectroglottogram::to_amplitude_tier_levels)
        // Conversion
        .method("to_sound_ptr", &RElectroglottogram::to_sound_ptr)
        // Export
        .method("as_vector", &RElectroglottogram::as_vector)
        .method("as_data_frame", &RElectroglottogram::as_data_frame)
        .method("get_info", &RElectroglottogram::get_info)
        .method("save", &RElectroglottogram::save)
    ;

    // Factory functions
    function("Electroglottogram_create", &electroglottogram_create);
    function("Sound_extract_Electroglottogram", &sound_extract_electroglottogram);
}
