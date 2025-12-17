// formant_wrapper.cpp
// Implementation of Formant wrapper class

#include "formant_wrapper.h"
#include <numeric>
#include <cmath>

namespace pladdrr {

PraatFormant::PraatFormant(double maxF, double dur)
    : maxFormant(maxF), duration(dur) {
    
    // MOCK IMPLEMENTATION
    double timeStep = 0.01; // 10ms frames
    int numFrames = static_cast<int>(duration / timeStep);
    
    timeStamps.resize(numFrames);
    formantValues.resize(numFrames);
    
    // Generate mock formants (F1, F2, F3)
    for (int i = 0; i < numFrames; ++i) {
        timeStamps[i] = i * timeStep;
        
        // Typical vowel formants with some variation
        formantValues[i].push_back(700.0 + 50.0 * std::sin(2.0 * M_PI * 3.0 * timeStamps[i])); // F1
        formantValues[i].push_back(1200.0 + 100.0 * std::cos(2.0 * M_PI * 2.0 * timeStamps[i])); // F2
        formantValues[i].push_back(2500.0 + 200.0 * std::sin(2.0 * M_PI * 1.0 * timeStamps[i])); // F3
    }
    
    Rcpp::Rcout << "Mock: Created formant object with " << numFrames << " frames" << std::endl;
}

PraatFormant::~PraatFormant() {
    // Real implementation: forget(praatFormant);
    Rcpp::Rcout << "Mock: Destroying formant object" << std::endl;
}

double PraatFormant::getValueAtTime(int formantNumber, double time, const std::string& unit) const {
    // MOCK IMPLEMENTATION
    // Real implementation would call Formant_getValueAtTime
    
    if (formantNumber < 1 || time < 0.0 || time > duration) {
        return 0.0;
    }
    
    // Linear interpolation
    for (size_t i = 0; i < timeStamps.size() - 1; ++i) {
        if (time >= timeStamps[i] && time <= timeStamps[i + 1]) {
            if (formantNumber > static_cast<int>(formantValues[i].size())) {
                return 0.0;
            }
            
            double t = (time - timeStamps[i]) / (timeStamps[i + 1] - timeStamps[i]);
            double v1 = formantValues[i][formantNumber - 1];
            double v2 = formantValues[i + 1][formantNumber - 1];
            return v1 * (1.0 - t) + v2 * t;
        }
    }
    
    return 0.0;
}

double PraatFormant::getBandwidthAtTime(int formantNumber, double time, const std::string& unit) const {
    // MOCK IMPLEMENTATION
    // Real implementation would call Formant_getBandwidthAtTime
    
    // Mock: return typical bandwidth values
    if (formantNumber == 1) return 50.0;
    if (formantNumber == 2) return 70.0;
    if (formantNumber == 3) return 110.0;
    return 100.0;
}

double PraatFormant::getMean(int formantNumber, const std::string& unit) const {
    // MOCK IMPLEMENTATION
    
    if (formantNumber < 1 || formantValues.empty()) {
        return 0.0;
    }
    
    double sum = 0.0;
    int count = 0;
    
    for (const auto& frame : formantValues) {
        if (formantNumber <= static_cast<int>(frame.size())) {
            sum += frame[formantNumber - 1];
            count++;
        }
    }
    
    return (count > 0) ? sum / count : 0.0;
}

Rcpp::DataFrame PraatFormant::getFormantValues() const {
    int numFrames = timeStamps.size();
    int numFormants = formantValues.empty() ? 0 : formantValues[0].size();
    
    Rcpp::NumericVector time(numFrames);
    std::vector<Rcpp::NumericVector> formants(numFormants);
    
    for (int f = 0; f < numFormants; ++f) {
        formants[f] = Rcpp::NumericVector(numFrames);
    }
    
    for (int i = 0; i < numFrames; ++i) {
        time[i] = timeStamps[i];
        for (int f = 0; f < numFormants; ++f) {
            formants[f][i] = formantValues[i][f];
        }
    }
    
    Rcpp::List dataList = Rcpp::List::create(Rcpp::Named("time") = time);
    for (int f = 0; f < numFormants; ++f) {
        std::string colName = "F" + std::to_string(f + 1);
        dataList[colName] = formants[f];
    }
    
    return Rcpp::DataFrame(dataList);
}

int PraatFormant::getNumberOfFormants() const {
    return formantValues.empty() ? 0 : formantValues[0].size();
}

} // namespace pladdrr
