// powercepstrum_wrappers.cpp
// Rcpp wrappers for Praat PowerCepstrum and PowerCepstrogram objects

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "LPC/PowerCepstrum.h"
#include "LPC/PowerCepstrogram.h"
#include "LPC/Sound_to_PowerCepstrogram.h"
#include "LPC/Cepstrum_and_Spectrum.h"
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
        Melder_clearError();
        stop("Failed to create PowerCepstrogram from Sound");
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
                                         double qmin, double qmax,
                                         std::string fit_method, double tolerance) {
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
    
    // Convert fit method string to enum
    kCepstrum_trendType trend_type = kCepstrum_trendType::EXPONENTIAL_DECAY;
    if (fit_method == "straight") trend_type = kCepstrum_trendType::LINEAR;
    else if (fit_method == "exponential decay") trend_type = kCepstrum_trendType::EXPONENTIAL_DECAY;
    else stop("Invalid fit method");
    
    kCepstrum_trendFit fit_type = kCepstrum_trendFit::ROBUST_SLOW;
    
    // Handle qmax = 0 (use default)
    if (qmax == 0) {
        qmax = cepstrum->xmax;
    }
    
    try {
        double qpeak;
        double prominence = PowerCepstrum_getPeakProminence(
            cepstrum.get(),
            1.0 / qmax,  // Convert quefrency to pitch floor
            1.0 / qmin,  // Convert quefrency to pitch ceiling
            interp_type,
            qmin,
            qmax,
            trend_type,
            fit_type,
            qpeak
        );
        return prominence;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get peak prominence");
    }
}

// [[Rcpp::export(.powercepstrum_get_quefrency_of_peak)]]
double powercepstrum_get_quefrency_of_peak(SEXP xptr, std::string interpolation,
                                           double qmin, double qmax) {
    XPtr<structPowerCepstrum> cepstrum(xptr);
    if (!cepstrum) stop("Invalid PowerCepstrum pointer");
    
    kCepstrum_peakInterpolation interp_type = kCepstrum_peakInterpolation::PARABOLIC;
    if (interpolation == "none") interp_type = kCepstrum_peakInterpolation::NONE;
    else if (interpolation == "parabolic") interp_type = kCepstrum_peakInterpolation::PARABOLIC;
    else if (interpolation == "cubic") interp_type = kCepstrum_peakInterpolation::CUBIC;
    
    if (qmax == 0) {
        qmax = cepstrum->xmax;
    }
    
    try {
        double maximum, quefrency;
        PowerCepstrum_getMaximumAndQuefrency_q(
            cepstrum.get(),
            qmin,
            qmax,
            interp_type,
            maximum,
            quefrency
        );
        return quefrency;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get quefrency of peak");
    }
}

// [[Rcpp::export(.powercepstrum_get_value_at_quefrency)]]
double powercepstrum_get_value_at_quefrency(SEXP xptr, double quefrency,
                                             std::string interpolation, std::string unit) {
    XPtr<structPowerCepstrum> cepstrum(xptr);
    if (!cepstrum) stop("Invalid PowerCepstrum pointer");
    
    // Find the quefrency index
    double index = 1.0 + (quefrency - cepstrum->x1) / cepstrum->dx;
    if (index < 1 || index > cepstrum->nx) {
        stop("Quefrency out of range");
    }
    
    try {
        integer bin = (integer) floor(index);
        double fraction = index - bin;
        
        double value;
        if (interpolation == "linear" && bin < cepstrum->nx) {
            value = (1.0 - fraction) * cepstrum->z[1][bin] + fraction * cepstrum->z[1][bin + 1];
        } else {
            value = cepstrum->z[1][bin];
        }
        
        // Convert to requested unit
        if (unit == "dB") {
            return value;  // Already in dB
        } else {
            return pow(10.0, value / 10.0);  // Convert to linear
        }
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get value at quefrency");
    }
}

// ==============================================================================
// PowerCepstrum modification
// ==============================================================================

// [[Rcpp::export(.powercepstrum_smooth)]]
SEXP powercepstrum_smooth(SEXP xptr, double averaging_window, int nsamples) {
    XPtr<structPowerCepstrum> cepstrum(xptr);
    if (!cepstrum) stop("Invalid PowerCepstrum pointer");
    
    try {
        autoPowerCepstrum smoothed = PowerCepstrum_smooth(cepstrum.get(), averaging_window, nsamples);
        return create_xptr_from_auto<structPowerCepstrum>(smoothed);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to smooth PowerCepstrum");
    }
}

// ==============================================================================
// PowerCepstrum conversions
// ==============================================================================

// [[Rcpp::export(.powercepstrum_to_matrix)]]
SEXP powercepstrum_to_matrix(SEXP xptr) {
    XPtr<structPowerCepstrum> cepstrum(xptr);
    if (!cepstrum) stop("Invalid PowerCepstrum pointer");
    
    try {
        autoMatrix matrix = PowerCepstrum_to_Matrix(cepstrum.get());
        return create_xptr_from_auto<structMatrix>(matrix);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert PowerCepstrum to Matrix");
    }
}

// [[Rcpp::export(.powercepstrum_as_matrix)]]
NumericMatrix powercepstrum_as_matrix(SEXP xptr) {
    XPtr<structPowerCepstrum> cepstrum(xptr);
    if (!cepstrum) stop("Invalid PowerCepstrum pointer");
    
    NumericMatrix mat(1, cepstrum->nx);
    
    for (integer i = 1; i <= cepstrum->nx; i++) {
        mat(0, i - 1) = cepstrum->z[1][i];
    }
    
    return mat;
}

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

// [[Rcpp::export(.powercepstrum_get_peak_prominence_cpps)]]
double powercepstrum_get_peak_prominence_cpps(SEXP xptr,
                                             double pitch_floor,
                                             double pitch_ceiling,
                                             int interpolation,
                                             double qstart_fit,
                                             double qend_fit,
                                             int trend_type,
                                             int fit_method) {
    XPtr<structPowerCepstrum> cepstrum(xptr);
    if (!cepstrum) stop("Invalid PowerCepstrum pointer");
    
    try {
        // Convert integer enums to Praat types
        kVector_peakInterpolation interp_type = static_cast<kVector_peakInterpolation>(interpolation);
        kCepstrum_trendType trend = static_cast<kCepstrum_trendType>(trend_type);
        kCepstrum_trendFit fit = static_cast<kCepstrum_trendFit>(fit_method);
        
        double qpeak = 0.0;
        double prominence = PowerCepstrum_getPeakProminence(
            cepstrum.get(),
            pitch_floor,
            pitch_ceiling,
            interp_type,
            qstart_fit,
            qend_fit,
            trend,
            fit,
            qpeak
        );
        
        return prominence;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to compute peak prominence from PowerCepstrum");
    }
}
