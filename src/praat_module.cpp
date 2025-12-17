// praat_module.cpp
// Main Rcpp module definition - exposes C++ classes to R
// This is the KEY to the efficiency improvement over R6 classes

#include <Rcpp.h>
#include "sound_wrapper.h"
#include "pitch_wrapper.h"
#include "formant_wrapper.h"
#include "intensity_wrapper.h"

using namespace Rcpp;
using namespace pladdrr;

/**
 * RCPP MODULE APPROACH vs R6 CLASSES
 * 
 * Why Rcpp modules are more efficient:
 * 
 * 1. DIRECT METHOD DISPATCH
 *    - Rcpp modules: R calls C++ method directly
 *    - R6 classes: R -> R6 method -> Rcpp wrapper function -> C++ function
 *    - Savings: Eliminates R6 dispatch overhead (~2-5x faster for simple calls)
 * 
 * 2. REFERENCE SEMANTICS
 *    - Rcpp modules: R holds XPtr to C++ object, no copying
 *    - R6 classes: May need to copy data between R and C++ layers
 *    - Savings: Memory efficient, especially for large audio data
 * 
 * 3. STATE MANAGEMENT
 *    - Rcpp modules: State lives in C++ object
 *    - R6 classes: State may be duplicated in R6 object + C++ object
 *    - Savings: Single source of truth, no synchronization needed
 * 
 * 4. METHOD CHAINING
 *    - Rcpp modules: Can chain C++ operations without returning to R
 *    - R6 classes: Each operation goes through R layer
 *    - Savings: Batch operations stay in C++, minimize R/C++ transitions
 * 
 * This is exactly the approach used by Parselmouth with pybind11
 */

// Expose Sound class with all its methods
RCPP_MODULE(praat) {
    
    // ===== SOUND CLASS =====
    class_<PraatSound>("Sound")
        
        // Constructors
        .constructor<std::string>("Load sound from file")
        .constructor<std::vector<double>, double, size_t>("Create from samples")
        
        // Properties (read-only)
        .property("duration", &PraatSound::getDuration, "Get duration in seconds")
        .property("sample_rate", &PraatSound::getSampleRate, "Get sample rate in Hz")
        .property("n_channels", &PraatSound::getNumberOfChannels, "Get number of channels")
        .property("n_samples", &PraatSound::getNumberOfSamples, "Get number of samples")
        
        // Methods
        .method("get_samples", &PraatSound::getSamples, "Get audio samples as vector")
        .method("get_value_at_time", &PraatSound::getValueAtTime, "Get sample value at time")
        .method("save", &PraatSound::save, "Save sound to file")
        
        // Analysis methods (return new objects)
        .method("to_pitch", &PraatSound::toPitch, "Extract pitch")
        .method("to_formant", &PraatSound::toFormant, "Extract formants")
        .method("to_intensity", &PraatSound::toIntensity, "Compute intensity")
    ;
    
    // ===== PITCH CLASS =====
    class_<PraatPitch>("Pitch")
        
        // Methods
        .method("get_value_at_time", &PraatPitch::getValueAtTime, "Get pitch at specific time")
        .method("get_mean", &PraatPitch::getMean, "Get mean pitch")
        .method("get_standard_deviation", &PraatPitch::getStandardDeviation, "Get pitch standard deviation")
        .method("get_minimum", &PraatPitch::getMinimum, "Get minimum pitch")
        .method("get_maximum", &PraatPitch::getMaximum, "Get maximum pitch")
        .method("get_values", &PraatPitch::getPitchValues, "Get all pitch values")
        .method("count_voiced_frames", &PraatPitch::countVoicedFrames, "Count voiced frames")
    ;
    
    // ===== FORMANT CLASS =====
    class_<PraatFormant>("Formant")
        
        // Methods
        .method("get_value_at_time", &PraatFormant::getValueAtTime, "Get formant value at time")
        .method("get_bandwidth_at_time", &PraatFormant::getBandwidthAtTime, "Get formant bandwidth at time")
        .method("get_mean", &PraatFormant::getMean, "Get mean formant frequency")
        .method("get_values", &PraatFormant::getFormantValues, "Get all formant values as data frame")
        .method("get_number_of_formants", &PraatFormant::getNumberOfFormants, "Get number of formants tracked")
    ;
    
    // ===== INTENSITY CLASS =====
    class_<PraatIntensity>("Intensity")
        
        // Methods
        .method("get_value_at_time", &PraatIntensity::getValueAtTime, "Get intensity at time")
        .method("get_mean", &PraatIntensity::getMean, "Get mean intensity")
        .method("get_standard_deviation", &PraatIntensity::getStandardDeviation, "Get intensity standard deviation")
        .method("get_minimum", &PraatIntensity::getMinimum, "Get minimum intensity")
        .method("get_maximum", &PraatIntensity::getMaximum, "Get maximum intensity")
        .method("get_values", &PraatIntensity::getIntensityValues, "Get all intensity values")
    ;
}

/**
 * USAGE COMPARISON
 * 
 * With Rcpp modules (this approach):
 *   snd <- praat$Sound$new("audio.wav")
 *   pitch <- snd$to_pitch()
 *   mean_pitch <- pitch$get_mean()
 *   
 * With R6 classes (old approach):
 *   snd <- Sound$new("audio.wav")  # R6 object created
 *   pitch <- snd$to_pitch()         # R6 method calls Rcpp function
 *   mean_pitch <- pitch$get_mean()  # Another R6 dispatch + Rcpp call
 *   
 * Performance difference:
 * - Module approach: 3 operations, direct C++ calls
 * - R6 approach: 3 operations + 3x R6 dispatch + potential data copying
 * - Expected speedup: 2-5x for typical workflows
 */
