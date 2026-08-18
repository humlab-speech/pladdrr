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
#include "praat.github.io/fon/AmplitudeTier.h"
#include "praat.github.io/fon/IntensityTier.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/PointProcess.h"

// [[Rcpp::export]]
SEXP amplitude_tier_create_cpp(double tmin, double tmax) {
  try {
    autoAmplitudeTier tier = AmplitudeTier_create(tmin, tmax);
    return Rcpp::XPtr<structAmplitudeTier>(tier.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to create AmplitudeTier");
  }
}

// [[Rcpp::export]]
SEXP intensity_tier_to_amplitude_tier_cpp(SEXP xptr) {
  try {
    IntensityTier tier = static_cast<IntensityTier>(R_ExternalPtrAddr(xptr));
    autoAmplitudeTier result = IntensityTier_to_AmplitudeTier(tier);
    return Rcpp::XPtr<structAmplitudeTier>(result.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to convert IntensityTier to AmplitudeTier");
  }
}

// [[Rcpp::export]]
SEXP point_process_sound_to_amplitude_tier_point_cpp(SEXP pp_xptr, SEXP sound_xptr) {
  try {
    PointProcess pp = static_cast<PointProcess>(R_ExternalPtrAddr(pp_xptr));
    Sound sound = static_cast<Sound>(R_ExternalPtrAddr(sound_xptr));
    autoAmplitudeTier result = PointProcess_Sound_to_AmplitudeTier_point(pp, sound);
    return Rcpp::XPtr<structAmplitudeTier>(result.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to extract AmplitudeTier from PointProcess and Sound");
  }
}

