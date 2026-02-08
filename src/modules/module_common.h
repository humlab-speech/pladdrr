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
// module_common.h - Shared utilities for Rcpp Modules
//
// Provides common macros, includes, and utilities used across all pladdrr modules.

#ifndef PLADDRR_MODULE_COMMON_H
#define PLADDRR_MODULE_COMMON_H

#include <Rcpp.h>
#include "../praat_xptr_utils.h"
#include "../praat_types.h"
#include "../praat_error_handling.h"

// ============================================================================
// Pointer Validation Macros
// ============================================================================

// Validate pointer and stop with informative error if invalid
#define VALIDATE_PTR(ptr, type) \
    if (!ptr || ptr.get() == nullptr) \
        Rcpp::stop("Invalid " #type " pointer")

// Validate pointer and return NA if invalid (for property getters)
#define VALIDATE_PTR_OR_NA(ptr, na_value) \
    if (!ptr || ptr.get() == nullptr) return na_value

// ============================================================================
// Range Validation
// ============================================================================

#define VALIDATE_FRAME_RANGE(ptr, frame_number) \
    if (frame_number < 1 || frame_number > ptr->nx) \
        Rcpp::stop("Frame number out of range [1, %d]: %d", ptr->nx, frame_number)

#define VALIDATE_CHANNEL_RANGE(ptr, channel) \
    if (channel < 1 || channel > ptr->ny) \
        Rcpp::stop("Channel out of range [1, %d]: %d", ptr->ny, channel)

// ============================================================================
// NaN/NA Input Guards
// ============================================================================

// Return NA_REAL for scalar NaN/NA input (prevents C++ exceptions from Praat)
#define GUARD_NAN_SCALAR(val) if (ISNAN(val)) return NA_REAL

// Return NA_REAL for range queries with NaN/NA bounds
#define GUARD_NAN_RANGE(a, b) if (ISNAN(a) || ISNAN(b)) return NA_REAL

// ============================================================================
// Unit Conversion Helpers
// ============================================================================

// Common unit codes used across Praat objects
// These match Praat's internal enums
namespace PlaadrrUnits {
    // Pitch/frequency units
    constexpr int HERTZ = 0;
    constexpr int SEMITONES = 1;
    constexpr int MEL = 2;
    constexpr int ERB = 3;
    constexpr int LOGHERTZ = 4;

    // Intensity units
    constexpr int DB = 0;
    constexpr int ENERGY = 1;
    constexpr int SONES = 2;

    // Interpolation methods
    constexpr int NEAREST = 0;
    constexpr int LINEAR = 1;
    constexpr int CUBIC = 2;
    constexpr int SINC70 = 3;
    constexpr int SINC700 = 4;
}

// ============================================================================
// Module Registration Helper
// ============================================================================

// Helper macro for exposing a class with standard properties
#define EXPOSE_PRAAT_CLASS(name, class_type) \
    Rcpp::class_<class_type>(name) \
        .constructor() \
        .property("is_valid", &class_type::is_valid, "Check if object pointer is valid")

// ============================================================================
// Data Frame Construction Helpers
// ============================================================================

// Create a named numeric vector (helper for DataFrame construction)
inline Rcpp::NumericVector named_numeric(const char* name, Rcpp::NumericVector& vec) {
    vec.attr("names") = Rcpp::CharacterVector::create(name);
    return vec;
}

#endif // PLADDRR_MODULE_COMMON_H
