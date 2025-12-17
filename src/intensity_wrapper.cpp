// intensity_wrapper.cpp
// Implementation of Intensity wrapper class

#include "intensity_wrapper.h"
#include <cmath>
#include <numeric>
#include <algorithm>

namespace pladdrr {

PraatIntensity::PraatIntensity(double dur) : duration(dur) {
    // MOCK IMPLEMENTATION
    double timeStep = 0.01; // 10ms frames
    int numFrames = static_cast<int>(duration / timeStep);
    
    timeStamps.resize(numFrames);
    intensityValues.resize(numFrames);
    
    // Generate mock intensity values (in dB)
    for (int i = 0; i < numFrames; ++i) {
        timeStamps[i] = i * timeStep;
        // Simulate intensity variation
        intensityValues[i] = 70.0 + 10.0 * std::sin(2.0 * M_PI * 2.0 * timeStamps[i]);
    }
    
    Rcpp::Rcout << "Mock: Created intensity object with " << numFrames << " frames" << std::endl;
}

PraatIntensity::~PraatIntensity() {
    // Real implementation: forget(praatIntensity);
    Rcpp::Rcout << "Mock: Destroying intensity object" << std::endl;
}

double PraatIntensity::getValueAtTime(double time) const {
    // MOCK IMPLEMENTATION
    // Real implementation would call Intensity_getValueAtTime
    
    if (time < 0.0 || time > duration) {
        return 0.0;
    }
    
    // Linear interpolation
    for (size_t i = 0; i < timeStamps.size() - 1; ++i) {
        if (time >= timeStamps[i] && time <= timeStamps[i + 1]) {
            double t = (time - timeStamps[i]) / (timeStamps[i + 1] - timeStamps[i]);
            return intensityValues[i] * (1.0 - t) + intensityValues[i + 1] * t;
        }
    }
    
    return intensityValues.back();
}

double PraatIntensity::getMean() const {
    // MOCK IMPLEMENTATION
    if (intensityValues.empty()) {
        return 0.0;
    }
    return std::accumulate(intensityValues.begin(), intensityValues.end(), 0.0) / intensityValues.size();
}

double PraatIntensity::getStandardDeviation() const {
    // MOCK IMPLEMENTATION
    if (intensityValues.size() < 2) {
        return 0.0;
    }
    
    double mean = getMean();
    double sq_sum = 0.0;
    for (double val : intensityValues) {
        sq_sum += (val - mean) * (val - mean);
    }
    
    return std::sqrt(sq_sum / (intensityValues.size() - 1));
}

double PraatIntensity::getMinimum() const {
    // MOCK IMPLEMENTATION
    auto it = std::min_element(intensityValues.begin(), intensityValues.end());
    return (it != intensityValues.end()) ? *it : 0.0;
}

double PraatIntensity::getMaximum() const {
    // MOCK IMPLEMENTATION
    auto it = std::max_element(intensityValues.begin(), intensityValues.end());
    return (it != intensityValues.end()) ? *it : 0.0;
}

Rcpp::List PraatIntensity::getIntensityValues() const {
    return Rcpp::List::create(
        Rcpp::Named("time") = timeStamps,
        Rcpp::Named("intensity") = intensityValues
    );
}

} // namespace pladdrr
