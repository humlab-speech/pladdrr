// formant_wrapper.h
// C++ wrapper class for Praat Formant objects

#ifndef FORMANT_WRAPPER_H
#define FORMANT_WRAPPER_H

#include <Rcpp.h>
#include <vector>

namespace pladdrr {

/**
 * Wrapper class for Praat Formant objects
 */
class PraatFormant {
private:
    // In actual implementation: Formant* praatFormant;
    double maxFormant;
    double duration;
    std::vector<std::vector<double>> formantValues; // [frame][formantNum]
    std::vector<double> timeStamps;
    
public:
    PraatFormant(double maxF, double dur);
    ~PraatFormant();
    
    // Prevent copying
    PraatFormant(const PraatFormant&) = delete;
    PraatFormant& operator=(const PraatFormant&) = delete;
    
    /**
     * Get formant value at specific time
     * formantNumber: 1-based (F1, F2, F3, ...)
     */
    double getValueAtTime(int formantNumber, double time, const std::string& unit = "Hertz") const;
    
    /**
     * Get bandwidth at specific time
     */
    double getBandwidthAtTime(int formantNumber, double time, const std::string& unit = "Hertz") const;
    
    /**
     * Get mean of specific formant
     */
    double getMean(int formantNumber, const std::string& unit = "Hertz") const;
    
    /**
     * Get all formant values as R data frame
     */
    Rcpp::DataFrame getFormantValues() const;
    
    /**
     * Get number of formants tracked
     */
    int getNumberOfFormants() const;
};

} // namespace pladdrr

#endif // FORMANT_WRAPPER_H
