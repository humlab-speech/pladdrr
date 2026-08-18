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
// pitchtier_wrappers.cpp
// C++ wrappers for Praat PitchTier functions

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/PitchTier.h"
#include "fon/PitchTier_to_Sound.h"
#include "fon/RealTier.h"
#include "fon/Sound.h"
#include "fon/Pitch.h"
#include "dwtools/Pitch_extensions.h"

using namespace Rcpp;

// ============================================================================
// CREATION
// ============================================================================

// [[Rcpp::export(.pitchtier_create)]]
SEXP pitchtier_create(double tmin, double tmax) {
    try {
        autoPitchTier tier = PitchTier_create(tmin, tmax);
        return create_xptr_from_auto<structPitchTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create PitchTier");
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

// [[Rcpp::export(.pitchtier_read)]]
SEXP pitchtier_read(std::string path) {
    try {
        structMelderFile file = {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        autoPitchTier tier = Data_readFromTextFile(&file).static_cast_move<structPitchTier>();
        return create_xptr_from_auto<structPitchTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to read PitchTier");
    }
}

// ============================================================================
// ADVANCED MODIFICATION METHODS
// ============================================================================

// [[Rcpp::export(.pitchtier_interpolate_quadratically)]]
void pitchtier_interpolate_quadratically(XPtr<structPitchTier> tier,
                                          int points_per_parabola,
                                          bool logarithmically) {
    if (!tier) stop("Invalid PitchTier pointer");

    try {
        RealTier_interpolateQuadratically(tier.get(),
                                          static_cast<integer>(points_per_parabola),
                                          logarithmically);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to interpolate quadratically");
    }
}

// ============================================================================
// CONVERSION METHODS - Sound synthesis
// ============================================================================

// [[Rcpp::export(.pitchtier_to_sound_pulse_train)]]
SEXP pitchtier_to_sound_pulse_train(XPtr<structPitchTier> tier,
                                     double sampling_frequency,
                                     double adapt_factor,
                                     double adapt_time,
                                     int interpolation_depth) {
    if (!tier) stop("Invalid PitchTier pointer");

    try {
        autoSound sound = PitchTier_to_Sound_pulseTrain(
            tier.get(),
            sampling_frequency,
            adapt_factor,
            adapt_time,
            static_cast<integer>(interpolation_depth),
            false  // hum = false for pulse train
        );
        return create_xptr_from_auto<structSound>(sound);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert PitchTier to pulse train sound");
    }
}

// [[Rcpp::export(.pitchtier_to_sound_phonation)]]
SEXP pitchtier_to_sound_phonation(XPtr<structPitchTier> tier,
                                   double sampling_frequency,
                                   double adapt_factor,
                                   double maximum_period,
                                   double open_phase,
                                   double collision_phase,
                                   double power1,
                                   double power2) {
    if (!tier) stop("Invalid PitchTier pointer");

    try {
        autoSound sound = PitchTier_to_Sound_phonation(
            tier.get(),
            sampling_frequency,
            adapt_factor,
            maximum_period,
            open_phase,
            collision_phase,
            power1,
            power2,
            false  // hum = false
        );
        return create_xptr_from_auto<structSound>(sound);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert PitchTier to phonation sound");
    }
}

// [[Rcpp::export(.pitchtier_to_sound_sine)]]
SEXP pitchtier_to_sound_sine(XPtr<structPitchTier> tier,
                              double tmin,
                              double tmax,
                              double sampling_frequency) {
    if (!tier) stop("Invalid PitchTier pointer");

    try {
        autoSound sound = PitchTier_to_Sound_sine(
            tier.get(),
            tmin,
            tmax,
            sampling_frequency
        );
        return create_xptr_from_auto<structSound>(sound);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert PitchTier to sine sound");
    }
}

// ============================================================================
// CONVERSION METHODS - Pitch
// ============================================================================

// [[Rcpp::export(.pitchtier_to_pitch)]]
SEXP pitchtier_to_pitch(XPtr<structPitchTier> tier,
                         double time_step,
                         double pitch_floor,
                         double pitch_ceiling) {
    if (!tier) stop("Invalid PitchTier pointer");

    try {
        autoPitch pitch = PitchTier_to_Pitch(
            tier.get(),
            time_step,
            pitch_floor,
            pitch_ceiling
        );
        return create_xptr_from_auto<structPitch>(pitch);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert PitchTier to Pitch");
    }
}
