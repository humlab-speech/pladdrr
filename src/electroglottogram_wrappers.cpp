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

