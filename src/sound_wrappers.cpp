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
// sound_wrappers.cpp - Rcpp wrappers for Praat Sound object
//
// Provides R6-compatible wrappers for creating, querying, modifying,
// and transforming Praat Sound objects.

// [[Rcpp::interfaces(r, cpp)]]
// [[Rcpp::plugins(cpp17)]]

#include "praat_types.h"  // Must come before Rcpp for type declarations
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"
#include "simd_utils.h"

// Praat headers
#include "fon/Sound.h"
#include "fon/Sound_to_Pitch.h"
#include "praat.github.io/dwtools/Sound_to_Pitch2.h"
#include "fon/Sound_to_Formant.h"
#include "fon/Sound_to_Intensity.h"
#include "fon/Sound_to_Harmonicity.h"
#include "fon/Sound_and_Spectrogram.h"
#include "fon/Sound_and_Spectrum.h"
#include "fon/Sound_to_PointProcess.h"
#include "fon/Pitch_to_PointProcess.h"
#include "fon/Ltas.h"
#include "fon/FormantGrid.h"
#include "praat.github.io/LPC/Sound_to_Formant_mt.h"
#include "praat.github.io/dwtools/Sound_and_Spectrogram_extensions.h"
#include "praat.github.io/dwtools/Spectrogram_extensions.h"
#include "fon/TextGrid.h"
#include "fon/TextGrid_Sound.h"
#include "praat.github.io/dwtools/Sound_and_TextGrid_extensions.h"
#include "praat.github.io/dwtools/Intensity_extensions.h"
#include "praat.github.io/dwtools/TextGrid_extensions.h"  // IntervalTier_cutIntervals_minimumDuration etc.
#include "melder/melder.h"
#include "fon/Pitch_to_PitchTier.h"
#include "fon/DurationTier.h"
#include "fon/RealTier.h"
#include "fon/Manipulation.h"
#include "fon/Vector.h"

using namespace Rcpp;

// Forward declaration - NUMfpp initialization from NUMmachar.cpp
extern void NUMmachar();

// Forward declarations for functions in sound_extensions_minimal.cpp
autoSound Sound_Pitch_changeSpeaker(Sound me, Pitch him,
    double formantMultiplier, double pitchMultiplier,
    double pitchRangeMultiplier, double durationMultiplier);
autoSound Sound_changeSpeaker(Sound me, double pitchMin, double pitchMax,
    double formantMultiplier, double pitchMultiplier,
    double pitchRangeMultiplier, double durationMultiplier);
extern void NUMrandom_initializeSafelyAndUnpredictably();  // RNG initialization

// Helper function to ensure all numeric libraries are initialized
static void ensure_numeric_libs_initialized() {
    static bool initialized = false;
    if (!initialized) {
        NUMmachar();
        NUMrandom_initializeSafelyAndUnpredictably();
        initialized = true;
    }
}


// ============================================================================
// Sound Creation
// ============================================================================

//' Read Sound from file using native Praat readers (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_read_from_file_native)]]
XPtr<structSound> sound_read_from_file_native(std::string path) {
    try {
        // Initialize numeric libraries if needed
        ensure_numeric_libs_initialized();
        
        // Convert path to MelderFile
        structMelderFile file { };
        Melder_pathToFile(Melder_peek8to32(path.c_str()), &file);
        
        // Read sound using native Praat reader (auto-detects format)
        // Supports: WAV, AIFF, AIFC, NeXT/Sun, NIST
        autoSound sound = Sound_readFromSoundFile(&file);
        
        return create_xptr_from_auto<structSound>(sound);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Native sound file reading failed: " + path + 
             "\n(Try different format or check file corruption)");
    }
}

//' Create Sound from values (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_create_from_values)]]
XPtr<structSound> sound_create_from_values(
    NumericMatrix values,
    double sampling_rate,
    double start_time = 0.0
) {
    if (values.ncol() == 0 || values.nrow() == 0) {
        stop("Cannot create sound from empty values");
    }
    if (sampling_rate <= 0.0) {
        stop("Sampling rate must be positive");
    }
    
    try {
        int n_channels = values.nrow();
        int n_samples = values.ncol();
        double duration = n_samples / sampling_rate;
        
        autoSound sound = Sound_createSimple(n_channels, duration, sampling_rate);
        
        // Set start time (xmin)
        sound->xmin = start_time;
        sound->xmax = start_time + duration;
        sound->x1 = start_time + 0.5 * sound->dx;
        
        // Copy values
        for (int ch = 1; ch <= n_channels; ch++) {
            const double* src = &values(ch - 1, 0);
            double* dst = &sound->z[ch][1];
            std::memcpy(dst, src, n_samples * sizeof(double));
        }
        
        return create_xptr_from_auto<structSound>(sound);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create sound from values");
    }
}

//' Create simple tone (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_create_tone)]]
XPtr<structSound> sound_create_tone(
    double duration,
    double sampling_rate,
    double frequency,
    double amplitude
) {
    try {
        autoSound sound = Sound_createSimple(1, duration, sampling_rate);

        // Generate tone
        double* dst = &sound->z[1][1];
        double t = sound->x1;
        for (int i = 0; i < sound->nx; i++) {
            dst[i] = amplitude * sin(2.0 * M_PI * frequency * t);
            t += sound->dx;
        }

        return create_xptr_from_auto<structSound>(sound);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create tone");
    }
}

// [[Rcpp::export(.sound_create_pure_tone)]]
XPtr<structSound> sound_create_pure_tone(
    int channels,
    double starting_time,
    double end_time,
    double sample_rate,
    double frequency,
    double amplitude,
    double fade_in_duration,
    double fade_out_duration
) {
    try {
        autoSound result = Sound_createAsPureTone(
            (integer)channels, starting_time, end_time,
            sample_rate, frequency, amplitude,
            fade_in_duration, fade_out_duration
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create pure tone");
    }
}

// [[Rcpp::export(.sound_create_tone_complex)]]
XPtr<structSound> sound_create_tone_complex(
    double starting_time,
    double end_time,
    double sample_rate,
    int phase,
    double frequency_step,
    double first_frequency,
    double ceiling,
    int number_of_components
) {
    try {
        autoSound result = Sound_createAsToneComplex(
            starting_time, end_time, sample_rate,
            phase, frequency_step, first_frequency,
            ceiling, (integer)number_of_components
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create tone complex");
    }
}

// ============================================================================
// Sound Query Methods
// ============================================================================

//' Get sound duration (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_get_duration)]]
double sound_get_duration(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    return sound->xmax - sound->xmin;
}

//' Get sampling frequency (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_get_sampling_frequency)]]
double sound_get_sampling_frequency(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    return 1.0 / sound->dx;
}

//' Get number of samples (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_get_number_of_samples)]]
int sound_get_number_of_samples(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    return sound->nx;
}

//' Get number of channels (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_get_number_of_channels)]]
int sound_get_number_of_channels(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    return sound->ny;
}

//' Get value at time (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_get_value_at_time)]]
double sound_get_value_at_time(
    XPtr<structSound> xptr,
    double time,
    int channel,
    std::string interpolation = "linear"
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (channel < 1 || channel > sound->ny) {
        stop("Invalid channel number");
    }
    if (time < sound->xmin || time > sound->xmax) {
        return NA_REAL;
    }
    
    // Parse interpolation type
    kVector_valueInterpolation interp_type;
    if (interpolation == "nearest") {
        interp_type = kVector_valueInterpolation::NEAREST;
    } else if (interpolation == "linear") {
        interp_type = kVector_valueInterpolation::LINEAR;
    } else if (interpolation == "cubic") {
        interp_type = kVector_valueInterpolation::CUBIC;
    } else if (interpolation == "sinc70") {
        interp_type = kVector_valueInterpolation::SINC70;
    } else if (interpolation == "sinc700") {
        interp_type = kVector_valueInterpolation::SINC700;
    } else {
        stop("Invalid interpolation type. Must be: nearest, linear, cubic, sinc70, or sinc700");
    }
    
    try {
        return Vector_getValueAtX(
            sound,
            time,
            channel,
            interp_type
        );
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

#ifdef HAVE_XSIMD
extern double sound_get_rms_simd(XPtr<structSound>, double, double);
extern double sound_get_energy_simd(XPtr<structSound>, double, double);
extern double sound_get_power_simd(XPtr<structSound>, double, double);
#endif

//' Get RMS (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_get_rms)]]
double sound_get_rms(
    XPtr<structSound> xptr,
    double from_time,
    double to_time
) {
#ifdef HAVE_XSIMD
    if (use_simd()) {
        return sound_get_rms_simd(xptr, from_time, to_time);
    }
#endif
    
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (from_time == 0.0) from_time = sound->xmin;
    if (to_time == 0.0) to_time = sound->xmax;
    
    try {
        double rms = 0.0;
        for (int ch = 1; ch <= sound->ny; ch++) {
            double channel_rms = Sound_getRootMeanSquare(sound, from_time, to_time);
            rms += channel_rms * channel_rms;
        }
        return sqrt(rms / sound->ny);
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

//' Get energy (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_get_energy)]]
double sound_get_energy(
    XPtr<structSound> xptr,
    double from_time,
    double to_time
) {
#ifdef HAVE_XSIMD
    if (use_simd()) {
        return sound_get_energy_simd(xptr, from_time, to_time);
    }
#endif
    
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (from_time == 0.0) from_time = sound->xmin;
    if (to_time == 0.0) to_time = sound->xmax;
    
    try {
        return Sound_getEnergy(sound, from_time, to_time);
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

//' Get power (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_get_power)]]
double sound_get_power(
    XPtr<structSound> xptr,
    double from_time,
    double to_time
) {
#ifdef HAVE_XSIMD
    if (use_simd()) {
        return sound_get_power_simd(xptr, from_time, to_time);
    }
#endif
    
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (from_time == 0.0) from_time = sound->xmin;
    if (to_time == 0.0) to_time = sound->xmax;
    
    try {
        return Sound_getPower(sound, from_time, to_time);
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

//' Get intensity in dB (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_get_intensity_db)]]
double sound_get_intensity_db(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        double power = Sound_getPower(sound, sound->xmin, sound->xmax);
        if (power <= 0.0) return NA_REAL;
        return 10.0 * log10(power / 4.0e-10);  // Reference: 2e-5 Pa RMS
    } catch (MelderError) {
        Melder_clearError();
        return NA_REAL;
    }
}

// ============================================================================
// Sound Transformation Methods (return new objects)
// ============================================================================

//' Convert Sound to Pitch (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pitch)]]
XPtr<structPitch> sound_to_pitch(
    XPtr<structSound> sound_xptr,
    double time_step,
    double pitch_floor,
    double pitch_ceiling
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    try {
        autoPitch pitch = Sound_to_Pitch(
            sound,
            time_step,
            pitch_floor,
            pitch_ceiling
        );
        
        return create_xptr_from_auto<structPitch>(pitch);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract pitch");
    }
}

//' Convert Sound to Pitch using autocorrelation with full voicing parameters (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pitch_ac)]]
XPtr<structPitch> sound_to_pitch_ac(
    XPtr<structSound> sound_xptr,
    double time_step,
    double pitch_floor,
    double pitch_ceiling,
    int max_candidates,
    bool very_accurate,
    double silence_threshold,
    double voicing_threshold,
    double octave_cost,
    double octave_jump_cost,
    double voiced_unvoiced_cost
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    try {
        autoPitch pitch = Sound_to_Pitch_rawAc(
            sound,
            time_step,
            pitch_floor,
            pitch_ceiling,
            static_cast<integer>(max_candidates),
            very_accurate,
            silence_threshold,
            voicing_threshold,
            octave_cost,
            octave_jump_cost,
            voiced_unvoiced_cost
        );
        
        return create_xptr_from_auto<structPitch>(pitch);
        
    } catch (MelderError) {
        autostring32 error_message = Melder_dup(Melder_getError());
        Melder_clearError();
        std::string error_str = Melder_peek32to8(error_message.get());
        stop("Failed to extract pitch using autocorrelation. Praat error: " + error_str);
    }
}

//' Convert Sound to Pitch using cross-correlation with full voicing parameters (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pitch_cc)]]
XPtr<structPitch> sound_to_pitch_cc(
    XPtr<structSound> sound_xptr,
    double time_step,
    double pitch_floor,
    double pitch_ceiling,
    int max_candidates,
    bool very_accurate,
    double silence_threshold,
    double voicing_threshold,
    double octave_cost,
    double octave_jump_cost,
    double voiced_unvoiced_cost
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    try {
        autoPitch pitch = Sound_to_Pitch_rawCc(
            sound,
            time_step,
            pitch_floor,
            pitch_ceiling,
            static_cast<integer>(max_candidates),
            very_accurate,
            silence_threshold,
            voicing_threshold,
            octave_cost,
            octave_jump_cost,
            voiced_unvoiced_cost
        );
        
        return create_xptr_from_auto<structPitch>(pitch);
        
    } catch (MelderError) {
        autostring32 error_message = Melder_dup(Melder_getError());
        Melder_clearError();
        std::string error_str = Melder_peek32to8(error_message.get());
        stop("Failed to extract pitch using cross-correlation. Praat error: " + error_str);
    }
}

//' Convert Sound to Pitch using Subharmonic Summation (SHS) (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pitch_shs)]]
XPtr<structPitch> sound_to_pitch_shs(
    XPtr<structSound> sound_xptr,
    double time_step,
    double pitch_floor,
    double max_frequency,
    double pitch_ceiling,
    int max_subharmonics,
    int max_candidates,
    double compression_factor,
    int n_points_per_octave
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");

    try {
        autoPitch pitch = Sound_to_Pitch_shs(
            sound,
            time_step,
            pitch_floor,
            max_frequency,
            pitch_ceiling,
            static_cast<integer>(max_subharmonics),
            static_cast<integer>(max_candidates),
            compression_factor,
            static_cast<integer>(n_points_per_octave)
        );

        return create_xptr_from_auto<structPitch>(pitch);

    } catch (MelderError) {
        autostring32 error_message = Melder_dup(Melder_getError());
        Melder_clearError();
        std::string error_str = Melder_peek32to8(error_message.get());
        stop("Failed to extract pitch using SHS. Praat error: " + error_str);
    }
}

//' Convert Sound to Pitch using SPINET (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pitch_spinet)]]
XPtr<structPitch> sound_to_pitch_spinet(
    XPtr<structSound> sound_xptr,
    double time_step,
    double window_duration,
    double min_frequency,
    double max_frequency,
    int n_filters,
    double pitch_ceiling,
    int max_candidates
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");

    try {
        autoPitch pitch = Sound_to_Pitch_SPINET(
            sound,
            time_step,
            window_duration,
            min_frequency,
            max_frequency,
            static_cast<integer>(n_filters),
            pitch_ceiling,
            max_candidates
        );

        return create_xptr_from_auto<structPitch>(pitch);

    } catch (MelderError) {
        autostring32 error_message = Melder_dup(Melder_getError());
        Melder_clearError();
        std::string error_str = Melder_peek32to8(error_message.get());
        stop("Failed to extract pitch using SPINET. Praat error: " + error_str);
    }
}

//' Convert Sound to Formant via Burg (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_formant_burg)]]
XPtr<structFormant> sound_to_formant_burg(
    XPtr<structSound> sound_xptr,
    double time_step,
    double max_formants,
    double max_frequency,
    double window_length,
    double pre_emphasis_from
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    // Ensure NUMfpp is initialized
    NUMmachar();

    
    try {
        autoFormant formant = Sound_to_Formant_burg(
            sound,
            time_step,
            max_formants,
            max_frequency,
            window_length,
            pre_emphasis_from
        );
        
        return create_xptr_from_auto<structFormant>(formant);
        
    } catch (MelderError) {
        std::string error_msg = "Failed to extract formants: ";
        conststring32 praat_error = Melder_getError();
        if (praat_error) {
            error_msg += Melder_peek32to8(praat_error);
        }
        Melder_clearError();
        stop(error_msg);
    }
}

//' Convert Sound to Intensity (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_intensity)]]
XPtr<structIntensity> sound_to_intensity(
    XPtr<structSound> sound_xptr,
    double minimum_pitch,
    double time_step,
    bool subtract_mean
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    try {
        autoIntensity intensity = Sound_to_Intensity(
            sound,
            minimum_pitch,
            time_step,
            subtract_mean
        );
        
        return create_xptr_from_auto<structIntensity>(intensity);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract intensity");
    }
}

//' Convert Sound to Harmonicity (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_harmonicity_cc)]]
XPtr<structHarmonicity> sound_to_harmonicity_cc(
    XPtr<structSound> sound_xptr,
    double time_step,
    double min_pitch,
    double silence_threshold,
    double periods_per_window
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    try {
        autoHarmonicity hnr = Sound_to_Harmonicity_cc(
            sound,
            time_step,
            min_pitch,
            silence_threshold,
            periods_per_window
        );
        
        return create_xptr_from_auto<structHarmonicity>(hnr);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract harmonicity (cc)");
    }
}

//' Convert Sound to Harmonicity using autocorrelation (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_harmonicity_ac)]]
XPtr<structHarmonicity> sound_to_harmonicity_ac(
    XPtr<structSound> sound_xptr,
    double time_step,
    double min_pitch,
    double silence_threshold,
    double periods_per_window
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");

    try {
        autoHarmonicity hnr = Sound_to_Harmonicity_ac(
            sound,
            time_step,
            min_pitch,
            silence_threshold,
            periods_per_window
        );

        return create_xptr_from_auto<structHarmonicity>(hnr);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract harmonicity (ac)");
    }
}

//' Convert Sound to Harmonicity (GNE - Glottal-to-Noise Excitation ratio)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_harmonicity_gne)]]
XPtr<structMatrix> sound_to_harmonicity_gne(
    XPtr<structSound> sound_xptr,
    double fmin,
    double fmax,
    double bandwidth,
    double step
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    try {
        autoMatrix gne = Sound_to_Harmonicity_GNE(
            sound,
            fmin,
            fmax,
            bandwidth,
            step
        );
        
        return create_xptr_from_auto<structMatrix>(gne);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to compute GNE");
    }
}

//' Convert Sound to Spectrum (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_spectrum)]]
XPtr<structSpectrum> sound_to_spectrum(
    XPtr<structSound> sound_xptr,
    bool fast
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    try {
        autoSpectrum spectrum = Sound_to_Spectrum(sound, fast);
        return create_xptr_from_auto<structSpectrum>(spectrum);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create spectrum");
    }
}

//' Convert Sound to Ltas (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_ltas)]]
SEXP sound_to_ltas(
    XPtr<structSound> sound_xptr,
    double bandwidth
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    try {
        autoLtas ltas = Sound_to_Ltas(sound, bandwidth);
        return create_xptr_from_auto<structLtas>(ltas);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create Ltas");
    }
}

//' Convert Sound to Spectrogram (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_spectrogram)]]
XPtr<structSpectrogram> sound_to_spectrogram(
    XPtr<structSound> sound_xptr,
    double window_length,
    double max_frequency,
    double time_step,
    double frequency_step,
    std::string window_shape
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    try {
        // Convert window shape string to enum
        kSound_to_Spectrogram_windowShape shape;
        if (window_shape == "square" || window_shape == "Square" || window_shape == "SQUARE") {
            shape = kSound_to_Spectrogram_windowShape::SQUARE;
        } else if (window_shape == "Hamming" || window_shape == "hamming" || window_shape == "HAMMING") {
            shape = kSound_to_Spectrogram_windowShape::HAMMING;
        } else if (window_shape == "Bartlett" || window_shape == "bartlett" || window_shape == "BARTLETT") {
            shape = kSound_to_Spectrogram_windowShape::BARTLETT;
        } else if (window_shape == "Welch" || window_shape == "welch" || window_shape == "WELCH") {
            shape = kSound_to_Spectrogram_windowShape::WELCH;
        } else if (window_shape == "Hanning" || window_shape == "hanning" || window_shape == "HANNING") {
            shape = kSound_to_Spectrogram_windowShape::HANNING;
        } else if (window_shape == "Gaussian" || window_shape == "gaussian" || window_shape == "GAUSSIAN") {
            shape = kSound_to_Spectrogram_windowShape::GAUSSIAN;
        } else {
            stop("Unknown window shape: " + window_shape + ". Must be one of: square, Hamming, Bartlett, Welch, Hanning, Gaussian");
        }
        
        // Use Praat's Sound_to_Spectrogram_e function
        // Maximum oversampling factors set to 8 (Praat defaults)
        autoSpectrogram spectrogram = Sound_to_Spectrogram_e(
            sound,
            window_length,      // effectiveAnalysisWidth
            max_frequency,      // fmax
            time_step,          // minimumTimeStep1
            frequency_step,     // minimumFreqStep1
            shape,              // windowShape
            8.0,                // maximumTimeOversampling
            8.0                 // maximumFreqOversampling
        );
        
        return create_xptr_from_auto<structSpectrogram>(spectrogram);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create spectrogram");
    }
}

// ============================================================================
// Sound File Writing
// ============================================================================

//' Write Sound to file using native Praat writers (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_write_to_file_native)]]
void sound_write_to_file_native(
    XPtr<structSound> sound_xptr,
    std::string path,
    std::string format,
    int bits_per_sample
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    ensure_numeric_libs_initialized();
    
    try {
        // Convert format string to Praat constant
        int praat_format = 0;
        std::string fmt_upper = format;
        std::transform(fmt_upper.begin(), fmt_upper.end(), fmt_upper.begin(), ::toupper);
        
        if (fmt_upper == "WAV") {
            praat_format = Melder_WAV;
        } else if (fmt_upper == "AIFF" || fmt_upper == "AIF") {
            praat_format = Melder_AIFF;
        } else if (fmt_upper == "AIFC") {
            praat_format = Melder_AIFC;
        } else if (fmt_upper == "NIST") {
            praat_format = Melder_NIST;
        } else if (fmt_upper == "NEXT" || fmt_upper == "SUN" || fmt_upper == "AU") {
            praat_format = Melder_NEXT_SUN;
        } else {
            stop("Unsupported format: " + format + 
                 ". Supported: WAV, AIFF, AIFC, NIST, NEXT/SUN");
        }
        
        // Validate bits per sample
        if (bits_per_sample != 16 && bits_per_sample != 24 && bits_per_sample != 32) {
            stop("bits_per_sample must be 16, 24, or 32");
        }
        
        // Create Praat MelderFile
        structMelderFile file { };
        Melder_pathToFile(Melder_peek8to32(path.c_str()), &file);
        
        // Write using Praat's native writer
        Sound_saveAsAudioFile(sound, &file, praat_format, bits_per_sample);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to write Sound to file: " + path);
    }
}

// ============================================================================
// Sound Export Methods
// ============================================================================

//' Export Sound as data frame (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_as_data_frame)]]
DataFrame sound_as_data_frame(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    int n_samples = sound->nx;
    int n_channels = sound->ny;
    int total_rows = n_samples * n_channels;
    
    NumericVector time(total_rows);
    IntegerVector channel(total_rows);
    NumericVector value(total_rows);
    
    int row = 0;
    for (int ch = 1; ch <= n_channels; ch++) {
        for (int i = 1; i <= n_samples; i++) {
            time[row] = sound->x1 + (i - 1) * sound->dx;
            channel[row] = ch;
            value[row] = sound->z[ch][i];
            row++;
        }
    }
    
    return DataFrame::create(
        Named("time") = time,
        Named("channel") = channel,
        Named("value") = value
    );
}

//' Export Sound as matrix (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_as_matrix)]]
NumericMatrix sound_as_matrix(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    NumericMatrix mat(sound->ny, sound->nx);
    
    // Copy channels with SIMD optimization
    for (int ch = 1; ch <= sound->ny; ch++) {
        const double* src = &sound->z[ch][1];
        double* dst = &mat(ch - 1, 0);
        std::memcpy(dst, src, sound->nx * sizeof(double));
    }
    
    return mat;
}

//' Save Sound to file (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_save)]]
void sound_save(
    XPtr<structSound> xptr,
    std::string path,
    int file_type
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        
        // file_type: 0 = WAV, 1 = AIFF, 2 = AIFC, 3 = NeXT/Sun, 4 = NIST, 5 = FLAC
        int format_int = file_type;
        
        Sound_saveAsAudioFile(sound, &file, format_int, 16);  // 16-bit
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to save sound to: " + path);
    }
}

// ============================================================================
// Sound to PointProcess Conversions
// ============================================================================

//' Create PointProcess from Sound and Pitch using cross-correlation (internal)
//' 
//' This is the critical two-object command needed for DSI.
//' Praat equivalent: Select Sound and Pitch, then "To PointProcess (cc)"
//' 
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_pitch_to_pointprocess_cc)]]
XPtr<structPointProcess> sound_pitch_to_pointprocess_cc(
    XPtr<structSound> sound_xptr,
    XPtr<structPitch> pitch_xptr
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    structPitch* pitch = get_ptr(pitch_xptr, "Pitch");
    
    try {
        // TWO-OBJECT COMMAND: [Sound, Pitch] -> To PointProcess (cc)
        autoPointProcess pp = Sound_Pitch_to_PointProcess_cc(sound, pitch);
        return create_xptr_from_auto<structPointProcess>(pp);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create PointProcess from Sound and Pitch (cc)");
    }
}

//' Create PointProcess from Sound and Pitch near peaks (internal)
//' 
//' Two-object command: uses existing Pitch object to guide peak detection.
//' Praat equivalent: Select Sound and Pitch, then "To PointProcess (peaks)..."
//' 
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_pitch_to_pointprocess_peaks)]]
XPtr<structPointProcess> sound_pitch_to_pointprocess_peaks(
    XPtr<structSound> sound_xptr,
    XPtr<structPitch> pitch_xptr,
    bool include_maxima,
    bool include_minima
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    structPitch* pitch = get_ptr(pitch_xptr, "Pitch");
    
    try {
        // TWO-OBJECT COMMAND: [Sound, Pitch] -> To PointProcess (peaks)
        autoPointProcess pp = Sound_Pitch_to_PointProcess_peaks(
            sound, pitch, include_maxima, include_minima
        );
        return create_xptr_from_auto<structPointProcess>(pp);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create PointProcess from Sound and Pitch (peaks)");
    }
}

//' Extract glottal pulses from sound using cross-correlation (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_point_process_periodic_cc)]]
XPtr<structPointProcess> sound_to_point_process_periodic_cc(
    XPtr<structSound> xptr,
    double time_step,
    double pitch_floor,
    double pitch_ceiling,
    double max_period_factor,
    double max_amplitude_factor
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        // First create pitch object
        autoPitch pitch = Sound_to_Pitch(sound, time_step, pitch_floor, pitch_ceiling);
        
        // Then create PointProcess from Sound and Pitch
        autoPointProcess pp = Sound_Pitch_to_PointProcess_cc(sound, pitch.get());
        
        return create_xptr_from_auto<structPointProcess>(pp);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract glottal pulses from sound");
    }
}

//' Extract extrema (peaks) from sound (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_point_process_extrema)]]
XPtr<structPointProcess> sound_to_point_process_extrema(
    XPtr<structSound> xptr,
    int channel,
    bool include_maxima,
    bool include_minima,
    int interpolation
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        // Convert interpolation int to enum
        kVector_peakInterpolation interp_type = static_cast<kVector_peakInterpolation>(interpolation);
        
        autoPointProcess pp = Sound_to_PointProcess_extrema(
            sound,
            channel,
            interp_type,
            include_maxima,
            include_minima
        );
        
        return create_xptr_from_auto<structPointProcess>(pp);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract extrema from sound");
    }
}

//' Extract zero crossings from sound (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_point_process_zeros)]]
XPtr<structPointProcess> sound_to_point_process_zeros(
    XPtr<structSound> xptr,
    int channel,
    bool include_raisers,
    bool include_fallers
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        autoPointProcess pp = Sound_to_PointProcess_zeroes(
            sound,
            channel,
            include_raisers,
            include_fallers
        );
        
        return create_xptr_from_auto<structPointProcess>(pp);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract zero crossings from sound");
    }
}

//' Extract periodic pulses using cross-correlation (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pointprocess_periodic_cc)]]
XPtr<structPointProcess> sound_to_pointprocess_periodic_cc(
    XPtr<structSound> xptr,
    double pitch_floor,
    double pitch_ceiling
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        autoPointProcess pp = Sound_to_PointProcess_periodic_cc(
            sound,
            pitch_floor,
            pitch_ceiling
        );
        
        return create_xptr_from_auto<structPointProcess>(pp);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract periodic pulses (cross-correlation method)");
    }
}

//' Extract periodic pulses using peak detection (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pointprocess_periodic_peaks)]]
XPtr<structPointProcess> sound_to_pointprocess_periodic_peaks(
    XPtr<structSound> xptr,
    double pitch_floor,
    double pitch_ceiling,
    bool include_maxima,
    bool include_minima
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        autoPointProcess pp = Sound_to_PointProcess_periodic_peaks(
            sound,
            pitch_floor,
            pitch_ceiling,
            include_maxima,
            include_minima
        );
        
        return create_xptr_from_auto<structPointProcess>(pp);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract periodic pulses (peak detection method)");
    }
}

// ============================================================================
// Sound Extraction Methods
// ============================================================================

//' Extract a specific channel from Sound (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_extract_channel)]]
XPtr<structSound> sound_extract_channel(
    XPtr<structSound> xptr,
    int channel
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (channel < 1 || channel > sound->ny) {
        stop("Channel must be between 1 and " + std::to_string(sound->ny));
    }
    
    try {
        autoSound extracted = Sound_extractChannel(sound, channel);
        return create_xptr_from_auto<structSound>(extracted);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract channel from sound");
    }
}

//' Extract part of Sound by time (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_extract_part)]]
XPtr<structSound> sound_extract_part(
    XPtr<structSound> xptr,
    double from_time,
    double to_time,
    int window_shape,
    double relative_width,
    bool preserve_times
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        kSound_windowShape window = static_cast<kSound_windowShape>(window_shape);
        
        autoSound extracted = Sound_extractPart(
            sound,
            from_time,
            to_time,
            window,
            relative_width,
            preserve_times
        );
        
        return create_xptr_from_auto<structSound>(extracted);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract part of sound");
    }
}

// ============================================================================
// Sound Modification Methods
// ============================================================================

//' Scale intensity of Sound to target dB level (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_scale_intensity)]]
void sound_scale_intensity(
    XPtr<structSound> xptr,
    double new_intensity_db
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        Sound_scaleIntensity(sound, new_intensity_db);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to scale intensity");
    }
}

#ifdef HAVE_XSIMD
extern void sound_scale_peak_simd(XPtr<structSound>, double);
extern XPtr<structSound> sound_mix_simd(XPtr<structSound>, XPtr<structSound>, double);
#endif

//' Scale peak amplitude of Sound (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_scale_peak)]]
void sound_scale_peak(
    XPtr<structSound> xptr,
    double new_peak
) {
#ifdef HAVE_XSIMD
    if (use_simd()) {
        sound_scale_peak_simd(xptr, new_peak);
        return;
    }
#endif
    
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        Vector_scale(sound, new_peak);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to scale peak");
    }
}

//' Pre-emphasize Sound (high-pass filter) (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_pre_emphasize)]]
void sound_pre_emphasize(
    XPtr<structSound> xptr,
    double from_frequency
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        Sound_preEmphasize_inplace(sound, from_frequency);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to pre-emphasize sound");
    }
}

//' De-emphasize Sound (low-pass filter) (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_de_emphasize)]]
void sound_de_emphasize(
    XPtr<structSound> xptr,
    double from_frequency
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        Sound_deEmphasize_inplace(sound, from_frequency);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to de-emphasize sound");
    }
}

//' Filter Sound - pass Hann band (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_filter_pass_hann_band)]]
XPtr<structSound> sound_filter_pass_hann_band(
    XPtr<structSound> xptr,
    double fmin,
    double fmax,
    double smooth
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        autoSound filtered = Sound_filter_passHannBand(sound, fmin, fmax, smooth);
        return create_xptr_from_auto<structSound>(filtered);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to apply pass Hann band filter");
    }
}

//' Filter Sound - stop Hann band (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_filter_stop_hann_band)]]
XPtr<structSound> sound_filter_stop_hann_band(
    XPtr<structSound> xptr,
    double fmin,
    double fmax,
    double smooth
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        autoSound filtered = Sound_filter_stopHannBand(sound, fmin, fmax, smooth);
        return create_xptr_from_auto<structSound>(filtered);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to apply stop Hann band filter");
    }
}


// ============================================================================
// Advanced Sound Modification Methods (return new Sound)
// ============================================================================

//' Resample Sound to new sampling frequency (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_resample)]]
XPtr<structSound> sound_resample(
    XPtr<structSound> xptr,
    double new_frequency,
    int precision
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        autoSound resampled = Sound_resample(sound, new_frequency, precision);
        return create_xptr_from_auto<structSound>(resampled);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to resample sound");
    }
}

//' Convert Sound to mono by averaging channels (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_convert_to_mono)]]
XPtr<structSound> sound_convert_to_mono(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        autoSound mono = Sound_convertToMono(sound);
        return create_xptr_from_auto<structSound>(mono);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert sound to mono");
    }
}

//' Convert mono Sound to stereo by duplicating channel (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_convert_to_stereo)]]
XPtr<structSound> sound_convert_to_stereo(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        autoSound stereo = Sound_convertToStereo(sound);
        return create_xptr_from_auto<structSound>(stereo);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert sound to stereo");
    }
}

//' Copy Sound object (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_copy)]]
XPtr<structSound> sound_copy(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    try {
        autoSound copy = Data_copy(sound);
        return create_xptr_from_auto<structSound>(copy);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to copy sound");
    }
}

//' Concatenate two Sound objects (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_concatenate)]]
XPtr<structSound> sound_concatenate(
    XPtr<structSound> xptr1,
    XPtr<structSound> xptr2,
    double overlap
) {
    structSound* sound1 = get_ptr(xptr1, "Sound");
    structSound* sound2 = get_ptr(xptr2, "Sound");
    
    try {
        // Create SoundList referencing the inputs; Sounds_concatenate only reads
        autoSoundList list = SoundList_create();
        list->addItem_ref(sound1);
        list->addItem_ref(sound2);
        
        // Concatenate with overlap
        autoSound concatenated = Sounds_concatenate(list.get(), overlap);
        return create_xptr_from_auto<structSound>(concatenated);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to concatenate sounds");
    }
}

//' Mix two Sound objects (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_mix)]]
XPtr<structSound> sound_mix(
    XPtr<structSound> xptr1,
    XPtr<structSound> xptr2,
    double balance
) {
#ifdef HAVE_XSIMD
    if (use_simd()) {
        return sound_mix_simd(xptr1, xptr2, balance);
    }
#endif
    
    structSound* sound1 = get_ptr(xptr1, "Sound");
    structSound* sound2 = get_ptr(xptr2, "Sound");
    
    try {
        // Sounds_convolve_same creates a sound of same duration by overlapping
        // For mixing, we want to add the waveforms with a balance factor
        
        // Ensure sounds have same sampling frequency
        if (sound1->dx != sound2->dx) {
            Melder_throw(U"Sounds must have same sampling frequency to mix");
        }
        
        // Create result with duration = max of the two
        double xmax = std::max(sound1->xmax, sound2->xmax);
        double xmin = std::min(sound1->xmin, sound2->xmin);
        integer nx = Melder_iceiling((xmax - xmin) / sound1->dx);
        integer ny = std::max(sound1->ny, sound2->ny);
        
        autoSound mixed = Sound_create(ny, xmin, xmax, nx, sound1->dx, sound1->x1);
        
        // Mix channels with balance
        for (integer ich = 1; ich <= ny; ich++) {
            for (integer i = 1; i <= nx; i++) {
                double t = mixed->x1 + (i - 1) * mixed->dx;
                double val1 = 0.0, val2 = 0.0;
                
                // Get value from sound1 if time is within range
                if (t >= sound1->xmin && t <= sound1->xmax && ich <= sound1->ny) {
                    integer i1 = Sampled_xToNearestIndex(sound1, t);
                    if (i1 >= 1 && i1 <= sound1->nx) {
                        val1 = sound1->z[ich][i1];
                    }
                }
                
                // Get value from sound2 if time is within range
                if (t >= sound2->xmin && t <= sound2->xmax && ich <= sound2->ny) {
                    integer i2 = Sampled_xToNearestIndex(sound2, t);
                    if (i2 >= 1 && i2 <= sound2->nx) {
                        val2 = sound2->z[ich][i2];
                    }
                }
                
                // Mix with balance: (s1 + balance * s2) / (1 + balance)
                mixed->z[ich][i] = (val1 + balance * val2) / (1.0 + balance);
            }
        }
        
        return create_xptr_from_auto<structSound>(mixed);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to mix sounds");
    }
}

// ============================================================================
// Sound to TextGrid conversions
// ============================================================================

//' Detect silences in Sound and create TextGrid (internal)
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_textgrid_silences)]]
XPtr<structTextGrid> sound_to_textgrid_silences(
    XPtr<structSound> sound_xptr,
    double min_pitch,
    double time_step,
    double silence_threshold,
    double min_silent_duration,
    double min_sounding_duration,
    std::string silent_label,
    std::string sounding_label
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    if (!sound) {
        stop("Invalid Sound pointer");
    }
    
    // Validate parameters
    if (min_pitch <= 0.0) {
        stop("min_pitch must be positive");
    }
    if (time_step < 0.0) {
        stop("time_step must be non-negative");
    }
    if (min_silent_duration < 0.0 || min_sounding_duration < 0.0) {
        stop("Duration parameters must be non-negative");
    }
    
    try {
        // Step 1: Convert Sound to Intensity
        autoIntensity intensity = Sound_to_Intensity(
            sound,
            min_pitch,
            time_step,
            true  // subtract mean pressure
        );
        
        if (!intensity) {
            stop("Failed to create Intensity from Sound");
        }
        
        // Step 2: Find maximum intensity manually (avoid buggy Vector_getMaximumAndX)
        double max_intensity_db = -1000.0;
        for (integer i = 1; i <= intensity->nx; i++) {
            if (intensity->z[1][i] > max_intensity_db) {
                max_intensity_db = intensity->z[1][i];
            }
        }
        
        // Calculate threshold relative to maximum
        double intensity_threshold = max_intensity_db + silence_threshold;  // silence_threshold is negative
        
        // Step 3: Create TextGrid manually
        autostring32 silent_u32 = Melder_8to32(silent_label.c_str());
        autostring32 sounding_u32 = Melder_8to32(sounding_label.c_str());
        
        autoTextGrid textgrid = TextGrid_create(intensity->xmin, intensity->xmax, U"silences", U"");
        IntervalTier tier = (IntervalTier) textgrid->tiers->at[1];
        
        // Step 4: Detect all boundaries first
        std::vector<double> boundaries;
        bool in_silence = intensity->z[1][1] < intensity_threshold;
        
        for (integer i = 2; i <= intensity->nx; i++) {
            bool current_is_silent = intensity->z[1][i] < intensity_threshold;
            
            if (current_is_silent != in_silence) {
                double boundary_time = intensity->x1 + (i - 1) * intensity->dx;
                boundaries.push_back(boundary_time);
                in_silence = current_is_silent;
            }
        }
        
        // Insert all boundaries
        for (double boundary_time : boundaries) {
            TextGrid_insertBoundary(textgrid.get(), 1, boundary_time);
        }
        
        // Step 5: Set labels for all intervals
        tier = (IntervalTier) textgrid->tiers->at[1];  // Refresh tier pointer
        for (integer i = 1; i <= tier->intervals.size; i++) {
            TextInterval interval = tier->intervals.at[i];
            double mid_time = (interval->xmin + interval->xmax) / 2.0;
            
            // Find intensity value at midpoint
            integer frame_index = Sampled_xToNearestIndex(intensity.get(), mid_time);
            if (frame_index < 1) frame_index = 1;
            if (frame_index > intensity->nx) frame_index = intensity->nx;
            
            bool is_silent = intensity->z[1][frame_index] < intensity_threshold;
            TextInterval_setText(interval, is_silent ? silent_u32.get() : sounding_u32.get());
        }
        
        // Step 6: Merge short intervals
        // (TODO: implement min_silent_duration and min_sounding_duration filtering)
        
        return create_xptr_from_auto<structTextGrid>(textgrid);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to detect silences in sound");
    }
}

// ============================================================================
// TextGrid interval extraction
// ============================================================================

// [[Rcpp::export(.sound_extract_intervals_where)]]
Rcpp::List sound_extract_intervals_where(
    XPtr<structSound> sound_xptr,
    XPtr<structTextGrid> textgrid_xptr,
    int tier_number,
    int which_comparison,
    std::string text_pattern
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    structTextGrid* textgrid = get_ptr(textgrid_xptr, "TextGrid");
    
    try {
        // Extract matching intervals using Praat function
        autoSoundList sounds = TextGrid_Sound_extractIntervalsWhere(
            textgrid,
            sound,
            tier_number,
            static_cast<kMelder_string>(which_comparison),
            Melder_peek8to32(text_pattern.c_str()),
            false  // preserveTimes
        );
        
        return move_collection_to_xptr_list(sounds);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract sound intervals");
    }
}

// ============================================================================
// BATCH OPERATIONS - Minimize R→C boundary crossings
// These functions process multiple items in a single C++ call
// ============================================================================

//' Concatenate multiple Sound objects in one C++ call (internal)
//'
//' This avoids O(n) R→C boundary crossings that occur with Reduce(concatenate, sounds).
//' All concatenation happens at C++ level with a single result returned.
//'
//' @param sound_list List of Sound external pointers
//' @param overlap Overlap duration in seconds between consecutive sounds
//' @return Single concatenated Sound external pointer
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_concatenate_all)]]
XPtr<structSound> sound_concatenate_all(
    Rcpp::List sound_list,
    double overlap = 0.0
) {
    if (sound_list.size() == 0) {
        stop("Cannot concatenate empty list of sounds");
    }

    // Helper function to extract XPtr from R6 object or raw pointer
    auto extract_xptr = [](SEXP item) -> XPtr<structSound> {
        if (Rf_isEnvironment(item)) {
            // R6 object - extract pointer from .xptr field
            Rcpp::Environment env(item);
            if (env.exists(".xptr")) {
                return XPtr<structSound>(env[".xptr"]);
            } else {
                stop("Sound R6 object missing .xptr field");
            }
        } else if (TYPEOF(item) == EXTPTRSXP) {
            // Raw external pointer
            return XPtr<structSound>(item);
        } else {
            stop("Element is not a Sound object or pointer");
        }
    };

    if (sound_list.size() == 1) {
        // Single sound - just return a copy
        XPtr<structSound> xptr = extract_xptr(sound_list[0]);
        structSound* sound = get_ptr(xptr, "Sound");
        try {
            autoSound copy = Data_copy(sound);
            return create_xptr_from_auto<structSound>(copy);
        } catch (MelderError) {
            Melder_clearError();
            stop("Failed to copy sound");
        }
    }

    try {
        // Create SoundList and add all sounds
        autoSoundList list = SoundList_create();

        // Reference the inputs instead of copying; Sounds_concatenate only reads
        for (int i = 0; i < sound_list.size(); i++) {
            XPtr<structSound> xptr = extract_xptr(sound_list[i]);
            structSound* sound = get_ptr(xptr, "Sound");
            list->addItem_ref(sound);
        }

        // Concatenate all at once with overlap
        autoSound concatenated = Sounds_concatenate(list.get(), overlap);
        return create_xptr_from_auto<structSound>(concatenated);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to concatenate sounds");
    }
}

//' Extract multiple parts from Sound in one C++ call (internal)
//'
//' Extracts all time ranges in a single C++ call, returning a list of Sound xptrs.
//' Avoids O(n) R→C boundary crossings from calling extract_part() in a loop.
//'
//' @param xptr Sound external pointer
//' @param from_times Numeric vector of start times
//' @param to_times Numeric vector of end times
//' @param window_shape Window shape (0=rectangular, etc.)
//' @param relative_width Relative width for windowing
//' @param preserve_times Whether to preserve original times
//' @return List of Sound external pointers
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_extract_parts_batch)]]
Rcpp::List sound_extract_parts_batch(
    XPtr<structSound> xptr,
    NumericVector from_times,
    NumericVector to_times,
    int window_shape = 0,
    double relative_width = 1.0,
    bool preserve_times = false
) {
    structSound* sound = get_ptr(xptr, "Sound");

    if (from_times.size() != to_times.size()) {
        stop("from_times and to_times must have same length");
    }

    int n = from_times.size();
    Rcpp::List result(n);

    try {
        kSound_windowShape window = static_cast<kSound_windowShape>(window_shape);

        for (int i = 0; i < n; i++) {
            autoSound extracted = Sound_extractPart(
                sound,
                from_times[i],
                to_times[i],
                window,
                relative_width,
                preserve_times
            );
            result[i] = create_xptr_from_auto<structSound>(extracted);
        }

        return result;

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract parts from sound");
    }
}

//' Extract pitch from multiple sounds in one C++ call (internal)
//'
//' Processes a list of Sound objects and returns list of Pitch objects.
//' Avoids O(n) R→C boundary crossings from calling to_pitch() in a loop.
//'
//' @param sound_list List of Sound external pointers
//' @param time_step Time step (0 = automatic)
//' @param pitch_floor Pitch floor in Hz
//' @param pitch_ceiling Pitch ceiling in Hz
//' @return List of Pitch external pointers
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pitch_batch)]]
Rcpp::List sound_to_pitch_batch(
    Rcpp::List sound_list,
    double time_step = 0.0,
    double pitch_floor = 75.0,
    double pitch_ceiling = 600.0
) {
    int n = sound_list.size();
    Rcpp::List result(n);

    try {
        for (int i = 0; i < n; i++) {
            XPtr<structSound> xptr = sound_list[i];
            structSound* sound = get_ptr(xptr, "Sound");

            autoPitch pitch = Sound_to_Pitch(
                sound,
                time_step,
                pitch_floor,
                pitch_ceiling
            );
            result[i] = create_xptr_from_auto<structPitch>(pitch);
        }

        return result;

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract pitch from sounds");
    }
}

//' Extract pitch (AC) from multiple sounds in one C++ call (internal)
//'
//' Batch version of to_pitch_ac with full voicing parameters.
//' Avoids O(n) R→C boundary crossings for VUV analysis workflows.
//'
//' @param sound_list List of Sound external pointers
//' @param time_step Time step (0 = automatic)
//' @param pitch_floor Pitch floor in Hz
//' @param pitch_ceiling Pitch ceiling in Hz
//' @param max_candidates Maximum candidates per frame
//' @param very_accurate Use very accurate algorithm
//' @param silence_threshold Silence threshold
//' @param voicing_threshold Voicing threshold
//' @param octave_cost Octave cost
//' @param octave_jump_cost Octave jump cost
//' @param voiced_unvoiced_cost Voiced/unvoiced cost
//' @return List of Pitch external pointers
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pitch_ac_batch)]]
Rcpp::List sound_to_pitch_ac_batch(
    Rcpp::List sound_list,
    double time_step = 0.0,
    double pitch_floor = 75.0,
    double pitch_ceiling = 600.0,
    int max_candidates = 15,
    bool very_accurate = false,
    double silence_threshold = 0.03,
    double voicing_threshold = 0.45,
    double octave_cost = 0.01,
    double octave_jump_cost = 0.35,
    double voiced_unvoiced_cost = 0.14
) {
    int n = sound_list.size();
    Rcpp::List result(n);

    try {
        for (int i = 0; i < n; i++) {
            XPtr<structSound> xptr = sound_list[i];
            structSound* sound = get_ptr(xptr, "Sound");

            autoPitch pitch = Sound_to_Pitch_rawAc(
                sound,
                time_step,
                pitch_floor,
                pitch_ceiling,
                static_cast<integer>(max_candidates),
                very_accurate,
                silence_threshold,
                voicing_threshold,
                octave_cost,
                octave_jump_cost,
                voiced_unvoiced_cost
            );
            result[i] = create_xptr_from_auto<structPitch>(pitch);
        }

        return result;

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract pitch (AC) from sounds");
    }
}

//' Extract pitch (CC) from multiple sounds in one C++ call (internal)
//'
//' Batch version of to_pitch_cc with full voicing parameters.
//' Avoids O(n) R→C boundary crossings for VUV analysis workflows.
//'
//' @param sound_list List of Sound external pointers
//' @param time_step Time step (0 = automatic)
//' @param pitch_floor Pitch floor in Hz
//' @param pitch_ceiling Pitch ceiling in Hz
//' @param max_candidates Maximum candidates per frame
//' @param very_accurate Use very accurate algorithm
//' @param silence_threshold Silence threshold
//' @param voicing_threshold Voicing threshold
//' @param octave_cost Octave cost
//' @param octave_jump_cost Octave jump cost
//' @param voiced_unvoiced_cost Voiced/unvoiced cost
//' @return List of Pitch external pointers
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_pitch_cc_batch)]]
Rcpp::List sound_to_pitch_cc_batch(
    Rcpp::List sound_list,
    double time_step = 0.0,
    double pitch_floor = 75.0,
    double pitch_ceiling = 600.0,
    int max_candidates = 15,
    bool very_accurate = false,
    double silence_threshold = 0.03,
    double voicing_threshold = 0.45,
    double octave_cost = 0.01,
    double octave_jump_cost = 0.35,
    double voiced_unvoiced_cost = 0.14
) {
    int n = sound_list.size();
    Rcpp::List result(n);

    try {
        for (int i = 0; i < n; i++) {
            XPtr<structSound> xptr = sound_list[i];
            structSound* sound = get_ptr(xptr, "Sound");

            autoPitch pitch = Sound_to_Pitch_rawCc(
                sound,
                time_step,
                pitch_floor,
                pitch_ceiling,
                static_cast<integer>(max_candidates),
                very_accurate,
                silence_threshold,
                voicing_threshold,
                octave_cost,
                octave_jump_cost,
                voiced_unvoiced_cost
            );
            result[i] = create_xptr_from_auto<structPitch>(pitch);
        }

        return result;

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract pitch (CC) from sounds");
    }
}

//' Extract formants from multiple sounds in one C++ call (internal)
//'
//' @param sound_list List of Sound external pointers
//' @param time_step Time step in seconds
//' @param max_formants Maximum number of formants
//' @param max_frequency Maximum frequency in Hz
//' @param window_length Window length in seconds
//' @param pre_emphasis_from Pre-emphasis from frequency
//' @return List of Formant external pointers
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_formant_batch)]]
Rcpp::List sound_to_formant_batch(
    Rcpp::List sound_list,
    double time_step = 0.005,
    double max_formants = 5.0,
    double max_frequency = 5500.0,
    double window_length = 0.025,
    double pre_emphasis_from = 50.0
) {
    ensure_numeric_libs_initialized();

    int n = sound_list.size();
    Rcpp::List result(n);

    try {
        for (int i = 0; i < n; i++) {
            XPtr<structSound> xptr = sound_list[i];
            structSound* sound = get_ptr(xptr, "Sound");

            autoFormant formant = Sound_to_Formant_burg(
                sound,
                time_step,
                max_formants,
                max_frequency,
                window_length,
                pre_emphasis_from
            );
            result[i] = create_xptr_from_auto<structFormant>(formant);
        }

        return result;

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract formants from sounds");
    }
}

//' Extract intensity from multiple sounds in one C++ call (internal)
//'
//' @param sound_list List of Sound external pointers
//' @param minimum_pitch Minimum pitch for analysis
//' @param time_step Time step (0 = automatic)
//' @param subtract_mean Whether to subtract mean
//' @return List of Intensity external pointers
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_to_intensity_batch)]]
Rcpp::List sound_to_intensity_batch(
    Rcpp::List sound_list,
    double minimum_pitch = 100.0,
    double time_step = 0.0,
    bool subtract_mean = true
) {
    int n = sound_list.size();
    Rcpp::List result(n);

    try {
        for (int i = 0; i < n; i++) {
            XPtr<structSound> xptr = sound_list[i];
            structSound* sound = get_ptr(xptr, "Sound");

            autoIntensity intensity = Sound_to_Intensity(
                sound,
                minimum_pitch,
                time_step,
                subtract_mean
            );
            result[i] = create_xptr_from_auto<structIntensity>(intensity);
        }

        return result;

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract intensity from sounds");
    }
}

//' Combined extract-and-analyze: extract parts and compute pitch in one C++ call (internal)
//'
//' This is the most efficient way to analyze multiple intervals from a sound.
//' Combines extract_parts_batch + to_pitch_batch in a single C++ call.
//'
//' @param xptr Sound external pointer
//' @param from_times Numeric vector of start times
//' @param to_times Numeric vector of end times
//' @param time_step Pitch time step
//' @param pitch_floor Pitch floor in Hz
//' @param pitch_ceiling Pitch ceiling in Hz
//' @return List of Pitch external pointers
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_extract_and_pitch_batch)]]
Rcpp::List sound_extract_and_pitch_batch(
    XPtr<structSound> xptr,
    NumericVector from_times,
    NumericVector to_times,
    double time_step = 0.0,
    double pitch_floor = 75.0,
    double pitch_ceiling = 600.0
) {
    structSound* sound = get_ptr(xptr, "Sound");

    if (from_times.size() != to_times.size()) {
        stop("from_times and to_times must have same length");
    }

    int n = from_times.size();
    Rcpp::List result(n);

    try {
        for (int i = 0; i < n; i++) {
            // Extract part
            autoSound extracted = Sound_extractPart(
                sound,
                from_times[i],
                to_times[i],
                kSound_windowShape::RECTANGULAR,
                1.0,
                false
            );

            // Analyze pitch immediately (no R6 wrapper overhead)
            autoPitch pitch = Sound_to_Pitch(
                extracted.get(),
                time_step,
                pitch_floor,
                pitch_ceiling
            );
            result[i] = create_xptr_from_auto<structPitch>(pitch);
        }

        return result;

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract and analyze pitch");
    }
}

//' Combined extract-and-analyze: extract parts and compute formants in one C++ call (internal)
//'
//' @param xptr Sound external pointer
//' @param from_times Numeric vector of start times
//' @param to_times Numeric vector of end times
//' @param time_step Formant time step
//' @param max_formants Maximum number of formants
//' @param max_frequency Maximum frequency
//' @param window_length Window length
//' @param pre_emphasis_from Pre-emphasis frequency
//' @return List of Formant external pointers
//' @keywords internal
//' @noRd
// [[Rcpp::export(.sound_extract_and_formant_batch)]]
Rcpp::List sound_extract_and_formant_batch(
    XPtr<structSound> xptr,
    NumericVector from_times,
    NumericVector to_times,
    double time_step = 0.005,
    double max_formants = 5.0,
    double max_frequency = 5500.0,
    double window_length = 0.025,
    double pre_emphasis_from = 50.0
) {
    ensure_numeric_libs_initialized();
    structSound* sound = get_ptr(xptr, "Sound");

    if (from_times.size() != to_times.size()) {
        stop("from_times and to_times must have same length");
    }

    int n = from_times.size();
    Rcpp::List result(n);

    try {
        for (int i = 0; i < n; i++) {
            // Extract part
            autoSound extracted = Sound_extractPart(
                sound,
                from_times[i],
                to_times[i],
                kSound_windowShape::RECTANGULAR,
                1.0,
                false
            );

            // Analyze formants immediately
            autoFormant formant = Sound_to_Formant_burg(
                extracted.get(),
                time_step,
                max_formants,
                max_frequency,
                window_length,
                pre_emphasis_from
            );
            result[i] = create_xptr_from_auto<structFormant>(formant);
        }

        return result;

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract and analyze formants");
    }
}

//' Get multiple pitch values at specific times in one C++ call (internal)
//'
//' Avoids O(n) R→C boundary crossings when getting pitch at multiple times.
//'
//' @param xptr Pitch external pointer
//' @param times Numeric vector of times
//' @param unit Unit (0=Hertz, 1=Hertz logarithmic, etc.)
//' @param interpolate Whether to interpolate
//' @return Numeric vector of pitch values
//' @keywords internal
//' @noRd
// [[Rcpp::export(.pitch_get_values_at_times)]]
NumericVector pitch_get_values_at_times(
    XPtr<structPitch> xptr,
    NumericVector times,
    int unit = 0,
    bool interpolate = true
) {
    structPitch* pitch = get_ptr(xptr, "Pitch");
    int n = times.size();
    NumericVector result(n);

    kPitch_unit pitch_unit = static_cast<kPitch_unit>(unit);

    for (int i = 0; i < n; i++) {
        double value = Pitch_getValueAtTime(
            pitch,
            times[i],
            pitch_unit,
            interpolate
        );
        result[i] = value;
    }

    return result;
}

//' Get multiple formant values at specific times in one C++ call (internal)
//'
//' @param xptr Formant external pointer
//' @param times Numeric vector of times
//' @param formant_number Which formant (1-5)
//' @param unit Unit (0=Hertz, 1=Bark)
//' @return Numeric vector of formant values
//' @keywords internal
//' @noRd
// [[Rcpp::export(.formant_get_values_at_times)]]
NumericVector formant_get_values_at_times(
    XPtr<structFormant> xptr,
    NumericVector times,
    int formant_number = 1,
    int unit = 0
) {
    structFormant* formant = get_ptr(xptr, "Formant");
    int n = times.size();
    NumericVector result(n);

    kFormant_unit formant_unit = static_cast<kFormant_unit>(unit);

    for (int i = 0; i < n; i++) {
        double value = Formant_getValueAtTime(
            formant,
            formant_number,
            times[i],
            formant_unit
        );
        result[i] = value;
    }

    return result;
}

//' Get multiple intensity values at specific times in one C++ call (internal)
//'
//' @param xptr Intensity external pointer
//' @param times Numeric vector of times
//' @param interpolation Interpolation type
//' @return Numeric vector of intensity values
//' @keywords internal
//' @noRd
// [[Rcpp::export(.intensity_get_values_at_times)]]
NumericVector intensity_get_values_at_times(
    XPtr<structIntensity> xptr,
    NumericVector times,
    int interpolation = 1
) {
    structIntensity* intensity = get_ptr(xptr, "Intensity");
    int n = times.size();
    NumericVector result(n);

    kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation);

    for (int i = 0; i < n; i++) {
        double value = Vector_getValueAtX(
            intensity,
            times[i],
            1,  // channel
            interp
        );
        result[i] = value;
    }

    return result;
}

// ============================================================================
// Gap Analysis: New Wrappers (Tier 1 + Tier 2)
// ============================================================================

//' Sound: To Ltas (pitch-corrected) (internal)
//' @noRd
// [[Rcpp::export(.sound_to_ltas_pitch_corrected)]]
XPtr<structLtas> sound_to_ltas_pitch_corrected(
    XPtr<structSound> xptr,
    double pitch_floor,
    double pitch_ceiling,
    double max_frequency,
    double bandwidth,
    double shortest_period,
    double longest_period,
    double max_period_factor
) {
    structSound* sound = get_ptr(xptr, "Sound");

    try {
        autoLtas ltas = Sound_to_Ltas_pitchCorrected(
            sound, pitch_floor, pitch_ceiling,
            max_frequency, bandwidth,
            shortest_period, longest_period, max_period_factor
        );
        return create_xptr_from_auto<structLtas>(ltas);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create pitch-corrected LTAS");
    }
}

//' Sound: To Formant (robust) (internal)
//' @noRd
// [[Rcpp::export(.sound_to_formant_robust)]]
XPtr<structFormant> sound_to_formant_robust(
    XPtr<structSound> xptr,
    double time_step,
    double max_formants,
    double max_frequency,
    double window_length,
    double pre_emphasis_from,
    double num_std_dev,
    int max_iterations
) {
    structSound* sound = get_ptr(xptr, "Sound");

    try {
        autoFormant formant = Sound_to_Formant_robust(
            sound,
            time_step,
            max_formants,
            max_frequency,
            window_length,
            pre_emphasis_from,
            50.0,   // safetyMargin (Praat default)
            num_std_dev,
            (integer) max_iterations,
            1e-6,   // tolerance (Praat default)
            0.0,    // location (Praat default)
            false   // wantlocation (Praat default)
        );
        return create_xptr_from_auto<structFormant>(formant);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract robust formants");
    }
}

//' Sound & Formant: Filter (internal)
//' @noRd
// [[Rcpp::export(.sound_formant_filter)]]
XPtr<structSound> sound_formant_filter(
    XPtr<structSound> sound_xptr,
    XPtr<structFormant> formant_xptr
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    structFormant* formant = get_ptr(formant_xptr, "Formant");

    try {
        autoSound result = Sound_Formant_filter(sound, formant);
        return create_xptr_from_auto<structSound>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to filter sound with formant");
    }
}

//' Sound & Formant: Filter (no scale) (internal)
//' @noRd
// [[Rcpp::export(.sound_formant_filter_noscale)]]
XPtr<structSound> sound_formant_filter_noscale(
    XPtr<structSound> sound_xptr,
    XPtr<structFormant> formant_xptr
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    structFormant* formant = get_ptr(formant_xptr, "Formant");

    try {
        autoSound result = Sound_Formant_filter_noscale(sound, formant);
        return create_xptr_from_auto<structSound>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to filter sound with formant (no scale)");
    }
}

//' Sound: To MelSpectrogram (internal)
//' @noRd
// [[Rcpp::export(.sound_to_mel_spectrogram)]]
XPtr<structMelSpectrogram> sound_to_mel_spectrogram(
    XPtr<structSound> xptr,
    double window_length,
    double time_step,
    double first_filter_frequency,
    double max_frequency,
    double frequency_step
) {
    structSound* sound = get_ptr(xptr, "Sound");

    try {
        autoMelSpectrogram result = Sound_to_MelSpectrogram(
            sound, window_length, time_step,
            first_filter_frequency, max_frequency, frequency_step
        );
        return create_xptr_from_auto<structMelSpectrogram>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create MelSpectrogram");
    }
}

//' Sound: To BarkSpectrogram (internal)
//' @noRd
// [[Rcpp::export(.sound_to_bark_spectrogram)]]
XPtr<structBarkSpectrogram> sound_to_bark_spectrogram(
    XPtr<structSound> xptr,
    double window_length,
    double time_step,
    double first_filter_frequency,
    double max_frequency,
    double frequency_step
) {
    structSound* sound = get_ptr(xptr, "Sound");

    try {
        autoBarkSpectrogram result = Sound_to_BarkSpectrogram(
            sound, window_length, time_step,
            first_filter_frequency, max_frequency, frequency_step
        );
        return create_xptr_from_auto<structBarkSpectrogram>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create BarkSpectrogram");
    }
}

//' MelSpectrogram: To MFCC (internal)
//' @noRd
// [[Rcpp::export(.mel_spectrogram_to_mfcc)]]
XPtr<structMFCC> mel_spectrogram_to_mfcc(
    XPtr<structMelSpectrogram> xptr,
    int number_of_coefficients
) {
    structMelSpectrogram* mel = get_ptr(xptr, "MelSpectrogram");

    try {
        autoMFCC result = MelSpectrogram_to_MFCC(mel, (integer) number_of_coefficients);
        return create_xptr_from_auto<structMFCC>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert MelSpectrogram to MFCC");
    }
}

//' MFCC: To MelSpectrogram (internal)
//' @noRd
// [[Rcpp::export(.mfcc_to_mel_spectrogram)]]
XPtr<structMelSpectrogram> mfcc_to_mel_spectrogram(
    XPtr<structMFCC> xptr,
    int first_coefficient,
    int last_coefficient,
    bool include_c0
) {
    structMFCC* mfcc = get_ptr(xptr, "MFCC");

    try {
        autoMelSpectrogram result = MFCC_to_MelSpectrogram(
            mfcc, (integer) first_coefficient, (integer) last_coefficient, include_c0
        );
        return create_xptr_from_auto<structMelSpectrogram>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert MFCC to MelSpectrogram");
    }
}

//' BandFilterSpectrogram: To Matrix (internal)
//' @noRd
// [[Rcpp::export(.band_filter_spectrogram_to_matrix)]]
XPtr<structMatrix> band_filter_spectrogram_to_matrix(
    SEXP xptr,
    bool to_db
) {
    structBandFilterSpectrogram* bfs = static_cast<structBandFilterSpectrogram*>(R_ExternalPtrAddr(xptr));
    if (!bfs) stop("Invalid BandFilterSpectrogram pointer");

    try {
        autoMatrix result = BandFilterSpectrogram_to_Matrix(bfs, to_db ? 1 : 0);
        return create_xptr_from_auto<structMatrix>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert BandFilterSpectrogram to Matrix");
    }
}

//' BandFilterSpectrogram: To Intensity (internal)
//' @noRd
// [[Rcpp::export(.band_filter_spectrogram_to_intensity)]]
XPtr<structIntensity> band_filter_spectrogram_to_intensity(
    SEXP xptr
) {
    structBandFilterSpectrogram* bfs = static_cast<structBandFilterSpectrogram*>(R_ExternalPtrAddr(xptr));
    if (!bfs) stop("Invalid BandFilterSpectrogram pointer");

    try {
        autoIntensity result = BandFilterSpectrogram_to_Intensity(bfs);
        return create_xptr_from_auto<structIntensity>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convert BandFilterSpectrogram to Intensity");
    }
}

//' Sound: Lengthen (overlap-add) (internal)
//' @noRd
// [[Rcpp::export(.sound_lengthen_ola)]]
XPtr<structSound> sound_lengthen_ola(
    XPtr<structSound> xptr,
    double fmin,
    double fmax,
    double factor
) {
    structSound* sound = get_ptr(xptr, "Sound");

    try {
        autoSound result = Sound_lengthen_overlapAdd(
            sound, fmin, fmax, factor
        );
        return create_xptr_from_auto<structSound>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to lengthen sound");
    }
}

//' Sound: Autocorrelate (internal)
//' @noRd
// [[Rcpp::export(.sound_autocorrelate)]]
XPtr<structSound> sound_autocorrelate(
    XPtr<structSound> xptr,
    int scaling,
    int signal_outside
) {
    structSound* sound = get_ptr(xptr, "Sound");

    try {
        autoSound result = Sound_autoCorrelate(
            sound,
            static_cast<kSounds_convolve_scaling>(scaling),
            static_cast<kSounds_convolve_signalOutsideTimeDomain>(signal_outside)
        );
        return create_xptr_from_auto<structSound>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to autocorrelate sound");
    }
}

//' Sounds: Convolve (internal)
//' @noRd
// [[Rcpp::export(.sounds_convolve_direct)]]
XPtr<structSound> sounds_convolve_export(
    XPtr<structSound> xptr1,
    XPtr<structSound> xptr2,
    int scaling,
    int signal_outside
) {
    structSound* sound1 = get_ptr(xptr1, "Sound");
    structSound* sound2 = get_ptr(xptr2, "Sound");

    try {
        autoSound result = Sounds_convolve(
            sound1, sound2,
            static_cast<kSounds_convolve_scaling>(scaling),
            static_cast<kSounds_convolve_signalOutsideTimeDomain>(signal_outside)
        );
        return create_xptr_from_auto<structSound>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to convolve sounds");
    }
}

//' Sounds: Cross-correlate (internal)
//' @noRd
// [[Rcpp::export(.sounds_cross_correlate_direct)]]
XPtr<structSound> sounds_cross_correlate_export(
    XPtr<structSound> xptr1,
    XPtr<structSound> xptr2,
    int scaling,
    int signal_outside
) {
    structSound* sound1 = get_ptr(xptr1, "Sound");
    structSound* sound2 = get_ptr(xptr2, "Sound");

    try {
        autoSound result = Sounds_crossCorrelate(
            sound1, sound2,
            static_cast<kSounds_convolve_scaling>(scaling),
            static_cast<kSounds_convolve_signalOutsideTimeDomain>(signal_outside)
        );
        return create_xptr_from_auto<structSound>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to cross-correlate sounds");
    }
}

//' Sound: Deepen band modulation (internal)
//' @noRd
// [[Rcpp::export(.sound_deepen_band_mod)]]
XPtr<structSound> sound_deepen_band_mod(
    XPtr<structSound> xptr,
    double enhancement_db,
    double flow,
    double fhigh,
    double slow_modulation,
    double fast_modulation,
    double band_smoothing
) {
    structSound* sound = get_ptr(xptr, "Sound");

    try {
        autoSound result = Sound_deepenBandModulation(
            sound, enhancement_db,
            flow, fhigh,
            slow_modulation, fast_modulation,
            band_smoothing
        );
        return create_xptr_from_auto<structSound>(result);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to deepen band modulation");
    }
}

//' Intensity: To TextGrid (silences) (internal)
//' @noRd
// [[Rcpp::export(.intensity_to_textgrid_silences)]]
XPtr<structTextGrid> intensity_to_textgrid_silences(
    XPtr<structIntensity> xptr,
    double silence_threshold,
    double min_silence_duration,
    double min_sounding_duration,
    std::string silent_label,
    std::string sounding_label
) {
    structIntensity* intensity = get_ptr(xptr, "Intensity");

    try {
        autostring32 silentStr = Melder_8to32(silent_label.c_str());
        autostring32 soundingStr = Melder_8to32(sounding_label.c_str());
        conststring32 silenceLabel = silentStr.get();
        conststring32 soundingLabel = soundingStr.get();

        const double duration = intensity->xmax - intensity->xmin;
        autoTextGrid thee = TextGrid_create(intensity->xmin, intensity->xmax, U"silences", U"");
        const IntervalTier it = (IntervalTier) thee->tiers->at[1];
        TextInterval_setText(it->intervals.at[1], soundingLabel);
        if (min_silence_duration > duration)
            return create_xptr_from_auto<structTextGrid>(thee);

        double intensity_max_db, intensity_min_db, xOfMaximum, xOfMinimum;
        Vector_getMaximumAndX(intensity, 0.0, 0.0, 1, kVector_peakInterpolation::PARABOLIC, &intensity_max_db, &xOfMaximum);
        Vector_getMinimumAndX(intensity, 0.0, 0.0, 1, kVector_peakInterpolation::PARABOLIC, &intensity_min_db, &xOfMinimum);

        const double intensityThreshold = intensity_max_db - fabs(silence_threshold);
        if (min_silence_duration > duration || intensityThreshold < intensity_min_db)
            return create_xptr_from_auto<structTextGrid>(thee);

        bool inSilenceInterval = intensity->z[1][1] < intensityThreshold;
        integer iinterval = 1;
        for (integer i = 2; i <= intensity->nx; i++) {
            bool addBoundary = false;
            conststring32 label = nullptr;
            if (intensity->z[1][i] < intensityThreshold) {
                if (!inSilenceInterval) {
                    addBoundary = true;
                    inSilenceInterval = true;
                    label = soundingLabel;
                }
            } else {
                if (inSilenceInterval) {
                    addBoundary = true;
                    inSilenceInterval = false;
                    label = silenceLabel;
                }
            }
            if (addBoundary) {
                const double time = intensity->x1 + (i - 1) * intensity->dx;
                if (time > intensity->xmin && time < intensity->xmax) {
                    const TextInterval ti = it->intervals.at[iinterval];
                    ti->xmax = time;
                    TextInterval_setText(ti, label);
                    autoTextInterval ti_new = TextInterval_create(time, intensity->xmax, U"");
                    it->intervals.addItem_unsorted_move(ti_new.move());
                    iinterval++;
                }
            }
        }
        // Relabel last interval
        conststring32 lastLabel = inSilenceInterval ? silenceLabel : soundingLabel;
        TextInterval_setText(it->intervals.at[iinterval], lastLabel);
        it->intervals.sort();

        if (min_sounding_duration > 0.0) {
            IntervalTier_cutIntervals_minimumDuration(it, soundingLabel, min_sounding_duration);
            IntervalTier_combineIntervalsOnLabelMatch(it, silenceLabel);
        }
        if (min_silence_duration > 0.0) {
            IntervalTier_cutIntervals_minimumDuration(it, silenceLabel, min_silence_duration);
            IntervalTier_combineIntervalsOnLabelMatch(it, soundingLabel);
        }

        return create_xptr_from_auto<structTextGrid>(thee);

    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create TextGrid from Intensity silences");
    }
}

// [[Rcpp::export(.sound_change_speaker)]]
XPtr<structSound> sound_change_speaker(
    XPtr<structSound> xptr,
    double pitch_floor,
    double pitch_ceiling,
    double formant_multiplier,
    double pitch_multiplier,
    double pitch_range_multiplier,
    double duration_multiplier
) {
    structSound* sound = get_ptr(xptr, "Sound");
    try {
        autoSound result = Sound_changeSpeaker(
            sound, pitch_floor, pitch_ceiling,
            formant_multiplier, pitch_multiplier,
            pitch_range_multiplier, duration_multiplier
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to change speaker characteristics");
    }
}

// [[Rcpp::export(.sound_pitch_change_speaker)]]
XPtr<structSound> sound_pitch_change_speaker(
    XPtr<structSound> sound_xptr,
    XPtr<structPitch> pitch_xptr,
    double formant_multiplier,
    double pitch_multiplier,
    double pitch_range_multiplier,
    double duration_multiplier
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    structPitch* pitch = get_ptr(pitch_xptr, "Pitch");
    try {
        autoSound result = Sound_Pitch_changeSpeaker(
            sound, pitch,
            formant_multiplier, pitch_multiplier,
            pitch_range_multiplier, duration_multiplier
        );
        return create_xptr_from_auto<structSound>(result);
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to change speaker characteristics (with Pitch)");
    }
}
