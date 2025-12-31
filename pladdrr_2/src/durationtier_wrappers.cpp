// durationtier_wrappers.cpp
// C++ wrappers for Praat DurationTier functions

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/DurationTier.h"

using namespace Rcpp;

// ============================================================================
// CREATION
// ============================================================================

// [[Rcpp::export(.durationtier_create)]]
SEXP durationtier_create(double tmin, double tmax) {
    try {
        autoDurationTier tier = DurationTier_create(tmin, tmax);
        return create_xptr_from_auto<structDurationTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create DurationTier");
    }
}

// ============================================================================
// QUERY METHODS
// ============================================================================

// [[Rcpp::export(.durationtier_get_start_time)]]
double durationtier_get_start_time(XPtr<structDurationTier> tier) {
    if (!tier) stop("Invalid DurationTier pointer");
    return tier->xmin;
}

// [[Rcpp::export(.durationtier_get_end_time)]]
double durationtier_get_end_time(XPtr<structDurationTier> tier) {
    if (!tier) stop("Invalid DurationTier pointer");
    return tier->xmax;
}

// [[Rcpp::export(.durationtier_get_number_of_points)]]
int durationtier_get_number_of_points(XPtr<structDurationTier> tier) {
    if (!tier) stop("Invalid DurationTier pointer");
    return tier->points.size;
}

// [[Rcpp::export(.durationtier_get_time_from_index)]]
double durationtier_get_time_from_index(XPtr<structDurationTier> tier, int index) {
    if (!tier) stop("Invalid DurationTier pointer");
    if (index < 1 || index > tier->points.size) {
        stop("Point index out of range");
    }
    return tier->points.at[index]->number;
}

// [[Rcpp::export(.durationtier_get_value_at_index)]]
double durationtier_get_value_at_index(XPtr<structDurationTier> tier, int index) {
    if (!tier) stop("Invalid DurationTier pointer");
    if (index < 1 || index > tier->points.size) {
        stop("Point index out of range");
    }
    return tier->points.at[index]->value;
}

// [[Rcpp::export(.durationtier_get_value_at_time)]]
double durationtier_get_value_at_time(XPtr<structDurationTier> tier, double time) {
    if (!tier) stop("Invalid DurationTier pointer");
    
    try {
        double value = RealTier_getValueAtTime(tier.get(), time);
        // DurationTier defaults to 1.0 if undefined
        if (isundef(value)) {
            return 1.0;
        }
        return value;
    } catch (MelderError) {
        Melder_clearError();
        return 1.0;
    }
}

// ============================================================================
// MODIFICATION METHODS
// ============================================================================

// [[Rcpp::export(.durationtier_add_point)]]
void durationtier_add_point(XPtr<structDurationTier> tier, double time, double value) {
    if (!tier) stop("Invalid DurationTier pointer");
    
    try {
        RealTier_addPoint(tier.get(), time, value);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to add point");
    }
}

// [[Rcpp::export(.durationtier_remove_point)]]
void durationtier_remove_point(XPtr<structDurationTier> tier, int index) {
    if (!tier) stop("Invalid DurationTier pointer");
    
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

// ============================================================================
// I/O METHODS
// ============================================================================

// [[Rcpp::export(.durationtier_save)]]
void durationtier_save(XPtr<structDurationTier> tier, std::string path) {
    if (!tier) stop("Invalid DurationTier pointer");
    
    try {
        structMelderFile file = {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        Data_writeToTextFile(tier.get(), &file);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to save DurationTier");
    }
}

// [[Rcpp::export(.durationtier_read)]]
SEXP durationtier_read(std::string path) {
    try {
        structMelderFile file = {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        autoDurationTier tier = Data_readFromTextFile(&file).static_cast_move<structDurationTier>();
        return create_xptr_from_auto<structDurationTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to read DurationTier");
    }
}
