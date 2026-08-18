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
// powercepstrum_wrappers.cpp
// Rcpp wrappers for Praat PowerCepstrum and PowerCepstrogram objects

#include "praat_types.h"
#include <Rcpp.h>
#include <cmath>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "LPC/PowerCepstrum.h"
#include "LPC/PowerCepstrogram.h"
#include "LPC/Sound_to_PowerCepstrogram.h"
#include "LPC/Cepstrum_and_Spectrum.h"
#include "LPC/Sound_and_Cepstrum.h"
#include "LPC/Cepstrum.h"
#include "stat/Table.h"
#include "fon/Spectrum.h"
#include "fon/Sound.h"
#include "fon/Matrix.h"
#include "fon/Sampled.h"
#include "melder/melder.h"

using namespace Rcpp;

// ==============================================================================
// Sound to PowerCepstrogram conversion
// ==============================================================================

// [[Rcpp::export(.sound_to_powercepstrogram)]]
SEXP sound_to_powercepstrogram(SEXP sound_xptr, double pitch_floor, double time_step, 
                                double maximum_frequency, double pre_emphasis_frequency) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound) stop("Invalid Sound pointer");
    
    // Validate Sound object
    if (sound->nx <= 0) {
        stop("Sound object has no samples");
    }
    if (sound->dx <= 0) {
        stop("Sound object has invalid sample period (dx <= 0)");
    }
    
    double duration = sound->xmax - sound->xmin;
    if (duration <= 0) {
        stop("Sound object has invalid duration");
    }
    
    double nyquist_freq = 0.5 / sound->dx;
    double sampling_rate = 1.0 / sound->dx;
    
    // Validate pitch_floor
    if (pitch_floor <= 0) {
        stop("pitch_floor must be positive");
    }
    if (pitch_floor >= nyquist_freq) {
        stop("pitch_floor (" + std::to_string(pitch_floor) + 
             " Hz) must be less than Nyquist frequency (" + 
             std::to_string(nyquist_freq) + " Hz)");
    }
    
    // Validate duration vs pitch_floor
    // Praat requires at least ~3 pitch periods for analysis
    double min_duration = 3.0 / pitch_floor;
    if (duration < min_duration) {
        stop("Sound duration (" + std::to_string(duration) + 
             " s) is too short for pitch_floor " + 
             std::to_string(pitch_floor) + " Hz. " +
             "Minimum duration: " + std::to_string(min_duration) + " s. " +
             "Either use a longer sound or increase pitch_floor.");
    }
    
    // Validate time_step
    if (time_step <= 0) {
        stop("time_step must be positive");
    }
    if (time_step > duration) {
        stop("time_step (" + std::to_string(time_step) + 
             " s) cannot be longer than sound duration (" + 
             std::to_string(duration) + " s)");
    }
    
    // Validate maximum_frequency
    if (maximum_frequency <= 0) {
        stop("maximum_frequency must be positive");
    }
    if (maximum_frequency >= nyquist_freq) {
        stop("maximum_frequency (" + std::to_string(maximum_frequency) + 
             " Hz) must be less than Nyquist frequency (" + 
             std::to_string(nyquist_freq) + " Hz). " +
             "Sound sampling rate is " + std::to_string(sampling_rate) + " Hz.");
    }
    
    // Validate pre_emphasis_frequency
    if (pre_emphasis_frequency < 0) {
        stop("pre_emphasis_frequency cannot be negative");
    }
    if (pre_emphasis_frequency > 0 && pre_emphasis_frequency >= nyquist_freq) {
        stop("pre_emphasis_frequency (" + std::to_string(pre_emphasis_frequency) + 
             " Hz) must be less than Nyquist frequency (" + 
             std::to_string(nyquist_freq) + " Hz)");
    }
    
    try {
        autoPowerCepstrogram cepstrogram = Sound_to_PowerCepstrogram(
            sound.get(),
            pitch_floor,
            time_step,
            maximum_frequency,
            pre_emphasis_frequency
        );
        return create_xptr_from_auto<structPowerCepstrogram>(cepstrogram);
    } catch (MelderError) {
        // Capture Praat error message before clearing
        autostring32 error_message = Melder_dup (Melder_getError());
        Melder_clearError();
        std::string error_str = Melder_peek32to8(error_message.get());
        stop("PowerCepstrogram creation failed. Praat error: " + error_str);
    }
}

// ==============================================================================
// Spectrum to PowerCepstrum conversion
// ==============================================================================

// [[Rcpp::export(.spectrum_to_powercepstrum)]]
SEXP spectrum_to_powercepstrum(SEXP spectrum_xptr) {
    XPtr<structSpectrum> spectrum(spectrum_xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        autoPowerCepstrum cepstrum = Spectrum_to_PowerCepstrum(spectrum.get());
        return create_xptr_from_auto<structPowerCepstrum>(cepstrum);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create PowerCepstrum from Spectrum");
    }
}

// ==============================================================================
// PowerCepstrum query methods
// ==============================================================================

// [[Rcpp::export(.powercepstrum_get_peak_prominence)]]
double powercepstrum_get_peak_prominence(SEXP xptr, std::string interpolation,
                                         double pitch_floor, double pitch_ceiling,
                                         double qmin, double qmax,
                                         std::string trend_type, std::string fit_method,
                                         double tolerance) {
    XPtr<structPowerCepstrum> cepstrum(xptr);
    if (!cepstrum) stop("Invalid PowerCepstrum pointer");
    
    // Convert interpolation string to enum
    kVector_peakInterpolation interp_type = kVector_peakInterpolation::NONE;
    if (interpolation == "none") interp_type = kVector_peakInterpolation::NONE;
    else if (interpolation == "parabolic") interp_type = kVector_peakInterpolation::PARABOLIC;
    else if (interpolation == "cubic") interp_type = kVector_peakInterpolation::CUBIC;
    else if (interpolation == "sinc70") interp_type = kVector_peakInterpolation::SINC70;
    else if (interpolation == "sinc700") interp_type = kVector_peakInterpolation::SINC700;
    else stop("Invalid interpolation type");
    
    // tolerance is unused by Praat's PowerCepstrum_getPeakProminence(), but we
    // keep the argument for API compatibility with the existing R wrapper.
    (void) tolerance;

    kCepstrum_trendType trend_type_enum = kCepstrum_trendType::EXPONENTIAL_DECAY;
    if (trend_type == "straight") trend_type_enum = kCepstrum_trendType::LINEAR;
    else if (trend_type == "exponential decay") trend_type_enum = kCepstrum_trendType::EXPONENTIAL_DECAY;
    else stop("Invalid trend type");

    kCepstrum_trendFit fit_type = kCepstrum_trendFit::ROBUST_SLOW;
    if (fit_method == "robust") fit_type = kCepstrum_trendFit::ROBUST_FAST;
    else if (fit_method == "least squares" || fit_method == "least_squares")
        fit_type = kCepstrum_trendFit::LEAST_SQUARES;
    else if (fit_method == "robust slow") fit_type = kCepstrum_trendFit::ROBUST_SLOW;
    else stop("Invalid fit method");
    
    // Handle qmax = 0 (use default)
    if (qmax == 0) {
        qmax = cepstrum->xmax;
    }
    
    try {
        double qpeak;
        // Note: pitch_floor and pitch_ceiling define the peak search range
        // qmin and qmax define the quefrency range for trend line fitting
        double prominence = PowerCepstrum_getPeakProminence(
            cepstrum.get(),
            pitch_floor,  // Pitch floor for peak search (e.g., 60 Hz)
            pitch_ceiling,  // Pitch ceiling for peak search (e.g., 333.3 Hz)
            interp_type,
            qmin,  // Quefrency start for trend line fit (e.g., 0.001 s)
            qmax,  // Quefrency end for trend line fit (e.g., 0.05 s)
            trend_type_enum,
            fit_type,
            qpeak
        );
        return prominence;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get peak prominence");
    }
}

// ==============================================================================
// PowerCepstrum modification
// ==============================================================================

// ==============================================================================
// PowerCepstrum conversions
// ==============================================================================

// ==============================================================================
// PowerCepstrogram query methods
// ==============================================================================

// [[Rcpp::export(.powercepstrogram_get_cpp_at_time)]]
double powercepstrogram_get_cpp_at_time(SEXP xptr, double time, std::string interpolation,
                                        double qmin, double qmax,
                                        std::string fit_method, double tolerance) {
    XPtr<structPowerCepstrogram> cepstrogram(xptr);
    if (!cepstrogram) stop("Invalid PowerCepstrogram pointer");
    
    // Extract PowerCepstrum slice at time
    try {
        autoPowerCepstrum slice = PowerCepstrogram_to_PowerCepstrum_slice(cepstrogram.get(), time);
        
        // Get CPP from the slice
        kVector_peakInterpolation interp_type = kVector_peakInterpolation::PARABOLIC;
        if (interpolation == "linear") interp_type = kVector_peakInterpolation::PARABOLIC;
        else if (interpolation == "cubic") interp_type = kVector_peakInterpolation::CUBIC;
        
        kCepstrum_trendType trend_type = kCepstrum_trendType::EXPONENTIAL_DECAY;
        if (fit_method == "straight") trend_type = kCepstrum_trendType::LINEAR;
        else if (fit_method == "exponential decay") trend_type = kCepstrum_trendType::EXPONENTIAL_DECAY;
        
        kCepstrum_trendFit fit_type = kCepstrum_trendFit::ROBUST_SLOW;
        
        if (qmax == 0) {
            qmax = slice->xmax;
        }
        
        double qpeak;
        double cpp = PowerCepstrum_getPeakProminence(
            slice.get(),
            1.0 / qmax,
            1.0 / qmin,
            interp_type,
            qmin,
            qmax,
            trend_type,
            fit_type,
            qpeak
        );
        
        return cpp;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get CPP at time");
    }
}

// [[Rcpp::export(.powercepstrogram_get_mean_cpp)]]
double powercepstrogram_get_mean_cpp(SEXP xptr, double from_time, double to_time,
                                     double qmin, double qmax,
                                     std::string fit_method, double tolerance) {
    XPtr<structPowerCepstrogram> cepstrogram(xptr);
    if (!cepstrogram) stop("Invalid PowerCepstrogram pointer");
    
    if (from_time == 0) from_time = cepstrogram->xmin;
    if (to_time == 0) to_time = cepstrogram->xmax;
    
    try {
        // Average CPP across time frames
        double sum_cpp = 0.0;
        integer n_frames = 0;
        
        integer iframe_start = Sampled_xToNearestIndex(cepstrogram, from_time);
        integer iframe_end = Sampled_xToNearestIndex(cepstrogram, to_time);
        
        kVector_peakInterpolation interp_type = kVector_peakInterpolation::PARABOLIC;
        kCepstrum_trendType trend_type = kCepstrum_trendType::EXPONENTIAL_DECAY;
        if (fit_method == "straight") trend_type = kCepstrum_trendType::LINEAR;
        else if (fit_method == "exponential decay") trend_type = kCepstrum_trendType::EXPONENTIAL_DECAY;
        kCepstrum_trendFit fit_type = kCepstrum_trendFit::ROBUST_SLOW;
        
        if (qmax == 0) {
            qmax = cepstrogram->ymax;
        }
        
        for (integer iframe = iframe_start; iframe <= iframe_end; iframe++) {
            double time = Sampled_indexToX(cepstrogram, iframe);
            autoPowerCepstrum slice = PowerCepstrogram_to_PowerCepstrum_slice(cepstrogram.get(), time);
            
            double qpeak;
            double cpp = PowerCepstrum_getPeakProminence(
                slice.get(),
                1.0 / qmax,
                1.0 / qmin,
                interp_type,
                qmin,
                qmax,
                trend_type,
                fit_type,
                qpeak
            );
            
            sum_cpp += cpp;
            n_frames++;
        }
        
        return (n_frames > 0) ? (sum_cpp / n_frames) : 0.0;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get mean CPP");
    }
}

// [[Rcpp::export(.powercepstrogram_to_powercepstrum_slice)]]
SEXP powercepstrogram_to_powercepstrum_slice(SEXP xptr, double time) {
    XPtr<structPowerCepstrogram> cepstrogram(xptr);
    if (!cepstrogram) stop("Invalid PowerCepstrogram pointer");
    
    try {
        autoPowerCepstrum slice = PowerCepstrogram_to_PowerCepstrum_slice(cepstrogram.get(), time);
        return create_xptr_from_auto<structPowerCepstrum>(slice);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get PowerCepstrum slice");
    }
}

// ==============================================================================
// PowerCepstrogram conversions
// ==============================================================================

// [[Rcpp::export(.powercepstrogram_to_matrix)]]
SEXP powercepstrogram_to_matrix(SEXP xptr) {
    XPtr<structPowerCepstrogram> cepstrogram(xptr);
    if (!cepstrogram) stop("Invalid PowerCepstrogram pointer");
    
    try {
        autoMatrix matrix = PowerCepstrogram_to_Matrix(cepstrogram.get());
        return create_xptr_from_auto<structMatrix>(matrix);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert PowerCepstrogram to Matrix");
    }
}

// [[Rcpp::export(.powercepstrogram_as_matrix)]]
NumericMatrix powercepstrogram_as_matrix(SEXP xptr) {
    XPtr<structPowerCepstrogram> cepstrogram(xptr);
    if (!cepstrogram) stop("Invalid PowerCepstrogram pointer");
    
    NumericMatrix mat(cepstrogram->ny, cepstrogram->nx);
    
    for (integer i = 1; i <= cepstrogram->ny; i++) {
        for (integer j = 1; j <= cepstrogram->nx; j++) {
            mat(i - 1, j - 1) = cepstrogram->z[i][j];
        }
    }
    
    return mat;
}

// [[Rcpp::export(.powercepstrogram_smooth)]]
SEXP powercepstrogram_smooth(SEXP xptr, double time_averaging_window, 
                             double quefrency_averaging_window) {
    XPtr<structPowerCepstrogram> cepstrogram(xptr);
    if (!cepstrogram) stop("Invalid PowerCepstrogram pointer");
    
    try {
        autoPowerCepstrogram smoothed = PowerCepstrogram_smooth(
            cepstrogram.get(),
            time_averaging_window,
            quefrency_averaging_window
        );
        return create_xptr_from_auto<structPowerCepstrogram>(smoothed);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to smooth PowerCepstrogram");
    }
}

// ==============================================================================
// CPPS (Smoothed Cepstral Peak Prominence) - Critical for AVQI
// ==============================================================================

// [[Rcpp::export(.powercepstrogram_get_cpps)]]
double powercepstrogram_get_cpps(SEXP xptr,
                                bool subtract_tilt,
                                double time_averaging_window,
                                double quefrency_averaging_window,
                                double pitch_floor,
                                double pitch_ceiling,
                                double delta_f0,
                                int interpolation,
                                double qstart_fit,
                                double qend_fit,
                                int trend_type,
                                int fit_method) {
    XPtr<structPowerCepstrogram> cepstrogram(xptr);
    if (!cepstrogram) stop("Invalid PowerCepstrogram pointer");
    
    try {
        // Convert integer enums to Praat types
        kVector_peakInterpolation interp_type = static_cast<kVector_peakInterpolation>(interpolation);
        kCepstrum_trendType trend = static_cast<kCepstrum_trendType>(trend_type);
        kCepstrum_trendFit fit = static_cast<kCepstrum_trendFit>(fit_method);
        
        double cpps = PowerCepstrogram_getCPPS(
            cepstrogram.get(),
            subtract_tilt,
            time_averaging_window,
            quefrency_averaging_window,
            pitch_floor,
            pitch_ceiling,
            delta_f0,
            interp_type,
            qstart_fit,
            qend_fit,
            trend,
            fit
        );
        
        return cpps;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to compute CPPS from PowerCepstrogram");
    }
}

// ==============================================================================
// Direct Sound to CPPS - Optimized single-call API (v4.1.0)
// ==============================================================================

// [[Rcpp::export(.sound_to_cpps_direct)]]
double sound_to_cpps_direct(
    SEXP sound_xptr,
    double cepstrogram_pitch_floor,
    double time_step,
    double max_frequency,
    double pre_emphasis_from,
    bool subtract_tilt,
    double time_averaging_window,
    double quefrency_averaging_window,
    double pitch_floor,
    double pitch_ceiling,
    double delta_f0,
    int interpolation,
    double qstart_fit,
    double qend_fit,
    int trend_type,
    int fit_method
) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound) stop("Invalid Sound pointer");

    try {
        // Step 1: Create PowerCepstrogram internally (not exposed to R)
        autoPowerCepstrogram cepstrogram = Sound_to_PowerCepstrogram(
            sound.get(),
            cepstrogram_pitch_floor,
            time_step,
            max_frequency,
            pre_emphasis_from
        );

        // Step 2: Calculate CPPS directly
        kVector_peakInterpolation interp_type = static_cast<kVector_peakInterpolation>(interpolation);
        kCepstrum_trendType trend = static_cast<kCepstrum_trendType>(trend_type);
        kCepstrum_trendFit fit = static_cast<kCepstrum_trendFit>(fit_method);

        double cpps = PowerCepstrogram_getCPPS(
            cepstrogram.get(),
            subtract_tilt,
            time_averaging_window,
            quefrency_averaging_window,
            pitch_floor,
            pitch_ceiling,
            delta_f0,
            interp_type,
            qstart_fit,
            qend_fit,
            trend,
            fit
        );

        // PowerCepstrogram automatically freed when function exits
        return cpps;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to compute CPPS directly from Sound");
    }
}

// ==============================================================================
// Additional PowerCepstrum Methods - Voice Quality Analysis
// ==============================================================================

// [[Rcpp::export(.powercepstrum_get_rnr)]]
double powercepstrum_get_rnr(SEXP xptr, double pitch_floor, double pitch_ceiling, double f0_fractional_width) {
    // NOTE: This function causes segfaults when PowerCepstrum is created from Spectrum.
    // The Praat function PowerCepstrum_getRNR requires workspace initialization that
    // is not available for PowerCepstrum objects created this way.
    // 
    // Workaround: Use HNR, CPP, or other voice quality metrics instead.
    // Or create PowerCepstrum from PowerCepstrogram$get_power_cepstrum_at_time()
    
    stop("get_rnr() is currently unsupported due to Praat internal requirements. Use HNR or CPP instead.");
    return 0.0; // Never reached
}

// [[Rcpp::export(.powercepstrum_tabulate_rhamonics)]]
SEXP powercepstrum_tabulate_rhamonics(SEXP xptr, double pitch_floor, double pitch_ceiling, int interpolation) {
    XPtr<structPowerCepstrum> cepstrum(xptr);
    if (!cepstrum) stop("Invalid PowerCepstrum pointer");
    
    try {
        kVector_peakInterpolation interp_type = static_cast<kVector_peakInterpolation>(interpolation);
        
        autoTable table = PowerCepstrum_tabulateRhamonics(
            cepstrum.get(),
            pitch_floor,
            pitch_ceiling,
            interp_type
        );
        
        return create_xptr_from_auto<structTable>(table);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to tabulate rhamonics");
    }
}

// ==============================================================================
// Sound to Cepstrum conversions (distinct from PowerCepstrum)
// ==============================================================================

// [[Rcpp::export(.sound_to_cepstrum)]]
SEXP sound_to_cepstrum(SEXP sound_xptr) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound) stop("Invalid Sound pointer");
    
    try {
        autoCepstrum cepstrum = Sound_to_Cepstrum(sound.get());
        return create_xptr_from_auto<structCepstrum>(cepstrum);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create Cepstrum from Sound");
    }
}

// [[Rcpp::export(.sound_to_cepstrum_bw)]]
SEXP sound_to_cepstrum_bw(SEXP sound_xptr) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound) stop("Invalid Sound pointer");
    
    try {
        autoCepstrum cepstrum = Sound_to_Cepstrum_bw(sound.get());
        return create_xptr_from_auto<structCepstrum>(cepstrum);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create bandwidth-weighted Cepstrum from Sound");
    }
}

// ==============================================================================
// Cepstrum conversion methods
// ==============================================================================

// [[Rcpp::export(.cepstrum_to_sound)]]
SEXP cepstrum_to_sound(SEXP cepstrum_xptr) {
    // NOTE: This function fails with "invalid file argument" error.
    // The error appears to come from R's error handling system, not Praat.
    // The Cepstrum_to_Sound function in Praat requires specific metadata
    // that may not be properly set when creating Cepstrum from Sound.
    //
    // Workaround: Cepstrum round-trip conversion is rarely needed.
    // If needed, use PowerCepstrum$to_spectrum() with random phases.
    
    stop("to_sound() is currently unsupported for Cepstrum objects. Complex cepstrum round-trip conversion is rarely needed in practice. If you need to convert back to sound, use PowerCepstrum$to_spectrum() instead.");
    return R_NilValue; // Never reached
}

// [[Rcpp::export(.cepstrum_to_spectrum)]]
SEXP cepstrum_to_spectrum(SEXP cepstrum_xptr) {
    XPtr<structCepstrum> cepstrum(cepstrum_xptr);
    if (!cepstrum) stop("Invalid Cepstrum pointer");
    
    try {
        autoSpectrum spectrum = Cepstrum_to_Spectrum(cepstrum.get());
        return create_xptr_from_auto<structSpectrum>(spectrum);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert Cepstrum to Spectrum");
    }
}

// [[Rcpp::export(.cepstrum_to_powercepstrum)]]
SEXP cepstrum_to_powercepstrum(SEXP cepstrum_xptr) {
    XPtr<structCepstrum> cepstrum(cepstrum_xptr);
    if (!cepstrum) stop("Invalid Cepstrum pointer");
    
    try {
        autoPowerCepstrum powercepstrum = Cepstrum_downto_PowerCepstrum(cepstrum.get());
        return create_xptr_from_auto<structPowerCepstrum>(powercepstrum);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert Cepstrum to PowerCepstrum");
    }
}

// [[Rcpp::export(.spectrum_to_cepstrum_hillenbrand)]]
SEXP spectrum_to_cepstrum_hillenbrand(SEXP spectrum_xptr) {
    XPtr<structSpectrum> spectrum(spectrum_xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        autoCepstrum cepstrum = Spectrum_to_Cepstrum_hillenbrand(spectrum.get());
        return create_xptr_from_auto<structCepstrum>(cepstrum);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create Hillenbrand Cepstrum from Spectrum");
    }
}

