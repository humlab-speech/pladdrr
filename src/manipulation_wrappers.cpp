// manipulation_wrappers.cpp
// C++ wrappers for Praat Manipulation functions

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/Manipulation.h"
#include "fon/Sound_and_Manipulation.h"
#include "fon/Manipulation_and_PitchTier.h"
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

// [[Rcpp::export(.manipulation_get_start_time)]]
double manipulation_get_start_time(XPtr<structManipulation> manip) {
    if (!manip) stop("Invalid Manipulation pointer");
    return manip->xmin;
}

// [[Rcpp::export(.manipulation_get_end_time)]]
double manipulation_get_end_time(XPtr<structManipulation> manip) {
    if (!manip) stop("Invalid Manipulation pointer");
    return manip->xmax;
}

// ============================================================================
// EXTRACT TIERS
// ============================================================================

// [[Rcpp::export(.manipulation_extract_pitch_tier)]]
SEXP manipulation_extract_pitch_tier(XPtr<structManipulation> manip) {
    if (!manip) stop("Invalid Manipulation pointer");
    
    try {
        autoPitchTier tier = Manipulation_extractPitchTier(manip.get());
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
        autoDurationTier tier = Manipulation_extractDurationTier(manip.get());
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

// [[Rcpp::export(.manipulation_replace_pitch_tier)]]
void manipulation_replace_pitch_tier(XPtr<structManipulation> manip, 
                                      XPtr<structPitchTier> pitch_tier) {
    if (!manip) stop("Invalid Manipulation pointer");
    if (!pitch_tier) stop("Invalid PitchTier pointer");
    
    try {
        // Make a copy of the pitch tier and replace
        autoPitchTier tier_copy = Data_copy(pitch_tier.get());
        manip->pitch = tier_copy.move();
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to replace PitchTier");
    }
}

// [[Rcpp::export(.manipulation_replace_duration_tier)]]
void manipulation_replace_duration_tier(XPtr<structManipulation> manip,
                                         XPtr<structDurationTier> duration_tier) {
    if (!manip) stop("Invalid Manipulation pointer");
    if (!duration_tier) stop("Invalid DurationTier pointer");
    
    try {
        // Make a copy of the duration tier and replace
        autoDurationTier tier_copy = Data_copy(duration_tier.get());
        manip->duration = tier_copy.move();
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to replace DurationTier");
    }
}

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

// [[Rcpp::export(.manipulation_get_resynthesis_lpc)]]
SEXP manipulation_get_resynthesis_lpc(XPtr<structManipulation> manip) {
    if (!manip) stop("Invalid Manipulation pointer");
    
    try {
        autoSound sound = Manipulation_to_Sound(manip.get(), Manipulation_LPC);
        return create_xptr_from_auto<structSound>(sound);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to resynthesize sound (LPC)");
    }
}
