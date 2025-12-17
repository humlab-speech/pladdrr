// pitch_wrapper.h
// C++ wrapper class for Praat Pitch objects

#ifndef PITCH_WRAPPER_H
#define PITCH_WRAPPER_H

#include <Rcpp.h>
#include <vector>

namespace pladdrr {

/**
 * Wrapper class for Praat Pitch objects
 * 
 * Represents pitch analysis results from Praat
 */
class PraatPitch {
private:
    // In actual implementation: Pitch* praatPitch;
    double pitchFloor;
    double pitchCeiling;
    double duration;
    std::vector<double> pitchValues; // Mock data: pitch at each time frame
    std::vector<double> timeStamps;
    
public:
    PraatPitch(double floor, double ceiling, double dur);
    ~PraatPitch();
    
    // Prevent copying
    PraatPitch(const PraatPitch&) = delete;
    PraatPitch& operator=(const PraatPitch&) = delete;
    
    /**
     * Get pitch value at specific time
     * Uses interpolation between frames
     */
    double getValueAtTime(double time, const std::string& unit = "Hertz") const;
    
    /**
     * Get mean pitch over entire duration
     */
    double getMean(const std::string& unit = "Hertz") const;
    
    /**
     * Get standard deviation of pitch
     */
    double getStandardDeviation(const std::string& unit = "Hertz") const;
    
    /**
     * Get minimum pitch
     */
    double getMinimum(const std::string& unit = "Hertz") const;
    
    /**
     * Get maximum pitch
     */
    double getMaximum(const std::string& unit = "Hertz") const;
    
    /**
     * Get all pitch values as R vectors
     */
    Rcpp::List getPitchValues() const;
    
    /**
     * Count number of voiced frames
     */
    int countVoicedFrames() const;
};

} // namespace pladdrr

#endif // PITCH_WRAPPER_H
