// pitchtier_wrappers.cpp
// C++ wrappers for Praat PitchTier functions

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/PitchTier.h"
#include "fon/PitchTier_to_Sound.h"

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

// [[Rcpp::export(.pitchtier_get_start_time)]]
double pitchtier_get_start_time(XPtr<structPitchTier> tier) {
    if (!tier) stop("Invalid PitchTier pointer");
    return tier->xmin;
}

// [[Rcpp::export(.pitchtier_get_end_time)]]
double pitchtier_get_end_time(XPtr<structPitchTier> tier) {
    if (!tier) stop("Invalid PitchTier pointer");
    return tier->xmax;
}

// [[Rcpp::export(.pitchtier_get_number_of_points)]]
int pitchtier_get_number_of_points(XPtr<structPitchTier> tier) {
    if (!tier) stop("Invalid PitchTier pointer");
    return tier->points.size;
}

// [[Rcpp::export(.pitchtier_get_time_from_index)]]
double pitchtier_get_time_from_index(XPtr<structPitchTier> tier, int index) {
    if (!tier) stop("Invalid PitchTier pointer");
    if (index < 1 || index > tier->points.size) {
        stop("Point index out of range");
    }
    return tier->points.at[index]->number;
}

// [[Rcpp::export(.pitchtier_get_value_at_index)]]
double pitchtier_get_value_at_index(XPtr<structPitchTier> tier, int index) {
    if (!tier) stop("Invalid PitchTier pointer");
    if (index < 1 || index > tier->points.size) {
        stop("Point index out of range");
    }
    return tier->points.at[index]->value;
}

// [[Rcpp::export(.pitchtier_get_value_at_time)]]
double pitchtier_get_value_at_time(XPtr<structPitchTier> tier, double time) {
    if (!tier) stop("Invalid PitchTier pointer");
    
    try {
        double value = RealTier_getValueAtTime(tier.get(), time);
        if (isundef(value)) {
            return NA_REAL;
        }
        return value;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pitchtier_get_mean)]]
double pitchtier_get_mean(XPtr<structPitchTier> tier, double tmin, double tmax) {
    if (!tier) stop("Invalid PitchTier pointer");
    
    try {
        return RealTier_getMean_curve(tier.get(), tmin, tmax);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to compute mean");
    }
}

// ============================================================================
// MODIFICATION METHODS
// ============================================================================

// [[Rcpp::export(.pitchtier_add_point)]]
void pitchtier_add_point(XPtr<structPitchTier> tier, double time, double value) {
    if (!tier) stop("Invalid PitchTier pointer");
    
    try {
        RealTier_addPoint(tier.get(), time, value);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to add point");
    }
}

// [[Rcpp::export(.pitchtier_remove_point)]]
void pitchtier_remove_point(XPtr<structPitchTier> tier, int index) {
    if (!tier) stop("Invalid PitchTier pointer");
    
    try {
        if (index < 1 || index > tier->points.size) {
            stop("Point index out of range");
        }
        tier->points.removeItem(index);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to remove point");
    }
}

// [[Rcpp::export(.pitchtier_remove_points_between)]]
void pitchtier_remove_points_between(XPtr<structPitchTier> tier, double tmin, double tmax) {
    if (!tier) stop("Invalid PitchTier pointer");
    
    try {
        AnyTier_removePointsBetween(tier.get()->asAnyTier(), tmin, tmax);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to remove points");
    }
}

// [[Rcpp::export(.pitchtier_multiply_frequencies)]]
void pitchtier_multiply_frequencies(XPtr<structPitchTier> tier, double factor) {
    if (!tier) stop("Invalid PitchTier pointer");
    
    try {
        PitchTier_multiplyFrequencies(tier.get(), tier->xmin, tier->xmax, factor);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to multiply frequencies");
    }
}

// [[Rcpp::export(.pitchtier_shift_frequencies)]]
void pitchtier_shift_frequencies(XPtr<structPitchTier> tier, double shift) {
    if (!tier) stop("Invalid PitchTier pointer");
    
    try {
        PitchTier_shiftFrequencies(tier.get(), tier->xmin, tier->xmax, shift, kPitch_unit::kPitch_unit_HERTZ);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to shift frequencies");
    }
}

// [[Rcpp::export(.pitchtier_stylize)]]
void pitchtier_stylize(XPtr<structPitchTier> tier, double frequency_resolution, bool use_semitones) {
    if (!tier) stop("Invalid PitchTier pointer");
    
    try {
        PitchTier_stylize(tier.get(), frequency_resolution, use_semitones);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to stylize");
    }
}

// ============================================================================
// I/O METHODS
// ============================================================================

// [[Rcpp::export(.pitchtier_save)]]
void pitchtier_save(XPtr<structPitchTier> tier, std::string path) {
    if (!tier) stop("Invalid PitchTier pointer");
    
    try {
        MelderFile file = {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        Data_writeToTextFile(tier.get(), &file);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to save PitchTier");
    }
}

// [[Rcpp::export(.pitchtier_read)]]
SEXP pitchtier_read(std::string path) {
    try {
        MelderFile file = {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        autoPitchTier tier = Data_readFromTextFile(&file).static_cast_move<structPitchTier>();
        return create_xptr_from_auto<structPitchTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to read PitchTier");
    }
}
