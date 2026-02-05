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
void amplitude_tier_add_point_cpp(SEXP xptr, double time, double value) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    RealTier_addPoint(tier, time, value);
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to add point to AmplitudeTier");
  }
}

// [[Rcpp::export]]
double amplitude_tier_get_value_at_time_cpp(SEXP xptr, double time) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    return RealTier_getValueAtTime(tier, time);
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to get value from AmplitudeTier");
  }
}

// [[Rcpp::export]]
int amplitude_tier_get_number_of_points_cpp(SEXP xptr) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    return tier->points.size;
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to get number of points");
  }
}

// [[Rcpp::export]]
SEXP amplitude_tier_to_intensity_tier_cpp(SEXP xptr, double threshold_db) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    autoIntensityTier result = AmplitudeTier_to_IntensityTier(tier, threshold_db);
    return Rcpp::XPtr<structIntensityTier>(result.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to convert AmplitudeTier to IntensityTier");
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
double amplitude_tier_get_shimmer_local_cpp(SEXP xptr, double shortest_period,
                                            double longest_period,
                                            double maximum_amplitude_factor) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    double result = AmplitudeTier_getShimmer_local_u(tier, shortest_period,
                                                      longest_period,
                                                      maximum_amplitude_factor);
    return result;
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// [[Rcpp::export]]
double amplitude_tier_get_shimmer_local_db_cpp(SEXP xptr, double shortest_period,
                                               double longest_period,
                                               double maximum_amplitude_factor) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    double result = AmplitudeTier_getShimmer_local_dB_u(tier, shortest_period,
                                                         longest_period,
                                                         maximum_amplitude_factor);
    return result;
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// [[Rcpp::export]]
double amplitude_tier_get_shimmer_apq3_cpp(SEXP xptr, double shortest_period,
                                           double longest_period,
                                           double maximum_amplitude_factor) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    double result = AmplitudeTier_getShimmer_apq3_u(tier, shortest_period,
                                                     longest_period,
                                                     maximum_amplitude_factor);
    return result;
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// [[Rcpp::export]]
double amplitude_tier_get_shimmer_apq5_cpp(SEXP xptr, double shortest_period,
                                           double longest_period,
                                           double maximum_amplitude_factor) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    double result = AmplitudeTier_getShimmer_apq5_u(tier, shortest_period,
                                                     longest_period,
                                                     maximum_amplitude_factor);
    return result;
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// [[Rcpp::export]]
double amplitude_tier_get_shimmer_apq11_cpp(SEXP xptr, double shortest_period,
                                            double longest_period,
                                            double maximum_amplitude_factor) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    double result = AmplitudeTier_getShimmer_apq11_u(tier, shortest_period,
                                                      longest_period,
                                                      maximum_amplitude_factor);
    return result;
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// [[Rcpp::export]]
double amplitude_tier_get_shimmer_dda_cpp(SEXP xptr, double shortest_period,
                                          double longest_period,
                                          double maximum_amplitude_factor) {
  try {
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(xptr));
    double result = AmplitudeTier_getShimmer_dda_u(tier, shortest_period,
                                                    longest_period,
                                                    maximum_amplitude_factor);
    return result;
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
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

// [[Rcpp::export]]
SEXP sound_amplitude_tier_multiply_cpp(SEXP sound_xptr, SEXP tier_xptr) {
  try {
    Sound sound = static_cast<Sound>(R_ExternalPtrAddr(sound_xptr));
    AmplitudeTier tier = static_cast<AmplitudeTier>(R_ExternalPtrAddr(tier_xptr));
    autoSound result = Sound_AmplitudeTier_multiply(sound, tier);
    return Rcpp::XPtr<structSound>(result.releaseToAmbiguousOwner());
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to multiply Sound by AmplitudeTier");
  }
}
