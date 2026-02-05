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
#include <Rcpp.h>
#include "praat.github.io/sys/Thing.h"
#include "praat.github.io/sensors/Electroglottogram.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/fon/AmplitudeTier.h"

// [[Rcpp::export]]
SEXP electroglottogram_create_cpp(double xmin, double xmax, int nx, double dx, double x1) {
  try {
    autoElectroglottogram egg = Electroglottogram_create(xmin, xmax, nx, dx, x1);
    return Rcpp::XPtr<structElectroglottogram>(egg.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to create Electroglottogram");
  }
}

// [[Rcpp::export]]
SEXP sound_extract_electroglottogram_cpp(SEXP xptr, int channel, bool invert) {
  try {
    Sound sound = static_cast<Sound>(R_ExternalPtrAddr(xptr));
    autoElectroglottogram egg = Sound_extractElectroglottogram(sound, channel, invert);
    return Rcpp::XPtr<structElectroglottogram>(egg.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to extract Electroglottogram from Sound");
  }
}

// [[Rcpp::export]]
SEXP electroglottogram_to_textgrid_closed_glottis_cpp(SEXP xptr,
                                                      double pitch_floor,
                                                      double pitch_ceiling,
                                                      double closing_threshold,
                                                      double peak_threshold) {
  try {
    Electroglottogram egg = static_cast<Electroglottogram>(R_ExternalPtrAddr(xptr));
    autoTextGrid tg = Electroglottogram_to_TextGrid_closedGlottis(
      egg,
      pitch_floor,
      pitch_ceiling,
      closing_threshold,
      peak_threshold
    );
    return Rcpp::XPtr<structTextGrid>(tg.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to extract closed glottis TextGrid");
  }
}

// [[Rcpp::export]]
Rcpp::List electroglottogram_to_amplitude_tier_levels_cpp(SEXP xptr,
                                                          double pitch_floor,
                                                          double pitch_ceiling,
                                                          double closing_threshold) {
  try {
    Electroglottogram egg = static_cast<Electroglottogram>(R_ExternalPtrAddr(xptr));
    autoAmplitudeTier peaks, valleys;
    autoAmplitudeTier levels = Electroglottogram_to_AmplitudeTier_levels(
      egg,
      pitch_floor,
      pitch_ceiling,
      closing_threshold,
      &peaks,
      &valleys
    );

    return Rcpp::List::create(
      Rcpp::Named("levels") = Rcpp::XPtr<structAmplitudeTier>(levels.releaseToAmbiguousOwner()),
      Rcpp::Named("peaks") = Rcpp::XPtr<structAmplitudeTier>(peaks.releaseToAmbiguousOwner()),
      Rcpp::Named("valleys") = Rcpp::XPtr<structAmplitudeTier>(valleys.releaseToAmbiguousOwner())
    );
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to extract amplitude tier levels");
  }
}

// [[Rcpp::export]]
SEXP electroglottogram_derivative_cpp(SEXP xptr,
                                     double lowpass_freq,
                                     double smoothing,
                                     double peak_amplitude) {
  try {
    Electroglottogram egg = static_cast<Electroglottogram>(R_ExternalPtrAddr(xptr));
    autoSound degg = Electroglottogram_derivative(egg, lowpass_freq, smoothing, peak_amplitude);
    return Rcpp::XPtr<structSound>(degg.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to calculate Electroglottogram derivative");
  }
}

// [[Rcpp::export]]
SEXP electroglottogram_first_central_difference_cpp(SEXP xptr, double peak_amplitude) {
  try {
    Electroglottogram egg = static_cast<Electroglottogram>(R_ExternalPtrAddr(xptr));
    autoSound degg = Electroglottogram_firstCentralDifference(egg, peak_amplitude);
    return Rcpp::XPtr<structSound>(degg.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to calculate first central difference");
  }
}

// [[Rcpp::export]]
SEXP electroglottogram_high_pass_filter_cpp(SEXP xptr,
                                           double from_freq,
                                           double smoothing) {
  try {
    Electroglottogram egg = static_cast<Electroglottogram>(R_ExternalPtrAddr(xptr));
    autoElectroglottogram filtered = Electroglottogram_highPassFilter(egg, from_freq, smoothing);
    return Rcpp::XPtr<structElectroglottogram>(filtered.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to high-pass filter Electroglottogram");
  }
}

// [[Rcpp::export]]
SEXP electroglottogram_to_sound_cpp(SEXP xptr) {
  try {
    Electroglottogram egg = static_cast<Electroglottogram>(R_ExternalPtrAddr(xptr));
    autoSound sound = Electroglottogram_to_Sound(egg);
    return Rcpp::XPtr<structSound>(sound.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to convert Electroglottogram to Sound");
  }
}
