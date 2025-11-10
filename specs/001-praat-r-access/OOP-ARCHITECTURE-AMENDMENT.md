# Object-Oriented Architecture Amendment for Speaker Package

**Created**: 2025-11-10  
**Status**: Master Amendment - Supersedes Previous Procedural Plans  
**Paradigm**: Complete Object-Oriented Architecture Aligned with Praat

## Executive Summary

This amendment fundamentally restructures the speaker package implementation to **mirror Praat's object-oriented architecture** rather than providing isolated procedural functions. The goal is to enable direct transcoding of Praat scripts to R while maintaining native C++ performance without Python/Parselmouth dependencies.

## Core Problem Identified

### Previous Approach (Procedural)
```r
# Isolated function calls - doesn't match Praat's design
pitch_data <- praat_extract_pitch(audio_file, min_pitch = 75)
formant_data <- praat_extract_formant(audio_file, max_formant = 5500)
```

**Issues**:
- Ignores Praat's object hierarchy
- Forces data copying between R and C++ for each call
- No object persistence or method chaining
- Cannot represent Praat workflows accurately
- Missing critical objects (TextGrid, Manipulation, Tier objects)

### New Approach (Object-Oriented)
```r
# Mirrors Praat's object model
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant_hz = 5500)

# Method chaining like Praat
mean_f0 <- pitch$get_mean(unit = "hertz")
f1_mean <- formant$get_mean(formant_number = 1)

# TextGrid integration
tg <- TextGrid$new("annotation.TextGrid")
label <- tg$get_label_at_time(tier_name = "words", time = 0.5)

# Manipulation (critical for voice modification)
manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(factor = 1.2)
modified <- manip$get_resynthesis_overlap_add()
```

## Praat's Object Hierarchy

Praat's C++ architecture is based on a class hierarchy:

```
Thing (base class)
├── Daata
│   ├── Function
│   │   ├── Sampled
│   │   │   ├── Sound
│   │   │   ├── Pitch
│   │   │   ├── Formant
│   │   │   ├── Intensity
│   │   │   ├── Harmonicity
│   │   │   ├── Spectrogram
│   │   │   ├── Spectrum
│   │   │   └── LPC
│   │   └── AnyTier
│   │       ├── PitchTier
│   │       ├── IntensityTier
│   │       ├── DurationTier
│   │       └── FormantGrid
│   ├── TextGrid
│   ├── Manipulation
│   ├── Table
│   └── PointProcess
└── Collection
```

## Implementation Strategy

### 1. R6 Class Architecture

Each Praat object type becomes an R6 class that wraps an external pointer to the C++ Praat object:

```r
#' @export
Sound <- R6::R6Class("Sound",
  inherit = PraatObject,
  private = list(
    ptr = NULL  # External pointer to C++ Sound object
  ),
  public = list(
    initialize = function(filepath = NULL, ...) {
      if (!is.null(filepath)) {
        private$ptr <- cpp_sound_read(filepath)
      }
      private$register_finalizer()
    },
    
    # Query methods
    get_sampling_frequency = function() {
      cpp_sound_get_sampling_frequency(private$ptr)
    },
    
    get_duration = function() {
      cpp_sound_get_duration(private$ptr)
    },
    
    # Transformation methods
    to_pitch = function(time_step = 0.0, 
                       pitch_floor = 75.0,
                       pitch_ceiling = 600.0) {
      pitch_ptr <- cpp_sound_to_pitch(private$ptr, time_step, 
                                      pitch_floor, pitch_ceiling)
      Pitch$new_from_pointer(pitch_ptr)
    },
    
    to_formant_burg = function(time_step = 0.0,
                               max_number_of_formants = 5.0,
                               maximum_formant = 5500.0,
                               window_length = 0.025,
                               pre_emphasis_from = 50.0) {
      formant_ptr <- cpp_sound_to_formant_burg(
        private$ptr, time_step, max_number_of_formants,
        maximum_formant, window_length, pre_emphasis_from
      )
      Formant$new_from_pointer(formant_ptr)
    },
    
    to_intensity = function(minimum_pitch = 100.0,
                           time_step = 0.0,
                           subtract_mean = TRUE) {
      intensity_ptr <- cpp_sound_to_intensity(
        private$ptr, minimum_pitch, time_step, subtract_mean
      )
      Intensity$new_from_pointer(intensity_ptr)
    },
    
    to_manipulation = function(time_step = 0.01,
                               minimum_pitch = 75.0,
                               maximum_pitch = 600.0) {
      manip_ptr <- cpp_sound_to_manipulation(
        private$ptr, time_step, minimum_pitch, maximum_pitch
      )
      Manipulation$new_from_pointer(manip_ptr)
    },
    
    # Modification methods
    filter_pass_hann_band = function(from_frequency, to_frequency, smoothing) {
      cpp_sound_filter_pass_hann_band(private$ptr, from_frequency, 
                                      to_frequency, smoothing)
      invisible(self)
    },
    
    # Export methods
    save = function(filepath, format = "WAV") {
      cpp_sound_save(private$ptr, filepath, format)
      invisible(self)
    }
  )
)
```

### 2. Naming Convention for Praat-Compatible Transcoding

To enable direct transcoding of Praat scripts, we use consistent naming:

**Praat Script**:
```praat
sound = Read from file: "audio.wav"
pitch = To Pitch: 0.0, 75, 600
meanF0 = Get mean: 0, 0, "Hertz"
```

**R Translation**:
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
```

**Naming Rules**:
- Constructor: `$new()` for file reading or creation
- Transformation: `to_*()` → creates new object (e.g., `to_pitch()`, `to_formant_burg()`)
- Query: `get_*()` → returns value (e.g., `get_mean()`, `get_value_at_time()`)
- Modification: `set_*()` or verb → modifies in place (e.g., `filter_*()`, `add_*()`)
- Export: `save()`, `write()`, `to_dataframe()`

### 3. Complete Object Implementation Roadmap

## Phase 1: Core Analysis Objects (CURRENT - Weeks 1-3)

### 1.1 Sound (Priority: CRITICAL) ✅ MOSTLY COMPLETE
**Status**: R6 implementation exists, needs completion of missing methods

**Missing Methods to Add**:
- `filter_pass_hann_band()`, `filter_stop_hann_band()`
- `resample()`, `convert_to_mono()`, `convert_to_stereo()`
- `concatenate()`, `mix()`
- `to_lpc_autocorrelation()`, `to_ltas()`, `to_cochleagram()`
- `to_mel_spectrogram()`, `to_mfcc()`

### 1.2 Pitch (Priority: CRITICAL) ✅ MOSTLY COMPLETE
**Status**: R6 implementation exists, needs manipulation methods

**Missing Methods to Add**:
- `interpolate()`, `smooth()`
- `to_pitch_tier()` (creates editable tier)
- `to_sound()` (resynthesize from pitch)

### 1.3 Formant (Priority: CRITICAL) ⚠️ **NEEDS R6 MIGRATION**
**Status**: Currently S3, must convert to R6

**Required R6 Class**:
```r
Formant <- R6Class("Formant",
  inherit = PraatObject,
  public = list(
    get_value_at_time = function(formant_number, time, unit = "hertz"),
    get_bandwidth_at_time = function(formant_number, time),
    get_mean = function(formant_number, from_time = 0, to_time = 0),
    get_standard_deviation = function(formant_number, from_time = 0, to_time = 0),
    to_formant_grid = function(),  # Create editable tier
    to_dataframe = function()
  )
)
```

### 1.4 Intensity (Priority: HIGH) ✅ COMPLETE
**Status**: R6 implementation complete

### 1.5 Harmonicity (Priority: HIGH) ✅ COMPLETE
**Status**: R6 implementation complete with full HNR analysis

### 1.6 PointProcess (Priority: HIGH) ✅ COMPLETE
**Status**: R6 implementation complete with jitter/shimmer

### 1.7 TextGrid (Priority: CRITICAL) ✅ MOSTLY COMPLETE
**Status**: R6 implementation exists, comprehensive tier management

**Missing Methods to Add** (if any):
- `extract_part()` (extract time range)
- `scale_times()` (for time-aligned manipulation)

## Phase 2: Manipulation Objects (Weeks 3-5)

### 2.1 Manipulation (Priority: CRITICAL) ❌ NOT IMPLEMENTED
**Purpose**: PSOLA-based pitch and duration modification

**Required R6 Class**:
```r
Manipulation <- R6Class("Manipulation",
  inherit = PraatObject,
  public = list(
    new = function(sound, time_step = 0.01, minimum_pitch = 75, maximum_pitch = 600),
    
    extract_pitch_tier = function(),      # Get editable pitch
    extract_duration_tier = function(),   # Get editable duration  
    extract_original_sound = function(),
    extract_pulses = function(),
    
    replace_pitch_tier = function(pitch_tier),
    replace_duration_tier = function(duration_tier),
    
    get_resynthesis_overlap_add = function(),  # Main resynthesis method
    get_resynthesis_lpc = function(),
    
    play = function()  # If audio playback is implemented
  )
)
```

**C++ Backend Required**:
- Wrapper for `Sound_to_Manipulation()`
- Wrapper for `Manipulation_replacePitchTier()`
- Wrapper for `Manipulation_getResynthesis_overlapAdd()`

### 2.2 PitchTier (Priority: CRITICAL) ❌ NOT IMPLEMENTED
**Purpose**: Editable pitch contour for manipulation

```r
PitchTier <- R6Class("PitchTier",
  inherit = PraatObject,
  public = list(
    new = function(t_min = 0, t_max = 1),
    new_from_pitch = function(pitch),  # Extract from Pitch object
    
    add_point = function(time, value),
    remove_point = function(index),
    remove_points_between = function(from_time, to_time),
    
    get_value_at_time = function(time),
    get_number_of_points = function(),
    
    multiply_frequencies = function(from_time, to_time, factor),
    shift_frequencies = function(from_time, to_time, shift),
    
    to_pitch = function(),  # Convert to Pitch object
    save = function(filepath)
  )
)
```

### 2.3 DurationTier (Priority: MEDIUM) ❌ NOT IMPLEMENTED
**Purpose**: Control duration modification in Manipulation

```r
DurationTier <- R6Class("DurationTier",
  inherit = PraatObject,
  public = list(
    new = function(t_min = 0, t_max = 1),
    add_point = function(time, value),
    get_value_at_time = function(time),
    multiply_durations = function(from_time, to_time, factor)
  )
)
```

### 2.4 IntensityTier (Priority: MEDIUM) ❌ NOT IMPLEMENTED
**Purpose**: Editable intensity contour

```r
IntensityTier <- R6Class("IntensityTier",
  inherit = PraatObject,
  public = list(
    new = function(t_min = 0, t_max = 1),
    new_from_intensity = function(intensity),
    add_point = function(time, value),
    get_value_at_time = function(time),
    multiply_intensities = function(from_time, to_time, factor)
  )
)
```

### 2.5 FormantGrid (Priority: MEDIUM) ❌ NOT IMPLEMENTED
**Purpose**: Editable formant trajectories

```r
FormantGrid <- R6Class("FormantGrid",
  inherit = PraatObject,
  public = list(
    new = function(t_min, t_max, num_formants),
    add_formant_point = function(formant_number, time, value),
    add_bandwidth_point = function(formant_number, time, value),
    get_formant_at_time = function(formant_number, time),
    to_formant = function()
  )
)
```

## Phase 3: Spectral Analysis Objects (Weeks 5-7)

### 3.1 Spectrum (Priority: HIGH) ❌ NOT IMPLEMENTED
**Purpose**: Frequency domain representation (FFT output)

```r
Spectrum <- R6Class("Spectrum",
  inherit = PraatObject,
  public = list(
    get_frequency_from_bin = function(bin_number),
    get_real_value_in_bin = function(bin_number),
    get_imaginary_value_in_bin = function(bin_number),
    get_power_at_frequency = function(frequency),
    get_band_density = function(from_freq, to_freq),
    to_ltas = function(),
    to_spectrogram = function()
  )
)
```

### 3.2 Spectrogram (Priority: HIGH) ❌ NOT IMPLEMENTED
**Purpose**: Time-frequency representation

```r
Spectrogram <- R6Class("Spectrogram",
  inherit = PraatObject,
  public = list(
    get_power_at = function(time, frequency),
    to_spectrum_slice = function(time),
    to_matrix = function(),
    paint = function()  # For visualization if graphics implemented
  )
)
```

### 3.3 LPC (Priority: MEDIUM) ❌ NOT IMPLEMENTED
**Purpose**: Linear Predictive Coding analysis

```r
LPC <- R6Class("LPC",
  inherit = PraatObject,
  public = list(
    to_formant = function(),
    to_spectrum_slice = function(time),
    to_polynomial = function(time)
  )
)
```

### 3.4 LTAS (Priority: MEDIUM) ❌ NOT IMPLEMENTED
**Purpose**: Long-term average spectrum

```r
Ltas <- R6Class("Ltas",
  inherit = PraatObject,
  public = list(
    get_frequency_of_maximum = function(from_freq, to_freq),
    get_value_at_frequency = function(frequency),
    get_mean = function(from_freq, to_freq),
    get_slope = function(from_freq, to_freq)
  )
)
```

### 3.5 MFCC (Priority: LOW) ❌ NOT IMPLEMENTED
**Purpose**: Mel-frequency cepstral coefficients for speech recognition

```r
MFCC <- R6Class("MFCC",
  inherit = PraatObject,
  public = list(
    get_coefficient = function(time, coefficient_number),
    to_matrix = function(),
    to_table = function()
  )
)
```

## Phase 4: Utility Objects (Weeks 7-8)

### 4.1 Table (Priority: MEDIUM) ❌ NOT IMPLEMENTED
**Purpose**: Praat's native table format (alternative to data.frame)

```r
Table <- R6Class("Table",
  inherit = PraatObject,
  public = list(
    get_number_of_rows = function(),
    get_number_of_columns = function(),
    get_column_label = function(column_number),
    get_value = function(row_number, column_label),
    set_value = function(row_number, column_label, value),
    to_dataframe = function(),
    save = function(filepath)
  )
)
```

### 4.2 Matrix (Priority: LOW) ❌ NOT IMPLEMENTED
**Purpose**: 2D numerical data container

```r
Matrix <- R6Class("Matrix",
  inherit = PraatObject,
  public = list(
    get_value_at_xy = function(x, y),
    to_r_matrix = function()
  )
)
```

## Phase 5: Integration with AV Package (Week 8)

### 5.1 AV Package Integration
**Purpose**: Use humlab-speech/av fork for robust audio I/O

**Required Changes**:
```r
# In Sound class
Sound <- R6Class("Sound",
  public = list(
    new = function(filepath = NULL, start_time = NULL, end_time = NULL) {
      if (!is.null(filepath)) {
        # Use av package for reading
        audio_info <- av::av_media_info(filepath)
        
        if (!is.null(start_time) || !is.null(end_time)) {
          # Extract time range using av
          temp_file <- tempfile(fileext = ".wav")
          av::av_audio_convert(
            filepath, temp_file,
            start_time = start_time %||% 0,
            total_time = (end_time %||% audio_info$duration) - (start_time %||% 0)
          )
          private$ptr <- cpp_sound_read(temp_file)
          unlink(temp_file)
        } else {
          private$ptr <- cpp_sound_read(filepath)
        }
      }
    },
    
    save = function(filepath, format = "wav", sample_rate = NULL) {
      # Save to temp file via C++
      temp_file <- tempfile(fileext = ".wav")
      cpp_sound_save(private$ptr, temp_file)
      
      # Use av for format conversion if needed
      if (tolower(tools::file_ext(filepath)) != "wav" || !is.null(sample_rate)) {
        av::av_audio_convert(
          temp_file, filepath,
          sample_rate = sample_rate
        )
        unlink(temp_file)
      } else {
        file.copy(temp_file, filepath, overwrite = TRUE)
        unlink(temp_file)
      }
      invisible(self)
    }
  )
)
```

## C++ Implementation Strategy

### External Pointer Management

All Praat objects are managed through external pointers with proper memory management:

```cpp
// In src/sound-class.cpp
// [[Rcpp::export]]
SEXP cpp_sound_read(std::string filepath) {
  try {
    autoSound sound = Sound_readFromSoundFile(Melder_peek8to32(filepath.c_str()));
    Sound* sound_copy = Data_copy(sound.get()).releaseToAmbiguousOwner();
    
    Rcpp::XPtr<Sound> ptr(sound_copy, true);  // true = auto-delete
    ptr.attr("class") = "praat_sound_ptr";
    return ptr;
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to read sound file");
  }
}

// [[Rcpp::export]]
SEXP cpp_sound_to_pitch(SEXP sound_ptr, double time_step, 
                        double pitch_floor, double pitch_ceiling) {
  try {
    Rcpp::XPtr<Sound> sound(sound_ptr);
    autoPitch pitch = Sound_to_Pitch(*sound, time_step, pitch_floor, pitch_ceiling);
    
    Pitch* pitch_copy = Data_copy(pitch.get()).releaseToAmbiguousOwner();
    Rcpp::XPtr<Pitch> ptr(pitch_copy, true);
    ptr.attr("class") = "praat_pitch_ptr";
    return ptr;
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to create Pitch object");
  }
}
```

### Memory Management Pattern

```cpp
// Template for all Praat object wrappers
template <typename T>
class PraatObjectWrapper {
  T* obj_;
  
public:
  PraatObjectWrapper(T* obj) : obj_(obj) {}
  
  ~PraatObjectWrapper() {
    if (obj_) {
      forget(obj_);  // Praat's deallocation
    }
  }
  
  T* get() { return obj_; }
  T* release() { 
    T* temp = obj_;
    obj_ = nullptr;
    return temp;
  }
};
```

## Documentation Strategy

### Praat Script Transcoding Guide

Create vignette showing Praat → R translations:

```r
# vignettes/praat-to-r-guide.Rmd

## Basic Analysis Workflow

**Praat**:
```praat
sound = Read from file: "recording.wav"
pitch = To Pitch: 0.0, 75, 600
mean_pitch = Get mean: 0, 0, "Hertz"
```

**R (speaker package)**:
```r
sound <- Sound$new("recording.wav")
pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)
mean_pitch <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
```

## Pitch Manipulation

**Praat**:
```praat
sound = Read from file: "recording.wav"
manipulation = To Manipulation: 0.01, 75, 600
pitch_tier = Extract pitch tier
Multiply frequencies: 0, 0, 1.2
plus Manipulation
Replace pitch tier
select Manipulation
new_sound = Get resynthesis (overlap-add)
```

**R (speaker package)**:
```r
sound <- Sound$new("recording.wav")
manipulation <- sound$to_manipulation(time_step = 0.01, 
                                     minimum_pitch = 75, 
                                     maximum_pitch = 600)
pitch_tier <- manipulation$extract_pitch_tier()
pitch_tier$multiply_frequencies(from_time = 0, to_time = 0, factor = 1.2)
manipulation$replace_pitch_tier(pitch_tier)
new_sound <- manipulation$get_resynthesis_overlap_add()
```
```

## Testing Strategy

### Object-Oriented Tests

```r
# tests/testthat/test-sound-object.R
test_that("Sound object creation and methods work", {
  sound <- Sound$new(test_wav_file())
  
  expect_s3_class(sound, "Sound")
  expect_s3_class(sound, "PraatObject")
  
  expect_type(sound$get_duration(), "double")
  expect_type(sound$get_sampling_frequency(), "double")
  
  # Test transformation
  pitch <- sound$to_pitch()
  expect_s3_class(pitch, "Pitch")
  
  mean_f0 <- pitch$get_mean()
  expect_type(mean_f0, "double")
  expect_true(mean_f0 > 0)
})

test_that("Sound to Formant workflow works", {
  sound <- Sound$new(test_wav_file())
  formant <- sound$to_formant_burg(maximum_formant = 5500)
  
  expect_s3_class(formant, "Formant")
  
  f1 <- formant$get_value_at_time(1, 0.5)
  expect_type(f1, "double")
  expect_true(f1 > 0 && f1 < 2000)  # Typical F1 range
})

test_that("Manipulation workflow works", {
  sound <- Sound$new(test_wav_file())
  manip <- sound$to_manipulation()
  
  expect_s3_class(manip, "Manipulation")
  
  pitch_tier <- manip$extract_pitch_tier()
  expect_s3_class(pitch_tier, "PitchTier")
  
  pitch_tier$multiply_frequencies(from_time = 0, to_time = 0, factor = 1.5)
  manip$replace_pitch_tier(pitch_tier)
  
  resynthesized <- manip$get_resynthesis_overlap_add()
  expect_s3_class(resynthesized, "Sound")
})
```

## Implementation Timeline

### Week 1-2: Foundation Completion
- [x] Sound R6 class (complete missing methods)
- [x] Pitch R6 class (add manipulation methods)
- [ ] **Formant R6 migration** (critical priority)
- [ ] Update C++ bindings for missing methods

### Week 3-4: Manipulation System
- [ ] Manipulation R6 class
- [ ] PitchTier R6 class
- [ ] DurationTier R6 class
- [ ] IntensityTier R6 class
- [ ] FormantGrid R6 class
- [ ] C++ wrappers for Manipulation functions

### Week 5-6: Spectral Analysis
- [ ] Spectrum R6 class
- [ ] Spectrogram R6 class
- [ ] LPC R6 class
- [ ] LTAS R6 class
- [ ] C++ wrappers for spectral functions

### Week 7: Utilities & Integration
- [ ] Table R6 class
- [ ] Matrix R6 class
- [ ] AV package integration for I/O
- [ ] MFCC R6 class (if time permits)

### Week 8: Documentation & Testing
- [ ] Comprehensive test coverage
- [ ] Praat-to-R transcoding guide
- [ ] API reference documentation
- [ ] Parselmouth migration examples
- [ ] Performance benchmarks

## Success Criteria

1. ✅ **OOP Architecture**: All major Praat objects have R6 equivalents
2. ✅ **Direct Transcoding**: Praat scripts can be mechanically translated to R
3. ✅ **Method Completeness**: Core workflows (analysis, manipulation, export) fully supported
4. ✅ **No Python Dependency**: All functionality native R + C++
5. ✅ **Performance**: Comparable to Praat native performance
6. ✅ **Documentation**: Clear migration guide from Praat and Parselmouth

## Migration from Parselmouth

For users coming from Parselmouth (Python), the API should feel familiar:

**Parselmouth (Python)**:
```python
import parselmouth

sound = parselmouth.Sound("audio.wav")
pitch = sound.to_pitch()
mean_f0 = pitch.get_mean()

manipulation = sound.to_manipulation()
pitch_tier = manipulation.extract_pitch_tier()
pitch_tier.multiply_frequencies(0, 0, 1.2)
manipulation.replace_pitch_tier(pitch_tier)
new_sound = manipulation.get_resynthesis_overlap_add()
```

**Speaker (R)**:
```r
library(speaker)

sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch()
mean_f0 <- pitch$get_mean()

manipulation <- sound$to_manipulation()
pitch_tier <- manipulation$extract_pitch_tier()
pitch_tier$multiply_frequencies(0, 0, 1.2)
manipulation$replace_pitch_tier(pitch_tier)
new_sound <- manipulation$get_resynthesis_overlap_add()
```

## Appendix: Complete Method Inventory

See separate document: `COMPLETE-METHOD-INVENTORY.md`

---

**This amendment supersedes all previous procedural implementation plans and establishes the object-oriented paradigm as the foundation for the speaker package.**
