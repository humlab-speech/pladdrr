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

// [[Rcpp::export(.formantgrid_get_start_time)]]
double formantgrid_get_start_time(XPtr<structFormantGrid> grid) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    return grid->xmin;
}

// [[Rcpp::export(.formantgrid_get_end_time)]]
double formantgrid_get_end_time(XPtr<structFormantGrid> grid) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    return grid->xmax;
}

// [[Rcpp::export(.formantgrid_get_number_of_formants)]]
int formantgrid_get_number_of_formants(XPtr<structFormantGrid> grid) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    return grid->formants.size;
}

// ============================================================================
// Query methods - Formant values
// ============================================================================

// [[Rcpp::export(.formantgrid_get_formant_at_time)]]
double formantgrid_get_formant_at_time(
    XPtr<structFormantGrid> grid,
    int formant_number,
    double time
) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        double value = FormantGrid_getFormantAtTime(
            grid.get(),
            formant_number,
            time
        );
        if (isundef(value)) {
            return NA_REAL;
        }
        return value;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.formantgrid_get_bandwidth_at_time)]]
double formantgrid_get_bandwidth_at_time(
    XPtr<structFormantGrid> grid,
    int formant_number,
    double time
) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        double value = FormantGrid_getBandwidthAtTime(
            grid.get(),
            formant_number,
            time
        );
        if (isundef(value)) {
            return NA_REAL;
        }
        return value;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// ============================================================================
// Modification methods
// ============================================================================

// [[Rcpp::export(.formantgrid_add_formant_point)]]
void formantgrid_add_formant_point(
    XPtr<structFormantGrid> grid,
    int formant_number,
    double time,
    double value
) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        FormantGrid_addFormantPoint(grid.get(), formant_number, time, value);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to add formant point");
    }
}

// [[Rcpp::export(.formantgrid_add_bandwidth_point)]]
void formantgrid_add_bandwidth_point(
    XPtr<structFormantGrid> grid,
    int formant_number,
    double time,
    double value
) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        FormantGrid_addBandwidthPoint(grid.get(), formant_number, time, value);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to add bandwidth point");
    }
}

// [[Rcpp::export(.formantgrid_remove_formant_points_between)]]
void formantgrid_remove_formant_points_between(
    XPtr<structFormantGrid> grid,
    int formant_number,
    double tmin,
    double tmax
) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        FormantGrid_removeFormantPointsBetween(
            grid.get(),
            formant_number,
            tmin,
            tmax
        );
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to remove formant points");
    }
}

// [[Rcpp::export(.formantgrid_remove_bandwidth_points_between)]]
void formantgrid_remove_bandwidth_points_between(
    XPtr<structFormantGrid> grid,
    int formant_number,
    double tmin,
    double tmax
) {
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        FormantGrid_removeBandwidthPointsBetween(
            grid.get(),
            formant_number,
            tmin,
            tmax
        );
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to remove bandwidth points");
    }
}

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

// [[Rcpp::export(.sound_formantgrid_filter_noscale)]]
XPtr<structSound> sound_formantgrid_filter_noscale(
    XPtr<structSound> sound,
    XPtr<structFormantGrid> grid
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    if (!grid) Rcpp::stop("Invalid FormantGrid pointer");
    
    try {
        autoSound filtered = Sound_FormantGrid_filter_noscale(
            sound.get(),
            grid.get()
        );
        return create_xptr_from_auto<structSound>(filtered);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to filter sound with FormantGrid (no scale)");
    }
}
