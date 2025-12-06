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
#include "fon/Sound_to_Formant.h"
#include "fon/Sound_to_Intensity.h"
#include "fon/Sound_to_Harmonicity.h"
#include "fon/Sound_and_Spectrogram.h"
#include "fon/Sound_and_Spectrum.h"
#include "fon/Sound_to_PointProcess.h"
#include "fon/Pitch_to_PointProcess.h"
#include "fon/Ltas.h"
#include "fon/TextGrid.h"
#include "fon/TextGrid_Sound.h"
#include "melder/melder.h"

using namespace Rcpp;

// ============================================================================
// Sound Creation
// ============================================================================

//' Read Sound from file (internal)
//' @keywords internal
// [[Rcpp::export(.sound_read_from_file)]]
XPtr<structSound> sound_read_from_file(std::string path) {
    // NOTE: File I/O currently has issues - under investigation
    // Use Sound$create_tone(), Sound$create_from_formula(), etc. instead
    // See SESSION_SUMMARY_2025-11-19.md for details
    stop("Sound file reading is currently unavailable. Use Sound$create_tone() or other creation methods.");
    
    /* Original implementation - disabled until file I/O is fixed:
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        
        autoSound sound = Sound_readFromSoundFile(&file);
        return create_xptr_from_auto<structSound>(sound);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to read sound file: " + path);
    }
    */
}

//' Create Sound from values (internal)
//' @keywords internal
// [[Rcpp::export(.sound_create_from_values)]]
XPtr<structSound> sound_create_from_values(
    NumericMatrix values,
    double sampling_rate
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

// ============================================================================
// Sound Query Methods
// ============================================================================

//' Get sound duration (internal)
//' @keywords internal
// [[Rcpp::export(.sound_get_duration)]]
double sound_get_duration(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    return sound->xmax - sound->xmin;
}

//' Get sampling frequency (internal)
//' @keywords internal
// [[Rcpp::export(.sound_get_sampling_frequency)]]
double sound_get_sampling_frequency(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    return 1.0 / sound->dx;
}

//' Get number of samples (internal)
//' @keywords internal
// [[Rcpp::export(.sound_get_number_of_samples)]]
int sound_get_number_of_samples(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    return sound->nx;
}

//' Get number of channels (internal)
//' @keywords internal
// [[Rcpp::export(.sound_get_number_of_channels)]]
int sound_get_number_of_channels(XPtr<structSound> xptr) {
    structSound* sound = get_ptr(xptr, "Sound");
    return sound->ny;
}

//' Get value at time (internal)
//' @keywords internal
// [[Rcpp::export(.sound_get_value_at_time)]]
double sound_get_value_at_time(
    XPtr<structSound> xptr,
    double time,
    int channel
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (channel < 1 || channel > sound->ny) {
        stop("Invalid channel number");
    }
    if (time < sound->xmin || time > sound->xmax) {
        return NA_REAL;
    }
    
    try {
        return Vector_getValueAtX(
            sound,
            time,
            channel,
            kVector_valueInterpolation::LINEAR
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
            max_candidates,
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
            max_candidates,
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

//' Convert Sound to Formant via Burg (internal)
//' @keywords internal
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
        Melder_clearError();
        stop("Failed to extract formants");
    }
}

//' Convert Sound to Intensity (internal)
//' @keywords internal
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
        stop("Failed to extract harmonicity");
    }
}

//' Convert Sound to Spectrum (internal)
//' @keywords internal
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
// Sound Export Methods
// ============================================================================

//' Export Sound as data frame (internal)
//' @keywords internal
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

//' Extract glottal pulses from sound using cross-correlation (internal)
//' @keywords internal
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

// ============================================================================
// Advanced Sound Modification Methods (return new Sound)
// ============================================================================

//' Resample Sound to new sampling frequency (internal)
//' @keywords internal
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
// [[Rcpp::export(.sound_concatenate)]]
XPtr<structSound> sound_concatenate(
    XPtr<structSound> xptr1,
    XPtr<structSound> xptr2,
    double overlap
) {
    structSound* sound1 = get_ptr(xptr1, "Sound");
    structSound* sound2 = get_ptr(xptr2, "Sound");
    
    try {
        // Create SoundList and add both sounds
        autoSoundList list = SoundList_create();
        list->addItem_move(Data_copy(sound1));
        list->addItem_move(Data_copy(sound2));
        
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
        
        // Convert to R list of Sound XPtrs
        Rcpp::List result(sounds->size);
        for (integer i = 1; i <= sounds->size; i++) {
            Sound extracted = sounds->at[i];
            // Create copy to avoid ownership issues
            autoSound copy = Data_copy(extracted);
            result[i-1] = create_xptr_from_auto<structSound>(copy);
        }
        
        return result;
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to extract sound intervals");
    }
}
