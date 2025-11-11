// pitch_wrappers.cpp
// C++ wrappers for Praat Pitch object
// Part of the speaker package

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_types.h"

// Praat headers
#include "praat.github.io/fon/Pitch.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Sound_to_Pitch.h"
#include "praat.github.io/fon/Pitch_to_PointProcess.h"
#include "praat.github.io/fon/Pitch_to_PitchTier.h"
#include "praat.github.io/fon/PitchTier.h"
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/melder/melder.h"

using namespace Rcpp;

// ============================================================================
// Creation methods
// ============================================================================

// [[Rcpp::export(.pitch_from_sound)]]
Rcpp::XPtr<structPitch> pitch_from_sound(
    Rcpp::XPtr<structSound> sound,
    double time_step,
    double pitch_floor,
    double pitch_ceiling
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    
    try {
        autoPitch pitch = Sound_to_Pitch(
            sound.get(),
            time_step,
            pitch_floor,
            pitch_ceiling
        );
        return create_xptr_from_auto<structPitch>(pitch);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract pitch from sound");
    }
}

// Advanced methods - commented out for now, use Sound_to_Pitch instead
// TODO: Implement with full parameter support
/*
// [[Rcpp::export(.pitch_from_sound_ac)]]
Rcpp::XPtr<structPitch> pitch_from_sound_ac(
    Rcpp::XPtr<structSound> sound,
    double time_step,
    double pitch_floor,
    double very_accurate,
    double silence_threshold,
    double voicing_threshold,
    double octave_cost,
    double octave_jump_cost,
    double voiced_unvoiced_cost,
    double pitch_ceiling
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    
    try {
        autoPitch pitch = Sound_to_Pitch_rawAc(
            sound.get(),
            time_step,
            pitch_floor,
            pitch_ceiling,
            15,  // maxnCandidates
            very_accurate,
            silence_threshold,
            voicing_threshold,
            octave_cost,
            octave_jump_cost,
            voiced_unvoiced_cost
        );
        return create_xptr_from_auto<structPitch>(pitch);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract pitch using autocorrelation method");
    }
}

// [[Rcpp::export(.pitch_from_sound_cc)]]
Rcpp::XPtr<structPitch> pitch_from_sound_cc(
    Rcpp::XPtr<structSound> sound,
    double time_step,
    double pitch_floor,
    double pitch_ceiling
) {
    if (!sound) Rcpp::stop("Invalid Sound pointer");
    
    try {
        autoPitch pitch = Sound_to_Pitch_rawCc(
            sound.get(),
            time_step,
            pitch_floor,
            pitch_ceiling,
            15,  // maxnCandidates
            true,  // veryAccurate
            0.03,  // silence_threshold
            0.45,  // voicing_threshold
            0.01,  // octave_cost
            0.35,  // octave_jump_cost
            0.14   // voiced_unvoiced_cost
        );
        return create_xptr_from_auto<structPitch>(pitch);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract pitch using cross-correlation method");
    }
}
*/

// ============================================================================
// Query methods - Time domain
// ============================================================================

// [[Rcpp::export(.pitch_get_time_from_frame)]]
double pitch_get_time_from_frame(Rcpp::XPtr<structPitch> pitch, int frame_number) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    if (frame_number < 1 || frame_number > pitch->nx)
        Rcpp::stop("Frame number out of range");
    
    return Sampled_indexToX(pitch.get(), frame_number);
}

// [[Rcpp::export(.pitch_get_frame_from_time)]]
int pitch_get_frame_from_time(Rcpp::XPtr<structPitch> pitch, double time) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    return (int)Sampled_xToNearestIndex(pitch.get(), time);
}

// [[Rcpp::export(.pitch_get_number_of_frames)]]
int pitch_get_number_of_frames(Rcpp::XPtr<structPitch> pitch) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    return pitch->nx;
}

// [[Rcpp::export(.pitch_get_time_step)]]
double pitch_get_time_step(Rcpp::XPtr<structPitch> pitch) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    return pitch->dx;
}

// ============================================================================
// Query methods - Pitch values
// ============================================================================

// [[Rcpp::export(.pitch_get_value_at_time)]]
double pitch_get_value_at_time(
    Rcpp::XPtr<structPitch> pitch,
    double time,
    int unit,
    bool interpolate
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double value = Pitch_getValueAtTime(
            pitch.get(),
            time,
            static_cast<kPitch_unit>(unit),
            interpolate
        );
        return value;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get pitch value at time");
    }
}

// [[Rcpp::export(.pitch_get_mean)]]
double pitch_get_mean(
    Rcpp::XPtr<structPitch> pitch,
    double from_time,
    double to_time,
    int unit
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double mean = Pitch_getMean(
            pitch.get(),
            from_time,
            to_time,
            static_cast<kPitch_unit>(unit)
        );
        return mean;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get mean pitch");
    }
}

// [[Rcpp::export(.pitch_get_standard_deviation)]]
double pitch_get_standard_deviation(
    Rcpp::XPtr<structPitch> pitch,
    double from_time,
    double to_time,
    int unit
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double sd = Pitch_getStandardDeviation(
            pitch.get(),
            from_time,
            to_time,
            static_cast<kPitch_unit>(unit)
        );
        return sd;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get pitch standard deviation");
    }
}

// [[Rcpp::export(.pitch_get_quantile)]]
double pitch_get_quantile(
    Rcpp::XPtr<structPitch> pitch,
    double from_time,
    double to_time,
    double quantile,
    int unit
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double value = Pitch_getQuantile(
            pitch.get(),
            from_time,
            to_time,
            quantile,
            static_cast<kPitch_unit>(unit)
        );
        return value;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get pitch quantile");
    }
}

// [[Rcpp::export(.pitch_get_minimum)]]
double pitch_get_minimum(
    Rcpp::XPtr<structPitch> pitch,
    double from_time,
    double to_time,
    int unit,
    bool interpolate
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double minimum = Pitch_getMinimum(
            pitch.get(),
            from_time,
            to_time,
            static_cast<kPitch_unit>(unit),
            interpolate
        );
        return minimum;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get minimum pitch");
    }
}

// [[Rcpp::export(.pitch_get_maximum)]]
double pitch_get_maximum(
    Rcpp::XPtr<structPitch> pitch,
    double from_time,
    double to_time,
    int unit,
    bool interpolate
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double maximum = Pitch_getMaximum(
            pitch.get(),
            from_time,
            to_time,
            static_cast<kPitch_unit>(unit),
            interpolate
        );
        return maximum;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get maximum pitch");
    }
}

// [[Rcpp::export(.pitch_get_time_of_minimum)]]
double pitch_get_time_of_minimum(
    Rcpp::XPtr<structPitch> pitch,
    double from_time,
    double to_time,
    int unit,
    bool interpolate
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double time = Pitch_getTimeOfMinimum(
            pitch.get(),
            from_time,
            to_time,
            static_cast<kPitch_unit>(unit),
            interpolate
        );
        return time;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get time of minimum pitch");
    }
}

// [[Rcpp::export(.pitch_get_time_of_maximum)]]
double pitch_get_time_of_maximum(
    Rcpp::XPtr<structPitch> pitch,
    double from_time,
    double to_time,
    int unit,
    bool interpolate
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double time = Pitch_getTimeOfMaximum(
            pitch.get(),
            from_time,
            to_time,
            static_cast<kPitch_unit>(unit),
            interpolate
        );
        return time;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get time of maximum pitch");
    }
}

// [[Rcpp::export(.pitch_count_voiced_frames)]]
int pitch_count_voiced_frames(Rcpp::XPtr<structPitch> pitch) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        integer count = Pitch_countVoicedFrames(pitch.get());
        return (int)count;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to count voiced frames");
    }
}

// ============================================================================
// Export methods
// ============================================================================

// [[Rcpp::export(.pitch_as_matrix)]]
Rcpp::NumericMatrix pitch_as_matrix(Rcpp::XPtr<structPitch> pitch) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    integer nx = pitch->nx;
    Rcpp::NumericMatrix result(nx, 2);
    
    for (integer i = 1; i <= nx; i++) {
        double time = Sampled_indexToX(pitch.get(), i);
        double freq = Pitch_getValueAtTime(pitch.get(), time, kPitch_unit::HERTZ, false);
        
        result(i-1, 0) = time;
        result(i-1, 1) = (freq > 0 && freq < pitch->ceiling) ? freq : NA_REAL;
    }
    
    colnames(result) = CharacterVector::create("time", "frequency");
    return result;
}

// [[Rcpp::export(.pitch_as_data_frame)]]
Rcpp::DataFrame pitch_as_data_frame(Rcpp::XPtr<structPitch> pitch) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    integer nx = pitch->nx;
    Rcpp::NumericVector time(nx);
    Rcpp::NumericVector frequency(nx);
    Rcpp::LogicalVector voiced(nx);
    
    for (integer i = 1; i <= nx; i++) {
        double t = Sampled_indexToX(pitch.get(), i);
        double freq = Pitch_getValueAtTime(pitch.get(), t, kPitch_unit::HERTZ, false);
        bool is_voiced = (freq > 0 && freq < pitch->ceiling);
        
        time[i-1] = t;
        frequency[i-1] = is_voiced ? freq : NA_REAL;
        voiced[i-1] = is_voiced;
    }
    
    return DataFrame::create(
        Named("time") = time,
        Named("frequency") = frequency,
        Named("voiced") = voiced
    );
}

// ============================================================================
// Save method
// ============================================================================

// [[Rcpp::export(.pitch_save)]]
void pitch_save(Rcpp::XPtr<structPitch> pitch, std::string path) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        structMelderFile file = {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        Data_writeToTextFile(pitch.get(), &file);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to save pitch to file: " + path);
    }
}

// ============================================================================
// Transform methods
// ============================================================================

// [[Rcpp::export(.pitch_to_point_process)]]
Rcpp::XPtr<structPointProcess> pitch_to_point_process(Rcpp::XPtr<structPitch> pitch) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        autoPointProcess pp = Pitch_to_PointProcess(pitch.get());
        return create_xptr_from_auto<structPointProcess>(pp);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert Pitch to PointProcess");
    }
}

// [[Rcpp::export(.pitch_down_to_pitch_tier)]]
Rcpp::XPtr<structPitchTier> pitch_down_to_pitch_tier(Rcpp::XPtr<structPitch> pitch) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        autoPitchTier tier = Pitch_to_PitchTier(pitch.get());
        return create_xptr_from_auto<structPitchTier>(tier);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to convert Pitch to PitchTier");
    }
}
