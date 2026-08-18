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
// utils.cpp - Utility functions for Praat-R interface
//
// This file provides error handling, type conversion, and validation utilities
// for interfacing between R (via Rcpp) and Praat C code.

#include <Rcpp.h>
#include <string>
#include <stdexcept>

using namespace Rcpp;

// ============================================================================
// Error Handling Utilities
// ============================================================================

//' Convert Praat errors to R exceptions
//'
//' Wraps Praat function calls and converts Praat's error system to R exceptions
//'
//' @param error_msg Error message from Praat
//' @return This function never returns; it always raises an R error via
//'   \code{stop()}.
//' @examples
//' result <- tryCatch(
//'   pladdrr:::praat_error_to_r("example failure"),
//'   error = function(e) conditionMessage(e)
//' )
//' result
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
void praat_error_to_r(const std::string& error_msg) {
    Rcpp::stop("Praat error: " + error_msg);
}

// Safe error wrapper for Praat calls
//
// Provides a consistent error handling pattern for Praat operations
//
// @param context Description of what operation failed
// @keywords internal
void throw_praat_error(const std::string& context) {
    Rcpp::stop("Praat operation failed: " + context);
}

// ============================================================================
// Parameter Validation Utilities
// ============================================================================

// Validate positive numeric parameter
//
// Ensures a numeric parameter is positive (> 0)
//
// @param value The value to check
// @param param_name Name of the parameter for error messages
// @keywords internal
void validate_positive(double value, const std::string& param_name) {
    if (value <= 0.0) {
        Rcpp::stop("Parameter '" + param_name + "' must be positive, got: " +
                   std::to_string(value));
    }
}

// Validate non-negative numeric parameter
//
// Ensures a numeric parameter is non-negative (>= 0)
//
// @param value The value to check
// @param param_name Name of the parameter for error messages
// @keywords internal
void validate_non_negative(double value, const std::string& param_name) {
    if (value < 0.0) {
        Rcpp::stop("Parameter '" + param_name + "' must be non-negative, got: " +
                   std::to_string(value));
    }
}

// Validate numeric parameter is in range
//
// Ensures a numeric parameter falls within a specified range
//
// @param value The value to check
// @param min_val Minimum allowed value (inclusive)
// @param max_val Maximum allowed value (inclusive)
// @param param_name Name of the parameter for error messages
// @keywords internal
void validate_range(double value, double min_val, double max_val,
                   const std::string& param_name) {
    if (value < min_val || value > max_val) {
        Rcpp::stop("Parameter '" + param_name + "' must be in range [" +
                   std::to_string(min_val) + ", " + std::to_string(max_val) +
                   "], got: " + std::to_string(value));
    }
}

// Validate integer parameter is positive
//
// Ensures an integer parameter is positive (> 0)
//
// @param value The value to check
// @param param_name Name of the parameter for error messages
// @keywords internal
void validate_positive_int(int value, const std::string& param_name) {
    if (value <= 0) {
        Rcpp::stop("Parameter '" + param_name + "' must be a positive integer, got: " +
                   std::to_string(value));
    }
}

// ============================================================================
// Sound Object Validation
// ============================================================================

// Validate that an R list represents a valid sound object
//
// Checks that a list contains the required fields for a praat_sound object
//
// @param sound_obj R list representing a sound object
// @return true if valid, throws error if invalid
// @keywords internal
bool validate_sound_object(const List& sound_obj) {
    // Check required fields
    if (!sound_obj.containsElementNamed("values")) {
        Rcpp::stop("Invalid sound object: missing 'values' field");
    }
    if (!sound_obj.containsElementNamed("sampling_rate")) {
        Rcpp::stop("Invalid sound object: missing 'sampling_rate' field");
    }
    if (!sound_obj.containsElementNamed("n_samples")) {
        Rcpp::stop("Invalid sound object: missing 'n_samples' field");
    }
    if (!sound_obj.containsElementNamed("duration")) {
        Rcpp::stop("Invalid sound object: missing 'duration' field");
    }

    // Validate sampling rate
    double sr = sound_obj["sampling_rate"];
    validate_positive(sr, "sampling_rate");

    // Validate consistency
    NumericVector values = sound_obj["values"];
    int n_samples = sound_obj["n_samples"];
    double duration = sound_obj["duration"];

    if (values.size() != n_samples) {
        Rcpp::stop("Inconsistent sound object: n_samples (" +
                   std::to_string(n_samples) + ") != length(values) (" +
                   std::to_string(values.size()) + ")");
    }

    // Check duration consistency (with small tolerance for floating-point)
    double expected_duration = n_samples / sr;
    if (std::abs(duration - expected_duration) > 1e-6) {
        Rcpp::warning("Sound object duration may be inconsistent: " +
                     std::to_string(duration) + " vs expected " +
                     std::to_string(expected_duration));
    }

    return true;
}

// ============================================================================
// Pitch Object Validation
// ============================================================================

// Validate that an R list represents a valid pitch object
//
// Checks that a list contains the required fields for a praat_pitch object
//
// @param pitch_obj R list representing a pitch object
// @return true if valid, throws error if invalid
// @keywords internal
bool validate_pitch_object(const List& pitch_obj) {
    // Check class attribute
    if (!pitch_obj.hasAttribute("class")) {
        Rcpp::stop("Invalid pitch object: missing class attribute");
    }

    CharacterVector cls = pitch_obj.attr("class");
    bool has_pitch_class = false;
    for (int i = 0; i < cls.size(); i++) {
        if (as<std::string>(cls[i]) == "praat_pitch") {
            has_pitch_class = true;
            break;
        }
    }
    if (!has_pitch_class) {
        Rcpp::stop("Invalid pitch object: must have class 'praat_pitch'");
    }

    // For data.frame representation, check for time and frequency columns
    // Details will depend on final data model implementation

    return true;
}

// ============================================================================
// Type Conversion Utilities
// ============================================================================

// Convert R logical to C++ bool with NA handling
//
// Safely converts R logical values to C++ bool, handling NA as false
//
// @param x R logical value
// @param default_val Default value if NA
// @return bool value
// @keywords internal
bool logical_to_bool(LogicalVector x, bool default_val = false) {
    if (x.size() == 0) {
        return default_val;
    }
    if (LogicalVector::is_na(x[0])) {
        return default_val;
    }
    return x[0];
}

// Convert R numeric to C++ double with NA handling
//
// Safely converts R numeric values to C++ double
//
// @param x R numeric value
// @return double value (returns R_NaN if NA)
// @keywords internal
double numeric_to_double(NumericVector x) {
    if (x.size() == 0) {
        return R_NaN;
    }
    return x[0];
}
