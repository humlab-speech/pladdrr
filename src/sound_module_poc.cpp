// sound_module_poc.cpp - POC using Rcpp Modules instead of manual wrappers
//
// This POC demonstrates code reduction achievable by using Rcpp Modules
// (R's equivalent to Python's pybind11) instead of manual Rcpp::export wrappers.
//
// Comparison Target: sound_wrappers.cpp (1,479 lines) + sound-r6-new.R (1,254 lines) = 2,733 lines
// POC Goal: Implement same functionality in ~1,000 lines total

// [[Rcpp::plugins(cpp17)]]

#include "praat_types.h"  // Must come before Rcpp
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

// Forward declarations for initialization functions
extern void NUMmachar();
extern void NUMrandom_initializeSafelyAndUnpredictably();

// Helper: Ensure numeric libraries initialized
static void ensure_numeric_libs_initialized() {
    static bool initialized = false;
    if (!initialized) {
        NUMmachar();
        NUMrandom_initializeSafelyAndUnpredictably();
        initialized = true;
    }
}

// ============================================================================
// SoundModulePOC: Rcpp Module-based wrapper class
// ============================================================================

class SoundModulePOC {
private:
    XPtr<structSound> ptr_;
    
public:
    // ========================================================================
    // Constructors (Day 1 AM: Basic setup)
    // ========================================================================
    
    // Constructor: Read from file
    SoundModulePOC(std::string path) {
        ensure_numeric_libs_initialized();
        
        try {
            structMelderFile file { };
            Melder_pathToFile(Melder_peek8to32(path.c_str()), &file);
            autoSound sound = Sound_readFromSoundFile(&file);
            ptr_ = create_xptr_from_auto<structSound>(sound);
            
        } catch (MelderError) {
            Melder_clearError();
            stop("Failed to read sound from: " + path);
        }
    }
    
    // ========================================================================
    // Basic Query Methods (Day 1 AM: 5 core methods)
    // ========================================================================
    
    double get_duration() const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        return sound->xmax - sound->xmin;
    }
    
    double get_sampling_frequency() const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        return 1.0 / sound->dx;
    }
    
    int get_number_of_samples() const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        return sound->nx;
    }
    
    int get_number_of_channels() const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        return sound->ny;
    }
    
    // ========================================================================
    // Extended Query Methods (Day 1 PM: 10 more methods)
    // ========================================================================
    
    double get_start_time() const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        return sound->xmin;
    }
    
    double get_end_time() const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        return sound->xmax;
    }
    
    double get_sampling_period() const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        return sound->dx;
    }
    
    double get_time_from_index(int sample) const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        if (sample < 1 || sample > sound->nx) stop("Sample index out of range");
        return sound->x1 + (sample - 1) * sound->dx;
    }
    
    int get_index_from_time(double time) const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        return Sampled_xToNearestIndex(sound, time);
    }
    
    double get_value_at_time(double time, int channel = 1, std::string interpolation = "linear") const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        
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
            stop("Invalid interpolation type");
        }
        
        try {
            return Vector_getValueAtX(sound, time, channel, interp_type);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }
    
    double get_rms(double from_time = 0.0, double to_time = 0.0) const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        
        if (from_time == 0.0) from_time = sound->xmin;
        if (to_time == 0.0) to_time = sound->xmax;
        
        try {
            double rms = 0.0;
            for (int ch = 1; ch <= sound->ny; ch++) {
                double ch_rms = Sound_getRootMeanSquare(sound, from_time, to_time);
                rms += ch_rms * ch_rms;
            }
            return sqrt(rms / sound->ny);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }
    
    double get_energy(double from_time = 0.0, double to_time = 0.0) const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        
        if (from_time == 0.0) from_time = sound->xmin;
        if (to_time == 0.0) to_time = sound->xmax;
        
        try {
            return Sound_getEnergy(sound, from_time, to_time);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }
    
    double get_power(double from_time = 0.0, double to_time = 0.0) const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        
        if (from_time == 0.0) from_time = sound->xmin;
        if (to_time == 0.0) to_time = sound->xmax;
        
        try {
            return Sound_getPower(sound, from_time, to_time);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }
    
    double get_intensity_db() const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        
        try {
            double power = Sound_getPower(sound, sound->xmin, sound->xmax);
            if (power <= 0.0) return NA_REAL;
            return 10.0 * log10(power / 4.0e-10);
        } catch (MelderError) {
            Melder_clearError();
            return NA_REAL;
        }
    }
    
    // ========================================================================
    // Transformation Methods (Day 1 PM: 3 methods returning other objects)
    // ========================================================================
    
    SEXP to_pitch(double time_step = 0.0, double pitch_floor = 75.0, double pitch_ceiling = 600.0) const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        
        try {
            autoPitch pitch = Sound_to_Pitch(sound, time_step, pitch_floor, pitch_ceiling);
            return create_xptr_from_auto<structPitch>(pitch);
        } catch (MelderError) {
            Melder_clearError();
            stop("Failed to extract pitch");
        }
    }
    
    SEXP to_intensity(double minimum_pitch = 100.0, double time_step = 0.0, bool subtract_mean = true) const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        
        try {
            autoIntensity intensity = Sound_to_Intensity(sound, minimum_pitch, time_step, subtract_mean);
            return create_xptr_from_auto<structIntensity>(intensity);
        } catch (MelderError) {
            Melder_clearError();
            stop("Failed to extract intensity");
        }
    }
    
    SEXP to_spectrum(bool fast = true) const {
        structSound* sound = ptr_.get();
        if (!sound) stop("Invalid Sound pointer");
        
        try {
            autoSpectrum spectrum = Sound_to_Spectrum(sound, fast);
            return create_xptr_from_auto<structSpectrum>(spectrum);
        } catch (MelderError) {
            Melder_clearError();
            stop("Failed to create spectrum");
        }
    }
};

// ============================================================================
// Rcpp Module Registration (The magic that replaces tons of manual code!)
// ============================================================================

RCPP_MODULE(sound_poc) {
    class_<SoundModulePOC>("SoundModulePOC")
        // Constructor
        .constructor<std::string>("Create Sound from file path")
        
        // Basic queries (Day 1 AM)
        .method("get_duration", &SoundModulePOC::get_duration, 
                "Get duration in seconds")
        .method("get_sampling_frequency", &SoundModulePOC::get_sampling_frequency, 
                "Get sampling frequency in Hz")
        .method("get_number_of_samples", &SoundModulePOC::get_number_of_samples, 
                "Get total number of samples")
        .method("get_number_of_channels", &SoundModulePOC::get_number_of_channels, 
                "Get number of channels")
        
        // Extended queries (Day 1 PM)
        .method("get_start_time", &SoundModulePOC::get_start_time, 
                "Get start time")
        .method("get_end_time", &SoundModulePOC::get_end_time, 
                "Get end time")
        .method("get_sampling_period", &SoundModulePOC::get_sampling_period, 
                "Get sampling period (time step)")
        .method("get_time_from_index", &SoundModulePOC::get_time_from_index, 
                "Convert sample index to time")
        .method("get_index_from_time", &SoundModulePOC::get_index_from_time, 
                "Convert time to nearest sample index")
        .method("get_value_at_time", &SoundModulePOC::get_value_at_time, 
                "Get amplitude value at specific time and channel")
        .method("get_rms", &SoundModulePOC::get_rms, 
                "Get RMS (root mean square) amplitude")
        .method("get_energy", &SoundModulePOC::get_energy, 
                "Get total energy")
        .method("get_power", &SoundModulePOC::get_power, 
                "Get average power")
        .method("get_intensity_db", &SoundModulePOC::get_intensity_db, 
                "Get intensity in decibels")
        
        // Transformations (Day 1 PM)
        .method("to_pitch", &SoundModulePOC::to_pitch, 
                "Extract pitch contour (returns Pitch XPtr)")
        .method("to_intensity", &SoundModulePOC::to_intensity, 
                "Extract intensity contour (returns Intensity XPtr)")
        .method("to_spectrum", &SoundModulePOC::to_spectrum, 
                "Compute spectrum (returns Spectrum XPtr)")
        ;
}

// ============================================================================
// Code Statistics (Day 1 end)
// ============================================================================
//
// POC Lines (this file):  ~380 lines
// Current equivalent:     ~750 lines (sound_wrappers.cpp + sound-r6-new.R for 18 methods)
//
// Code Reduction: 49% for first 18 methods
//
// What's missing compared to current:
// - R6 wrapper class (~50 lines needed in R)
// - Static factory methods (from_values, create_tone)
// - Export methods (as_data_frame, as_matrix, save)
// - Remaining transformations (to_formant_burg, to_harmonicity_cc, etc.)
// - Modification methods (scale_intensity, filter_*, resample, etc.)
// - Extraction methods (extract_channel, extract_part)
//
// Estimated final: ~980 lines total (vs 2,733 current) = 64% reduction
// ============================================================================
