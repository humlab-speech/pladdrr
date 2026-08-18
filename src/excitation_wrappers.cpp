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
// excitation_wrappers.cpp
// Wrapper functions for Praat Excitation object

#include <Rcpp.h>
#include "praat.github.io/fon/Excitation.h"
#include "praat.github.io/fon/Spectrum_to_Excitation.h"
#include "praat.github.io/fon/Cochleagram_and_Excitation.h"
#include "praat.github.io/fon/Excitation_to_Formant.h"
#include "praat.github.io/fon/Spectrum.h"

// [[Rcpp::export(.spectrum_to_excitation)]]
SEXP spectrum_to_excitation(SEXP spectrum_xptr, double erb_density) {
  try {
    Rcpp::XPtr<structSpectrum> spectrum(spectrum_xptr);
    if (!spectrum) {
      Rcpp::stop("Invalid Spectrum object");
    }
    
    autoExcitation result = Spectrum_to_Excitation(spectrum, erb_density);
    
    if (!result) {
      Rcpp::stop("Failed to create Excitation from Spectrum");
    }
    
    Rcpp::XPtr<structExcitation> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    Rcpp::stop("Praat error in Spectrum_to_Excitation");
  }
}

// [[Rcpp::export(.excitation_to_formant)]]
SEXP excitation_to_formant(SEXP xptr, int max_formants) {
  try {
    Rcpp::XPtr<structExcitation> excitation(xptr);
    if (!excitation) {
      Rcpp::stop("Invalid Excitation object");
    }
    
    autoFormant result = Excitation_to_Formant(excitation, max_formants);
    
    if (!result) {
      Rcpp::stop("Failed to extract formants from Excitation");
    }
    
    Rcpp::XPtr<structFormant> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    Rcpp::stop("Praat error in Excitation_to_Formant");
  }
}

// Finalizer for Excitation objects
