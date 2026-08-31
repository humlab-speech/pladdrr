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
// praat_direct.cpp
// Direct function dispatch API - bypasses R6 overhead for performance-critical code
// pladdrr v2.2.1 - Phase 2 Performance Enhancement
//
// These functions provide 2-3x speedup over R6 method dispatch by:
// 1. Accepting XPtrs directly (no R6 environment lookup)
// 2. Using positional arguments (no named parameter matching)
// 3. Returning raw values (no R6 object wrapping)
//
// IMPORTANT: Output is numerically identical to R6 methods

#include <Rcpp.h>
#include "praat.github.io/fon/Sound.h"
#include "praat.github.io/fon/Pitch.h"
#include "praat.github.io/fon/Formant.h"
#include "praat.github.io/fon/Intensity.h"
#include "praat.github.io/fon/Spectrum.h"
#include "praat.github.io/fon/Spectrogram.h"
#include "praat.github.io/fon/Harmonicity.h"
#include "praat.github.io/fon/PointProcess.h"
#include "praat.github.io/fon/Sound_to_Pitch.h"
#include "praat.github.io/fon/Sound_to_Formant.h"
#include "praat.github.io/fon/Sound_to_Intensity.h"
#include "praat.github.io/fon/Sound_to_Harmonicity.h"
#include "praat.github.io/LPC/PowerCepstrogram.h"
#include "praat.github.io/LPC/PowerCepstrum.h"
#include "praat_xptr_utils.h"

using namespace Rcpp;

// Forward declaration
extern void NUMmachar();

// =============================================================================
// Sound Direct Functions
// =============================================================================

//' Get Sound duration directly
//' @param sound_xptr External pointer to Sound
//' @return Duration in seconds
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
//' pladdrr:::sound_get_duration_direct(sound$.xptr)
//' @noRd
// [[Rcpp::export]]
double sound_get_duration_direct(SEXP sound_xptr) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }
    return sound->xmax - sound->xmin;
}

//' Get Sound RMS directly
//' @param sound_xptr External pointer to Sound
//' @param from_time Start time (0 = start)
//' @return RMS value
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
//' pladdrr:::sound_get_rms_direct(sound$.xptr)
//' @noRd
// [[Rcpp::export]]
double sound_get_rms_direct(SEXP sound_xptr, double from_time = 0, double to_time = 0) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = sound->xmin;
        to_time = sound->xmax;
    }
    return Sound_getRootMeanSquare(sound.get(), from_time, to_time);
}

// =============================================================================
// Pitch Direct Functions
// =============================================================================

//' Get pitch value at time directly (no R6 dispatch)
//' @param pitch_xptr External pointer to Pitch
//' @param unit 0=Hertz, 1=Hertz_log, 2=mel, 3=logHertz, 4=semitones
//' @return Pitch value
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_get_value_direct(pitch$.xptr, 0.5)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
double pitch_get_value_direct(SEXP pitch_xptr, double time, int unit = 0, bool interpolate = true) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);
    return Pitch_getValueAtTime(pitch.get(), time, p_unit, interpolate);
}

//' Get pitch mean directly
//' @param pitch_xptr External pointer to Pitch
//' @param from_time Start time (0 = start)
//' @inheritParams pladdrr_shared_time0 to_time
//' @param unit Unit code
//' @return Mean pitch
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_get_mean_direct(pitch$.xptr)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
double pitch_get_mean_direct(SEXP pitch_xptr, double from_time = 0, double to_time = 0, int unit = 0) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = pitch->xmin;
        to_time = pitch->xmax;
    }
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);
    return Pitch_getMean(pitch.get(), from_time, to_time, p_unit);
}

//' Get pitch standard deviation directly
//' @param pitch_xptr External pointer to Pitch
//' @param from_time Start time
//' @param to_time End time
//' @param unit Unit code
//' @return Standard deviation
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_get_stdev_direct(pitch$.xptr)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
double pitch_get_stdev_direct(SEXP pitch_xptr, double from_time = 0, double to_time = 0, int unit = 0) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = pitch->xmin;
        to_time = pitch->xmax;
    }
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);
    return Pitch_getStandardDeviation(pitch.get(), from_time, to_time, p_unit);
}

//' Get pitch minimum directly
//' @param pitch_xptr External pointer to Pitch
//' @param from_time Start time
//' @param to_time End time
//' @param unit Unit code
//' @return Minimum pitch
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_get_minimum_direct(pitch$.xptr)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
double pitch_get_minimum_direct(SEXP pitch_xptr, double from_time = 0, double to_time = 0,
                                 int unit = 0, bool interpolate = false) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = pitch->xmin;
        to_time = pitch->xmax;
    }
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);
    return Pitch_getMinimum(pitch.get(), from_time, to_time, p_unit, interpolate);
}

//' Get pitch maximum directly
//' @param pitch_xptr External pointer to Pitch
//' @param from_time Start time
//' @param to_time End time
//' @param unit Unit code
//' @return Maximum pitch
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_get_maximum_direct(pitch$.xptr)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
double pitch_get_maximum_direct(SEXP pitch_xptr, double from_time = 0, double to_time = 0,
                                 int unit = 0, bool interpolate = false) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = pitch->xmin;
        to_time = pitch->xmax;
    }
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);
    return Pitch_getMaximum(pitch.get(), from_time, to_time, p_unit, interpolate);
}

//' Get pitch quantile directly
//' @param pitch_xptr External pointer to Pitch
//' @param quantile Quantile (0-1, 0.5 = median)
//' @param from_time Start time
//' @param to_time End time
//' @param unit Unit code
//' @return Quantile value
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_get_quantile_direct(pitch$.xptr, 0.5)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
double pitch_get_quantile_direct(SEXP pitch_xptr, double quantile,
                                  double from_time = 0, double to_time = 0, int unit = 0) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = pitch->xmin;
        to_time = pitch->xmax;
    }
    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);
    return Pitch_getQuantile(pitch.get(), from_time, to_time, quantile, p_unit);
}

//' Count voiced frames directly
//' @param pitch_xptr External pointer to Pitch
//' @return Number of voiced frames
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' pitch <- sound$to_pitch()
//' pladdrr:::pitch_count_voiced_direct(pitch$.xptr)
//' @noRd
// [[Rcpp::export]]
int pitch_count_voiced_direct(SEXP pitch_xptr) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }
    return Pitch_countVoicedFrames(pitch.get());
}

// =============================================================================
// Formant Direct Functions
// =============================================================================

//' Get formant value at time directly
//' @param formant_xptr External pointer to Formant
//' @param formant_number Formant number (1=F1, 2=F2, etc)
//' @param unit 0=Hertz, 1=Bark
//' @return Formant frequency
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
//' formant <- sound$to_formant_burg()
//' pladdrr:::formant_get_value_direct(formant$.xptr, 1, 0.15, 0)
//' @noRd
// [[Rcpp::export]]
double formant_get_value_direct(SEXP formant_xptr, int formant_number, double time, int unit = 0) {
    XPtr<structFormant> formant(formant_xptr);
    if (!formant || formant.get() == nullptr) {
        stop("Invalid Formant pointer");
    }
    kFormant_unit f_unit = static_cast<kFormant_unit>(unit);
    return Formant_getValueAtTime(formant.get(), formant_number, time, f_unit);
}

//' Get formant bandwidth at time directly
//' @param formant_xptr External pointer to Formant
//' @param formant_number Formant number
//' @param unit Unit code
//' @return Bandwidth
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
//' formant <- sound$to_formant_burg()
//' pladdrr:::formant_get_bandwidth_direct(formant$.xptr, 1, 0.15, 0)
//' @noRd
// [[Rcpp::export]]
double formant_get_bandwidth_direct(SEXP formant_xptr, int formant_number, double time, int unit = 0) {
    XPtr<structFormant> formant(formant_xptr);
    if (!formant || formant.get() == nullptr) {
        stop("Invalid Formant pointer");
    }
    kFormant_unit f_unit = static_cast<kFormant_unit>(unit);
    return Formant_getBandwidthAtTime(formant.get(), formant_number, time, f_unit);
}

//' Get formant mean directly
//' @param formant_xptr External pointer to Formant
//' @param formant_number Formant number
//' @param from_time Start time
//' @param to_time End time
//' @param unit Unit code
//' @return Mean formant frequency
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
//' formant <- sound$to_formant_burg()
//' pladdrr:::formant_get_mean_direct(formant$.xptr, 1)
//' @noRd
// [[Rcpp::export]]
double formant_get_mean_direct(SEXP formant_xptr, int formant_number,
                                double from_time = 0, double to_time = 0, int unit = 0) {
    XPtr<structFormant> formant(formant_xptr);
    if (!formant || formant.get() == nullptr) {
        stop("Invalid Formant pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = formant->xmin;
        to_time = formant->xmax;
    }
    kFormant_unit f_unit = static_cast<kFormant_unit>(unit);
    return Formant_getMean(formant.get(), formant_number, from_time, to_time, f_unit);
}

// =============================================================================
// Intensity Direct Functions
// =============================================================================

//' Get intensity value at time directly
//' @param intensity_xptr External pointer to Intensity
//' @param interpolation 0=nearest, 1=linear, 2=cubic, 3=sinc70, 4=sinc700
//' @return Intensity in dB
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' intensity <- sound$to_intensity()
//' pladdrr:::intensity_get_value_direct(intensity$.xptr, 0.25)
//' @noRd
// [[Rcpp::export]]
double intensity_get_value_direct(SEXP intensity_xptr, double time, int interpolation = 2) {
    XPtr<structIntensity> intensity(intensity_xptr);
    if (!intensity || intensity.get() == nullptr) {
        stop("Invalid Intensity pointer");
    }
    kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation);
    return Vector_getValueAtX(intensity.get(), time, 1, interp);
}

//' Get intensity mean directly
//' @param intensity_xptr External pointer to Intensity
//' @param from_time Start time
//' @param to_time End time
//' @param averaging_method 0=energy, 1=sones, 2=dB
//' @return Mean intensity
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' intensity <- sound$to_intensity()
//' pladdrr:::intensity_get_mean_direct(intensity$.xptr)
//' @noRd
// [[Rcpp::export]]
double intensity_get_mean_direct(SEXP intensity_xptr, double from_time = 0, double to_time = 0,
                                  int averaging_method = 0) {
    XPtr<structIntensity> intensity(intensity_xptr);
    if (!intensity || intensity.get() == nullptr) {
        stop("Invalid Intensity pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = intensity->xmin;
        to_time = intensity->xmax;
    }
    return Intensity_getAverage(intensity.get(), from_time, to_time, averaging_method);
}

//' Get intensity minimum directly
//' @param intensity_xptr External pointer to Intensity
//' @param from_time Start time
//' @param to_time End time
//' @return Minimum intensity in dB
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' intensity <- sound$to_intensity()
//' pladdrr:::intensity_get_minimum_direct(intensity$.xptr)
//' @noRd
// [[Rcpp::export]]
double intensity_get_minimum_direct(SEXP intensity_xptr, double from_time = 0, double to_time = 0) {
    XPtr<structIntensity> intensity(intensity_xptr);
    if (!intensity || intensity.get() == nullptr) {
        stop("Invalid Intensity pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = intensity->xmin;
        to_time = intensity->xmax;
    }
    return Vector_getMinimum(intensity.get(), from_time, to_time, kVector_peakInterpolation::NONE);
}

//' Get intensity maximum directly
//' @param intensity_xptr External pointer to Intensity
//' @param from_time Start time
//' @param to_time End time
//' @return Maximum intensity in dB
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' intensity <- sound$to_intensity()
//' pladdrr:::intensity_get_maximum_direct(intensity$.xptr)
//' @noRd
// [[Rcpp::export]]
double intensity_get_maximum_direct(SEXP intensity_xptr, double from_time = 0, double to_time = 0) {
    XPtr<structIntensity> intensity(intensity_xptr);
    if (!intensity || intensity.get() == nullptr) {
        stop("Invalid Intensity pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = intensity->xmin;
        to_time = intensity->xmax;
    }
    return Vector_getMaximum(intensity.get(), from_time, to_time, kVector_peakInterpolation::NONE);
}

// =============================================================================
// Harmonicity Direct Functions
// =============================================================================

//' Get harmonicity value at time directly
//' @param harmonicity_xptr External pointer to Harmonicity
//' @return HNR in dB
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' harmonicity <- sound$to_harmonicity_cc()
//' pladdrr:::harmonicity_get_value_direct(harmonicity$.xptr, 0.25)
//' @noRd
// [[Rcpp::export]]
double harmonicity_get_value_direct(SEXP harmonicity_xptr, double time, int interpolation = 2) {
    XPtr<structHarmonicity> harmonicity(harmonicity_xptr);
    if (!harmonicity || harmonicity.get() == nullptr) {
        stop("Invalid Harmonicity pointer");
    }
    kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation);
    return Vector_getValueAtX(harmonicity.get(), time, 1, interp);
}

//' Get harmonicity mean directly
//' @param harmonicity_xptr External pointer to Harmonicity
//' @param from_time Start time
//' @param to_time End time
//' @return Mean HNR in dB
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' harmonicity <- sound$to_harmonicity_cc()
//' pladdrr:::harmonicity_get_mean_direct(harmonicity$.xptr)
//' @noRd
// [[Rcpp::export]]
double harmonicity_get_mean_direct(SEXP harmonicity_xptr, double from_time = 0, double to_time = 0) {
    XPtr<structHarmonicity> harmonicity(harmonicity_xptr);
    if (!harmonicity || harmonicity.get() == nullptr) {
        stop("Invalid Harmonicity pointer");
    }
    if (from_time == 0 && to_time == 0) {
        from_time = harmonicity->xmin;
        to_time = harmonicity->xmax;
    }
    return Harmonicity_getMean(harmonicity.get(), from_time, to_time);
}

// =============================================================================
// Conversion Direct Functions (return new XPtrs)
// =============================================================================

//' Create Pitch from Sound directly (no R6 wrapping)
//' @param sound_xptr External pointer to Sound
//' @return External pointer to Pitch
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
//' pitch_xptr <- pladdrr:::sound_to_pitch_direct(sound$.xptr)
//' pitch <- Pitch(.xptr = pitch_xptr)
//' @noRd
// [[Rcpp::export]]
SEXP sound_to_pitch_direct(SEXP sound_xptr, double time_step = 0,
                            double pitch_floor = 75, double pitch_ceiling = 600) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    NUMmachar();

    try {
        autoPitch result = Sound_to_Pitch(sound.get(), time_step, pitch_floor, pitch_ceiling);
        Pitch raw = result.releaseToAmbiguousOwner();
        return XPtr<structPitch>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create Pitch from Sound");
    }
}

//' Create Formant from Sound directly (Burg method)
//' @param sound_xptr External pointer to Sound
//' @return External pointer to Formant
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 220, duration = 0.5)
//' formant_xptr <- pladdrr:::sound_to_formant_direct(sound$.xptr)
//' formant <- Formant(.xptr = formant_xptr)
//' @noRd
// [[Rcpp::export]]
SEXP sound_to_formant_direct(SEXP sound_xptr, double time_step = 0,
                              double max_formants = 5, double max_formant = 5500,
                              double window_length = 0.025, double pre_emphasis = 50) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    NUMmachar();

    try {
        autoFormant result = Sound_to_Formant_burg(
            sound.get(), time_step, max_formants, max_formant, window_length, pre_emphasis
        );
        Formant raw = result.releaseToAmbiguousOwner();
        return XPtr<structFormant>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create Formant from Sound");
    }
}

//' Create Intensity from Sound directly
//' @param sound_xptr External pointer to Sound
//' @param minimum_pitch Minimum pitch for analysis (Hz)
//' @inheritParams pladdrr_shared_timeauto time_step
//' @return External pointer to Intensity
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
//' intensity_xptr <- pladdrr:::sound_to_intensity_direct(sound$.xptr)
//' intensity <- Intensity(.xptr = intensity_xptr)
//' @noRd
// [[Rcpp::export]]
SEXP sound_to_intensity_direct(SEXP sound_xptr, double minimum_pitch = 100,
                                double time_step = 0, bool subtract_mean = true) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    NUMmachar();

    try {
        autoIntensity result = Sound_to_Intensity(
            sound.get(), minimum_pitch, time_step, subtract_mean
        );
        Intensity raw = result.releaseToAmbiguousOwner();
        return XPtr<structIntensity>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create Intensity from Sound");
    }
}

//' Create Harmonicity from Sound directly (cross-correlation)
//' @param sound_xptr External pointer to Sound
//' @return External pointer to Harmonicity
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5)
//' harm_xptr <- pladdrr:::sound_to_harmonicity_direct(sound$.xptr)
//' harmonicity <- Harmonicity(.xptr = harm_xptr)
//' @noRd
// [[Rcpp::export]]
SEXP sound_to_harmonicity_direct(SEXP sound_xptr, double time_step = 0.01,
                                  double minimum_pitch = 75, double silence_threshold = 0.1,
                                  double periods_per_window = 1.0) {
    XPtr<structSound> sound(sound_xptr);
    if (!sound || sound.get() == nullptr) {
        stop("Invalid Sound pointer");
    }

    NUMmachar();

    try {
        autoHarmonicity result = Sound_to_Harmonicity_cc(
            sound.get(), time_step, minimum_pitch, silence_threshold, periods_per_window
        );
        Harmonicity raw = result.releaseToAmbiguousOwner();
        return XPtr<structHarmonicity>(raw, true);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create Harmonicity from Sound");
    }
}

// =============================================================================
// Compound Operations (multiple queries in single call)
// =============================================================================

//' Get all common pitch statistics in single call
//' @param pitch_xptr External pointer to Pitch
//' @param from_time Start time
//' @param to_time End time
//' @param unit Unit code
//' @return List with min, max, mean, stdev, median, q25, q75
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 1.0)
//' pitch <- sound$to_pitch()
//' stats <- pladdrr:::pitch_get_all_stats_direct(pitch$.xptr)
//' str(stats)
//' @keywords internal
//' @noRd
// [[Rcpp::export]]
List pitch_get_all_stats_direct(SEXP pitch_xptr, double from_time = 0, double to_time = 0, int unit = 0) {
    XPtr<structPitch> pitch(pitch_xptr);
    if (!pitch || pitch.get() == nullptr) {
        stop("Invalid Pitch pointer");
    }

    if (from_time == 0 && to_time == 0) {
        from_time = pitch->xmin;
        to_time = pitch->xmax;
    }

    kPitch_unit p_unit = static_cast<kPitch_unit>(unit);

    return List::create(
        Named("min") = Pitch_getMinimum(pitch.get(), from_time, to_time, p_unit, false),
        Named("max") = Pitch_getMaximum(pitch.get(), from_time, to_time, p_unit, false),
        Named("mean") = Pitch_getMean(pitch.get(), from_time, to_time, p_unit),
        Named("stdev") = Pitch_getStandardDeviation(pitch.get(), from_time, to_time, p_unit),
        Named("median") = Pitch_getQuantile(pitch.get(), from_time, to_time, 0.5, p_unit),
        Named("q25") = Pitch_getQuantile(pitch.get(), from_time, to_time, 0.25, p_unit),
        Named("q75") = Pitch_getQuantile(pitch.get(), from_time, to_time, 0.75, p_unit),
        Named("count_voiced") = Pitch_countVoicedFrames(pitch.get())
    );
}

//' Get F1-F4 at single time point
//' @param formant_xptr External pointer to Formant
//' @param unit Unit code (0=Hertz, 1=Bark)
//' @return NumericVector with F1, F2, F3, F4
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
//' formant <- sound$to_formant_burg()
//' pladdrr:::formant_get_f1_f4_direct(formant$.xptr, 0.15, 0)
//' @noRd
// [[Rcpp::export]]
NumericVector formant_get_f1_f4_direct(SEXP formant_xptr, double time, int unit = 0) {
    XPtr<structFormant> formant(formant_xptr);
    if (!formant || formant.get() == nullptr) {
        stop("Invalid Formant pointer");
    }

    kFormant_unit f_unit = static_cast<kFormant_unit>(unit);
    NumericVector result(4);

    result[0] = Formant_getValueAtTime(formant.get(), 1, time, f_unit);
    result[1] = Formant_getValueAtTime(formant.get(), 2, time, f_unit);
    result[2] = Formant_getValueAtTime(formant.get(), 3, time, f_unit);
    result[3] = Formant_getValueAtTime(formant.get(), 4, time, f_unit);

    result.names() = CharacterVector::create("F1", "F2", "F3", "F4");
    return result;
}

// =============================================================================
// PointProcess Direct Functions (NEW for VUV performance)
// =============================================================================

//' Get PointProcess mean period directly
//' @param pp_xptr External pointer to PointProcess
//' @inheritParams pladdrr_shared_time0 from_time
//' @return Mean period in seconds
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' pp <- sound$to_point_process_periodic_cc(75, 600)
//' pladdrr:::get_point_process_mean_period_direct(pp$.xptr)
//' @noRd
// [[Rcpp::export]]
double get_point_process_mean_period_direct(SEXP pp_xptr,
                                              double from_time = 0, 
                                              double to_time = 0,
                                              double period_floor = 0.0001, 
                                              double period_ceiling = 0.02,
                                              double max_period_factor = 1.3) {
    XPtr<structPointProcess> pp(pp_xptr);
    if (!pp || pp.get() == nullptr) {
        stop("Invalid PointProcess pointer");
    }
    
    if (from_time == 0 && to_time == 0) {
        from_time = pp->xmin;
        to_time = pp->xmax;
    }
    
    try {
        return PointProcess_getMeanPeriod(pp.get(), from_time, to_time,
                                          period_floor, period_ceiling, 
                                          max_period_factor);
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

//' Get PointProcess standard deviation of periods directly
//' @param pp_xptr External pointer to PointProcess
//' @return Standard deviation of periods
//' @keywords internal
//' @examples
//' sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate = 16000)
//' pp <- sound$to_point_process_periodic_cc(75, 600)
//' pladdrr:::get_point_process_stdev_period_direct(pp$.xptr)
//' @noRd
// [[Rcpp::export]]
double get_point_process_stdev_period_direct(SEXP pp_xptr,
                                               double from_time = 0,
                                               double to_time = 0,
                                               double period_floor = 0.0001,
                                               double period_ceiling = 0.02,
                                               double max_period_factor = 1.3) {
    XPtr<structPointProcess> pp(pp_xptr);
    if (!pp || pp.get() == nullptr) {
        stop("Invalid PointProcess pointer");
    }
    
    if (from_time == 0 && to_time == 0) {
        from_time = pp->xmin;
        to_time = pp->xmax;
    }
    
    try {
        return PointProcess_getStdevPeriod(pp.get(), from_time, to_time,
                                           period_floor, period_ceiling,
                                           max_period_factor);
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}
