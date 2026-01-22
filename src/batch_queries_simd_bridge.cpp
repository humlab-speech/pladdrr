/* batch_queries_simd_bridge.cpp
 *
 * Bridge functions for integrating SIMD batch query operations with Rcpp
 *
 * Copyright (C) 2026 pladdrr development team
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or (at
 * your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 */

#include <Rcpp.h>
#include "praat.github.io/melder/melder.h"

// Forward declarations from batch_queries_simd.cpp
extern "C" {
    double calculate_mean_simd(const double* values, integer n);
    double calculate_stdev_simd(const double* values, integer n, double mean);
    void calculate_min_max_simd(const double* values, integer n, double* min_val, double* max_val);
    double calculate_quantile_simd(const double* values, integer n, double quantile);
    void calculate_batch_statistics_simd(
        const double* values, integer n,
        double* mean, double* stdev, double* min_val, double* max_val
    );
    bool should_use_simd_for_batch_queries();
}

using namespace Rcpp;

// ============================================================================
// Bridge: NumericVector to C-style array for SIMD
// ============================================================================

/**
 * Calculate mean of NumericVector with SIMD
 *
 * @param values NumericVector
 * @return Mean value
 */
// [[Rcpp::export]]
double calculate_mean_simd_bridge(NumericVector values) {
    int n = values.size();
    if (n == 0) return NA_REAL;

    // Create 1-based array
    std::vector<double> arr(n + 1);
    for (int i = 0; i < n; i++) {
        arr[i + 1] = values[i];
    }

    return calculate_mean_simd(arr.data(), n);
}

/**
 * Calculate standard deviation with SIMD
 *
 * @param values NumericVector
 * @param mean Pre-computed mean (optional, default 0.0 computes it)
 * @return Standard deviation
 */
// [[Rcpp::export]]
double calculate_stdev_simd_bridge(NumericVector values, double mean = 0.0) {
    int n = values.size();
    if (n < 2) return 0.0;

    std::vector<double> arr(n + 1);
    for (int i = 0; i < n; i++) {
        arr[i + 1] = values[i];
    }

    return calculate_stdev_simd(arr.data(), n, mean);
}

/**
 * Calculate min and max with SIMD
 *
 * @param values NumericVector
 * @return List with min and max
 */
// [[Rcpp::export]]
List calculate_min_max_simd_bridge(NumericVector values) {
    int n = values.size();
    if (n == 0) {
        return List::create(Named("min") = NA_REAL, Named("max") = NA_REAL);
    }

    std::vector<double> arr(n + 1);
    for (int i = 0; i < n; i++) {
        arr[i + 1] = values[i];
    }

    double min_val, max_val;
    calculate_min_max_simd(arr.data(), n, &min_val, &max_val);

    return List::create(Named("min") = min_val, Named("max") = max_val);
}

/**
 * Calculate quantile with SIMD-optimized sorting
 *
 * @param values NumericVector
 * @param quantile Quantile value (0.0 to 1.0)
 * @return Quantile value
 */
// [[Rcpp::export]]
double calculate_quantile_simd_bridge(NumericVector values, double quantile) {
    int n = values.size();
    if (n == 0) return NA_REAL;

    std::vector<double> arr(n + 1);
    for (int i = 0; i < n; i++) {
        arr[i + 1] = values[i];
    }

    return calculate_quantile_simd(arr.data(), n, quantile);
}

/**
 * Calculate all basic statistics in one pass with SIMD
 *
 * @param values NumericVector
 * @return List with mean, stdev, min, max
 */
// [[Rcpp::export]]
List calculate_batch_statistics_simd_bridge(NumericVector values) {
    int n = values.size();
    if (n == 0) {
        return List::create(
            Named("mean") = NA_REAL,
            Named("stdev") = NA_REAL,
            Named("min") = NA_REAL,
            Named("max") = NA_REAL
        );
    }

    std::vector<double> arr(n + 1);
    for (int i = 0; i < n; i++) {
        arr[i + 1] = values[i];
    }

    double mean, stdev, min_val, max_val;
    calculate_batch_statistics_simd(arr.data(), n, &mean, &stdev, &min_val, &max_val);

    return List::create(
        Named("mean") = mean,
        Named("stdev") = stdev,
        Named("min") = min_val,
        Named("max") = max_val
    );
}

// ============================================================================
// Bridge: Batch Interval Statistics
// ============================================================================

/**
 * Calculate statistics for multiple intervals with SIMD
 * Optimized for batch processing of interval-based metrics
 *
 * @param intervals_values List of NumericVectors, one per interval
 * @param metric String: "mean", "stdev", "min", "max", or "all"
 * @return NumericVector or NumericMatrix depending on metric
 */
// [[Rcpp::export]]
SEXP calculate_interval_statistics_simd_bridge(List intervals_values, String metric) {
    int n_intervals = intervals_values.size();
    if (n_intervals == 0) {
        return NumericVector(0);
    }

    std::string metric_str = metric.get_cstring();

    if (metric_str == "all") {
        // Return matrix with all statistics
        NumericMatrix result(n_intervals, 4);
        colnames(result) = CharacterVector::create("mean", "stdev", "min", "max");

        for (int i = 0; i < n_intervals; i++) {
            NumericVector values = as<NumericVector>(intervals_values[i]);
            int n = values.size();

            if (n == 0) {
                result(i, 0) = NA_REAL;
                result(i, 1) = NA_REAL;
                result(i, 2) = NA_REAL;
                result(i, 3) = NA_REAL;
                continue;
            }

            std::vector<double> arr(n + 1);
            for (int j = 0; j < n; j++) {
                arr[j + 1] = values[j];
            }

            double mean, stdev, min_val, max_val;
            calculate_batch_statistics_simd(arr.data(), n, &mean, &stdev, &min_val, &max_val);

            result(i, 0) = mean;
            result(i, 1) = stdev;
            result(i, 2) = min_val;
            result(i, 3) = max_val;
        }

        return result;
    } else {
        // Return vector with single metric
        NumericVector result(n_intervals);

        for (int i = 0; i < n_intervals; i++) {
            NumericVector values = as<NumericVector>(intervals_values[i]);
            int n = values.size();

            if (n == 0) {
                result[i] = NA_REAL;
                continue;
            }

            std::vector<double> arr(n + 1);
            for (int j = 0; j < n; j++) {
                arr[j + 1] = values[j];
            }

            if (metric_str == "mean") {
                result[i] = calculate_mean_simd(arr.data(), n);
            } else if (metric_str == "stdev") {
                double mean = calculate_mean_simd(arr.data(), n);
                result[i] = calculate_stdev_simd(arr.data(), n, mean);
            } else if (metric_str == "min" || metric_str == "max") {
                double min_val, max_val;
                calculate_min_max_simd(arr.data(), n, &min_val, &max_val);
                result[i] = (metric_str == "min") ? min_val : max_val;
            } else {
                stop("Unknown metric: " + metric_str);
            }
        }

        return result;
    }
}

/**
 * Calculate multiple quantiles for multiple intervals with SIMD
 *
 * @param intervals_values List of NumericVectors
 * @param quantiles NumericVector of quantile values (e.g., c(0.25, 0.50, 0.75))
 * @return NumericMatrix with intervals as rows, quantiles as columns
 */
// [[Rcpp::export]]
NumericMatrix calculate_interval_quantiles_simd_bridge(
    List intervals_values,
    NumericVector quantiles
) {
    int n_intervals = intervals_values.size();
    int n_quantiles = quantiles.size();

    NumericMatrix result(n_intervals, n_quantiles);

    for (int i = 0; i < n_intervals; i++) {
        NumericVector values = as<NumericVector>(intervals_values[i]);
        int n = values.size();

        if (n == 0) {
            for (int q = 0; q < n_quantiles; q++) {
                result(i, q) = NA_REAL;
            }
            continue;
        }

        std::vector<double> arr(n + 1);
        for (int j = 0; j < n; j++) {
            arr[j + 1] = values[j];
        }

        for (int q = 0; q < n_quantiles; q++) {
            result(i, q) = calculate_quantile_simd(arr.data(), n, quantiles[q]);
        }
    }

    // Set column names
    CharacterVector col_names(n_quantiles);
    for (int q = 0; q < n_quantiles; q++) {
        std::ostringstream ss;
        ss << "q" << quantiles[q];
        col_names[q] = ss.str();
    }
    colnames(result) = col_names;

    return result;
}

/**
 * Check if SIMD should be used for batch queries
 *
 * @return Logical value
 */
// [[Rcpp::export]]
bool should_use_simd_for_batch_queries_bridge() {
    return should_use_simd_for_batch_queries();
}

/* End of file batch_queries_simd_bridge.cpp */
