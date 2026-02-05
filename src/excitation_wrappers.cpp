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

// [[Rcpp::export(.excitation_create)]]
SEXP excitation_create(double freq_step, int n_freqs) {
  try {
    autoExcitation result = Excitation_create(freq_step, n_freqs);
    if (!result) {
      Rcpp::stop("Failed to create Excitation object");
    }
    Rcpp::XPtr<structExcitation> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    Rcpp::stop("Praat error in Excitation_create");
  }
}

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

// [[Rcpp::export(.excitation_get_loudness)]]
double excitation_get_loudness(SEXP xptr) {
  try {
    Rcpp::XPtr<structExcitation> excitation(xptr);
    if (!excitation) {
      Rcpp::stop("Invalid Excitation object");
    }
    
    double loudness = Excitation_getLoudness(excitation);
    return loudness;
  } catch (MelderError) {
    Rcpp::stop("Praat error getting loudness");
  }
}

// [[Rcpp::export(.excitation_get_value_at_frequency)]]
double excitation_get_value_at_frequency(SEXP xptr, double freq_bark) {
  try {
    Rcpp::XPtr<structExcitation> excitation(xptr);
    if (!excitation) {
      Rcpp::stop("Invalid Excitation object");
    }
    
    // Excitation inherits from Vector, use Vector_getValueAtX
    integer i = Melder_iround((freq_bark - excitation->x1) / excitation->dx + 1);
    
    if (i < 1 || i > excitation->nx) {
      return 0.0;  // Outside range
    }
    
    return excitation->z[1][i];
  } catch (...) {
    Rcpp::stop("Error getting value at frequency");
  }
}

// [[Rcpp::export(.excitation_get_distance)]]
double excitation_get_distance(SEXP xptr1, SEXP xptr2) {
  try {
    Rcpp::XPtr<structExcitation> excitation1(xptr1);
    Rcpp::XPtr<structExcitation> excitation2(xptr2);
    
    if (!excitation1 || !excitation2) {
      Rcpp::stop("Invalid Excitation object(s)");
    }
    
    double distance = Excitation_getDistance(excitation1, excitation2);
    return distance;
  } catch (MelderError) {
    Rcpp::stop("Praat error calculating excitation distance");
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

// [[Rcpp::export(.excitation_as_vector)]]
Rcpp::DataFrame excitation_as_vector(SEXP xptr) {
  try {
    Rcpp::XPtr<structExcitation> excitation(xptr);
    if (!excitation) {
      Rcpp::stop("Invalid Excitation object");
    }
    
    int n = excitation->nx;
    Rcpp::NumericVector freqs(n);
    Rcpp::NumericVector values(n);
    
    for (int i = 1; i <= n; i++) {
      freqs(i-1) = excitation->x1 + (i - 1) * excitation->dx;
      values(i-1) = excitation->z[1][i];
    }
    
    return Rcpp::DataFrame::create(
      Rcpp::Named("frequency_bark") = freqs,
      Rcpp::Named("excitation") = values
    );
  } catch (...) {
    Rcpp::stop("Error converting Excitation to vector");
  }
}

// [[Rcpp::export(.excitation_get_info)]]
Rcpp::List excitation_get_info(SEXP xptr) {
  try {
    Rcpp::XPtr<structExcitation> excitation(xptr);
    if (!excitation) {
      Rcpp::stop("Invalid Excitation object");
    }
    
    return Rcpp::List::create(
      Rcpp::Named("xmin") = excitation->xmin,
      Rcpp::Named("xmax") = excitation->xmax,
      Rcpp::Named("nx") = excitation->nx,
      Rcpp::Named("dx") = excitation->dx,
      Rcpp::Named("x1") = excitation->x1
    );
  } catch (...) {
    Rcpp::stop("Error getting Excitation info");
  }
}

// Finalizer for Excitation objects
// [[Rcpp::export(.excitation_finalizer)]]
void excitation_finalizer(SEXP xptr) {
  // XPtr handles cleanup automatically, no need for explicit delete
  // The finalizer is set up by create_xptr_from_auto which handles it
}
