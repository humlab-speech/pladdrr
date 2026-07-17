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

//' Get FormantTier start time
//' @param xptr External pointer to FormantTier
//' @return Start time in seconds
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_get_start_time)]]
double formanttier_get_start_time(SEXP xptr) {
    XPtr<structFormantTier> ft(xptr);
    if (!ft) stop("Invalid FormantTier pointer");
    return ft->xmin;
}

//' Get FormantTier end time
//' @param xptr External pointer to FormantTier
//' @return End time in seconds
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_get_end_time)]]
double formanttier_get_end_time(SEXP xptr) {
    XPtr<structFormantTier> ft(xptr);
    if (!ft) stop("Invalid FormantTier pointer");
    return ft->xmax;
}

//' Get number of points in FormantTier
//' @param xptr External pointer to FormantTier
//' @return Number of points
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_get_number_of_points)]]
int formanttier_get_number_of_points(SEXP xptr) {
    XPtr<structFormantTier> ft(xptr);
    if (!ft) stop("Invalid FormantTier pointer");
    return static_cast<int>(ft->points.size);
}

//' Get minimum number of formants
//' @param xptr External pointer to FormantTier
//' @return Minimum number of formants across points
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_get_min_num_formants)]]
int formanttier_get_min_num_formants(SEXP xptr) {
    XPtr<structFormantTier> ft(xptr);
    if (!ft) stop("Invalid FormantTier pointer");
    return static_cast<int>(FormantTier_getMinNumFormants(ft.get()));
}

//' Get maximum number of formants
//' @param xptr External pointer to FormantTier
//' @return Maximum number of formants across points
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_get_max_num_formants)]]
int formanttier_get_max_num_formants(SEXP xptr) {
    XPtr<structFormantTier> ft(xptr);
    if (!ft) stop("Invalid FormantTier pointer");
    return static_cast<int>(FormantTier_getMaxNumFormants(ft.get()));
}

//' Get formant value at time
//' @param xptr External pointer to FormantTier
//' @param formant_number Formant number (1=F1, 2=F2, etc.)
//' @param time Time in seconds
//' @return Formant frequency in Hz
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_get_value_at_time)]]
double formanttier_get_value_at_time(SEXP xptr, int formant_number, double time) {
    XPtr<structFormantTier> ft(xptr);
    if (!ft) stop("Invalid FormantTier pointer");
    return FormantTier_getValueAtTime(ft.get(), formant_number, time);
}

//' Get formant bandwidth at time
//' @param xptr External pointer to FormantTier
//' @param formant_number Formant number (1=F1, 2=F2, etc.)
//' @param time Time in seconds
//' @return Bandwidth in Hz
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_get_bandwidth_at_time)]]
double formanttier_get_bandwidth_at_time(SEXP xptr, int formant_number, double time) {
    XPtr<structFormantTier> ft(xptr);
    if (!ft) stop("Invalid FormantTier pointer");
    return FormantTier_getBandwidthAtTime(ft.get(), formant_number, time);
}

// ==============================================================================
// Filtering
// ==============================================================================

//' Filter Sound through FormantTier
//' @param sound_xptr External pointer to Sound
//' @param ft_xptr External pointer to FormantTier
//' @return External pointer to filtered Sound
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_filter_sound)]]
SEXP formanttier_filter_sound(SEXP sound_xptr, SEXP ft_xptr) {
    XPtr<structSound> sound(sound_xptr);
    XPtr<structFormantTier> ft(ft_xptr);
    if (!sound) stop("Invalid Sound pointer");
    if (!ft) stop("Invalid FormantTier pointer");

    try {
        autoSound result = Sound_FormantTier_filter(sound.get(), ft.get());
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to filter Sound: " + error_msg);
    }
    return R_NilValue;
}

//' Filter Sound through FormantTier (no scaling)
//' @param sound_xptr External pointer to Sound
//' @param ft_xptr External pointer to FormantTier
//' @return External pointer to filtered Sound
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formanttier_filter_sound_noscale)]]
SEXP formanttier_filter_sound_noscale(SEXP sound_xptr, SEXP ft_xptr) {
    XPtr<structSound> sound(sound_xptr);
    XPtr<structFormantTier> ft(ft_xptr);
    if (!sound) stop("Invalid Sound pointer");
    if (!ft) stop("Invalid FormantTier pointer");

    try {
        autoSound result = Sound_FormantTier_filter_noscale(sound.get(), ft.get());
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to filter Sound: " + error_msg);
    }
    return R_NilValue;
}
