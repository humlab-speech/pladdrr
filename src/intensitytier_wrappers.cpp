// intensitytier_wrappers.cpp
// C++ wrappers for Praat IntensityTier functions

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/IntensityTier.h"

using namespace Rcpp;

// ============================================================================
// CREATION
// ============================================================================

// [[Rcpp::export(.intensitytier_create)]]
SEXP intensitytier_create(double tmin, double tmax) {
    try {
        autoIntensityTier tier = IntensityTier_create(tmin, tmax);
        return create_xptr_from_auto<structIntensityTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create IntensityTier");
    }
}

// ============================================================================
// QUERY METHODS
// ============================================================================

// [[Rcpp::export(.intensitytier_get_start_time)]]
double intensitytier_get_start_time(XPtr<structIntensityTier> tier) {
    if (!tier) stop("Invalid IntensityTier pointer");
    return tier->xmin;
}

// [[Rcpp::export(.intensitytier_get_end_time)]]
double intensitytier_get_end_time(XPtr<structIntensityTier> tier) {
    if (!tier) stop("Invalid IntensityTier pointer");
    return tier->xmax;
}

// [[Rcpp::export(.intensitytier_get_number_of_points)]]
int intensitytier_get_number_of_points(XPtr<structIntensityTier> tier) {
    if (!tier) stop("Invalid IntensityTier pointer");
    return tier->points.size;
}

// [[Rcpp::export(.intensitytier_get_time_from_index)]]
double intensitytier_get_time_from_index(XPtr<structIntensityTier> tier, int index) {
    if (!tier) stop("Invalid IntensityTier pointer");
    if (index < 1 || index > tier->points.size) {
        stop("Point index out of range");
    }
    return tier->points.at[index]->number;
}

// [[Rcpp::export(.intensitytier_get_value_at_index)]]
double intensitytier_get_value_at_index(XPtr<structIntensityTier> tier, int index) {
    if (!tier) stop("Invalid IntensityTier pointer");
    if (index < 1 || index > tier->points.size) {
        stop("Point index out of range");
    }
    return tier->points.at[index]->value;
}

// [[Rcpp::export(.intensitytier_get_value_at_time)]]
double intensitytier_get_value_at_time(XPtr<structIntensityTier> tier, double time) {
    if (!tier) stop("Invalid IntensityTier pointer");
    
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

// [[Rcpp::export(.intensitytier_get_mean)]]
double intensitytier_get_mean(XPtr<structIntensityTier> tier, double tmin, double tmax) {
    if (!tier) stop("Invalid IntensityTier pointer");
    
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

// [[Rcpp::export(.intensitytier_add_point)]]
void intensitytier_add_point(XPtr<structIntensityTier> tier, double time, double value) {
    if (!tier) stop("Invalid IntensityTier pointer");
    
    try {
        RealTier_addPoint(tier.get(), time, value);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to add point");
    }
}

// [[Rcpp::export(.intensitytier_remove_point)]]
void intensitytier_remove_point(XPtr<structIntensityTier> tier, int index) {
    if (!tier) stop("Invalid IntensityTier pointer");
    
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

// [[Rcpp::export(.intensitytier_save)]]
void intensitytier_save(XPtr<structIntensityTier> tier, std::string path) {
    if (!tier) stop("Invalid IntensityTier pointer");
    
    try {
        MelderFile file = {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        Data_writeToTextFile(tier.get(), &file);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to save IntensityTier");
    }
}

// [[Rcpp::export(.intensitytier_read)]]
SEXP intensitytier_read(std::string path) {
    try {
        MelderFile file = {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        autoIntensityTier tier = Data_readFromTextFile(&file).static_cast_move<structIntensityTier>();
        return create_xptr_from_auto<structIntensityTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to read IntensityTier");
    }
}
