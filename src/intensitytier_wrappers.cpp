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
// intensitytier_wrappers.cpp
// C++ wrappers for Praat IntensityTier functions

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/IntensityTier.h"

using namespace Rcpp;

// ============================================================================
// CREATION
// ============================================================================

// [[Rcpp::export(.intensitytier_create)]]
SEXP intensitytier_create(double tmin, double tmax) {
    try {
        autoIntensityTier tier = IntensityTier_create(tmin, tmax);
        return create_xptr_from_auto<structIntensityTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create IntensityTier");
    }
}

// ============================================================================
// QUERY METHODS
// ============================================================================

// ============================================================================
// MODIFICATION METHODS
// ============================================================================

// ============================================================================
// I/O METHODS
// ============================================================================

