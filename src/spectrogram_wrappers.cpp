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

// ============================================================================
// CONVERSION METHODS
// ============================================================================

// ============================================================================
// QUERY METHODS
// ============================================================================

// ============================================================================
// TRANSFORMATION METHODS
// ============================================================================

// ============================================================================
// EXPORT METHODS
// ============================================================================

