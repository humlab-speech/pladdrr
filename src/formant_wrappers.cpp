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
// formant_wrappers.cpp
// C++ wrappers for Praat Formant object
// Part of the speaker package

// [[Rcpp::interfaces(r, cpp)]]
// [[Rcpp::plugins(cpp17)]]

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"
#include "datatable_utils.h"

// Praat headers
#include "fon/Formant.h"
#include "fon/Sound.h"
#include "fon/Sound_to_Formant.h"
#include "stat/Table.h"
#include "melder/melder.h"

using namespace Rcpp;

// Forward declarations
extern void NUMmachar();  // NUMfpp initialization
extern void NUMrandom_initializeSafelyAndUnpredictably();  // RNG initialization

// Helper function to ensure all numeric libraries are initialized
static void ensure_numeric_libs_initialized() {
    static bool initialized = false;
    if (!initialized) {
        NUMmachar();
        NUMrandom_initializeSafelyAndUnpredictably();
        initialized = true;
    }
}

// ============================================================================
// Creation methods
// ============================================================================

// [[Rcpp::export(.formant_from_sound_keepall)]]
XPtr<structFormant> formant_from_sound_keepall(
    XPtr<structSound> sound,
    double time_step,
    double max_number_of_formants,
    double maximum_formant,
    double window_length,
    double pre_emphasis_from
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    // Ensure NUMfpp is initialized
    ensure_numeric_libs_initialized();
    
    try {
        autoFormant formant = Sound_to_Formant_keepAll(
            sound.get(),
            time_step,
            max_number_of_formants,
            maximum_formant,
            window_length,
            pre_emphasis_from
        );
        return create_xptr_from_auto<structFormant>(formant);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract formants (keep all)");
    }
}

// [[Rcpp::export(.formant_from_sound_willems)]]
XPtr<structFormant> formant_from_sound_willems(
    XPtr<structSound> sound,
    double time_step,
    double number_of_formants,
    double maximum_formant,
    double window_length,
    double pre_emphasis_from
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    // Ensure NUMfpp is initialized
    ensure_numeric_libs_initialized();
    
    try {
        autoFormant formant = Sound_to_Formant_willems(
            sound.get(),
            time_step,
            number_of_formants,
            maximum_formant,
            window_length,
            pre_emphasis_from
        );
        return create_xptr_from_auto<structFormant>(formant);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract formants using Willems method");
    }
}

// [[Rcpp::export(.formant_from_sound_sl)]]
XPtr<structFormant> formant_from_sound_sl(
    XPtr<structSound> sound,
    double time_step,
    int number_of_poles,
    double maximum_formant,
    double window_length,
    double pre_emphasis_from
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    // Ensure NUMfpp is initialized
    ensure_numeric_libs_initialized();
    
    try {
        // which = 2 for Split-Levinson method
        autoFormant formant = Sound_to_Formant_any(
            sound.get(),
            time_step,
            number_of_poles,
            maximum_formant,
            window_length,
            2,  // Split-Levinson
            pre_emphasis_from,
            50.0  // safety margin
        );
        return create_xptr_from_auto<structFormant>(formant);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract formants using Split-Levinson method");
    }
}

// ============================================================================
// Query methods - Time domain
// ============================================================================

// ============================================================================
// Query methods - Formant values
// ============================================================================

// [[Rcpp::export(.formant_get_all_values_at_time)]]
Rcpp::NumericVector formant_get_all_values_at_time(
    Rcpp::XPtr<structFormant> formant,
    double time,
    int max_formants,
    int unit
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");

    try {
        Rcpp::NumericVector out(max_formants);
        for (int i = 0; i < max_formants; i++) {
            out[i] = Formant_getValueAtTime(
                formant.get(),
                i + 1,
                time,
                static_cast<kFormant_unit>(unit)
            );
        }
        return out;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get all formant values at time");
    }
}

// ============================================================================
// Export methods
// ============================================================================

// ============================================================================
// Formant tracking and export
// ============================================================================

// [[Rcpp::export(.formant_tracker)]]
Rcpp::XPtr<structFormant> formant_tracker(
    Rcpp::XPtr<structFormant> formant,
    int number_of_tracks,
    double ref_f1 = 550.0,
    double ref_f2 = 1650.0,
    double ref_f3 = 2750.0,
    double ref_f4 = 3850.0,
    double ref_f5 = 4950.0,
    double frequency_cost = 1.0,
    double bandwidth_cost = 1.0,
    double transition_cost = 1.0
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        autoFormant tracked = Formant_tracker(
            formant.get(),
            number_of_tracks,
            ref_f1, ref_f2, ref_f3, ref_f4, ref_f5,
            frequency_cost,
            bandwidth_cost,
            transition_cost
        );
        return create_xptr_from_auto<structFormant>(tracked);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to track formants");
    }
}

// [[Rcpp::export(.formant_down_to_table)]]
Rcpp::XPtr<structTable> formant_down_to_table(
    Rcpp::XPtr<structFormant> formant,
    bool include_frame_numbers = true,
    bool include_time = true,
    int time_decimals = 6,
    bool include_intensity = true,
    int intensity_decimals = 3,
    bool include_number_of_formants = true,
    int frequency_decimals = 3,
    bool include_bandwidths = true
) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        autoTable table = Formant_downto_Table(
            formant.get(),
            include_frame_numbers,
            include_time, time_decimals,
            include_intensity, intensity_decimals,
            include_number_of_formants, frequency_decimals,
            include_bandwidths
        );
        return create_xptr_from_auto<structTable>(table);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert Formant to Table");
    }
}


