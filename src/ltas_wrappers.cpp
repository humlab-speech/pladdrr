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
// Ltas (Long-term Average Spectrum) wrappers for speaker package
// Provides R bindings for Praat's Ltas object

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat.github.io/fon/Ltas.h"
#include "praat.github.io/fon/Vector.h"
#include "praat.github.io/fon/Spectrum.h"

using namespace Rcpp;

// ============================================================================
// Query methods - Frequency domain
// ============================================================================

// [[Rcpp::export(.ltas_get_bin_from_frequency)]]
int ltas_get_bin_from_frequency(Rcpp::XPtr<structLtas> ltas, double frequency) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  integer bin = Sampled_xToIndex(ltas.get(), frequency);
  return static_cast<int>(bin);
}

// [[Rcpp::export(.ltas_get_frequency_from_bin)]]
double ltas_get_frequency_from_bin(Rcpp::XPtr<structLtas> ltas, int bin) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  return Sampled_indexToX(ltas.get(), bin);
}

// [[Rcpp::export(.ltas_get_number_of_bins)]]
int ltas_get_number_of_bins(Rcpp::XPtr<structLtas> ltas) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  return static_cast<int>(ltas->nx);
}

// [[Rcpp::export(.ltas_get_bin_width)]]
double ltas_get_bin_width(Rcpp::XPtr<structLtas> ltas) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  return ltas->dx;
}

// [[Rcpp::export(.ltas_get_lowest_frequency)]]
double ltas_get_lowest_frequency(Rcpp::XPtr<structLtas> ltas) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  return ltas->xmin;
}

// [[Rcpp::export(.ltas_get_highest_frequency)]]
double ltas_get_highest_frequency(Rcpp::XPtr<structLtas> ltas) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  return ltas->xmax;
}

// ============================================================================
// Query methods - Values
// ============================================================================

// [[Rcpp::export(.ltas_get_value_at_frequency)]]
double ltas_get_value_at_frequency(Rcpp::XPtr<structLtas> ltas, double frequency, int unit, bool interpolate) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  if (frequency < ltas->xmin || frequency > ltas->xmax) {
    return NA_REAL;
  }
  
  double value;
  if (interpolate) {
    value = Vector_getValueAtX(ltas.get(), frequency, 1, kVector_valueInterpolation::LINEAR);
  } else {
    integer bin = Sampled_xToNearestIndex(ltas.get(), frequency);
    value = ltas->z[1][bin];
  }
  
  // Convert units if needed (0=dB, 1=sones, 2=linear)
  if (unit == 1) {  // sones
    value = pow(10.0, value / 10.0);  // Convert dB to linear, then to sones
  } else if (unit == 2) {  // linear
    value = pow(10.0, value / 10.0);
  }
  
  return value;
}

// [[Rcpp::export(.ltas_get_minimum)]]
double ltas_get_minimum(Rcpp::XPtr<structLtas> ltas, double fmin, double fmax, int unit, bool interpolate) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  if (fmin == 0.0) fmin = ltas->xmin;
  if (fmax == 0.0) fmax = ltas->xmax;
  
  double min_value = 1e308;
  integer imin = Sampled_xToNearestIndex(ltas.get(), fmin);
  integer imax = Sampled_xToNearestIndex(ltas.get(), fmax);
  
  for (integer i = imin; i <= imax; i++) {
    if (ltas->z[1][i] < min_value) {
      min_value = ltas->z[1][i];
    }
  }
  
  // Convert units
  if (unit == 1) {  // sones
    min_value = pow(10.0, min_value / 10.0);
  } else if (unit == 2) {  // linear
    min_value = pow(10.0, min_value / 10.0);
  }
  
  return min_value;
}

// [[Rcpp::export(.ltas_get_maximum)]]
double ltas_get_maximum(Rcpp::XPtr<structLtas> ltas, double fmin, double fmax, int interpolation) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  if (fmin == 0.0) fmin = ltas->xmin;
  if (fmax == 0.0) fmax = ltas->xmax;
  
  // Use Praat's Vector_getMaximum with interpolation
  // interpolation: 0=NONE, 1=PARABOLIC, 2=CUBIC, 3=SINC70, 4=SINC700
  kVector_peakInterpolation interp_type = static_cast<kVector_peakInterpolation>(interpolation);
  
  try {
    double max_value = Vector_getMaximum((structVector*)ltas.get(), fmin, fmax, interp_type);
    return max_value;  // Already in dB
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to get maximum from Ltas");
  }
}

// [[Rcpp::export(.ltas_get_frequency_of_maximum)]]
double ltas_get_frequency_of_maximum(Rcpp::XPtr<structLtas> ltas, double fmin, double fmax, int interpolation) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  if (fmin == 0.0) fmin = ltas->xmin;
  if (fmax == 0.0) fmax = ltas->xmax;
  
  // Find bin with maximum value
  double max_value = -1e308;
  integer max_bin = 0;
  integer imin = Sampled_xToNearestIndex(ltas.get(), fmin);
  integer imax = Sampled_xToNearestIndex(ltas.get(), fmax);
  
  for (integer i = imin; i <= imax; i++) {
    if (ltas->z[1][i] > max_value) {
      max_value = ltas->z[1][i];
      max_bin = i;
    }
  }
  
  if (max_bin == 0) return NA_REAL;
  
  double frequency = Sampled_indexToX(ltas.get(), max_bin);
  
  // Apply parabolic interpolation if requested (interpolation == 2)
  if (interpolation == 2 && max_bin > 1 && max_bin < ltas->nx) {
    double y1 = ltas->z[1][max_bin - 1];
    double y2 = ltas->z[1][max_bin];
    double y3 = ltas->z[1][max_bin + 1];
    
    // Parabolic peak refinement: offset = (y1-y3)/(2*(2*y2-y1-y3))
    double denominator = 2.0 * (2.0 * y2 - y1 - y3);
    if (fabs(denominator) > 1e-10) {
      double offset = (y1 - y3) / denominator;
      frequency += offset * ltas->dx;  // Adjust by bin width
    }
  }
  
  return frequency;
}

// [[Rcpp::export(.ltas_get_mean)]]
double ltas_get_mean(Rcpp::XPtr<structLtas> ltas, double fmin, double fmax, int unit) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  if (fmin == 0.0) fmin = ltas->xmin;
  if (fmax == 0.0) fmax = ltas->xmax;
  
  double sum = 0.0;
  integer count = 0;
  integer imin = Sampled_xToNearestIndex(ltas.get(), fmin);
  integer imax = Sampled_xToNearestIndex(ltas.get(), fmax);
  
  for (integer i = imin; i <= imax; i++) {
    sum += ltas->z[1][i];
    count++;
  }
  
  double mean_value = count > 0 ? sum / count : NA_REAL;
  
  // Convert units
  if (unit == 1) {  // sones
    mean_value = pow(10.0, mean_value / 10.0);
  } else if (unit == 2) {  // linear
    mean_value = pow(10.0, mean_value / 10.0);
  }
  
  return mean_value;
}

// [[Rcpp::export(.ltas_get_slope)]]
double ltas_get_slope(Rcpp::XPtr<structLtas> ltas, double f1min, double f1max, double f2min, double f2max, int averagingMethod) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  try {
    // Use Praat's native Ltas_getSlope function
    // averagingMethod: 1=energy, 2=sones, 3=dB (Praat enum values)
    double slope = Ltas_getSlope(ltas.get(), f1min, f1max, f2min, f2max, averagingMethod);
    return slope;
  } catch(MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to calculate LTAS slope");
  }
}

// ============================================================================
// Transformation methods
// ============================================================================

// [[Rcpp::export(.ltas_compute_trend_line)]]
Rcpp::XPtr<structLtas> ltas_compute_trend_line(Rcpp::XPtr<structLtas> ltas, double fmin, double fmax) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  if (fmin == 0.0) fmin = ltas->xmin;
  if (fmax == 0.0) fmax = ltas->xmax;
  
  autoLtas trend = Ltas_computeTrendLine(ltas.get(), fmin, fmax);
  return create_xptr_from_auto<structLtas>(trend);
}

// [[Rcpp::export(.ltas_subtract_trend_line)]]
Rcpp::XPtr<structLtas> ltas_subtract_trend_line(Rcpp::XPtr<structLtas> ltas, double fmin, double fmax) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  if (fmin == 0.0) fmin = ltas->xmin;
  if (fmax == 0.0) fmax = ltas->xmax;
  
  autoLtas corrected = Ltas_subtractTrendLine(ltas.get(), fmin, fmax);
  return create_xptr_from_auto<structLtas>(corrected);
}

// ============================================================================
// Export methods
// ============================================================================

// [[Rcpp::export(.ltas_as_data_frame)]]
DataFrame ltas_as_data_frame(Rcpp::XPtr<structLtas> ltas) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  NumericVector frequency(ltas->nx);
  NumericVector power_db(ltas->nx);
  
  for (integer i = 1; i <= ltas->nx; i++) {
    frequency[i-1] = Sampled_indexToX(ltas.get(), i);
    power_db[i-1] = ltas->z[1][i];
  }
  
  return DataFrame::create(
    Named("frequency") = frequency,
    Named("power_db") = power_db,
    Named("stringsAsFactors") = false
  );
}

// [[Rcpp::export(.ltas_as_matrix)]]
NumericVector ltas_as_matrix(Rcpp::XPtr<structLtas> ltas) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");
  
  NumericVector values(ltas->nx);
  
  for (integer i = 1; i <= ltas->nx; i++) {
    values[i-1] = ltas->z[1][i];
  }
  
  return values;
}
