// [[Rcpp::interfaces(r, cpp)]]
// [[Rcpp::plugins(cpp17)]]

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/Sound.h"
#include "fon/Intensity.h"
#include "fon/Sound_to_Intensity.h"
#include "fon/IntensityTier.h"
#include "fon/Intensity_to_IntensityTier.h"
#include "fon/Vector.h"
#include "melder/melder.h"

using namespace Rcpp;

// Note: sound_to_intensity is already defined in sound_wrappers.cpp
// We only need the query methods here

// [[Rcpp::export(".intensity_get_value_at_time")]]
double intensity_get_value_at_time(XPtr<structIntensity> intensity_xptr, double time, int interpolation_type) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    // Convert int to enum
    kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation_type);
    double value = Vector_getValueAtX(intensity_xptr.get(), time, 1, interp);
    
    return value;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getValueAtTime");
  }
}

// [[Rcpp::export(".intensity_get_mean")]]
double intensity_get_mean(XPtr<structIntensity> intensity_xptr, double from_time, double to_time) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    // Use Intensity_getAverage with ENERGY method (method 1)
    double mean = Intensity_getAverage(intensity_xptr.get(), from_time, to_time, 1);
    
    return mean;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getMean");
  }
}

// [[Rcpp::export(".intensity_get_minimum")]]
double intensity_get_minimum(XPtr<structIntensity> intensity_xptr, double from_time, double to_time) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    // Use parabolic interpolation (2)
    kVector_peakInterpolation interp = kVector_peakInterpolation::PARABOLIC;
    double minimum = Vector_getMinimum(intensity_xptr.get(), from_time, to_time, interp);
    
    return minimum;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getMinimum");
  }
}

// [[Rcpp::export(".intensity_get_maximum")]]
double intensity_get_maximum(XPtr<structIntensity> intensity_xptr, double from_time, double to_time) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    // Use parabolic interpolation (2)
    kVector_peakInterpolation interp = kVector_peakInterpolation::PARABOLIC;
    double maximum = Vector_getMaximum(intensity_xptr.get(), from_time, to_time, interp);
    
    return maximum;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getMaximum");
  }
}

// [[Rcpp::export(".intensity_get_standard_deviation")]]
double intensity_get_standard_deviation(XPtr<structIntensity> intensity_xptr, double from_time, double to_time) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    Intensity intensity = intensity_xptr.get();
    
    // Calculate standard deviation manually since Intensity doesn't have a built-in method
    // Get mean first
    double mean = Intensity_getAverage(intensity, from_time, to_time, 1);
    
    // Determine frame range
    integer ifmin, ifmax;
    if (from_time == 0.0) from_time = intensity->xmin;
    if (to_time == 0.0) to_time = intensity->xmax;
    
    Sampled_getWindowSamples(intensity, from_time, to_time, &ifmin, &ifmax);
    
    // Calculate variance
    double sum_sq = 0.0;
    integer count = 0;
    
    for (integer i = ifmin; i <= ifmax; i++) {
      double value = intensity->z[1][i];
      if (std::isfinite(value)) {
        double diff = value - mean;
        sum_sq += diff * diff;
        count++;
      }
    }
    
    if (count < 2) {
      return undefined;
    }
    
    double variance = sum_sq / (count - 1);
    return sqrt(variance);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getStandardDeviation");
  }
}

// [[Rcpp::export(".intensity_get_quantile")]]
double intensity_get_quantile(XPtr<structIntensity> intensity_xptr, double from_time, double to_time, double quantile) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    double value = Intensity_getQuantile(intensity_xptr.get(), from_time, to_time, quantile);
    
    return value;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getQuantile");
  }
}

// [[Rcpp::export(".intensity_get_time_of_minimum")]]
double intensity_get_time_of_minimum(XPtr<structIntensity> intensity_xptr, double from_time, double to_time) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    // Use parabolic interpolation (2)
    kVector_peakInterpolation interp = kVector_peakInterpolation::PARABOLIC;
    double time_of_min = Vector_getXOfMinimum(intensity_xptr.get(), from_time, to_time, interp);
    
    return time_of_min;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getTimeOfMinimum");
  }
}

// [[Rcpp::export(".intensity_get_time_of_maximum")]]
double intensity_get_time_of_maximum(XPtr<structIntensity> intensity_xptr, double from_time, double to_time) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    // Use parabolic interpolation (2)
    kVector_peakInterpolation interp = kVector_peakInterpolation::PARABOLIC;
    double time_of_max = Vector_getXOfMaximum(intensity_xptr.get(), from_time, to_time, interp);
    
    return time_of_max;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getTimeOfMaximum");
  }
}

// [[Rcpp::export(".intensity_get_time_from_frame")]]
double intensity_get_time_from_frame(XPtr<structIntensity> intensity_xptr, int frame) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    Intensity intensity = intensity_xptr.get();
    
    if (frame < 1 || frame > intensity->nx) {
      stop("Frame number out of range");
    }
    
    // Calculate time from frame (1-based indexing)
    double time = intensity->x1 + (frame - 1) * intensity->dx;
    
    return time;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getTimeFromFrame");
  }
}

// [[Rcpp::export(".intensity_get_frame_from_time")]]
int intensity_get_frame_from_time(XPtr<structIntensity> intensity_xptr, double time) {
  try {
    Melder_clearError();
    
    validate_xptr(intensity_xptr, "Intensity");
    
    Intensity intensity = intensity_xptr.get();
    
    // Find nearest frame (1-based)
    integer frame = Sampled_xToNearestIndex(intensity, time);
    
    return static_cast<int>(frame);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Intensity_getFrameFromTime");
  }
}

// [[Rcpp::export(".intensity_get_number_of_frames")]]
int intensity_get_number_of_frames(XPtr<structIntensity> intensity_xptr) {
  try {
    validate_xptr(intensity_xptr, "Intensity");
    return intensity_xptr->nx;
  } catch (...) {
    stop("Error getting number of frames");
  }
}

// [[Rcpp::export(".intensity_get_sampling_period")]]
double intensity_get_sampling_period(XPtr<structIntensity> intensity_xptr) {
  try {
    validate_xptr(intensity_xptr, "Intensity");
    return intensity_xptr->dx;
  } catch (...) {
    stop("Error getting sampling period");
  }
}

// [[Rcpp::export(".intensity_get_start_time")]]
double intensity_get_start_time(XPtr<structIntensity> intensity_xptr) {
  try {
    validate_xptr(intensity_xptr, "Intensity");
    return intensity_xptr->xmin;
  } catch (...) {
    stop("Error getting start time");
  }
}

// [[Rcpp::export(".intensity_get_end_time")]]
double intensity_get_end_time(XPtr<structIntensity> intensity_xptr) {
  try {
    validate_xptr(intensity_xptr, "Intensity");
    return intensity_xptr->xmax;
  } catch (...) {
    stop("Error getting end time");
  }
}

// ============================================================================
// Transform methods
// ============================================================================

// [[Rcpp::export(".intensity_down_to_intensity_tier")]]
XPtr<structIntensityTier> intensity_down_to_intensity_tier(XPtr<structIntensity> intensity_xptr) {
  try {
    validate_xptr(intensity_xptr, "Intensity");
    autoIntensityTier tier = Intensity_to_IntensityTier(intensity_xptr.get());
    return create_xptr_from_auto<structIntensityTier>(tier);
  } catch (MelderError) {
    Melder_clearError();
    stop("Failed to convert Intensity to IntensityTier");
  }
}
