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
#include "praat.github.io/dwtools/Ltas_extensions.h"
#include "praat.github.io/fon/Ltas_to_SpectrumTier.h"

using namespace Rcpp;

// ============================================================================
// Query methods - Frequency domain
// ============================================================================

// ============================================================================
// Query methods - Values
// ============================================================================

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

//' Report spectral trend (slope and intercept with fit statistics)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.ltas_report_spectral_trend)]]
List ltas_report_spectral_trend(
    XPtr<structLtas> xptr,
    double fmin,
    double fmax,
    std::string frequency_scale,
    std::string fit_method
) {
    structLtas* ltas = get_ptr(xptr, "Ltas");
    
    // Default to full range if not specified
    if (fmin == 0.0) fmin = ltas->xmin;
    if (fmax == 0.0) fmax = ltas->xmax;
    
    // Map frequency_scale: "linear" or "logarithmic"
    bool logScale = (frequency_scale == "logarithmic");
    
    // Map fit_method: "least squares" (1) or "robust" (2)
    int method = (fit_method == "least squares") ? 1 : 2;
    
    try {
        // Get window samples
        integer ifmin, ifmax;
        const integer numberOfSamples = Sampled_getWindowSamples(ltas, fmin, fmax, &ifmin, &ifmax);
        Melder_require(numberOfSamples > 1,
            U"There should be at least two data points to fit a line.");
        
        // Prepare x and y data (mirroring Ltas_fitTrendLine logic)
        autoVEC x = raw_VEC(numberOfSamples);
        autoVEC y = raw_VEC(numberOfSamples);
        for (integer i = ifmin; i <= ifmax; i++) {
            const integer ixy = i - ifmin + 1;
            x[ixy] = ltas->x1 + (i - 1) * ltas->dx;
            if (logScale)
                x[ixy] = log10(x[ixy]); // For Ltas always x1 > 0
            y[ixy] = ltas->z[1][i];
        }
        
        // Fit trend line (calls NUMlineFit internally)
        double slope, intercept;
        Ltas_fitTrendLine(ltas, fmin, fmax, logScale, method, &slope, &intercept);
        
        // Calculate fit statistics: R² and residual standard error
        double y_mean = 0.0;
        for (integer i = 1; i <= numberOfSamples; i++) {
            y_mean += y[i];
        }
        y_mean /= numberOfSamples;
        
        double ss_res = 0.0, ss_tot = 0.0;
        for (integer i = 1; i <= numberOfSamples; i++) {
            double y_pred = slope * x[i] + intercept;
            double residual = y[i] - y_pred;
            ss_res += residual * residual;
            ss_tot += (y[i] - y_mean) * (y[i] - y_mean);
        }
        
        double r_squared = (ss_tot > 0.0) ? (1.0 - (ss_res / ss_tot)) : NA_REAL;
        double residual_std_error = (numberOfSamples > 2) ? 
            sqrt(ss_res / (numberOfSamples - 2)) : NA_REAL;
        
        // Prepare fitted values for return (in original frequency scale)
        NumericVector frequencies(numberOfSamples);
        NumericVector power_db_observed(numberOfSamples);
        NumericVector power_db_fitted(numberOfSamples);
        NumericVector residuals(numberOfSamples);
        
        for (integer i = ifmin; i <= ifmax; i++) {
            const integer ixy = i - ifmin + 1;
            double freq_orig = ltas->x1 + (i - 1) * ltas->dx;
            double x_val = logScale ? log10(freq_orig) : freq_orig;
            double y_obs = ltas->z[1][i];
            double y_fit = slope * x_val + intercept;
            
            frequencies[ixy - 1] = freq_orig;
            power_db_observed[ixy - 1] = y_obs;
            power_db_fitted[ixy - 1] = y_fit;
            residuals[ixy - 1] = y_obs - y_fit;
        }
        
        DataFrame fitted_df = DataFrame::create(
            Named("frequency") = frequencies,
            Named("power_db_observed") = power_db_observed,
            Named("power_db_fitted") = power_db_fitted,
            Named("residual") = residuals,
            Named("stringsAsFactors") = false
        );
        
        return List::create(
            Named("slope") = slope,
            Named("intercept") = intercept,
            Named("frequency_scale") = frequency_scale,
            Named("fit_method") = fit_method,
            Named("fmin") = fmin,
            Named("fmax") = fmax,
            Named("slope_units") = logScale ? "dB/decade" : "dB/Hz",
            Named("r_squared") = r_squared,
            Named("residual_std_error") = residual_std_error,
            Named("n_points") = static_cast<int>(numberOfSamples),
            Named("fitted_values") = fitted_df
        );
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to compute spectral trend");
    }
}

// ============================================================================
// Analysis: peak-picking
// ============================================================================

// [[Rcpp::export(.ltas_to_spectrum_tier_peaks)]]
Rcpp::XPtr<structSpectrumTier> ltas_to_spectrum_tier_peaks(Rcpp::XPtr<structLtas> ltas) {
  if (!ltas) Rcpp::stop("Invalid Ltas pointer");

  try {
    autoSpectrumTier peaks = Ltas_to_SpectrumTier_peaks(ltas.get());
    return create_xptr_from_auto<structSpectrumTier>(peaks);
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to find peaks in Ltas");
  }
}

// ============================================================================
// Export methods
// ============================================================================

// [[Rcpp::export(.ltases_average)]]
XPtr<structLtas> ltases_average(List ltas_list) {
    if (ltas_list.size() < 1) {
        stop("Need at least one Ltas object to average");
    }

    try {
        autoLtasBag bag = LtasBag_create();
        for (int i = 0; i < ltas_list.size(); i++) {
            XPtr<structLtas> xptr = as<XPtr<structLtas>>(ltas_list[i]);
            if (!xptr) stop("Invalid Ltas pointer at index %d", i + 1);
            bag->addItem_ref(xptr.get());
        }
        autoLtas result = Ltases_average(bag.get());
        return create_xptr_from_auto<structLtas>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to average Ltas objects");
    }
}
