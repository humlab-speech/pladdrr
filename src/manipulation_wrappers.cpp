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
// manipulation_wrappers.cpp
// C++ wrappers for Praat Manipulation functions

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/Manipulation.h"
#include "fon/PitchTier.h"
#include "fon/DurationTier.h"
#include "fon/PointProcess.h"
#include "fon/Sound.h"

using namespace Rcpp;

// ============================================================================
// CREATION
// ============================================================================

// [[Rcpp::export(.manipulation_from_sound)]]
SEXP manipulation_from_sound(XPtr<structSound> sound, double time_step, 
                              double pitch_floor, double pitch_ceiling) {
    if (!sound) stop("Invalid Sound pointer");
    
    try {
        autoManipulation manip = Sound_to_Manipulation(
            sound.get(), time_step, pitch_floor, pitch_ceiling
        );
        return create_xptr_from_auto<structManipulation>(manip);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create Manipulation from Sound");
    }
}

// ============================================================================
// QUERY METHODS
// ============================================================================

// ============================================================================
// EXTRACT TIERS
// ============================================================================

// [[Rcpp::export(.manipulation_extract_pitch_tier)]]
SEXP manipulation_extract_pitch_tier(XPtr<structManipulation> manip) {
    if (!manip) stop("Invalid Manipulation pointer");
    
    try {
        if (!manip->pitch) {
            stop("No pitch tier in Manipulation");
        }
        autoPitchTier tier = Data_copy(manip->pitch.get());
        return create_xptr_from_auto<structPitchTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract PitchTier");
    }
}

// [[Rcpp::export(.manipulation_extract_duration_tier)]]
SEXP manipulation_extract_duration_tier(XPtr<structManipulation> manip) {
    if (!manip) stop("Invalid Manipulation pointer");
    
    try {
        if (!manip->duration) {
            stop("No duration tier in Manipulation");
        }
        autoDurationTier tier = Data_copy(manip->duration.get());
        return create_xptr_from_auto<structDurationTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract DurationTier");
    }
}

// [[Rcpp::export(.manipulation_extract_pulses)]]
SEXP manipulation_extract_pulses(XPtr<structManipulation> manip) {
    if (!manip) stop("Invalid Manipulation pointer");
    
    try {
        if (!manip->pulses) {
            stop("No pulses in Manipulation");
        }
        autoPointProcess pp = Data_copy(manip->pulses.get());
        return create_xptr_from_auto<structPointProcess>(pp);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract pulses");
    }
}

// [[Rcpp::export(.manipulation_extract_original_sound)]]
SEXP manipulation_extract_original_sound(XPtr<structManipulation> manip) {
    if (!manip) stop("Invalid Manipulation pointer");
    
    try {
        if (!manip->sound) {
            stop("No original sound in Manipulation");
        }
        autoSound sound = Data_copy(manip->sound.get());
        return create_xptr_from_auto<structSound>(sound);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract original sound");
    }
}

// ============================================================================
// REPLACE TIERS
// ============================================================================

// ============================================================================
// SYNTHESIS METHODS
// ============================================================================

// [[Rcpp::export(.manipulation_get_resynthesis_overlap_add)]]
SEXP manipulation_get_resynthesis_overlap_add(XPtr<structManipulation> manip) {
    if (!manip) stop("Invalid Manipulation pointer");
    
    try {
        autoSound sound = Manipulation_to_Sound(manip.get(), 
                                                  Manipulation_OVERLAPADD);
        return create_xptr_from_auto<structSound>(sound);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to resynthesize sound (overlap-add)");
    }
}

// LPC resynthesis disabled - requires LPC module not available in current Praat version
// // [[Rcpp::export(.manipulation_get_resynthesis_lpc)]]
// SEXP manipulation_get_resynthesis_lpc(XPtr<structManipulation> manip) {
//     if (!manip) stop("Invalid Manipulation pointer");
//     
//     try {
//         autoSound sound = Manipulation_to_Sound(manip.get(), Manipulation_PULSES_LPC);
//         return create_xptr_from_auto<structSound>(sound);
//     } catch (MelderError) {
//         Melder_clearError();
//         stop("Failed to resynthesize sound (LPC)");
//     }
// }
