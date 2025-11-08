// [[Rcpp::interfaces(r, cpp)]]
// [[Rcpp::plugins(cpp17)]]

#include "praat_types.h"
#include <Rcpp.h>
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "fon/Sound.h"
#include "fon/Harmonicity.h"
#include "fon/Sound_to_Harmonicity.h"
#include "fon/Vector.h"
#include "melder/melder.h"

using namespace Rcpp;

// [[Rcpp::export(".harmonicity_to_sound_ac")]]
XPtr<structHarmonicity> harmonicity_from_sound_ac(XPtr<structSound> sound_xptr, double time_step, double min_pitch,
                               double silence_threshold, double periods_per_window) {
  try {
    Melder_clearError();
    
    validate_xptr(sound_xptr, "Sound");
    
    // Create Harmonicity object using autocorrelation method
    autoHarmonicity harmonicity = Sound_to_Harmonicity_ac(
      sound_xptr.get(),
      time_step,
      min_pitch,
      silence_threshold,
      periods_per_window
    );
    
    return create_xptr_from_auto<structHarmonicity>(harmonicity);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Sound_to_Harmonicity_ac");
  }
}

// [[Rcpp::export(".harmonicity_to_sound_cc")]]
XPtr<structHarmonicity> harmonicity_from_sound_cc(XPtr<structSound> sound_xptr, double time_step, double min_pitch,
                               double silence_threshold, double periods_per_window) {
  try {
    Melder_clearError();
    
    validate_xptr(sound_xptr, "Sound");
    
    // Create Harmonicity object using cross-correlation method
    autoHarmonicity harmonicity = Sound_to_Harmonicity_cc(
      sound_xptr.get(),
      time_step,
      min_pitch,
      silence_threshold,
      periods_per_window
    );
    
    return create_xptr_from_auto<structHarmonicity>(harmonicity);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Sound_to_Harmonicity_cc");
  }
}

// [[Rcpp::export(".harmonicity_get_value_at_time")]]
double harmonicity_get_value_at_time(XPtr<structHarmonicity> harmonicity_xptr, double time, int interpolation_type) {
  try {
    Melder_clearError();
    
    validate_xptr(harmonicity_xptr, "Harmonicity");
    
    // Convert int to enum
    kVector_valueInterpolation interp = static_cast<kVector_valueInterpolation>(interpolation_type);
    double value = Vector_getValueAtX(harmonicity_xptr.get(), time, 1, interp);
    
    return value;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Harmonicity_getValueAtTime");
  }
}

// [[Rcpp::export(".harmonicity_get_mean")]]
double harmonicity_get_mean(XPtr<structHarmonicity> harmonicity_xptr, double from_time, double to_time) {
  try {
    Melder_clearError();
    
    validate_xptr(harmonicity_xptr, "Harmonicity");
    
    double mean = Harmonicity_getMean(harmonicity_xptr.get(), from_time, to_time);
    
    return mean;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Harmonicity_getMean");
  }
}

// [[Rcpp::export(".harmonicity_get_minimum")]]
double harmonicity_get_minimum(XPtr<structHarmonicity> harmonicity_xptr, double from_time, double to_time, int interpolation_type) {
  try {
    Melder_clearError();
    
    validate_xptr(harmonicity_xptr, "Harmonicity");
    
    // Convert int to enum
    kVector_peakInterpolation interp = static_cast<kVector_peakInterpolation>(interpolation_type);
    double minimum = Vector_getMinimum(harmonicity_xptr.get(), from_time, to_time, interp);
    
    return minimum;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Harmonicity_getMinimum");
  }
}

// [[Rcpp::export(".harmonicity_get_maximum")]]
double harmonicity_get_maximum(XPtr<structHarmonicity> harmonicity_xptr, double from_time, double to_time, int interpolation_type) {
  try {
    Melder_clearError();
    
    validate_xptr(harmonicity_xptr, "Harmonicity");
    
    // Convert int to enum
    kVector_peakInterpolation interp = static_cast<kVector_peakInterpolation>(interpolation_type);
    double maximum = Vector_getMaximum(harmonicity_xptr.get(), from_time, to_time, interp);
    
    return maximum;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Harmonicity_getMaximum");
  }
}

// [[Rcpp::export(".harmonicity_get_standard_deviation")]]
double harmonicity_get_standard_deviation(XPtr<structHarmonicity> harmonicity_xptr, double from_time, double to_time) {
  try {
    Melder_clearError();
    
    validate_xptr(harmonicity_xptr, "Harmonicity");
    
    double std_dev = Harmonicity_getStandardDeviation(harmonicity_xptr.get(), from_time, to_time);
    
    return std_dev;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Harmonicity_getStandardDeviation");
  }
}

// [[Rcpp::export(".harmonicity_get_time_of_minimum")]]
double harmonicity_get_time_of_minimum(XPtr<structHarmonicity> harmonicity_xptr, double from_time, double to_time, int interpolation_type) {
  try {
    Melder_clearError();
    
    validate_xptr(harmonicity_xptr, "Harmonicity");
    
    // Convert int to enum
    kVector_peakInterpolation interp = static_cast<kVector_peakInterpolation>(interpolation_type);
    double time_of_min = Vector_getXOfMinimum(harmonicity_xptr.get(), from_time, to_time, interp);
    
    return time_of_min;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Harmonicity_getTimeOfMinimum");
  }
}

// [[Rcpp::export(".harmonicity_get_time_of_maximum")]]
double harmonicity_get_time_of_maximum(XPtr<structHarmonicity> harmonicity_xptr, double from_time, double to_time, int interpolation_type) {
  try {
    Melder_clearError();
    
    validate_xptr(harmonicity_xptr, "Harmonicity");
    
    // Convert int to enum
    kVector_peakInterpolation interp = static_cast<kVector_peakInterpolation>(interpolation_type);
    double time_of_max = Vector_getXOfMaximum(harmonicity_xptr.get(), from_time, to_time, interp);
    
    return time_of_max;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Harmonicity_getTimeOfMaximum");
  }
}

// [[Rcpp::export(".harmonicity_as_matrix")]]
NumericMatrix harmonicity_as_matrix(XPtr<structHarmonicity> harmonicity_xptr) {
  try {
    Melder_clearError();
    
    validate_xptr(harmonicity_xptr, "Harmonicity");
    
    Harmonicity harmonicity = harmonicity_xptr.get();
    
    integer n_frames = harmonicity->nx;
    double xmin = harmonicity->x1;
    double dx = harmonicity->dx;
    
    // Create matrix: 2 rows (time, value)
    NumericMatrix result(2, n_frames);
    
    for (integer i = 1; i <= n_frames; i++) {
      double time = xmin + (i - 1) * dx;
      double value = harmonicity->z[1][i];
      result(0, i-1) = time;
      result(1, i-1) = value;
    }
    
    return result;
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error in Harmonicity_asMatrix");
  }
}

// [[Rcpp::export(".harmonicity_get_number_of_frames")]]
int harmonicity_get_number_of_frames(XPtr<structHarmonicity> harmonicity_xptr) {
  try {
    validate_xptr(harmonicity_xptr, "Harmonicity");
    return harmonicity_xptr->nx;
  } catch (...) {
    stop("Error getting number of frames");
  }
}

// [[Rcpp::export(".harmonicity_get_time_step")]]
double harmonicity_get_time_step(XPtr<structHarmonicity> harmonicity_xptr) {
  try {
    validate_xptr(harmonicity_xptr, "Harmonicity");
    return harmonicity_xptr->dx;
  } catch (...) {
    stop("Error getting time step");
  }
}

// [[Rcpp::export(".harmonicity_get_start_time")]]
double harmonicity_get_start_time(XPtr<structHarmonicity> harmonicity_xptr) {
  try {
    validate_xptr(harmonicity_xptr, "Harmonicity");
    return harmonicity_xptr->xmin;
  } catch (...) {
    stop("Error getting start time");
  }
}

// [[Rcpp::export(".harmonicity_get_end_time")]]
double harmonicity_get_end_time(XPtr<structHarmonicity> harmonicity_xptr) {
  try {
    validate_xptr(harmonicity_xptr, "Harmonicity");
    return harmonicity_xptr->xmax;
  } catch (...) {
    stop("Error getting end time");
  }
}
