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
// longsound_wrappers.cpp
// Rcpp wrappers for Praat LongSound functionality that fall outside the
// per-instance RLongSound module (see modules/longsound_module.cpp):
// construction (needed before an RLongSound wrapper can exist) and the
// buffer-size preference (global state, not tied to one LongSound instance).

#include <Rcpp.h>
#include "praat_types.h"
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

#include "fon/LongSound.h"

using namespace Rcpp;

// ==============================================================================
// Creation
// ==============================================================================

//' Open a LongSound from file
//' @param path Path to audio file
//' @return External pointer to LongSound
//' @keywords internal
//' @noRd
// [[Rcpp::export(.longsound_open)]]
SEXP longsound_open(std::string path) {
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_8to32(path.c_str()).get(), &file);
        autoLongSound ls = LongSound_open(&file);
        return create_xptr_from_auto<structLongSound>(ls);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to open LongSound: " + error_msg);
    }
    return R_NilValue;
}

// ==============================================================================
// Buffer size preference (global, applies to every LongSound opened afterward)
// ==============================================================================

//' Get the LongSound streaming buffer size preference
//' @return Buffer size in seconds
//' @keywords internal
//' @noRd
// [[Rcpp::export(.longsound_get_buffer_size_pref_seconds)]]
double longsound_get_buffer_size_pref_seconds() {
    return static_cast<double>(LongSound_getBufferSizePref_seconds());
}

//' Set the LongSound streaming buffer size preference
//' @param seconds Buffer size in seconds
//' @keywords internal
//' @noRd
// [[Rcpp::export(.longsound_set_buffer_size_pref_seconds)]]
void longsound_set_buffer_size_pref_seconds(double seconds) {
    LongSound_setBufferSizePref_seconds(static_cast<integer>(seconds));
}
