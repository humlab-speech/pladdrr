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
// powercepstrum_module.cpp
// Rcpp Module exposing PowerCepstrum and PowerCepstrogram functionality (pladdrr 2.0)
//
// PowerCepstrum: magnitude-only cepstrum for CPP analysis
// PowerCepstrogram: time-varying cepstral representation for CPPS

#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/LPC/PowerCepstrum.h"
#include "praat.github.io/LPC/PowerCepstrogram.h"
#include "praat.github.io/LPC/Sound_to_PowerCepstrogram.h"
#include "praat.github.io/LPC/Cepstrum_and_Spectrum.h"
#include "praat.github.io/fon/Spectrum.h"
#include "praat.github.io/fon/Matrix.h"
#include "praat.github.io/fon/Sampled.h"
#include "praat.github.io/stat/Table.h"

using namespace Rcpp;

// ============================================================================
// RPowerCepstrum class
// ============================================================================

class RPowerCepstrum {
private:
    XPtr<structPowerCepstrum> ptr;

public:
    RPowerCepstrum() : ptr(R_NilValue) {}
    RPowerCepstrum(XPtr<structPowerCepstrum> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Quefrency domain properties
    double get_qmin() { VALIDATE_PTR(ptr, PowerCepstrum); return ptr->xmin; }
    double get_qmax() { VALIDATE_PTR(ptr, PowerCepstrum); return ptr->xmax; }
    double get_quefrency_range() { VALIDATE_PTR(ptr, PowerCepstrum); return ptr->xmax - ptr->xmin; }
    int get_n_bins() { VALIDATE_PTR(ptr, PowerCepstrum); return static_cast<int>(ptr->nx); }
    double get_dq() { VALIDATE_PTR(ptr, PowerCepstrum); return ptr->dx; }
    double get_q1() { VALIDATE_PTR(ptr, PowerCepstrum); return ptr->x1; }

    // Query methods
    double get_value_at_quefrency(double quefrency, std::string interpolation, std::string unit) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        double index = 1.0 + (quefrency - ptr->x1) / ptr->dx;
        if (index < 1 || index > ptr->nx) return NA_REAL;

        integer bin = (integer) floor(index);
        double fraction = index - bin;
        double value;

        if (interpolation == "linear" && bin < ptr->nx) {
            value = (1.0 - fraction) * ptr->z[1][bin] + fraction * ptr->z[1][bin + 1];
        } else {
            value = ptr->z[1][bin];
        }

        if (unit == "dB") {
            return value;
        } else {
            return pow(10.0, value / 10.0);
        }
    }

    double get_quefrency_of_peak(std::string interpolation, double qmin, double qmax) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        kCepstrum_peakInterpolation interp = kCepstrum_peakInterpolation::PARABOLIC;
        if (interpolation == "none") interp = kCepstrum_peakInterpolation::NONE;
        else if (interpolation == "cubic") interp = kCepstrum_peakInterpolation::CUBIC;

        if (qmax == 0) qmax = ptr->xmax;

        try {
            double maximum, quefrency;
            PowerCepstrum_getMaximumAndQuefrency_q(ptr.get(), qmin, qmax, interp, maximum, quefrency);
            return quefrency;
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    double get_peak_prominence(double pitch_floor, double pitch_ceiling,
                               int interpolation, double qstart_fit, double qend_fit,
                               int trend_type, int fit_method) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            kVector_peakInterpolation interp = static_cast<kVector_peakInterpolation>(interpolation);
            kCepstrum_trendType trend = static_cast<kCepstrum_trendType>(trend_type);
            kCepstrum_trendFit fit = static_cast<kCepstrum_trendFit>(fit_method);

            double qpeak = 0.0;
            double prominence = PowerCepstrum_getPeakProminence(
                ptr.get(), pitch_floor, pitch_ceiling, interp,
                qstart_fit, qend_fit, trend, fit, qpeak
            );
            return prominence;
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    List get_peak_prominence_hillenbrand(double pitch_floor, double pitch_ceiling) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            double qpeak = 0.0;
            double prominence = PowerCepstrum_getPeakProminence_hillenbrand(
                ptr.get(), pitch_floor, pitch_ceiling, qpeak
            );
            return List::create(
                Named("prominence") = prominence,
                Named("quefrency") = qpeak
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get Hillenbrand peak prominence");
        }
    }

    // Trend analysis
    List fit_trend_line(double qmin, double qmax, int trend_type, int fit_method) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            kCepstrum_trendType trend = static_cast<kCepstrum_trendType>(trend_type);
            kCepstrum_trendFit fit = static_cast<kCepstrum_trendFit>(fit_method);

            double slope = 0.0, intercept = 0.0;
            PowerCepstrum_fitTrendLine(ptr.get(), qmin, qmax, &slope, &intercept, trend, fit);
            return List::create(
                Named("slope") = slope,
                Named("intercept") = intercept
            );
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to fit trend line");
        }
    }

    double get_trend_line_value(double quefrency, double qstart_fit, double qend_fit,
                                int trend_type, int fit_method) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            kCepstrum_trendType trend = static_cast<kCepstrum_trendType>(trend_type);
            kCepstrum_trendFit fit = static_cast<kCepstrum_trendFit>(fit_method);
            return PowerCepstrum_getTrendLineValue(ptr.get(), quefrency, qstart_fit, qend_fit, trend, fit);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Modifications
    XPtr<structPowerCepstrum> smooth_ptr(double averaging_window, int nsamples) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            autoPowerCepstrum smoothed = PowerCepstrum_smooth(ptr.get(), averaging_window, nsamples);
            structPowerCepstrum* raw = smoothed.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to smooth PowerCepstrum");
        }
    }

    XPtr<structPowerCepstrum> subtract_trend_ptr(double qstart_fit, double qend_fit,
                                                  int trend_type, int fit_method) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            kCepstrum_trendType trend = static_cast<kCepstrum_trendType>(trend_type);
            kCepstrum_trendFit fit = static_cast<kCepstrum_trendFit>(fit_method);
            autoPowerCepstrum detrended = PowerCepstrum_subtractTrend(
                ptr.get(), qstart_fit, qend_fit, trend, fit
            );
            structPowerCepstrum* raw = detrended.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to subtract trend");
        }
    }

    void subtract_trend_inplace(double qstart_fit, double qend_fit, int trend_type, int fit_method) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            kCepstrum_trendType trend = static_cast<kCepstrum_trendType>(trend_type);
            kCepstrum_trendFit fit = static_cast<kCepstrum_trendFit>(fit_method);
            PowerCepstrum_subtractTrend_inplace(ptr.get(), qstart_fit, qend_fit, trend, fit);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to subtract trend in-place");
        }
    }

    // Conversions
    XPtr<structSpectrum> to_spectrum_ptr(bool random_phases) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            autoSpectrum spectrum = PowerCepstrum_to_Spectrum(ptr.get(), random_phases);
            structSpectrum* raw = spectrum.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert PowerCepstrum to Spectrum");
        }
    }

    XPtr<structMatrix> to_matrix_ptr() {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            autoMatrix matrix = PowerCepstrum_to_Matrix(ptr.get());
            structMatrix* raw = matrix.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert PowerCepstrum to Matrix");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, PowerCepstrum);
        std::vector<double> quefrencies, values;
        for (integer i = 1; i <= ptr->nx; i++) {
            quefrencies.push_back(ptr->x1 + (i - 1) * ptr->dx);
            values.push_back(ptr->z[1][i]);
        }
        return DataFrame::create(
            Named("quefrency") = quefrencies,
            Named("power_dB") = values
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, PowerCepstrum);
        NumericMatrix mat(1, ptr->nx);
        for (integer i = 1; i <= ptr->nx; i++) {
            mat(0, i - 1) = ptr->z[1][i];
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, PowerCepstrum);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save PowerCepstrum");
        }
    }
};

// ============================================================================
// RPowerCepstrogram class
// ============================================================================

class RPowerCepstrogram {
private:
    XPtr<structPowerCepstrogram> ptr;

public:
    RPowerCepstrogram() : ptr(R_NilValue) {}
    RPowerCepstrogram(XPtr<structPowerCepstrogram> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Time domain properties
    double get_xmin() { VALIDATE_PTR(ptr, PowerCepstrogram); return ptr->xmin; }
    double get_xmax() { VALIDATE_PTR(ptr, PowerCepstrogram); return ptr->xmax; }
    double get_duration() { VALIDATE_PTR(ptr, PowerCepstrogram); return ptr->xmax - ptr->xmin; }
    int get_nx() { VALIDATE_PTR(ptr, PowerCepstrogram); return static_cast<int>(ptr->nx); }
    double get_dx() { VALIDATE_PTR(ptr, PowerCepstrogram); return ptr->dx; }

    // Quefrency domain properties
    double get_ymin() { VALIDATE_PTR(ptr, PowerCepstrogram); return ptr->ymin; }
    double get_ymax() { VALIDATE_PTR(ptr, PowerCepstrogram); return ptr->ymax; }
    int get_ny() { VALIDATE_PTR(ptr, PowerCepstrogram); return static_cast<int>(ptr->ny); }
    double get_dy() { VALIDATE_PTR(ptr, PowerCepstrogram); return ptr->dy; }

    // CPP at specific time
    double get_cpp_at_time(double time, std::string interpolation,
                           double qmin, double qmax,
                           std::string fit_method, double tolerance) {
        VALIDATE_PTR(ptr, PowerCepstrogram);
        try {
            autoPowerCepstrum slice = PowerCepstrogram_to_PowerCepstrum_slice(ptr.get(), time);

            kVector_peakInterpolation interp_type = kVector_peakInterpolation::PARABOLIC;
            if (interpolation == "linear") interp_type = kVector_peakInterpolation::PARABOLIC;
            else if (interpolation == "cubic") interp_type = kVector_peakInterpolation::CUBIC;

            kCepstrum_trendType trend_type = kCepstrum_trendType::EXPONENTIAL_DECAY;
            if (fit_method == "straight") trend_type = kCepstrum_trendType::LINEAR;

            kCepstrum_trendFit fit_type = kCepstrum_trendFit::ROBUST_SLOW;

            if (qmax == 0) qmax = slice->xmax;

            double qpeak;
            double cpp = PowerCepstrum_getPeakProminence(
                slice.get(), 1.0/qmax, 1.0/qmin, interp_type,
                qmin, qmax, trend_type, fit_type, qpeak
            );
            return cpp;
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // CPPS - critical for AVQI
    double get_cpps(bool subtract_tilt, double time_averaging_window,
                    double quefrency_averaging_window, double pitch_floor,
                    double pitch_ceiling, double delta_f0, int interpolation,
                    double qstart_fit, double qend_fit, int trend_type, int fit_method) {
        VALIDATE_PTR(ptr, PowerCepstrogram);
        try {
            kVector_peakInterpolation interp = static_cast<kVector_peakInterpolation>(interpolation);
            kCepstrum_trendType trend = static_cast<kCepstrum_trendType>(trend_type);
            kCepstrum_trendFit fit = static_cast<kCepstrum_trendFit>(fit_method);

            return PowerCepstrogram_getCPPS(
                ptr.get(), subtract_tilt, time_averaging_window,
                quefrency_averaging_window, pitch_floor, pitch_ceiling,
                delta_f0, interp, qstart_fit, qend_fit, trend, fit
            );
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }

    // Extract slice
    XPtr<structPowerCepstrum> get_slice_ptr(double time) {
        VALIDATE_PTR(ptr, PowerCepstrogram);
        try {
            autoPowerCepstrum slice = PowerCepstrogram_to_PowerCepstrum_slice(ptr.get(), time);
            structPowerCepstrum* raw = slice.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get PowerCepstrum slice");
        }
    }

    // Smoothing
    XPtr<structPowerCepstrogram> smooth_ptr(double time_averaging_window,
                                             double quefrency_averaging_window) {
        VALIDATE_PTR(ptr, PowerCepstrogram);
        try {
            autoPowerCepstrogram smoothed = PowerCepstrogram_smooth(
                ptr.get(), time_averaging_window, quefrency_averaging_window
            );
            structPowerCepstrogram* raw = smoothed.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to smooth PowerCepstrogram");
        }
    }

    // Conversions
    XPtr<structMatrix> to_matrix_ptr() {
        VALIDATE_PTR(ptr, PowerCepstrogram);
        try {
            autoMatrix matrix = PowerCepstrogram_to_Matrix(ptr.get());
            structMatrix* raw = matrix.releaseToAmbiguousOwner();
            return make_praat_xptr(raw);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert PowerCepstrogram to Matrix");
        }
    }

    // Export
    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, PowerCepstrogram);
        NumericMatrix mat(ptr->ny, ptr->nx);
        for (integer i = 1; i <= ptr->ny; i++) {
            for (integer j = 1; j <= ptr->nx; j++) {
                mat(i - 1, j - 1) = ptr->z[i][j];
            }
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, PowerCepstrogram);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save PowerCepstrogram");
        }
    }
};

// ============================================================================
// Factory functions
// ============================================================================

XPtr<structPowerCepstrum> spectrum_to_powercepstrum(XPtr<structSpectrum> spectrum) {
    if (!spectrum || !spectrum.get()) Rcpp::stop("Invalid Spectrum pointer");
    try {
        autoPowerCepstrum cepstrum = Spectrum_to_PowerCepstrum(spectrum.get());
        structPowerCepstrum* raw = cepstrum.releaseToAmbiguousOwner();
        return make_praat_xptr(raw);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create PowerCepstrum from Spectrum");
    }
}

XPtr<structPowerCepstrogram> sound_to_powercepstrogram(
    XPtr<structSound> sound, double pitch_floor, double time_step,
    double maximum_frequency, double pre_emphasis_frequency) {

    if (!sound || !sound.get()) Rcpp::stop("Invalid Sound pointer");

    // Validate Sound
    if (sound->nx <= 0) Rcpp::stop("Sound has no samples");
    if (sound->dx <= 0) Rcpp::stop("Sound has invalid sample period");

    double duration = sound->xmax - sound->xmin;
    if (duration <= 0) Rcpp::stop("Sound has invalid duration");

    double nyquist = 0.5 / sound->dx;

    // Validate parameters
    if (pitch_floor <= 0) Rcpp::stop("pitch_floor must be positive");
    if (pitch_floor >= nyquist) {
        Rcpp::stop("pitch_floor must be less than Nyquist frequency (%.0f Hz)", nyquist);
    }
    if (time_step <= 0) Rcpp::stop("time_step must be positive");
    if (maximum_frequency <= 0 || maximum_frequency >= nyquist) {
        Rcpp::stop("maximum_frequency must be between 0 and Nyquist (%.0f Hz)", nyquist);
    }

    try {
        autoPowerCepstrogram cepstrogram = Sound_to_PowerCepstrogram(
            sound.get(), pitch_floor, time_step, maximum_frequency, pre_emphasis_frequency
        );
        structPowerCepstrogram* raw = cepstrogram.releaseToAmbiguousOwner();
        return make_praat_xptr(raw);
    } catch (MelderError) {
        autostring32 err = Melder_dup(Melder_getError());
        Melder_clearError();
        Rcpp::stop("PowerCepstrogram creation failed: %s", Melder_peek32to8(err.get()));
    }
}

// ============================================================================
// Module registration
// ============================================================================

RCPP_MODULE(powercepstrum_module) {
    // PowerCepstrum class
    class_<RPowerCepstrum>("RPowerCepstrum")
        .constructor()
        .constructor<XPtr<structPowerCepstrum>>()
        .method("is_valid", &RPowerCepstrum::is_valid)
        // Quefrency domain
        .method("get_qmin", &RPowerCepstrum::get_qmin)
        .method("get_qmax", &RPowerCepstrum::get_qmax)
        .method("get_quefrency_range", &RPowerCepstrum::get_quefrency_range)
        .method("get_n_bins", &RPowerCepstrum::get_n_bins)
        .method("get_dq", &RPowerCepstrum::get_dq)
        .method("get_q1", &RPowerCepstrum::get_q1)
        // Query
        .method("get_value_at_quefrency", &RPowerCepstrum::get_value_at_quefrency)
        .method("get_quefrency_of_peak", &RPowerCepstrum::get_quefrency_of_peak)
        .method("get_peak_prominence", &RPowerCepstrum::get_peak_prominence)
        .method("get_peak_prominence_hillenbrand", &RPowerCepstrum::get_peak_prominence_hillenbrand)
        // Trend
        .method("fit_trend_line", &RPowerCepstrum::fit_trend_line)
        .method("get_trend_line_value", &RPowerCepstrum::get_trend_line_value)
        // Modification
        .method("smooth_ptr", &RPowerCepstrum::smooth_ptr)
        .method("subtract_trend_ptr", &RPowerCepstrum::subtract_trend_ptr)
        .method("subtract_trend_inplace", &RPowerCepstrum::subtract_trend_inplace)
        // Conversion
        .method("to_spectrum_ptr", &RPowerCepstrum::to_spectrum_ptr)
        .method("to_matrix_ptr", &RPowerCepstrum::to_matrix_ptr)
        // Export
        .method("as_data_frame", &RPowerCepstrum::as_data_frame)
        .method("as_matrix", &RPowerCepstrum::as_matrix)
        .method("save", &RPowerCepstrum::save)
    ;

    // PowerCepstrogram class
    class_<RPowerCepstrogram>("RPowerCepstrogram")
        .constructor()
        .constructor<XPtr<structPowerCepstrogram>>()
        .method("is_valid", &RPowerCepstrogram::is_valid)
        // Time domain
        .method("get_xmin", &RPowerCepstrogram::get_xmin)
        .method("get_xmax", &RPowerCepstrogram::get_xmax)
        .method("get_duration", &RPowerCepstrogram::get_duration)
        .method("get_nx", &RPowerCepstrogram::get_nx)
        .method("get_dx", &RPowerCepstrogram::get_dx)
        // Quefrency domain
        .method("get_ymin", &RPowerCepstrogram::get_ymin)
        .method("get_ymax", &RPowerCepstrogram::get_ymax)
        .method("get_ny", &RPowerCepstrogram::get_ny)
        .method("get_dy", &RPowerCepstrogram::get_dy)
        // CPP/CPPS
        .method("get_cpp_at_time", &RPowerCepstrogram::get_cpp_at_time)
        .method("get_cpps", &RPowerCepstrogram::get_cpps)
        // Slice/smooth
        .method("get_slice_ptr", &RPowerCepstrogram::get_slice_ptr)
        .method("smooth_ptr", &RPowerCepstrogram::smooth_ptr)
        // Conversion
        .method("to_matrix_ptr", &RPowerCepstrogram::to_matrix_ptr)
        // Export
        .method("as_matrix", &RPowerCepstrogram::as_matrix)
        .method("save", &RPowerCepstrogram::save)
    ;

    // Factory functions
    function("Spectrum_to_PowerCepstrum", &spectrum_to_powercepstrum);
    function("Sound_to_PowerCepstrogram", &sound_to_powercepstrogram);
}
