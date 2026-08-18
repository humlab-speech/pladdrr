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
// formantgrid_wrappers.cpp
// C++ wrappers for Praat FormantGrid object
// Part of the speaker package

// [[Rcpp::interfaces(r, cpp)]]
// [[Rcpp::plugins(cpp17)]]

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/FormantGrid.h"
#include "fon/Formant.h"
#include "fon/Sound.h"
#include "melder/melder.h"

using namespace Rcpp;

// ============================================================================
// Creation methods
// ============================================================================

// [[Rcpp::export(.formantgrid_create)]]
XPtr<structFormantGrid> formantgrid_create(
    double tmin,
    double tmax,
    int number_of_formants,
    double initial_first_formant,
    double initial_formant_spacing,
    double initial_first_bandwidth,
    double initial_bandwidth_spacing
) {
    try {
        autoFormantGrid grid = FormantGrid_create(
            tmin, tmax, number_of_formants,
            initial_first_formant, initial_formant_spacing,
            initial_first_bandwidth, initial_bandwidth_spacing
        );
        return create_xptr_from_auto<structFormantGrid>(grid);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create FormantGrid");
    }
}

// [[Rcpp::export(.formantgrid_create_empty)]]
XPtr<structFormantGrid> formantgrid_create_empty(
    double tmin,
    double tmax,
    int number_of_formants
) {
    try {
        autoFormantGrid grid = FormantGrid_createEmpty(tmin, tmax, number_of_formants);
        return create_xptr_from_auto<structFormantGrid>(grid);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create empty FormantGrid");
    }
}

// [[Rcpp::export(.formantgrid_from_formant)]]
XPtr<structFormantGrid> formantgrid_from_formant(XPtr<structFormant> formant) {
    if (!formant) Rcpp::stop("Invalid Formant pointer");
    
    try {
        autoFormantGrid grid = Formant_downto_FormantGrid(formant.get());
        return create_xptr_from_auto<structFormantGrid>(grid);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert Formant to FormantGrid");
    }
}

// ============================================================================
// Query methods - Time domain
// ============================================================================

// ============================================================================
// Query methods - Formant values
// ============================================================================

// ============================================================================
// Modification methods
// ============================================================================

// ============================================================================
// Conversion methods
// ============================================================================

// [[Rcpp::export(.formantgrid_to_formant)]]
XPtr<structFormant> formantgrid_to_formant(
    XPtr<structFormantGrid> grid,
    double time_step,
    double intensity
) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        autoFormant formant = FormantGrid_to_Formant(
            grid.get(),
            time_step,
            intensity
        );
        return create_xptr_from_auto<structFormant>(formant);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert FormantGrid to Formant");
    }
}

// ============================================================================
// Synthesis methods
// ============================================================================

// [[Rcpp::export(.formantgrid_to_sound)]]
XPtr<structSound> formantgrid_to_sound(
    XPtr<structFormantGrid> grid,
    double sampling_frequency,
    double t_start, double f0_start,
    double t_mid, double f0_mid,
    double t_end, double f0_end,
    double adapt_factor, double maximum_period,
    double open_phase, double collision_phase,
    double power1, double power2
) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        autoSound sound = FormantGrid_to_Sound(
            grid.get(),
            sampling_frequency,
            t_start, f0_start,
            t_mid, f0_mid,
            t_end, f0_end,
            adapt_factor, maximum_period,
            open_phase, collision_phase,
            power1, power2
        );
        return create_xptr_from_auto<structSound>(sound);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to synthesize sound from FormantGrid");
    }
}

// ============================================================================
// Filtering methods
// ============================================================================

// [[Rcpp::export(.sound_formantgrid_filter)]]
XPtr<structSound> sound_formantgrid_filter(
    XPtr<structSound> sound,
    XPtr<structFormantGrid> grid
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        autoSound filtered = Sound_FormantGrid_filter(
            sound.get(),
            grid.get()
        );
        return create_xptr_from_auto<structSound>(filtered);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to filter sound with FormantGrid");
    }
}

