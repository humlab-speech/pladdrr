// sound_wrapper.h
// C++ wrapper class for Praat Sound objects
// This demonstrates the architecture - actual implementation would interface with Praat C code

#ifndef SOUND_WRAPPER_H
#define SOUND_WRAPPER_H

#include <Rcpp.h>
#include <string>
#include <vector>

namespace pladdrr {

/**
 * Wrapper class for Praat Sound objects
 * 
 * This class encapsulates a Praat Sound object and provides a clean C++ interface
 * that can be exposed to R via Rcpp modules. In a full implementation, this would
 * wrap actual Praat Sound* pointers and call Praat functions.
 * 
 * Key design principles:
 * - RAII: Constructor acquires Praat object, destructor releases it
 * - Reference semantics: R holds reference to C++ object, no copying
 * - Direct method calls: Methods call Praat functions directly
 */
class PraatSound {
private:
    // In actual implementation, this would be: Sound* praatSound;
    std::string filepath;
    double sampleRate;
    double duration;
    size_t numberOfChannels;
    std::vector<double> samples; // Mock data
    
public:
    /**
     * Constructor: Load sound from file
     * 
     * In full implementation, would call Praat's Sound_readFromFile
     * and handle Praat's error system (try/catch with MelderError)
     */
    PraatSound(const std::string& path);
    
    /**
     * Constructor: Create from samples
     * 
     * In full implementation, would call Sound_create
     */
    PraatSound(const std::vector<double>& samples, double sampleRate, size_t nChannels = 1);
    
    /**
     * Destructor: Clean up Praat object
     * 
     * In full implementation, would call forget(praatSound)
     */
    ~PraatSound();
    
    // Prevent copying (Praat objects should not be copied)
    PraatSound(const PraatSound&) = delete;
    PraatSound& operator=(const PraatSound&) = delete;
    
    // Accessors - These would call Praat accessor functions
    double getDuration() const { return duration; }
    double getSampleRate() const { return sampleRate; }
    size_t getNumberOfChannels() const { return numberOfChannels; }
    size_t getNumberOfSamples() const { return samples.size(); }
    
    /**
     * Get samples as R vector
     * 
     * In full implementation, would extract from Sound object's samples array
     */
    Rcpp::NumericVector getSamples() const;
    
    /**
     * Extract pitch using Praat's pitch analysis
     * 
     * In full implementation, would call Sound_to_Pitch
     * Returns a new PraatPitch object
     */
    Rcpp::XPtr<class PraatPitch> toPitch(double timeStep = 0.0, 
                                          double pitchFloor = 75.0, 
                                          double pitchCeiling = 600.0) const;
    
    /**
     * Extract formants using Praat's formant analysis
     * 
     * In full implementation, would call Sound_to_Formant_burg
     */
    Rcpp::XPtr<class PraatFormant> toFormant(double timeStep = 0.0,
                                              double maxFormant = 5500.0,
                                              double windowLength = 0.025,
                                              double preEmphasis = 50.0) const;
    
    /**
     * Compute intensity
     * 
     * In full implementation, would call Sound_to_Intensity
     */
    Rcpp::XPtr<class PraatIntensity> toIntensity(double minimumPitch = 100.0,
                                                   double timeStep = 0.0) const;
    
    /**
     * Save to file
     * 
     * In full implementation, would call Sound_writeToFile
     */
    void save(const std::string& path, const std::string& format = "wav") const;
    
    /**
     * Get value at specific time and channel
     */
    double getValueAtTime(double time, size_t channel = 0) const;
};

} // namespace pladdrr

#endif // SOUND_WRAPPER_H
