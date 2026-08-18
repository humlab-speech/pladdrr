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
// formanttier_wrappers.cpp
// Rcpp wrappers for Praat FormantTier functionality

#include <Rcpp.h>
#include "praat_types.h"
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

#include "fon/FormantTier.h"
#include "fon/Formant.h"
#include "fon/Sound.h"

using namespace Rcpp;

// ==============================================================================
// Creation
// ==============================================================================

//' Create an empty FormantTier
//' @param tmin Start time
//' @param tmax End time
//' @return External pointer to FormantTier
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_create)]]
SEXP formanttier_create(double tmin, double tmax) {
    if (tmax <= tmin) stop("tmax must be greater than tmin");

    try {
        autoFormantTier ft = FormantTier_create(tmin, tmax);
        return create_xptr_from_auto<structFormantTier>(ft);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to create FormantTier: " + error_msg);
    }
    return R_NilValue;
}

//' Create FormantTier from Formant (downsample)
//' @param xptr External pointer to Formant
//' @return External pointer to FormantTier
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_from_formant)]]
SEXP formanttier_from_formant(SEXP xptr) {
    XPtr<structFormant> formant(xptr);
    if (!formant) stop("Invalid Formant pointer");

    try {
        autoFormantTier ft = Formant_downto_FormantTier(formant.get());
        return create_xptr_from_auto<structFormantTier>(ft);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to create FormantTier from Formant: " + error_msg);
    }
    return R_NilValue;
}

// ==============================================================================
// Query
// ==============================================================================

// ==============================================================================
// Filtering
// ==============================================================================

