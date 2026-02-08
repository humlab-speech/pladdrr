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
// ltas_module.cpp
// Rcpp Module exposing Ltas (Long-Term Average Spectrum) functionality (pladdrr 2.0)

#include <Rcpp.h>
#include "module_common.h"
#include "../datatable_utils.h"
#include "praat.github.io/fon/Ltas.h"
#include "praat.github.io/fon/Matrix.h"

using namespace Rcpp;

class RLtas {
private:
    XPtr<structLtas> ptr;

public:
    RLtas() : ptr(R_NilValue) {}
    RLtas(XPtr<structLtas> xptr) : ptr(xptr) {}

    bool is_valid() { return ptr.get() != nullptr; }

    // Frequency domain properties
    double get_fmin() { VALIDATE_PTR(ptr, Ltas); return ptr->xmin; }
    double get_fmax() { VALIDATE_PTR(ptr, Ltas); return ptr->xmax; }
    double get_frequency_range() { VALIDATE_PTR(ptr, Ltas); return ptr->xmax - ptr->xmin; }
    int get_n_bins() { VALIDATE_PTR(ptr, Ltas); return static_cast<int>(ptr->nx); }
    double get_df() { VALIDATE_PTR(ptr, Ltas); return ptr->dx; }
    double get_f1() { VALIDATE_PTR(ptr, Ltas); return ptr->x1; }

    // Aliases
    int get_number_of_bins() { return get_n_bins(); }
    double get_bandwidth() { return get_df(); }

    // Frequency/bin conversion
    double get_frequency_from_bin(int bin) {
        VALIDATE_PTR(ptr, Ltas);
        return Matrix_columnToX(ptr.get(), bin);
    }

    int get_bin_from_frequency(double freq) {
        VALIDATE_PTR(ptr, Ltas);
        if (ISNAN(freq)) return NA_INTEGER;
        return static_cast<int>(Matrix_xToNearestColumn(ptr.get(), freq));
    }

    // Query methods
    double get_value_at_frequency(double freq, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        GUARD_NAN_SCALAR(freq);
        return Vector_getValueAtX(ptr.get(), freq, 1, (kVector_valueInterpolation)interpolation);
    }

    double get_value_at_bin(int bin) {
        VALIDATE_PTR(ptr, Ltas);
        if (bin < 1 || bin > ptr->nx) Rcpp::stop("Bin out of range");
        return ptr->z[1][bin];
    }

    double get_minimum(double fmin, double fmax, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        GUARD_NAN_RANGE(fmin, fmax);
        return Vector_getMinimum(ptr.get(), fmin, fmax, (kVector_peakInterpolation)interpolation);
    }

    double get_maximum(double fmin, double fmax, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        GUARD_NAN_RANGE(fmin, fmax);
        return Vector_getMaximum(ptr.get(), fmin, fmax, (kVector_peakInterpolation)interpolation);
    }

    double get_frequency_of_minimum(double fmin, double fmax, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        GUARD_NAN_RANGE(fmin, fmax);
        return Vector_getXOfMinimum(ptr.get(), fmin, fmax, (kVector_peakInterpolation)interpolation);
    }

    double get_frequency_of_maximum(double fmin, double fmax, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);
        GUARD_NAN_RANGE(fmin, fmax);
        return Vector_getXOfMaximum(ptr.get(), fmin, fmax, (kVector_peakInterpolation)interpolation);
    }

    double get_mean(double fmin, double fmax, int averaging_units) {
        VALIDATE_PTR(ptr, Ltas);
        GUARD_NAN_RANGE(fmin, fmax);
        return Sampled_getMean(ptr.get(), fmin, fmax, 0, averaging_units, true);
    }

    double get_slope(double f1min, double f1max, double f2min, double f2max, int averaging_units) {
        VALIDATE_PTR(ptr, Ltas);
        GUARD_NAN_RANGE(f1min, f1max);
        GUARD_NAN_RANGE(f2min, f2max);
        return Ltas_getSlope(ptr.get(), f1min, f1max, f2min, f2max, averaging_units);
    }

    double get_local_peak_height(double env_min, double env_max, double peak_min, double peak_max, int averaging_units) {
        VALIDATE_PTR(ptr, Ltas);
        GUARD_NAN_RANGE(env_min, env_max);
        GUARD_NAN_RANGE(peak_min, peak_max);
        return Ltas_getLocalPeakHeight(ptr.get(), env_min, env_max, peak_min, peak_max, averaging_units);
    }

    // ========================================================================
    // Batch Operations (Performance Enhancement - 36x -> 3x improvement)
    // ========================================================================

    // Get peaks (maximum values and their frequencies) for multiple frequency ranges
    // This is 18x faster than individual calls for pharyngeal analysis
    DataFrame get_peaks_batch(NumericVector fmins, NumericVector fmaxs, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);

        int n = fmins.size();
        if (n != fmaxs.size()) {
            Rcpp::stop("fmins and fmaxs must have same length");
        }

        NumericVector peak_values(n);
        NumericVector peak_frequencies(n);
        kVector_peakInterpolation interp = static_cast<kVector_peakInterpolation>(interpolation);

        try {
            for (int i = 0; i < n; i++) {
                double fmin = fmins[i];
                double fmax = fmaxs[i];
                if (ISNAN(fmin) || ISNAN(fmax)) {
                    peak_values[i] = NA_REAL;
                    peak_frequencies[i] = NA_REAL;
                    continue;
                }
                peak_values[i] = Vector_getMaximum(ptr.get(), fmin, fmax, interp);
                peak_frequencies[i] = Vector_getXOfMaximum(ptr.get(), fmin, fmax, interp);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get peaks batch from Ltas");
        }

        return DataFrame::create(
            Named("fmin") = fmins,
            Named("fmax") = fmaxs,
            Named("peak_value") = peak_values,
            Named("peak_frequency") = peak_frequencies
        );
    }

    // Get minimum values and their frequencies for multiple frequency ranges
    DataFrame get_minima_batch(NumericVector fmins, NumericVector fmaxs, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);

        int n = fmins.size();
        if (n != fmaxs.size()) {
            Rcpp::stop("fmins and fmaxs must have same length");
        }

        NumericVector min_values(n);
        NumericVector min_frequencies(n);
        kVector_peakInterpolation interp = static_cast<kVector_peakInterpolation>(interpolation);

        try {
            for (int i = 0; i < n; i++) {
                double fmin = fmins[i];
                double fmax = fmaxs[i];
                if (ISNAN(fmin) || ISNAN(fmax)) {
                    min_values[i] = NA_REAL;
                    min_frequencies[i] = NA_REAL;
                    continue;
                }
                min_values[i] = Vector_getMinimum(ptr.get(), fmin, fmax, interp);
                min_frequencies[i] = Vector_getXOfMinimum(ptr.get(), fmin, fmax, interp);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get minima batch from Ltas");
        }

        return DataFrame::create(
            Named("fmin") = fmins,
            Named("fmax") = fmaxs,
            Named("min_value") = min_values,
            Named("min_frequency") = min_frequencies
        );
    }

    // Get values at multiple frequencies in a single call
    NumericVector get_values_at_frequencies(NumericVector frequencies, int interpolation) {
        VALIDATE_PTR(ptr, Ltas);

        int n = frequencies.size();
        NumericVector values(n);
        kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation);

        try {
            for (int i = 0; i < n; i++) {
                if (ISNAN(frequencies[i])) { values[i] = NA_REAL; continue; }
                values[i] = Vector_getValueAtX(ptr.get(), frequencies[i], 1, interp);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get values at frequencies from Ltas");
        }

        return values;
    }

    // Get means for multiple frequency ranges
    NumericVector get_means_batch(NumericVector fmins, NumericVector fmaxs, int averaging_units) {
        VALIDATE_PTR(ptr, Ltas);

        int n = fmins.size();
        if (n != fmaxs.size()) {
            Rcpp::stop("fmins and fmaxs must have same length");
        }

        NumericVector means(n);

        try {
            for (int i = 0; i < n; i++) {
                if (ISNAN(fmins[i]) || ISNAN(fmaxs[i])) { means[i] = NA_REAL; continue; }
                means[i] = Sampled_getMean(ptr.get(), fmins[i], fmaxs[i], 0, averaging_units, true);
            }
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to get means batch from Ltas");
        }

        return means;
    }

    double get_standard_deviation(double fmin, double fmax, int averaging_units) {
        VALIDATE_PTR(ptr, Ltas);
        GUARD_NAN_RANGE(fmin, fmax);
        return Sampled_getStandardDeviation(ptr.get(), fmin, fmax, 0, averaging_units, true);
    }

    // Transform
    XPtr<structLtas> compute_trend_line_ptr(double fmin, double fmax) {
        VALIDATE_PTR(ptr, Ltas);
        try {
            autoLtas result = Ltas_computeTrendLine(ptr.get(), fmin, fmax);
            Ltas raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structLtas* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structLtas>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to compute trend line");
        }
    }

    XPtr<structLtas> subtract_trend_line_ptr(double fmin, double fmax) {
        VALIDATE_PTR(ptr, Ltas);
        try {
            autoLtas result = Ltas_subtractTrendLine(ptr.get(), fmin, fmax);
            Ltas raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structLtas* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structLtas>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to subtract trend line");
        }
    }

    XPtr<structMatrix> to_matrix_ptr() {
        VALIDATE_PTR(ptr, Ltas);
        try {
            autoMatrix result = Ltas_to_Matrix(ptr.get());
            structMatrix* raw = result.releaseToAmbiguousOwner();
            // Use proper deleter for Praat objects (calls forget() instead of delete)
            auto deleter = [](structMatrix* thing) {
                if (thing != nullptr) forget(thing);
            };
            return XPtr<structMatrix>(raw, deleter);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to convert to Matrix");
        }
    }

    // Export
    DataFrame as_data_frame() {
        VALIDATE_PTR(ptr, Ltas);
        std::vector<double> freqs, values;
        for (integer i = 1; i <= ptr->nx; i++) {
            freqs.push_back(Matrix_columnToX(ptr.get(), i));
            values.push_back(ptr->z[1][i]);
        }
        return pladdrr::dt::create_datatable(
            List::create(
                Named("frequency") = freqs,
                Named("power_density") = values
            ),
            CharacterVector::create("frequency", "power_density"),
            CharacterVector::create("frequency")
        );
    }

    NumericMatrix as_matrix() {
        VALIDATE_PTR(ptr, Ltas);
        NumericMatrix mat(ptr->nx, 2);
        for (integer i = 1; i <= ptr->nx; i++) {
            mat(i-1, 0) = Matrix_columnToX(ptr.get(), i);
            mat(i-1, 1) = ptr->z[1][i];
        }
        return mat;
    }

    void save(std::string path) {
        VALIDATE_PTR(ptr, Ltas);
        try {
            structMelderFile file = {};
            Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
            Data_writeToTextFile(ptr.get(), &file);
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to save Ltas");
        }
    }
};

RCPP_MODULE(ltas_module) {
    class_<RLtas>("RLtas")
        .constructor()
        .constructor<XPtr<structLtas>>()
        .method("is_valid", &RLtas::is_valid)
        .method("get_fmin", &RLtas::get_fmin)
        .method("get_fmax", &RLtas::get_fmax)
        .method("get_frequency_range", &RLtas::get_frequency_range)
        .method("get_n_bins", &RLtas::get_n_bins)
        .method("get_df", &RLtas::get_df)
        .method("get_f1", &RLtas::get_f1)
        .method("get_number_of_bins", &RLtas::get_number_of_bins)
        .method("get_bandwidth", &RLtas::get_bandwidth)
        .method("get_frequency_from_bin", &RLtas::get_frequency_from_bin)
        .method("get_bin_from_frequency", &RLtas::get_bin_from_frequency)
        .method("get_value_at_frequency", &RLtas::get_value_at_frequency)
        .method("get_value_at_bin", &RLtas::get_value_at_bin)
        .method("get_minimum", &RLtas::get_minimum)
        .method("get_maximum", &RLtas::get_maximum)
        .method("get_frequency_of_minimum", &RLtas::get_frequency_of_minimum)
        .method("get_frequency_of_maximum", &RLtas::get_frequency_of_maximum)
        .method("get_mean", &RLtas::get_mean)
        .method("get_slope", &RLtas::get_slope)
        .method("get_local_peak_height", &RLtas::get_local_peak_height)
        .method("get_standard_deviation", &RLtas::get_standard_deviation)
        // Batch operations (18x speedup for pharyngeal analysis)
        .method("get_peaks_batch", &RLtas::get_peaks_batch)
        .method("get_minima_batch", &RLtas::get_minima_batch)
        .method("get_values_at_frequencies", &RLtas::get_values_at_frequencies)
        .method("get_means_batch", &RLtas::get_means_batch)
        .method("compute_trend_line_ptr", &RLtas::compute_trend_line_ptr)
        .method("subtract_trend_line_ptr", &RLtas::subtract_trend_line_ptr)
        .method("to_matrix_ptr", &RLtas::to_matrix_ptr)
        .method("as_data_frame", &RLtas::as_data_frame)
        .method("as_matrix", &RLtas::as_matrix)
        .method("save", &RLtas::save)
    ;
}
