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
// PointProcess R6 wrapper functions
// Wraps Praat PointProcess C++ object for R6 PointProcess class

#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat includes
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/fon/PointProcess_and_Sound.h"
#include "praat.github.io/fon/VoiceAnalysis.h"
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/TextGrid.h"

using namespace Rcpp;

// Finalizer for PointProcess XPtr
void pointprocess_finalizer(structPointProcess* pp) {
    if (pp != nullptr) {
        forget(pp);
    }
}

// =============================================================================
// Query Methods - Basic
// =============================================================================

// [[Rcpp::export(.pointprocess_get_number_of_points)]]
int pointprocess_get_number_of_points(SEXP xptr) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    return pp->nt;
}

// [[Rcpp::export(.pointprocess_get_time_from_index)]]
double pointprocess_get_time_from_index(SEXP xptr, int index) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    if (index < 1 || index > pp->nt) {
        stop("Index out of range: %d (must be between 1 and %d)", index, pp->nt);
    }
    
    // Praat uses 1-based indexing internally
    return pp->t[index];
}

// [[Rcpp::export(.pointprocess_get_nearest_index)]]
int pointprocess_get_nearest_index(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        integer index = PointProcess_getNearestIndex(pp, time);
        return static_cast<int>(index);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get nearest index");
    }
}

// [[Rcpp::export(.pointprocess_get_low_index)]]
int pointprocess_get_low_index(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        integer index = PointProcess_getLowIndex(pp, time);
        return static_cast<int>(index);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get low index");
    }
}

// [[Rcpp::export(.pointprocess_get_high_index)]]
int pointprocess_get_high_index(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        integer index = PointProcess_getHighIndex(pp, time);
        return static_cast<int>(index);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to get high index");
    }
}

// [[Rcpp::export(.pointprocess_get_interval)]]
double pointprocess_get_interval(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double interval = PointProcess_getInterval(pp, time);
        return interval;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// =============================================================================
// Voice Quality - Jitter (Period Perturbation)
// =============================================================================

// [[Rcpp::export(.pointprocess_get_jitter_local)]]
double pointprocess_get_jitter_local(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_local(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_jitter_local_absolute)]]
double pointprocess_get_jitter_local_absolute(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_local_absolute(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_jitter_rap)]]
double pointprocess_get_jitter_rap(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_rap(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_jitter_ppq5)]]
double pointprocess_get_jitter_ppq5(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_ppq5(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_jitter_ddp)]]
double pointprocess_get_jitter_ddp(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double jitter = PointProcess_getJitter_ddp(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return jitter;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// =============================================================================
// Voice Quality - Shimmer (Amplitude Perturbation - requires Sound)
// =============================================================================

// [[Rcpp::export(.pointprocess_sound_get_shimmer_local)]]
double pointprocess_sound_get_shimmer_local(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_local(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_local_db)]]
double pointprocess_sound_get_shimmer_local_db(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_local_dB(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_apq3)]]
double pointprocess_sound_get_shimmer_apq3(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_apq3(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_apq5)]]
double pointprocess_sound_get_shimmer_apq5(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_apq5(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_apq11)]]
double pointprocess_sound_get_shimmer_apq11(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_apq11(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_sound_get_shimmer_dda)]]
double pointprocess_sound_get_shimmer_dda(
    SEXP pp_xptr,
    SEXP sound_xptr,
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor,
    double max_amplitude_factor
) {
    XPtr<structPointProcess> pp(pp_xptr);
    XPtr<structSound> sound(sound_xptr);
    
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    try {
        double shimmer = PointProcess_Sound_getShimmer_dda(
            pp, 
            sound,
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor,
            max_amplitude_factor
        );
        return shimmer;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// =============================================================================
// Period Statistics
// =============================================================================

// [[Rcpp::export(.pointprocess_get_mean_period)]]
double pointprocess_get_mean_period(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double mean_period = PointProcess_getMeanPeriod(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return mean_period;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// [[Rcpp::export(.pointprocess_get_stdev_period)]]
double pointprocess_get_stdev_period(
    SEXP xptr, 
    double from_time, 
    double to_time,
    double period_floor, 
    double period_ceiling, 
    double max_period_factor
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        double stdev_period = PointProcess_getStdevPeriod(
            pp, 
            from_time, 
            to_time, 
            period_floor, 
            period_ceiling, 
            max_period_factor
        );
        return stdev_period;
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// =============================================================================
// Modification Methods
// =============================================================================

// [[Rcpp::export(.pointprocess_add_point)]]
void pointprocess_add_point(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        PointProcess_addPoint(pp, time);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to add point at time %.6f", time);
    }
}

// [[Rcpp::export(.pointprocess_remove_point)]]
void pointprocess_remove_point(SEXP xptr, int index) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    if (index < 1 || index > pp->nt) {
        stop("Index out of range: %d (must be between 1 and %d)", index, pp->nt);
    }
    
    try {
        PointProcess_removePoint(pp, index);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to remove point at index %d", index);
    }
}

// [[Rcpp::export(.pointprocess_remove_point_near)]]
void pointprocess_remove_point_near(SEXP xptr, double time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        PointProcess_removePointNear(pp, time);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to remove point near time %.6f", time);
    }
}

// [[Rcpp::export(.pointprocess_remove_points_between)]]
void pointprocess_remove_points_between(SEXP xptr, double from_time, double to_time) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        PointProcess_removePointsBetween(pp, from_time, to_time);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to remove points between %.6f and %.6f", from_time, to_time);
    }
}

// =============================================================================
// Conversion Methods
// =============================================================================

// [[Rcpp::export(.pointprocess_to_textgrid_vuv)]]
Rcpp::XPtr<structTextGrid> pointprocess_to_textgrid_vuv(
    SEXP xptr,
    double max_voiced_period,
    double max_unvoiced_period
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        autoTextGrid tg = PointProcess_to_TextGrid_vuv(pp, max_voiced_period, max_unvoiced_period);
        return create_xptr_from_auto<structTextGrid>(tg);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert PointProcess to TextGrid (vuv)");
    }
}

// =============================================================================
// Voice Analysis Methods
// =============================================================================

// [[Rcpp::export(.pointprocess_voice_report)]]
List pointprocess_voice_report(SEXP sound_xptr, SEXP pitch_xptr, SEXP pp_xptr,
                               double tmin, double tmax,
                               double floor, double ceiling,
                               double maximum_period_factor,
                               double maximum_amplitude_factor,
                               double silence_threshold,
                               double voicing_threshold) {
    XPtr<structSound> sound(sound_xptr);
    XPtr<structPitch> pitch(pitch_xptr);
    XPtr<structPointProcess> pulses(pp_xptr);
    
    if (!sound || !pitch || !pulses) {
        stop("Invalid Sound, Pitch, or PointProcess pointer");
    }
    
    try {
        // Auto-window if needed
        Function_unidirectionalAutowindow(sound, &tmin, &tmax);
        
        // Calculate pitch statistics
        double median_pitch = Pitch_getQuantile(pitch, tmin, tmax, 0.50, kPitch_unit::HERTZ);
        double mean_pitch = Pitch_getMean(pitch, tmin, tmax, kPitch_unit::HERTZ);
        double stdev_pitch = Pitch_getStandardDeviation(pitch, tmin, tmax, kPitch_unit::HERTZ);
        double minimum_pitch = Pitch_getMinimum(pitch, tmin, tmax, kPitch_unit::HERTZ, 1);
        double maximum_pitch = Pitch_getMaximum(pitch, tmin, tmax, kPitch_unit::HERTZ, 1);
        
        // Pulse statistics
        double pmin = 0.8 / ceiling;
        double pmax = 1.25 / floor;
        
        MelderIntegerRange pulseNumbers = PointProcess_getWindowPoints(pulses, tmin, tmax);
        integer numberOfPeriods = PointProcess_getNumberOfPeriods(pulses, tmin, tmax, pmin, pmax, maximum_period_factor);
        double meanPeriod = PointProcess_getMeanPeriod(pulses, tmin, tmax, pmin, pmax, maximum_period_factor);
        double stdevPeriod = PointProcess_getStdevPeriod(pulses, tmin, tmax, pmin, pmax, maximum_period_factor);
        
        // Voicing
        MelderFraction unvoicedFraction = Pitch_getFractionOfLocallyUnvoicedFrames(
            pitch, tmin, tmax, ceiling, silence_threshold, voicing_threshold
        );
        MelderCountAndFraction breaks = PointProcess_getCountAndFractionOfVoiceBreaks(pulses, tmin, tmax, pmax);
        
        // Jitter measurements
        double jitter_local = PointProcess_getJitter_local(pulses, tmin, tmax, pmin, pmax, maximum_period_factor);
        double jitter_local_absolute = PointProcess_getJitter_local_absolute(pulses, tmin, tmax, pmin, pmax, maximum_period_factor);
        double jitter_rap = PointProcess_getJitter_rap(pulses, tmin, tmax, pmin, pmax, maximum_period_factor);
        double jitter_ppq5 = PointProcess_getJitter_ppq5(pulses, tmin, tmax, pmin, pmax, maximum_period_factor);
        double jitter_ddp = PointProcess_getJitter_ddp(pulses, tmin, tmax, pmin, pmax, maximum_period_factor);
        
        // Shimmer measurements
        double shimmer_local, shimmer_local_db, shimmer_apq3, shimmer_apq5, shimmer_apq11, shimmer_dda;
        PointProcess_Sound_getShimmer_multi(pulses, sound, tmin, tmax, pmin, pmax,
            maximum_period_factor, maximum_amplitude_factor,
            &shimmer_local, &shimmer_local_db, &shimmer_apq3, &shimmer_apq5, &shimmer_apq11, &shimmer_dda
        );
        
        // Harmonicity
        double mean_autocorrelation = Pitch_getMeanStrength(pitch, tmin, tmax, Pitch_STRENGTH_UNIT_AUTOCORRELATION);
        double mean_noise_to_harmonics_ratio = Pitch_getMeanStrength(pitch, tmin, tmax, Pitch_STRENGTH_UNIT_NOISE_HARMONICS_RATIO);
        double mean_harmonics_to_noise_ratio = Pitch_getMeanStrength(pitch, tmin, tmax, Pitch_STRENGTH_UNIT_HARMONICS_NOISE_DB);
        
        // Return all measurements as a named list
        return List::create(
            Named("time_range") = NumericVector::create(tmin, tmax),
            Named("duration") = tmax - tmin,
            
            // Pitch
            Named("median_pitch") = median_pitch,
            Named("mean_pitch") = mean_pitch,
            Named("stdev_pitch") = stdev_pitch,
            Named("minimum_pitch") = minimum_pitch,
            Named("maximum_pitch") = maximum_pitch,
            
            // Pulses
            Named("number_of_pulses") = static_cast<int>(pulseNumbers.size()),
            Named("number_of_periods") = static_cast<int>(numberOfPeriods),
            Named("mean_period") = meanPeriod,
            Named("stdev_period") = stdevPeriod,
            
            // Voicing
            Named("fraction_unvoiced_frames") = unvoicedFraction.get(),
            Named("number_of_voice_breaks") = static_cast<int>(breaks.count),
            Named("degree_of_voice_breaks") = breaks.getFraction(),
            
            // Jitter (as proportions, multiply by 100 for percentage)
            Named("jitter_local") = jitter_local,
            Named("jitter_local_absolute") = jitter_local_absolute,
            Named("jitter_rap") = jitter_rap,
            Named("jitter_ppq5") = jitter_ppq5,
            Named("jitter_ddp") = jitter_ddp,
            
            // Shimmer (as proportions, multiply by 100 for percentage)
            Named("shimmer_local") = shimmer_local,
            Named("shimmer_local_db") = shimmer_local_db,
            Named("shimmer_apq3") = shimmer_apq3,
            Named("shimmer_apq5") = shimmer_apq5,
            Named("shimmer_apq11") = shimmer_apq11,
            Named("shimmer_dda") = shimmer_dda,
            
            // Harmonicity
            Named("mean_autocorrelation") = mean_autocorrelation,
            Named("mean_noise_to_harmonics_ratio") = mean_noise_to_harmonics_ratio,
            Named("mean_harmonics_to_noise_ratio") = mean_harmonics_to_noise_ratio
        );
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to compute voice report");
    }
}

// =============================================================================
// I/O Methods
// =============================================================================

//' PointProcess: To Sound (pulse train) (internal)
// [[Rcpp::export(.pointprocess_to_sound_pulse_train)]]
XPtr<structSound> pointprocess_to_sound_pulse_train(
    SEXP xptr,
    double sampling_frequency,
    double adapt_factor,
    double adapt_time,
    int interpolation_depth
) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) stop("Invalid PointProcess pointer");

    try {
        autoSound result = PointProcess_to_Sound_pulseTrain(
            pp, sampling_frequency, adapt_factor, adapt_time,
            (integer) interpolation_depth
        );
        return create_xptr_from_auto<structSound>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert PointProcess to Sound (pulse train)");
    }
}

//' PointProcess: To Sound (hum) (internal)
// [[Rcpp::export(.pointprocess_to_sound_hum)]]
XPtr<structSound> pointprocess_to_sound_hum(SEXP xptr) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) stop("Invalid PointProcess pointer");

    try {
        autoSound result = PointProcess_to_Sound_hum(pp);
        return create_xptr_from_auto<structSound>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert PointProcess to Sound (hum)");
    }
}

// [[Rcpp::export(.pointprocess_save)]]
void pointprocess_save(SEXP xptr, std::string path) {
    XPtr<structPointProcess> pp(xptr);
    if (!pp) {
        stop("Invalid PointProcess pointer");
    }
    
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        Data_writeToTextFile(pp, &file);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to save PointProcess to: %s", path.c_str());
    }
}
