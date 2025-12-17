// pitch_wrapper.cpp
// Implementation of Pitch wrapper class

#include "pitch_wrapper.h"
#include <cmath>
#include <algorithm>
#include <numeric>

namespace pladdrr {

PraatPitch::PraatPitch(double floor, double ceiling, double dur)
    : pitchFloor(floor), pitchCeiling(ceiling), duration(dur) {
    
    // MOCK IMPLEMENTATION
    // Generate mock pitch contour (simulating natural pitch variation)
    double timeStep = 0.01; // 10ms frames
    int numFrames = static_cast<int>(duration / timeStep);
    
    pitchValues.resize(numFrames);
    timeStamps.resize(numFrames);
    
    // Generate mock pitch (varies around 200 Hz)
    double basePitch = 200.0;
    for (int i = 0; i < numFrames; ++i) {
        timeStamps[i] = i * timeStep;
        // Add some variation
        double t = timeStamps[i];
        pitchValues[i] = basePitch + 20.0 * std::sin(2.0 * M_PI * 5.0 * t);
        
        // Some frames are "unvoiced" (set to 0)
        if (std::fmod(t, 0.2) < 0.05) {
            pitchValues[i] = 0.0;
        }
    }
    
    Rcpp::Rcout << "Mock: Created pitch object with " << numFrames << " frames" << std::endl;
}

PraatPitch::~PraatPitch() {
    // Real implementation: forget(praatPitch);
    Rcpp::Rcout << "Mock: Destroying pitch object" << std::endl;
}

double PraatPitch::getValueAtTime(double time, const std::string& unit) const {
    // MOCK IMPLEMENTATION
    // Real implementation would call Pitch_getValueAtTime
    
    if (time < 0.0 || time > duration) {
        return 0.0; // undefined
    }
    
    // Linear interpolation
    for (size_t i = 0; i < timeStamps.size() - 1; ++i) {
        if (time >= timeStamps[i] && time <= timeStamps[i + 1]) {
            double t = (time - timeStamps[i]) / (timeStamps[i + 1] - timeStamps[i]);
            return pitchValues[i] * (1.0 - t) + pitchValues[i + 1] * t;
        }
    }
    
    return pitchValues.back();
}

double PraatPitch::getMean(const std::string& unit) const {
    // MOCK IMPLEMENTATION
    // Real implementation would call Pitch_getMean
    
    std::vector<double> voiced;
    for (double val : pitchValues) {
        if (val > 0.0) {
            voiced.push_back(val);
        }
    }
    
    if (voiced.empty()) {
        return 0.0;
    }
    
    return std::accumulate(voiced.begin(), voiced.end(), 0.0) / voiced.size();
}

double PraatPitch::getStandardDeviation(const std::string& unit) const {
    // MOCK IMPLEMENTATION
    std::vector<double> voiced;
    for (double val : pitchValues) {
        if (val > 0.0) {
            voiced.push_back(val);
        }
    }
    
    if (voiced.size() < 2) {
        return 0.0;
    }
    
    double mean = getMean(unit);
    double sq_sum = 0.0;
    for (double val : voiced) {
        sq_sum += (val - mean) * (val - mean);
    }
    
    return std::sqrt(sq_sum / (voiced.size() - 1));
}

double PraatPitch::getMinimum(const std::string& unit) const {
    // MOCK IMPLEMENTATION
    auto it = std::min_element(pitchValues.begin(), pitchValues.end(),
        [](double a, double b) { return (a > 0.0 && (b == 0.0 || a < b)); });
    
    return (it != pitchValues.end() && *it > 0.0) ? *it : 0.0;
}

double PraatPitch::getMaximum(const std::string& unit) const {
    // MOCK IMPLEMENTATION
    auto it = std::max_element(pitchValues.begin(), pitchValues.end());
    return (it != pitchValues.end()) ? *it : 0.0;
}

Rcpp::List PraatPitch::getPitchValues() const {
    return Rcpp::List::create(
        Rcpp::Named("time") = timeStamps,
        Rcpp::Named("pitch") = pitchValues
    );
}

int PraatPitch::countVoicedFrames() const {
    return std::count_if(pitchValues.begin(), pitchValues.end(),
                         [](double v) { return v > 0.0; });
}

} // namespace pladdrr
