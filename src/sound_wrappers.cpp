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

// Praat headers
#include "fon/Sound.h"
#include "fon/Sound_to_Pitch.h"
#include "fon/Sound_to_Formant.h"
#include "fon/Sound_to_Intensity.h"
#include "fon/Sound_to_Harmonicity.h"
#include "fon/Sound_and_Spectrogram.h"
#include "fon/Sound_and_Spectrum.h"
#include "melder/melder.h"

using namespace Rcpp;

// ============================================================================
// Sound Creation
// ============================================================================

//' Read Sound from file (internal)
//' @keywords internal
// [[Rcpp::export(.sound_read_from_file)]]
XPtr<structSound> sound_read_from_file(std::string path) {
    validate_xptr<structSound>(XPtr<structSound>(), "Sound");  // Just to initialize template
    
    try {
        structMelderFile file {};
        Melder_relativePathToFile(Melder_peek8to32(path.c_str()), &file);
        
        autoSound sound = Sound_readFromSoundFile(&file);
        return create_xptr_from_auto<structSound>(sound);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to read sound file: " + path);
    }
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
            for (int i = 1; i <= n_samples; i++) {
                sound->z[ch][i] = values(ch - 1, i - 1);
            }
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
        for (int i = 1; i <= sound->nx; i++) {
            double t = sound->x1 + (i - 1) * sound->dx;
            sound->z[1][i] = amplitude * sin(2.0 * M_PI * frequency * t);
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

//' Get RMS (internal)
//' @keywords internal
// [[Rcpp::export(.sound_get_rms)]]
double sound_get_rms(
    XPtr<structSound> xptr,
    double from_time,
    double to_time
) {
    structSound* sound = get_ptr(xptr, "Sound");
    
    if (from_time == 0.0) from_time = sound->xmin;
    if (to_time == 0.0) to_time = sound->xmax;
    
    try {
        double rms = 0.0;
        for (int ch = 1; ch <= sound->ny; ch++) {
            double channel_rms = Sound_getRootMeanSquare(sound, from_time, to_time, ch);
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

//' Convert Sound to Spectrogram (internal)
//' @keywords internal
// [[Rcpp::export(.sound_to_spectrogram)]]
XPtr<structSpectrogram> sound_to_spectrogram(
    XPtr<structSound> sound_xptr,
    double window_length,
    double maximum_frequency,
    double time_step,
    double frequency_step,
    int window_shape_int
) {
    structSound* sound = get_ptr(sound_xptr, "Sound");
    
    kSound_to_Spectrogram_windowShape window_shape = 
        static_cast<kSound_to_Spectrogram_windowShape>(window_shape_int);
    
    try {
        autoSpectrogram spec = Sound_to_Spectrogram(
            sound,
            window_length,
            maximum_frequency,
            time_step,
            frequency_step,
            window_shape,
            8.0,  // dynamic range
            8.0   // pre-emphasis
        );
        
        return create_xptr_from_auto<structSpectrogram>(spec);
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to create spectrogram");
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
    
    for (int ch = 1; ch <= sound->ny; ch++) {
        for (int i = 1; i <= sound->nx; i++) {
            mat(ch - 1, i - 1) = sound->z[ch][i];
        }
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
        Melder_SoundFileFormat format = static_cast<Melder_SoundFileFormat>(file_type);
        
        Sound_writeToAudioFile(sound, &file, format, 16);  // 16-bit
        
    } catch (MelderError) {
        Melder_clearError();
        stop("Failed to save sound to: " + path);
    }
}
