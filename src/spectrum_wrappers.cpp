// spectrum_wrappers.cpp
// Rcpp wrappers for Praat Spectrum object

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/Spectrum.h"
#include "fon/Sound_and_Spectrum.h"
#include "fon/Ltas.h"
#include "fon/Matrix.h"
#include "LPC/Cepstrum.h"
#include "LPC/Cepstrum_and_Spectrum.h"
#include "melder/melder.h"

using namespace Rcpp;

// Avoid ambiguity with Rcpp::Matrix
using PraatMatrix = structMatrix*;

// Query: Basic info

// [[Rcpp::export(.spectrum_get_lowest_frequency)]]
double spectrum_get_lowest_frequency(SEXP xptr) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    return spectrum->xmin;
}

// [[Rcpp::export(.spectrum_get_highest_frequency)]]
double spectrum_get_highest_frequency(SEXP xptr) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    return spectrum->xmax;
}

// [[Rcpp::export(.spectrum_get_number_of_bins)]]
int spectrum_get_number_of_bins(SEXP xptr) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    return spectrum->nx;
}

// [[Rcpp::export(.spectrum_get_frequency_step)]]
double spectrum_get_frequency_step(SEXP xptr) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    return spectrum->dx;
}

// [[Rcpp::export(.spectrum_get_frequency_from_bin)]]
double spectrum_get_frequency_from_bin(SEXP xptr, int bin) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    if (bin < 1 || bin > spectrum->nx) stop("Bin out of range");
    return spectrum->x1 + (bin - 1) * spectrum->dx;
}

// [[Rcpp::export(.spectrum_get_bin_from_frequency)]]
double spectrum_get_bin_from_frequency(SEXP xptr, double frequency) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    return 1.0 + (frequency - spectrum->x1) / spectrum->dx;
}

// Query: Values

// [[Rcpp::export(.spectrum_get_real_value_in_bin)]]
double spectrum_get_real_value_in_bin(SEXP xptr, int bin) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    if (bin < 1 || bin > spectrum->nx) stop("Bin out of range");
    return spectrum->z[1][bin];  // Row 1 is real part
}

// [[Rcpp::export(.spectrum_get_imaginary_value_in_bin)]]
double spectrum_get_imaginary_value_in_bin(SEXP xptr, int bin) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    if (bin < 1 || bin > spectrum->nx) stop("Bin out of range");
    return spectrum->z[2][bin];  // Row 2 is imaginary part
}

// Query: Band statistics

// [[Rcpp::export(.spectrum_get_band_density)]]
double spectrum_get_band_density(SEXP xptr, double fmin, double fmax) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        return Spectrum_getBandDensity(spectrum, fmin, fmax);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get band density");
    }
}

// [[Rcpp::export(.spectrum_get_band_energy)]]
double spectrum_get_band_energy(SEXP xptr, double fmin, double fmax) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        return Spectrum_getBandEnergy(spectrum, fmin, fmax);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get band energy");
    }
}

// Query: Spectral moments

// [[Rcpp::export(.spectrum_get_centre_of_gravity)]]
double spectrum_get_centre_of_gravity(SEXP xptr, double power) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        return Spectrum_getCentreOfGravity(spectrum, power);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get centre of gravity");
    }
}

// [[Rcpp::export(.spectrum_get_standard_deviation)]]
double spectrum_get_standard_deviation(SEXP xptr, double power) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        return Spectrum_getStandardDeviation(spectrum, power);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get standard deviation");
    }
}

// [[Rcpp::export(.spectrum_get_skewness)]]
double spectrum_get_skewness(SEXP xptr, double power) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        return Spectrum_getSkewness(spectrum, power);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get skewness");
    }
}

// [[Rcpp::export(.spectrum_get_kurtosis)]]
double spectrum_get_kurtosis(SEXP xptr, double power) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        return Spectrum_getKurtosis(spectrum, power);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get kurtosis");
    }
}

// [[Rcpp::export(.spectrum_get_central_moment)]]
double spectrum_get_central_moment(SEXP xptr, double moment, double power) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        return Spectrum_getCentralMoment(spectrum, moment, power);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get central moment");
    }
}

// Modification

// [[Rcpp::export(.spectrum_pass_hann_band)]]
void spectrum_pass_hann_band(SEXP xptr, double fmin, double fmax, double smooth) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        Spectrum_passHannBand(spectrum, fmin, fmax, smooth);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to apply pass band filter");
    }
}

// [[Rcpp::export(.spectrum_stop_hann_band)]]
void spectrum_stop_hann_band(SEXP xptr, double fmin, double fmax, double smooth) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        Spectrum_stopHannBand(spectrum, fmin, fmax, smooth);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to apply stop band filter");
    }
}

// [[Rcpp::export(.spectrum_cepstral_smoothing)]]
SEXP spectrum_cepstral_smoothing(XPtr<structSpectrum> spectrum, double bandwidth) {
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        autoSpectrum smoothed = Spectrum_cepstralSmoothing(spectrum.get(), bandwidth);
        return create_xptr_from_auto<structSpectrum>(smoothed);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to perform cepstral smoothing");
    }
}

// Transform

// [[Rcpp::export(.spectrum_to_sound)]]
SEXP spectrum_to_sound(XPtr<structSpectrum> spectrum) {
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        autoSound sound = Spectrum_to_Sound(spectrum.get());
        return create_xptr_from_auto<structSound>(sound);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert spectrum to sound");
    }
}

// Export

// [[Rcpp::export(.spectrum_as_matrix)]]
NumericMatrix spectrum_as_matrix(SEXP xptr) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    NumericMatrix mat(2, spectrum->nx);  // 2 rows: real + imaginary
    
    for (integer i = 1; i <= spectrum->nx; i++) {
        mat(0, i - 1) = spectrum->z[1][i];  // Real part
        mat(1, i - 1) = spectrum->z[2][i];  // Imaginary part
    }
    
    return mat;
}

// ==============================================================================
// Spectrum formula modification
// ==============================================================================

// [[Rcpp::export(.spectrum_formula)]]
void spectrum_formula(SEXP xptr, std::string formula_str) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        // Convert formula string to Praat format
        conststring32 formula = Melder_peek8to32(formula_str.c_str());
        
        // Apply formula using Praat's built-in formula interpreter
        // Note: Praat's Matrix_formula modifies in place
        Matrix_formula(reinterpret_cast<structMatrix*>(spectrum.get()), 
                      formula, nullptr, nullptr);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to apply formula to Spectrum");
    }
}

// [[Rcpp::export(.spectrum_to_ltas_1to1)]]
SEXP spectrum_to_ltas_1to1(SEXP xptr) {
    XPtr<structSpectrum> spectrum(xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        // Create LTAS with 1-to-1 frequency mapping
        autoLtas ltas = Spectrum_to_Ltas(spectrum.get(), 1.0);
        return create_xptr_from_auto<structLtas>(ltas);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert Spectrum to Ltas");
    }
}

// ==============================================================================
// Spectrum to Cepstrum conversions
// ==============================================================================

// [[Rcpp::export(.spectrum_to_cepstrum)]]
SEXP spectrum_to_cepstrum(SEXP spectrum_xptr) {
    XPtr<structSpectrum> spectrum(spectrum_xptr);
    if (!spectrum) stop("Invalid Spectrum pointer");
    
    try {
        autoCepstrum cepstrum = Spectrum_to_Cepstrum(spectrum.get());
        return create_xptr_from_auto<structCepstrum>(cepstrum);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create Cepstrum from Spectrum");
    }
}
