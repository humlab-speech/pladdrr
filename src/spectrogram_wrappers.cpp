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
// spectrogram_wrappers.cpp
// C++ wrappers for Praat Spectrogram functions

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/Matrix.h"
#include "fon/Spectrogram.h"
#include "fon/Spectrum.h"
#include "fon/Sound_and_Spectrogram.h"
#include "fon/Spectrum_and_Spectrogram.h"

using namespace Rcpp;

// ============================================================================
// TIME/FREQUENCY DOMAIN QUERIES
// ============================================================================

// [[Rcpp::export(.spectrogram_get_start_time)]]
double spectrogram_get_start_time(XPtr<structSpectrogram> spectrogram) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    return spectrogram->xmin;
}

// [[Rcpp::export(.spectrogram_get_end_time)]]
double spectrogram_get_end_time(XPtr<structSpectrogram> spectrogram) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    return spectrogram->xmax;
}

// [[Rcpp::export(.spectrogram_get_time_step)]]
double spectrogram_get_time_step(XPtr<structSpectrogram> spectrogram) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    return spectrogram->dx;
}

// [[Rcpp::export(.spectrogram_get_number_of_time_bins)]]
int spectrogram_get_number_of_time_bins(XPtr<structSpectrogram> spectrogram) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    return spectrogram->nx;
}

// [[Rcpp::export(.spectrogram_get_lowest_frequency)]]
double spectrogram_get_lowest_frequency(XPtr<structSpectrogram> spectrogram) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    return spectrogram->ymin;
}

// [[Rcpp::export(.spectrogram_get_highest_frequency)]]
double spectrogram_get_highest_frequency(XPtr<structSpectrogram> spectrogram) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    return spectrogram->ymax;
}

// [[Rcpp::export(.spectrogram_get_frequency_step)]]
double spectrogram_get_frequency_step(XPtr<structSpectrogram> spectrogram) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    return spectrogram->dy;
}

// [[Rcpp::export(.spectrogram_get_number_of_frequency_bins)]]
int spectrogram_get_number_of_frequency_bins(XPtr<structSpectrogram> spectrogram) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    return spectrogram->ny;
}

// ============================================================================
// CONVERSION METHODS
// ============================================================================

// [[Rcpp::export(.spectrogram_get_time_from_frame)]]
double spectrogram_get_time_from_frame(XPtr<structSpectrogram> spectrogram, int frame) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    if (frame < 1 || frame > spectrogram->nx) {
        stop("Frame index out of range");
    }
    return spectrogram->x1 + (frame - 1) * spectrogram->dx;
}

// [[Rcpp::export(.spectrogram_get_frequency_from_bin)]]
double spectrogram_get_frequency_from_bin(XPtr<structSpectrogram> spectrogram, int bin) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    if (bin < 1 || bin > spectrogram->ny) {
        stop("Bin index out of range");
    }
    return spectrogram->y1 + (bin - 1) * spectrogram->dy;
}

// ============================================================================
// QUERY METHODS
// ============================================================================

// [[Rcpp::export(.spectrogram_get_power_at)]]
double spectrogram_get_power_at(XPtr<structSpectrogram> spectrogram, double time, double frequency) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    
    try {
        /*
            Praat's "Spectrogram: Get power at (time, frequency)" is
            Matrix_getValueAtXY (praat_uvafon_init.cpp), i.e. bilinear
            interpolation between the four surrounding cells, undefined outside
            the domain. Before v4.9.19 this returned the nearest cell instead,
            which differed from Praat by up to ~24% at a single point and also
            disagreed with this class's own get_power_at_points(), which has
            always used Matrix_getValueAtXY.
        */
        const double value = Matrix_getValueAtXY(spectrogram.get(), time, frequency);
        return isdefined(value) ? value : NA_REAL;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get power");
    }
}

// ============================================================================
// TRANSFORMATION METHODS
// ============================================================================

// [[Rcpp::export(.spectrogram_to_spectrum)]]
SEXP spectrogram_to_spectrum(XPtr<structSpectrogram> spectrogram, double time) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    
    try {
        autoSpectrum spectrum = Spectrogram_to_Spectrum(spectrogram.get(), time);
        return create_xptr_from_auto<structSpectrum>(spectrum);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create spectrum");
    }
}

// ============================================================================
// EXPORT METHODS
// ============================================================================

// [[Rcpp::export(.spectrogram_as_matrix)]]
NumericMatrix spectrogram_as_matrix(XPtr<structSpectrogram> spectrogram) {
    if (!spectrogram) stop("Invalid Spectrogram pointer");
    
    int n_freqs = spectrogram->ny;
    int n_times = spectrogram->nx;
    
    NumericMatrix mat(n_freqs, n_times);
    
    for (int ifreq = 1; ifreq <= n_freqs; ifreq++) {
        for (int itime = 1; itime <= n_times; itime++) {
            mat(ifreq - 1, itime - 1) = spectrogram->z[ifreq][itime];
        }
    }
    
    return mat;
}
