# Amended Plan: Object-Oriented Praat R Interface

## Executive Summary

This document amends the original implementation plan to adopt an **object-oriented architecture** that mirrors Praat's native structure and aligns with proven approaches like the Python Parselmouth library. The key change is moving from a data-transfer model (S3 objects with copied data) to a **persistent C++ object model** (R6 classes with external pointers).

## Rationale for Change

### Current Limitations
1. **Data Transfer Overhead**: Current S3 approach copies data between R and C++ on every operation
2. **Diverges from Praat's OOP Design**: Praat is inherently object-oriented; functional wrappers obscure this
3. **Performance Issues**: Repeated data copying for chained operations (e.g., Sound → Pitch → Formant)
4. **Memory Inefficiency**: Duplicating large audio data in both R and C++ layers

### Benefits of Object-Oriented Approach
1. **Zero-Copy Operations**: Data remains in C++ memory; R holds lightweight pointers
2. **Natural API**: Methods on objects (`sound$extract_pitch()`) vs functions on data (`extract_pitch(sound)`)
3. **Better Performance**: Especially for operation chains and large audio files
4. **Alignment with Praat**: Mirrors Praat's object model and Parselmouth's proven design
5. **Future-Proof**: Easier to expose more of Praat's extensive object hierarchy

## Core Architectural Changes

### 1. Object System: S3 → R6

**Before (S3):**
```r
# Before (S3)
sound <- read_sound("audio.wav")  # Returns list with data
duration <- get_duration(sound)   # Functional call
pitch <- extract_pitch(sound)     # Data copied to C++, results copied back
```

**After (R6):**
```r
sound <- Sound$new("audio.wav")   # R6 object with XPtr to C++ Sound
duration <- sound$get_duration()  # Method call, no data copying
pitch <- sound$to_pitch()         # Returns new Pitch R6 object, minimal copying
```

### 2. Data Storage: R Vectors → External Pointers

**Before:**
- `praat_sound`: R list with `values` (numeric vector), `time`, `sampling_rate`
- All audio samples stored in R memory

**After:**
- `Sound`: R6 class with private `ptr` field (Rcpp::XPtr<Sound>)
- Audio samples remain in C++ Praat Sound object
- Only metadata/results returned to R when explicitly requested

### 3. Memory Management: Manual → RAII with Finalizers

**Before:**
- C++ objects created and destroyed per function call
- R objects managed by R's GC

**After:**
- C++ objects persistent across multiple method calls
- `XPtr` finalizers automatically clean up C++ objects when R6 object is garbage collected
- No memory leaks, no manual cleanup needed

## Naming Convention

**All method names follow Praat's command structure** with R `snake_case` convention:
- **Query methods**: `get_[property]` (e.g., `get_duration()`, `get_mean()`)
- **Transformation methods**: `to_[type]` (e.g., `to_pitch()`, `to_formant_burg()`)
- **Extraction methods**: `extract_[subset]` (e.g., `extract_part()`)
- **Modification methods**: `[action]` (e.g., `scale_intensity()`, `resample()`)

See `NAMING-CONVENTIONS.md` for complete mapping from Praat commands to R6 methods.

## Revised Object Hierarchy

### Core Praat Classes (Priority 1)

1. **Sound** - Audio waveform object
   - `Sound$new(path)` - Read from file
   - `Sound$from_values(values, sampling_rate)` - Create from data
   - `sound$get_duration()`, `sound$get_sampling_frequency()`
   - `sound$to_pitch()` - Returns Pitch object (was `extract_pitch`)
   - `sound$to_formant_burg()` - Returns Formant object (was `extract_formants`)
   - `sound$to_intensity()` - Returns Intensity object (was `extract_intensity`)
   - `sound$as_data_frame()` - Export data to R (explicit)

2. **Pitch** - Pitch contour object
   - Created via `sound$extract_pitch()` or `Pitch$new(path)`
   - `pitch$get_value_at_time(t)` - Query pitch at specific time
   - `pitch$get_mean()`, `pitch$get_median()`, `pitch$get_quantile(q)`
   - `pitch$as_data_frame()` - Export to R data.frame

3. **Formant** - Formant trajectory object
   - Created via `sound$extract_formants()`
   - `formant$get_value_at_time(t, formant_number)`
   - `formant$get_mean(formant_number)`
   - `formant$as_data_frame()`

4. **Intensity** - Intensity contour object
   - Created via `sound$extract_intensity()`
   - `intensity$get_value_at_time(t)`
   - `intensity$get_mean()`, `intensity$get_minimum()`, `intensity$get_maximum()`
   - `intensity$as_data_frame()`

### Supporting Classes (Priority 2)

5. **TextGrid** - Annotation tier system
   - `TextGrid$new(path)` or `textgrid <- sound$to_textgrid()`
   - `textgrid$get_tier_names()`
   - `textgrid$get_intervals(tier_name)`
   - `textgrid$as_data_frame()`

6. **Spectrogram** - Time-frequency representation
   - `spectrogram <- sound$to_spectrogram()`
   - `spectrogram$get_power_at(time, frequency)`
   - `spectrogram$as_matrix()`

## Implementation Strategy

### Phase 1: Foundation (Week 1-2)
- [ ] Add R6 package dependency to DESCRIPTION
- [ ] Implement base `PraatObject` R6 class with XPtr management
- [ ] Create C++ finalizer infrastructure for Praat objects
- [ ] Implement `Sound` R6 class with core methods
- [ ] Update build system for proper C++ object lifetime management

### Phase 2: Core Objects (Week 3-4)
- [ ] Implement `Pitch` R6 class
- [ ] Implement `Formant` R6 class
- [ ] Implement `Intensity` R6 class
- [ ] Create conversion methods (`$as_data_frame()`, etc.)
- [ ] Write comprehensive tests for object lifecycle

### Phase 3: Advanced Features (Week 5-6)
- [ ] Implement `TextGrid` R6 class
- [ ] Implement `Spectrogram` R6 class
- [ ] Add object serialization/deserialization
- [ ] Performance benchmarking vs S3 approach

### Phase 4: Polish & Documentation (Week 7-8)
- [ ] Comprehensive documentation with examples
- [ ] Migration guide from S3 (if any users exist)
- [ ] Performance optimization based on profiling
- [ ] Advanced vignettes showing OOP workflows

## Technical Specifications

### R6 Class Template

```r
#' @title Praat Sound Object
#' @description R6 class wrapping Praat's C++ Sound object
#' @export
Sound <- R6Class("Sound",
  inherit = PraatObject,  # Base class for all Praat objects
  
  public = list(
    #' @description Create a Sound object
    #' @param path Path to audio file (WAV, AIFF, etc.)
    #' @param from_pointer Internal use only
    initialize = function(path = NULL, from_pointer = NULL) {
      if (!is.null(from_pointer)) {
        private$ptr <- from_pointer
      } else if (!is.null(path)) {
        private$ptr <- .sound_read_from_file(path)
      } else {
        stop("Must provide either path or from_pointer")
      }
    },
    
    #' @description Get duration in seconds
    get_duration = function() {
      .sound_get_duration(private$ptr)
    },
    
    #' @description Extract pitch contour (transforms Sound to Pitch)
    #' @param time_step Time step for analysis (default: auto)
    #' @param pitch_floor Minimum pitch in Hz (default: 75)
    #' @param pitch_ceiling Maximum pitch in Hz (default: 600)
    #' @return Pitch R6 object
    to_pitch = function(time_step = 0.0, pitch_floor = 75, 
                        pitch_ceiling = 600) {
      pitch_ptr <- .sound_to_pitch(private$ptr, time_step, 
                                   pitch_floor, pitch_ceiling)
      Pitch$new(from_pointer = pitch_ptr)
    },
    
    #' @description Export to data frame
    #' @return data.frame with time and value columns
    as_data_frame = function() {
      .sound_as_data_frame(private$ptr)
    },
    
    #' @description Print method
    print = function() {
      cat("<Praat Sound>\n")
      cat(sprintf("  Duration: %.3f s\n", self$get_duration()))
      cat(sprintf("  Sampling frequency: %.0f Hz\n", 
                  self$get_sampling_frequency()))
      invisible(self)
    }
  ),
  
  private = list(
    ptr = NULL,
    
    # Finalizer called by R's GC
    finalize = function() {
      if (!is.null(private$ptr)) {
        # XPtr finalizer handles actual C++ deletion
        private$ptr <- NULL
      }
    }
  )
)
```

### C++ Wrapper Template

```cpp
#include <Rcpp.h>
#include "praat/fon/Sound.h"
#include "praat/fon/Pitch.h"

// Finalizer for Sound objects
void sound_finalizer(Sound* sound) {
  if (sound != nullptr) {
    forget(sound);  // Praat's memory management function
  }
}

// [[Rcpp::export(.sound_read_from_file)]]
Rcpp::XPtr<Sound> sound_read_from_file(std::string path) {
  try {
    autoSound sound = Sound_readFromSoundFile(
      Melder_peek8to32(path.c_str())
    );
    
    // Transfer ownership to XPtr with finalizer
    Sound* sound_ptr = sound.releaseToAmbiguousOwner();
    return Rcpp::XPtr<Sound>(sound_ptr, true, sound_finalizer);
    
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to read sound file: " + path);
  }
}

// [[Rcpp::export(.sound_get_duration)]]
double sound_get_duration(Rcpp::XPtr<Sound> sound_ptr) {
  if (!sound_ptr) {
    Rcpp::stop("Invalid sound pointer");
  }
  return sound_ptr->xmax - sound_ptr->xmin;
}

// [[Rcpp::export(.sound_to_pitch)]]
Rcpp::XPtr<Pitch> sound_to_pitch(Rcpp::XPtr<Sound> sound_ptr,
                                 double time_step,
                                 double pitch_floor,
                                 double pitch_ceiling) {
  if (!sound_ptr) {
    Rcpp::stop("Invalid sound pointer");
  }
  
  try {
    autoPitch pitch = Sound_to_Pitch_ac(
      sound_ptr.get(),
      time_step,
      pitch_floor,
      3.0,  // max candidates
      15,   // very accurate
      0.03, // silence threshold
      0.45, // voicing threshold
      0.01, // octave cost
      0.35, // octave jump cost
      0.14, // voiced/unvoiced cost
      pitch_ceiling
    );
    
    Pitch* pitch_ptr = pitch.releaseToAmbiguousOwner();
    return Rcpp::XPtr<Pitch>(pitch_ptr, true, pitch_finalizer);
    
  } catch (MelderError) {
    Melder_clearError();
    Rcpp::stop("Failed to extract pitch");
  }
}
```

## Migration from Current Implementation

### Files to Update

1. **`data-model.md`** - Complete rewrite for R6/XPtr model
2. **`contracts/r-function-signatures.md`** - Update all signatures to R6 methods
3. **`R/sound.R`** - Convert to R6 class definition
4. **`R/pitch.R`** - Convert to R6 class definition
5. **`src/praat_wrapper.cpp`** - Rewrite to use XPtr and finalizers
6. **`tests/testthat/test-*.R`** - Update all tests for R6 API
7. **`vignettes/*.Rmd`** - Update examples to use R6 syntax

### Backward Compatibility

Since this is an early-stage package, **no backward compatibility** is required. This is the right time to make this architectural shift before public release.

## Testing Strategy

### Unit Tests
```r
test_that("Sound object lifecycle", {
  # Creation
  sound <- Sound$new(test_wav_path)
  expect_s3_class(sound, "Sound")
  expect_s3_class(sound, "R6")
  
  # Methods work
  expect_gt(sound$get_duration(), 0)
  expect_gt(sound$get_sampling_frequency(), 0)
  
  # Object chaining
  pitch <- sound$extract_pitch()
  expect_s3_class(pitch, "Pitch")
  
  # Data export
  df <- sound$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_true("time" %in% names(df))
  expect_true("value" %in% names(df))
})

test_that("Memory management", {
  # Create and destroy many objects
  for (i in 1:100) {
    sound <- Sound$new(test_wav_path)
    pitch <- sound$extract_pitch()
    # Objects should be automatically cleaned up
  }
  # No memory leaks (verify with valgrind)
})
```

### Integration Tests
```r
test_that("Complete analysis pipeline", {
  # Realistic workflow
  sound <- Sound$new("speech_sample.wav")
  
  # Extract multiple features
  pitch <- sound$extract_pitch(pitch_floor = 75, pitch_ceiling = 300)
  formants <- sound$extract_formants()
  intensity <- sound$extract_intensity()
  
  # Query values
  pitch_at_0.5 <- pitch$get_value_at_time(0.5)
  f1_at_0.5 <- formants$get_value_at_time(0.5, formant_number = 1)
  
  # Export for further analysis in R
  pitch_df <- pitch$as_data_frame()
  
  # Verify results
  expect_true(!is.na(pitch_at_0.5))
  expect_true(!is.na(f1_at_0.5))
  expect_gt(nrow(pitch_df), 0)
})
```

## Performance Expectations

### Benchmarks vs S3 Approach

For a 10-second audio file with multiple operations:

| Operation | S3 (Data Copy) | R6 (Pointer) | Improvement |
|-----------|----------------|--------------|-------------|
| Read sound | 50 ms | 50 ms | 0% (same I/O) |
| Get duration | 0.1 ms | 0.01 ms | 10× (no data access) |
| Extract pitch | 200 ms | 200 ms | 0% (compute-bound) |
| Chain 5 ops | 1000 ms | 200 ms | 5× (no copying) |

**Key Insight**: Single operations see modest gains, but **operation chains** benefit enormously from avoiding data copying.

## Documentation Requirements

### User-Facing
1. **Vignette**: "Getting Started with speaker: An Object-Oriented Approach"
2. **Vignette**: "From Praat Scripts to R6: A Translation Guide"
3. **Vignette**: "Advanced Workflows: Chaining Praat Operations"
4. **Reference**: Full R6 class documentation with examples

### Developer-Facing
1. **`AMENDED-PLAN.md`** (this document)
2. **`data-model.md`** - Updated for R6/XPtr architecture
3. **`CONTRIBUTING.md`** - How to add new Praat object classes
4. **`MEMORY-MANAGEMENT.md`** - XPtr and finalizer best practices

## Risks and Mitigations

### Risk 1: R6 Learning Curve
- **Mitigation**: Comprehensive examples, vignettes showing standard workflows
- **Mitigation**: Provide convenience functions for common operations

### Risk 2: Memory Management Bugs
- **Mitigation**: Extensive testing with valgrind
- **Mitigation**: Conservative use of Praat's `auto*` smart pointers
- **Mitigation**: Clear finalizer implementation and testing

### Risk 3: Debugging Difficulty
- **Mitigation**: Better error messages from C++ layer
- **Mitigation**: Validation of XPtr before dereferencing
- **Mitigation**: Debug mode with extra checks

## Success Criteria

1. ✅ All core Praat objects (Sound, Pitch, Formant, Intensity) available as R6 classes
2. ✅ Zero memory leaks verified by valgrind
3. ✅ Performance improvements for chained operations (>3× faster)
4. ✅ API feels natural to R users familiar with R6
5. ✅ Complete test coverage (>90% for R code, >80% for C++ code)
6. ✅ Documentation with real-world examples
7. ✅ Benchmarks showing parity with Praat desktop application

## Timeline

- **Week 1-2**: R6 infrastructure and Sound class
- **Week 3-4**: Pitch, Formant, Intensity classes
- **Week 5-6**: Advanced classes, performance optimization
- **Week 7-8**: Documentation, vignettes, final testing
- **Week 9**: CRAN submission preparation

## Conclusion

This amended plan transforms the `speaker` package from a functional wrapper to a true object-oriented interface to Praat. By adopting R6 classes with external pointers, we:

1. **Match Praat's Design**: Objects behave like they do in Praat itself
2. **Improve Performance**: Eliminate unnecessary data copying
3. **Enable Scalability**: Easy to expose Praat's full object hierarchy
4. **Follow Best Practices**: Align with proven approach from Parselmouth

The refactoring effort is substantial but worthwhile, especially at this early stage. The resulting package will be more intuitive, more performant, and more maintainable.
