#include <Rcpp.h>

// Forward declarations for Praat types
typedef struct structSound *Sound;
typedef struct structPitch *Pitch;

// Now include Praat headers
#include "melder.h"
#include "Sound.h"
#include "Pitch.h"

using namespace Rcpp;

// ============================================================================
// Finalizers for automatic memory cleanup
// ============================================================================

void sound_finalizer(Sound sound) {
  if (sound != nullptr) {
    forget(sound);
  }
}

void pitch_finalizer(Pitch pitch) {
  if (pitch != nullptr) {
    forget(pitch);
  }
}

// ============================================================================
// Sound: I/O and Creation
// ============================================================================

// [[Rcpp::export(.sound_read_from_file)]]
XPtr<Sound> sound_read_from_file(std::string path) {
  try {
    autoSound sound = Sound_readFromSoundFile(Melder_peek8to32(path.c_str()));
    
    if (! sound) {
      stop("Failed to read sound file: " + path);
    }
    
    // Transfer ownership to XPtr with finalizer
    Sound sound_ptr = sound.releaseToAmbiguousOwner();
    return XPtr<Sound>(sound_ptr, true, sound_finalizer);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error while reading sound file: " + path);
  }
}

// [[Rcpp::export(.sound_create_from_values)]]
XPtr<Sound> sound_create_from_values(NumericVector values, double sampling_rate) {
  try {
    integer n_samples = values.size();
    
    // Create Sound object
    autoSound sound = Sound_create(
      1,                    // number of channels
      0.0,                 // xmin
      n_samples / sampling_rate,  // xmax
      n_samples,           // nx
      1.0 / sampling_rate, // dx
      0.5 / sampling_rate  // x1
    );
    
    // Copy values
    for (integer i = 1; i <= n_samples; i++) {
      sound->z[1][i] = values[i - 1];
    }
    
    // Transfer ownership to XPtr
    Sound sound_ptr = sound.releaseToAmbiguousOwner();
    return XPtr<Sound>(sound_ptr, true, sound_finalizer);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error while creating sound from values");
  }
}

// ============================================================================
// Sound: Query Methods
// ============================================================================

// [[Rcpp::export(.sound_get_duration)]]
double sound_get_duration(XPtr<Sound> sound_ptr) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  Sound sound = sound_ptr.get();
  return sound->xmax - sound->xmin;
}

// [[Rcpp::export(.sound_get_sampling_frequency)]]
double sound_get_sampling_frequency(XPtr<Sound> sound_ptr) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  Sound sound = sound_ptr.get();
  return 1.0 / sound->dx;
}

// [[Rcpp::export(.sound_get_number_of_channels)]]
int sound_get_number_of_channels(XPtr<Sound> sound_ptr) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  Sound sound = sound_ptr.get();
  return sound->ny;
}

// [[Rcpp::export(.sound_get_number_of_samples)]]
int sound_get_number_of_samples(XPtr<Sound> sound_ptr) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  Sound sound = sound_ptr.get();
  return sound->nx;
}

// [[Rcpp::export(.sound_get_time_from_sample)]]
double sound_get_time_from_sample(XPtr<Sound> sound_ptr, int sample) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  Sound sound = sound_ptr.get();
  
  if (sample < 1 || sample > sound->nx) {
    stop("Sample index out of range");
  }
  
  return Sampled_indexToX(sound, sample);
}

// [[Rcpp::export(.sound_get_value_at_time)]]
double sound_get_value_at_time(XPtr<Sound> sound_ptr, double time, int channel) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  Sound sound = sound_ptr.get();
  
  if (channel < 1 || channel > sound->ny) {
    stop("Channel index out of range");
  }
  
  try {
    double value = Vector_getValueAtX(
      sound,
      time,
      channel,
      Vector_VALUE_INTERPOLATION_LINEAR
    );
    
    return value;
    
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// ============================================================================
// Sound: Transformation Methods
// ============================================================================

// [[Rcpp::export(.sound_to_pitch)]]
XPtr<Pitch> sound_to_pitch(XPtr<Sound> sound_ptr,
                                 double time_step,
                                 double pitch_floor,
                                 double pitch_ceiling) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  try {
    Sound sound = sound_ptr.get();
    
    autoPitch pitch = Sound_to_Pitch_ac(
      sound,
      time_step,
      pitch_floor,
      3.0,      // max number of candidates
      15,       // very accurate
      0.03,     // silence threshold
      0.45,     // voicing threshold
      0.01,     // octave cost
      0.35,     // octave jump cost
      0.14,     // voiced/unvoiced cost
      pitch_ceiling
    );
    
    if (! pitch) {
      stop("Failed to create pitch object");
    }
    
    // Transfer ownership to XPtr
    Pitch pitch_ptr = pitch.releaseToAmbiguousOwner();
    return XPtr<Pitch>(pitch_ptr, true, pitch_finalizer);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error during pitch analysis");
  }
}

// [[Rcpp::export(.sound_extract_part)]]
XPtr<Sound> sound_extract_part(XPtr<Sound> sound_ptr,
                                     double from_time,
                                     double to_time) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  try {
    Sound sound = sound_ptr.get();
    
    autoSound part = Sound_extractPart(
      sound,
      from_time,
      to_time,
      kSound_windowShape::RECTANGULAR,
      1.0,    // relative width
      FALSE   // preserve times
    );
    
    if (! part) {
      stop("Failed to extract part");
    }
    
    // Transfer ownership to XPtr
    Sound part_ptr = part.releaseToAmbiguousOwner();
    return XPtr<Sound>(part_ptr, true, sound_finalizer);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error during part extraction");
  }
}

// ============================================================================
// Sound: Modification Methods
// ============================================================================

// [[Rcpp::export(.sound_scale_intensity)]]
void sound_scale_intensity(XPtr<Sound> sound_ptr, double new_average_intensity) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  try {
    Sound sound = sound_ptr.get();
    Sound_scaleIntensity(sound, new_average_intensity);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error during intensity scaling");
  }
}

// ============================================================================
// Sound: Export Methods
// ============================================================================

// [[Rcpp::export(.sound_as_data_frame)]]
DataFrame sound_as_data_frame(XPtr<Sound> sound_ptr) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  Sound sound = sound_ptr.get();
  
  integer n_samples = sound->nx;
  integer n_channels = sound->ny;
  
  NumericVector time(n_samples);
  NumericVector value(n_samples);
  
  // Get time points and values (for channel 1)
  for (integer i = 1; i <= n_samples; i++) {
    time[i - 1] = Sampled_indexToX(sound, i);
    value[i - 1] = sound->z[1][i];
  }
  
  if (n_channels == 1) {
    return DataFrame::create(
      Named("time") = time,
      Named("value") = value,
      _["stringsAsFactors"] = false
    );
  } else {
    // For stereo, include channel indicator
    IntegerVector channel_vec(n_samples * n_channels);
    NumericVector time_rep(n_samples * n_channels);
    NumericVector value_all(n_samples * n_channels);
    
    for (int ch = 1; ch <= n_channels; ch++) {
      for (integer i = 1; i <= n_samples; i++) {
        int idx = (ch - 1) * n_samples + (i - 1);
        time_rep[idx] = Sampled_indexToX(sound, i);
        value_all[idx] = sound->z[ch][i];
        channel_vec[idx] = ch;
      }
    }
    
    return DataFrame::create(
      Named("time") = time_rep,
      Named("channel") = channel_vec,
      Named("value") = value_all,
      _["stringsAsFactors"] = false
    );
  }
}

// [[Rcpp::export(.sound_save)]]
void sound_save(XPtr<Sound> sound_ptr, std::string path, std::string format) {
  if (!sound_ptr) {
    stop("Invalid sound pointer");
  }
  
  try {
    Sound sound = sound_ptr.get();
    
    if (format == "WAV" || format == "wav") {
      Sound_writeToWavFile(sound, Melder_peek8to32(path.c_str()));
    } else if (format == "AIFF" || format == "aiff") {
      Sound_writeToAiffFile(sound, Melder_peek8to32(path.c_str()));
    } else {
      stop("Unsupported format: " + format);
    }
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error while saving sound file");
  }
}

// ============================================================================
// Pitch: I/O
// ============================================================================

// [[Rcpp::export(.pitch_read_from_file)]]
XPtr<Pitch> pitch_read_from_file(std::string path) {
  try {
    autoPitch pitch = Data_readFromFile(Melder_peek8to32(path.c_str())).static_cast_move<structPitch>();
    
    if (! pitch) {
      stop("Failed to read pitch file: " + path);
    }
    
    // Transfer ownership to XPtr
    Pitch pitch_ptr = pitch.releaseToAmbiguousOwner();
    return XPtr<Pitch>(pitch_ptr, true, pitch_finalizer);
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error while reading pitch file: " + path);
  }
}

// [[Rcpp::export(.pitch_save)]]
void pitch_save(XPtr<Pitch> pitch_ptr, std::string path) {
  if (!pitch_ptr) {
    stop("Invalid pitch pointer");
  }
  
  try {
    Pitch pitch = pitch_ptr.get();
    Data_writeToTextFile(pitch, Melder_peek8to32(path.c_str()));
    
  } catch (MelderError) {
    Melder_clearError();
    stop("Praat error while saving pitch file");
  }
}

// ============================================================================
// Pitch: Query Methods
// ============================================================================

// [[Rcpp::export(.pitch_get_number_of_frames)]]
int pitch_get_number_of_frames(XPtr<Pitch> pitch_ptr) {
  if (!pitch_ptr) {
    stop("Invalid pitch pointer");
  }
  
  Pitch pitch = pitch_ptr.get();
  return pitch->nx;
}

// [[Rcpp::export(.pitch_get_time_step)]]
double pitch_get_time_step(XPtr<Pitch> pitch_ptr) {
  if (!pitch_ptr) {
    stop("Invalid pitch pointer");
  }
  
  Pitch pitch = pitch_ptr.get();
  return pitch->dx;
}

// [[Rcpp::export(.pitch_get_value_at_time)]]
double pitch_get_value_at_time(XPtr<Pitch> pitch_ptr, double time, std::string unit) {
  if (!pitch_ptr) {
    stop("Invalid pitch pointer");
  }
  
  try {
    Pitch pitch = pitch_ptr.get();
    
    int unit_code = (unit == "Hertz") ? kPitch_unit::HERTZ : kPitch_unit::SEMITONES_100;
    
    double value = Pitch_getValueAtTime(
      pitch,
      time,
      unit_code,
      TRUE  // interpolate
    );
    
    return (value == undefined) ? NA_REAL : value;
    
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// [[Rcpp::export(.pitch_get_mean)]]
double pitch_get_mean(XPtr<Pitch> pitch_ptr, double from_time, double to_time, std::string unit) {
  if (!pitch_ptr) {
    stop("Invalid pitch pointer");
  }
  
  try {
    Pitch pitch = pitch_ptr.get();
    
    int unit_code = (unit == "Hertz") ? kPitch_unit::HERTZ : kPitch_unit::SEMITONES_100;
    
    double value = Pitch_getMean(pitch, from_time, to_time, unit_code);
    
    return (value == undefined) ? NA_REAL : value;
    
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// [[Rcpp::export(.pitch_get_minimum)]]
double pitch_get_minimum(XPtr<Pitch> pitch_ptr, double from_time, double to_time, std::string unit) {
  if (!pitch_ptr) {
    stop("Invalid pitch pointer");
  }
  
  try {
    Pitch pitch = pitch_ptr.get();
    
    int unit_code = (unit == "Hertz") ? kPitch_unit::HERTZ : kPitch_unit::SEMITONES_100;
    
    double value = Pitch_getMinimum(pitch, from_time, to_time, unit_code, TRUE);
    
    return (value == undefined) ? NA_REAL : value;
    
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// [[Rcpp::export(.pitch_get_maximum)]]
double pitch_get_maximum(XPtr<Pitch> pitch_ptr, double from_time, double to_time, std::string unit) {
  if (!pitch_ptr) {
    stop("Invalid pitch pointer");
  }
  
  try {
    Pitch pitch = pitch_ptr.get();
    
    int unit_code = (unit == "Hertz") ? kPitch_unit::HERTZ : kPitch_unit::SEMITONES_100;
    
    double value = Pitch_getMaximum(pitch, from_time, to_time, unit_code, TRUE);
    
    return (value == undefined) ? NA_REAL : value;
    
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// [[Rcpp::export(.pitch_get_quantile)]]
double pitch_get_quantile(XPtr<Pitch> pitch_ptr, double quantile, double from_time, double to_time, std::string unit) {
  if (!pitch_ptr) {
    stop("Invalid pitch pointer");
  }
  
  try {
    Pitch pitch = pitch_ptr.get();
    
    int unit_code = (unit == "Hertz") ? kPitch_unit::HERTZ : kPitch_unit::SEMITONES_100;
    
    double value = Pitch_getQuantile(pitch, from_time, to_time, quantile, unit_code);
    
    return (value == undefined) ? NA_REAL : value;
    
  } catch (MelderError) {
    Melder_clearError();
    return NA_REAL;
  }
}

// ============================================================================
// Pitch: Export Methods
// ============================================================================

// [[Rcpp::export(.pitch_as_data_frame)]]
DataFrame pitch_as_data_frame(XPtr<Pitch> pitch_ptr) {
  if (!pitch_ptr) {
    stop("Invalid pitch pointer");
  }
  
  Pitch pitch = pitch_ptr.get();
  
  integer n_frames = pitch->nx;
  
  NumericVector time(n_frames);
  NumericVector frequency(n_frames);
  NumericVector strength(n_frames);
  
  for (integer i = 1; i <= n_frames; i++) {
    time[i - 1] = Sampled_indexToX(pitch, i);
    
    double f = Pitch_getValueAtTime(pitch, time[i - 1], kPitch_unit::HERTZ, FALSE);
    frequency[i - 1] = (f == undefined) ? NA_REAL : f;
    
    double s = pitch->frames[i].intensity;
    strength[i - 1] = (s == undefined) ? NA_REAL : s;
  }
  
  return DataFrame::create(
    Named("time") = time,
    Named("frequency") = frequency,
    Named("strength") = strength,
    _["stringsAsFactors"] = false
  );
}
