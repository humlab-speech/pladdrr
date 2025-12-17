// sound_wrapper.cpp
// Implementation of Sound wrapper class

#include "sound_wrapper.h"
#include "pitch_wrapper.h"
#include "formant_wrapper.h"
#include "intensity_wrapper.h"
#include <cmath>
#include <stdexcept>

namespace pladdrr {

PraatSound::PraatSound(const std::string& path) : filepath(path) {
    // MOCK IMPLEMENTATION
    // Real implementation would:
    // 1. Call Praat's Sound_readFromFile(path)
    // 2. Handle Praat errors via Melder_hasError()
    // 3. Store the Sound* pointer
    
    // For demonstration, create mock data
    sampleRate = 44100.0;
    duration = 1.0;
    numberOfChannels = 1;
    
    // Generate mock sine wave
    size_t numSamples = static_cast<size_t>(sampleRate * duration);
    samples.resize(numSamples);
    for (size_t i = 0; i < numSamples; ++i) {
        double t = static_cast<double>(i) / sampleRate;
        samples[i] = 0.5 * std::sin(2.0 * M_PI * 440.0 * t); // 440 Hz sine wave
    }
    
    Rcpp::Rcout << "Mock: Loaded sound from " << path << std::endl;
    Rcpp::Rcout << "  Sample rate: " << sampleRate << " Hz" << std::endl;
    Rcpp::Rcout << "  Duration: " << duration << " s" << std::endl;
}

PraatSound::PraatSound(const std::vector<double>& inputSamples, 
                       double sr, 
                       size_t nChannels)
    : samples(inputSamples), 
      sampleRate(sr), 
      numberOfChannels(nChannels) {
    
    // MOCK IMPLEMENTATION
    // Real implementation would:
    // 1. Call Sound_create(nChannels, xmin, xmax, nx, dx, x1)
    // 2. Copy samples into Sound object
    
    duration = static_cast<double>(samples.size()) / sampleRate;
    filepath = "<created>";
    
    Rcpp::Rcout << "Mock: Created sound from samples" << std::endl;
}

PraatSound::~PraatSound() {
    // MOCK IMPLEMENTATION
    // Real implementation would:
    // forget(praatSound); // Praat's memory management
    
    Rcpp::Rcout << "Mock: Destroying sound object" << std::endl;
}

Rcpp::NumericVector PraatSound::getSamples() const {
    // Real implementation would extract from Sound object
    return Rcpp::wrap(samples);
}

Rcpp::XPtr<PraatPitch> PraatSound::toPitch(double timeStep, 
                                            double pitchFloor, 
                                            double pitchCeiling) const {
    // MOCK IMPLEMENTATION
    // Real implementation would:
    // 1. Call Sound_to_Pitch(this->praatSound, timeStep, pitchFloor, pitchCeiling)
    // 2. Wrap result in PraatPitch object
    
    Rcpp::Rcout << "Mock: Computing pitch (floor=" << pitchFloor 
                << ", ceiling=" << pitchCeiling << ")" << std::endl;
    
    PraatPitch* pitch = new PraatPitch(pitchFloor, pitchCeiling, duration);
    return Rcpp::XPtr<PraatPitch>(pitch, true);
}

Rcpp::XPtr<PraatFormant> PraatSound::toFormant(double timeStep,
                                                double maxFormant,
                                                double windowLength,
                                                double preEmphasis) const {
    // MOCK IMPLEMENTATION
    // Real implementation would call Sound_to_Formant_burg
    
    Rcpp::Rcout << "Mock: Computing formants (max=" << maxFormant << " Hz)" << std::endl;
    
    PraatFormant* formant = new PraatFormant(maxFormant, duration);
    return Rcpp::XPtr<PraatFormant>(formant, true);
}

Rcpp::XPtr<PraatIntensity> PraatSound::toIntensity(double minimumPitch,
                                                    double timeStep) const {
    // MOCK IMPLEMENTATION
    // Real implementation would call Sound_to_Intensity
    
    Rcpp::Rcout << "Mock: Computing intensity (minPitch=" << minimumPitch << ")" << std::endl;
    
    PraatIntensity* intensity = new PraatIntensity(duration);
    return Rcpp::XPtr<PraatIntensity>(intensity, true);
}

void PraatSound::save(const std::string& path, const std::string& format) const {
    // MOCK IMPLEMENTATION
    // Real implementation would call Sound_writeToAudioFile or similar
    
    Rcpp::Rcout << "Mock: Saving sound to " << path << " (format: " << format << ")" << std::endl;
}

double PraatSound::getValueAtTime(double time, size_t channel) const {
    // MOCK IMPLEMENTATION
    // Real implementation would interpolate from Sound object
    
    if (channel >= numberOfChannels) {
        throw std::out_of_range("Channel index out of range");
    }
    
    if (time < 0.0 || time > duration) {
        return 0.0;
    }
    
    size_t sampleIndex = static_cast<size_t>(time * sampleRate);
    if (sampleIndex >= samples.size()) {
        return 0.0;
    }
    
    return samples[sampleIndex];
}

} // namespace pladdrr
