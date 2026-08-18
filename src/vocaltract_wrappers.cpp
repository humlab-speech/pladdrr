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
// vocaltract_wrappers.cpp
// Rcpp wrappers for Praat VocalTract functionality

#include <Rcpp.h>
#include "praat_types.h"
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

#include "fon/VocalTract.h"
#include "fon/VocalTract_to_Spectrum.h"

using namespace Rcpp;

// ==============================================================================
// Creation
// ==============================================================================

//' Create a VocalTract with specified sections
//' @param nx Number of sections
//' @param dx Section length in metres
//' @return External pointer to VocalTract
//' @keywords internal
//' @noRd
// [[Rcpp::export(.vocaltract_create)]]
SEXP vocaltract_create(int nx, double dx) {
    if (nx < 1) stop("nx must be >= 1");
    if (dx <= 0.0) stop("dx must be > 0");

    try {
        autoVocalTract vt = VocalTract_create(nx, dx);
        return create_xptr_from_auto<structVocalTract>(vt);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to create VocalTract: " + error_msg);
    }
    return R_NilValue;
}

//' Create VocalTract from phone specification
//' @param phone Phone name (a, e, i, o, u, y1, y2, y3, jery, p, t, k, x, pa, ta, ka, pi, ti, ki, pu, tu, ku)
//' @return External pointer to VocalTract
//' @keywords internal
//' @noRd
// [[Rcpp::export(.vocaltract_create_from_phone)]]
SEXP vocaltract_create_from_phone(std::string phone) {
    try {
        autostring32 phone32 = Melder_8to32(phone.c_str());
        autoVocalTract vt = VocalTract_createFromPhone(phone32.get());
        return create_xptr_from_auto<structVocalTract>(vt);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to create VocalTract from phone: " + error_msg);
    }
    return R_NilValue;
}

// ==============================================================================
// Query
// ==============================================================================

// ==============================================================================
// Conversion
// ==============================================================================

