// intensity_wrapper.h
// C++ wrapper class for Praat Intensity objects

#ifndef INTENSITY_WRAPPER_H
#define INTENSITY_WRAPPER_H

#include <Rcpp.h>
#include <vector>

namespace pladdrr {

/**
 * Wrapper class for Praat Intensity objects
 */
class PraatIntensity {
private:
    // In actual implementation: Intensity* praatIntensity;
    double duration;
    std::vector<double> intensityValues;
    std::vector<double> timeStamps;
    
public:
    PraatIntensity(double dur);
    ~PraatIntensity();
    
    // Prevent copying
    PraatIntensity(const PraatIntensity&) = delete;
    PraatIntensity& operator=(const PraatIntensity&) = delete;
    
    /**
     * Get intensity value at specific time (in dB)
     */
    double getValueAtTime(double time) const;
    
    /**
     * Get mean intensity
     */
    double getMean() const;
    
    /**
     * Get standard deviation
     */
    double getStandardDeviation() const;
    
    /**
     * Get minimum intensity
     */
    double getMinimum() const;
    
    /**
     * Get maximum intensity
     */
    double getMaximum() const;
    
    /**
     * Get all intensity values as R list
     */
    Rcpp::List getIntensityValues() const;
};

} // namespace pladdrr

#endif // INTENSITY_WRAPPER_H
