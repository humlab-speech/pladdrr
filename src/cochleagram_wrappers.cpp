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
// cochleagram_wrappers.cpp
// Wrapper functions for Praat Cochleagram object

#include <Rcpp.h>
#include "praat.github.io/fon/Cochleagram.h"
#include "praat.github.io/fon/Sound_to_Cochleagram.h"
#include "praat.github.io/fon/Cochleagram_and_Excitation.h"
#include "praat.github.io/fon/Sound.h"
#include "praat_error_handling.h"   // get_melder_error()

// [[Rcpp::export(.sound_to_cochleagram)]]
SEXP sound_to_cochleagram(SEXP sound_xptr, double dt, double df,
                          double window_length, double forward_masking_time) {
  try {
    Rcpp::XPtr<structSound> sound(sound_xptr);
    if (!sound) {
      Rcpp::stop("Invalid Sound object");
    }
    
    autoCochleagram result = Sound_to_Cochleagram(
      sound, dt, df, window_length, forward_masking_time
    );
    
    if (!result) {
      Rcpp::stop("Failed to create Cochleagram from Sound");
    }
    
    Rcpp::XPtr<structCochleagram> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    // Read the reason before clearing: Praat's error buffer is global and is
    // only emptied here, so stopping without it leaks this failure into every
    // later Praat error in the session.
    std::string praat_error = get_melder_error();
    Melder_clearError();
    Rcpp::stop("Praat error in Sound_to_Cochleagram: " + praat_error);
  }
}

// [[Rcpp::export(.sound_to_cochleagram_edb)]]
SEXP sound_to_cochleagram_edb(SEXP sound_xptr, double dtime, double dfreq,
                               bool has_synapse, double replenishment_rate,
                               double loss_rate, double return_rate,
                               double reprocessing_rate) {
  try {
    Rcpp::XPtr<structSound> sound(sound_xptr);
    if (!sound) {
      Rcpp::stop("Invalid Sound object");
    }
    
    autoCochleagram result = Sound_to_Cochleagram_edb(
      sound, dtime, dfreq, has_synapse ? 1 : 0,
      replenishment_rate, loss_rate, return_rate, reprocessing_rate
    );
    
    if (!result) {
      Rcpp::stop("Failed to create Cochleagram (EDB method) from Sound");
    }
    
    Rcpp::XPtr<structCochleagram> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    std::string praat_error = get_melder_error();
    Melder_clearError();
    Rcpp::stop("Praat error in Sound_to_Cochleagram_edb: " + praat_error);
  }
}

// [[Rcpp::export(.cochleagram_to_excitation)]]
SEXP cochleagram_to_excitation(SEXP xptr, double time) {
  try {
    Rcpp::XPtr<structCochleagram> cochleagram(xptr);
    if (!cochleagram) {
      Rcpp::stop("Invalid Cochleagram object");
    }
    
    autoExcitation result = Cochleagram_to_Excitation(cochleagram, time);
    
    if (!result) {
      Rcpp::stop("Failed to create Excitation from Cochleagram");
    }
    
    Rcpp::XPtr<structExcitation> ptr(result.releaseToAmbiguousOwner());
    return ptr;
  } catch (MelderError) {
    std::string praat_error = get_melder_error();
    Melder_clearError();
    Rcpp::stop("Praat error in Cochleagram_to_Excitation: " + praat_error);
  }
}

// Finalizer for Cochleagram objects
