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
#include "praat.github.io/fon/TextGrid.h"
#include "praat.github.io/dwtools/Sound_and_TextGrid_extensions.h"
#include "praat.github.io/melder/melder.h"

using namespace Rcpp;

// Forward declaration - NUMfpp initialization from NUMmachar.cpp
extern void NUMmachar();

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
    // Ensure NUMfpp is initialized before pitch analysis
    NUMmachar();

    
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

// Advanced methods - not currently exposed
// These methods provide alternative pitch extraction algorithms
// For now, Sound_to_Pitch provides the main AC algorithm with full parameter support
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
// Strength query methods
// ============================================================================

// [[Rcpp::export(.pitch_get_strength_at_time)]]
double pitch_get_strength_at_time(
    Rcpp::XPtr<structPitch> pitch,
    double time,
    int unit,
    bool interpolate
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double strength = Pitch_getStrengthAtTime(
            pitch.get(),
            time,
            static_cast<kPitch_unit>(unit),
            interpolate
        );
        return strength;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get pitch strength at time");
    }
}

// [[Rcpp::export(.pitch_get_mean_strength)]]
double pitch_get_mean_strength(
    Rcpp::XPtr<structPitch> pitch,
    double from_time,
    double to_time,
    int unit
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        double mean_strength = Pitch_getMeanStrength(
            pitch.get(),
            from_time,
            to_time,
            unit
        );
        return mean_strength;
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to get mean pitch strength");
    }
}

// ============================================================================
// Intensity query methods
// ============================================================================

// [[Rcpp::export(.pitch_get_intensity_at_time)]]
double pitch_get_intensity_at_time(
    Rcpp::XPtr<structPitch> pitch,
    double time
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    // Find nearest frame
    integer iframe = Sampled_xToNearestIndex(pitch.get(), time);
    if (iframe < 1 || iframe > pitch->nx) {
        return NA_REAL;
    }
    
    // Get intensity from frame
    Pitch_Frame frame = &pitch->frames[iframe];
    return frame->intensity;
}

// [[Rcpp::export(.pitch_get_mean_intensity)]]
double pitch_get_mean_intensity(
    Rcpp::XPtr<structPitch> pitch,
    double from_time,
    double to_time
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    // Find frame range
    integer ifrom = Sampled_xToHighIndex(pitch.get(), from_time);
    integer ito = Sampled_xToLowIndex(pitch.get(), to_time);
    
    if (ifrom < 1) ifrom = 1;
    if (ito > pitch->nx) ito = pitch->nx;
    if (ifrom > ito) return NA_REAL;
    
    // Compute mean intensity
    double sum = 0.0;
    integer count = 0;
    for (integer i = ifrom; i <= ito; i++) {
        Pitch_Frame frame = &pitch->frames[i];
        if (frame->intensity > 0.0) {
            sum += frame->intensity;
            count++;
        }
    }
    
    return (count > 0) ? (sum / count) : NA_REAL;
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

// Debug function to inspect raw pitch candidates
// [[Rcpp::export(.pitch_debug_candidates)]]
Rcpp::List pitch_debug_candidates(Rcpp::XPtr<structPitch> pitch, int max_frames = 10) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    Rcpp::List result;
    integer n_frames = pitch->nx < max_frames ? pitch->nx : max_frames;
    
    for (integer i = 1; i <= n_frames; i++) {
        Pitch_Frame frame = &pitch->frames[i];
        double t = Sampled_indexToX(pitch.get(), i);
        
        Rcpp::NumericVector freqs(frame->nCandidates);
        Rcpp::NumericVector strengths(frame->nCandidates);
        
        for (integer j = 1; j <= frame->nCandidates; j++) {
            freqs[j-1] = frame->candidates[j].frequency;
            strengths[j-1] = frame->candidates[j].strength;
        }
        
        result.push_back(Rcpp::List::create(
            Named("time") = t,
            Named("nCandidates") = (int)frame->nCandidates,
            Named("frequencies") = freqs,
            Named("strengths") = strengths,
            Named("ceiling") = pitch->ceiling
        ));
    }
    
    return result;
}

// Extract ALL pitch candidates from ALL frames as DataFrame
// This is needed for Brückl-style cyclicality calculation
// [[Rcpp::export(.pitch_get_all_candidates)]]
Rcpp::DataFrame pitch_get_all_candidates(Rcpp::XPtr<structPitch> pitch) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    // First pass: count total candidates
    integer total_candidates = 0;
    for (integer i = 1; i <= pitch->nx; i++) {
        Pitch_Frame frame = &pitch->frames[i];
        total_candidates += frame->nCandidates;
    }
    
    // Allocate vectors
    Rcpp::NumericVector times(total_candidates);
    Rcpp::IntegerVector frame_nums(total_candidates);
    Rcpp::IntegerVector candidate_nums(total_candidates);
    Rcpp::NumericVector frequencies(total_candidates);
    Rcpp::NumericVector strengths(total_candidates);
    
    // Second pass: fill vectors
    integer idx = 0;
    for (integer i = 1; i <= pitch->nx; i++) {
        Pitch_Frame frame = &pitch->frames[i];
        double t = Sampled_indexToX(pitch.get(), i);
        
        for (integer j = 1; j <= frame->nCandidates; j++) {
            times[idx] = t;
            frame_nums[idx] = (int)i;
            candidate_nums[idx] = (int)j;
            frequencies[idx] = frame->candidates[j].frequency;
            strengths[idx] = frame->candidates[j].strength;
            idx++;
        }
    }
    
    return DataFrame::create(
        Named("time") = times,
        Named("frame") = frame_nums,
        Named("candidate") = candidate_nums,
        Named("frequency") = frequencies,
        Named("strength") = strengths
    );
}

// [[Rcpp::export(.pitch_as_data_frame)]]
Rcpp::DataFrame pitch_as_data_frame(Rcpp::XPtr<structPitch> pitch, bool include_strength = false, bool include_intensity = false) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    integer nx = pitch->nx;
    Rcpp::NumericVector time(nx);
    Rcpp::NumericVector frequency(nx);
    Rcpp::LogicalVector voiced(nx);
    Rcpp::NumericVector strength(nx);
    Rcpp::NumericVector intensity(nx);
    
    for (integer i = 1; i <= nx; i++) {
        double t = Sampled_indexToX(pitch.get(), i);
        double freq = Pitch_getValueAtTime(pitch.get(), t, kPitch_unit::HERTZ, false);
        bool is_voiced = (freq > 0 && freq < pitch->ceiling);
        
        time[i-1] = t;
        frequency[i-1] = is_voiced ? freq : NA_REAL;
        voiced[i-1] = is_voiced;
        
        if (include_strength) {
            double str = Pitch_getStrengthAtTime(pitch.get(), t, kPitch_unit::HERTZ, false);
            strength[i-1] = (str >= 0) ? str : NA_REAL;
        }
        
        if (include_intensity) {
            Pitch_Frame frame = &pitch->frames[i];
            intensity[i-1] = frame->intensity;
        }
    }
    
    // Build result based on requested columns
    if (include_strength && include_intensity) {
        return DataFrame::create(
            Named("time") = time,
            Named("frequency") = frequency,
            Named("voiced") = voiced,
            Named("strength") = strength,
            Named("intensity") = intensity
        );
    } else if (include_strength) {
        return DataFrame::create(
            Named("time") = time,
            Named("frequency") = frequency,
            Named("voiced") = voiced,
            Named("strength") = strength
        );
    } else if (include_intensity) {
        return DataFrame::create(
            Named("time") = time,
            Named("frequency") = frequency,
            Named("voiced") = voiced,
            Named("intensity") = intensity
        );
    } else {
        return DataFrame::create(
            Named("time") = time,
            Named("frequency") = frequency,
            Named("voiced") = voiced
        );
    }
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


// [[Rcpp::export(.pitch_to_textgrid_vuv)]]
Rcpp::XPtr<structTextGrid> pitch_to_textgrid_vuv(
    Rcpp::XPtr<structPitch> pitch
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        // Create TextGrid with single interval tier
        autoTextGrid tg = TextGrid_create(
            pitch->xmin,
            pitch->xmax,
            U"vuv", U""
        );
        
        // Get tier and clear
        IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), 1);
        tier->intervals.removeAllItems();
        
        // Track state
        double start = pitch->xmin;
        bool voiced = false;
        
        for (integer i = 1; i <= pitch->nx; i++) {
            double t = Sampled_indexToX(pitch.get(), i);
            double f = Pitch_getValueAtTime(pitch.get(), t, kPitch_unit::HERTZ, false);
            bool v = isdefined(f) && f > 0.0;
            
            if (i == 1) {
                voiced = v;
            } else if (v != voiced || i == pitch->nx) {
                double end = (i == pitch->nx) ? pitch->xmax : t;
                autoTextInterval iv = TextInterval_create(start, end, voiced ? U"V" : U"U");
                tier->intervals.addItem_move(iv.move());
                start = t;
                voiced = v;
            }
        }
        
        return create_xptr_from_auto<structTextGrid>(tg);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create VUV TextGrid");
    }
}

// [[Rcpp::export(.pitch_to_textgrid_silences)]]
Rcpp::XPtr<structTextGrid> pitch_to_textgrid_silences(
    Rcpp::XPtr<structPitch> pitch,
    double min_silent_dur,
    double min_sounding_dur
) {
    if (!pitch) Rcpp::stop("Invalid Pitch pointer");
    
    try {
        autoTextGrid tg = TextGrid_create(pitch->xmin, pitch->xmax, U"silences", U"");
        IntervalTier tier = TextGrid_checkSpecifiedTierIsIntervalTier(tg.get(), 1);
        tier->intervals.removeAllItems();
        
        double start = pitch->xmin;
        bool silent = true;
        
        for (integer i = 1; i <= pitch->nx; i++) {
            double t = Sampled_indexToX(pitch.get(), i);
            double f = Pitch_getValueAtTime(pitch.get(), t, kPitch_unit::HERTZ, false);
            bool s = !isdefined(f) || f <= 0.0;
            
            if (i == 1) {
                silent = s;
            } else if (s != silent) {
                double dur = t - start;
                bool add = silent ? (dur >= min_silent_dur) : (dur >= min_sounding_dur);
                if (add) {
                    autoTextInterval iv = TextInterval_create(start, t, silent ? U"silent" : U"sounding");
                    tier->intervals.addItem_move(iv.move());
                }
                start = t;
                silent = s;
            }
        }
        
        // Final interval
        double dur = pitch->xmax - start;
        bool add = silent ? (dur >= min_silent_dur) : (dur >= min_sounding_dur);
        if (add) {
            autoTextInterval iv = TextInterval_create(start, pitch->xmax, silent ? U"silent" : U"sounding");
            tier->intervals.addItem_move(iv.move());
        }
        
        return create_xptr_from_auto<structTextGrid>(tg);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to create silence TextGrid");
    }
}
