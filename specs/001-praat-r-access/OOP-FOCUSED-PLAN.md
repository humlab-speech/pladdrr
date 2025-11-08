# Object-Oriented Praat R Package - Complete Implementation Plan

**Created**: 2025-11-08  
**Status**: Master Plan  
**Paradigm Shift**: From procedure-based functions → to object-based methods

## Executive Summary

This plan refocuses the speaker package to fully mirror Praat's object-oriented C++ architecture, exposing Praat's complete object hierarchy with all their methods in R. This approach aligns with:

1. **Praat's native design**: C++ objects with inheritance (Thing hierarchy)
2. **Parselmouth's proven success**: Python bindings that expose objects, not procedures
3. **R's modern capabilities**: R6 classes for true OOP with external pointers

## Problem with Original Approach

The original spec focused on **implementing specific procedures**:
- `praat_extract_pitch(sound)` - functional style
- `praat_extract_formant(sound)` - isolated operations
- No object persistence, chaining, or state

**Issues**:
- Doesn't reflect Praat's OOP design
- Forces data copying between operations
- Can't chain methods naturally
- Missing critical object types (TextGrid, Manipulation, etc.)
- Ignores Praat's rich method ecosystem (200+ methods)

## New Object-Oriented Approach

### Core Principle: Expose Objects, Not Procedures

```r
# OLD (procedure-based):
pitch_data <- praat_extract_pitch(audio_file, min_pitch = 75, max_pitch = 600)
formant_data <- praat_extract_formant(audio_file, max_formant = 5500)

# NEW (object-based - mirrors Praat):
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant_hz = 5500, num_formants = 5)

# Method chaining and object interaction:
f0_mean <- pitch$get_mean(unit = "hertz")
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5)

# TextGrid annotation (MISSING in original plan):
tg <- TextGrid$new("annotation.TextGrid")
word_tier <- tg$get_tier("words")
label <- tg$get_label_at_time("words", 0.5)

# Manipulation for pitch modification (MISSING in original plan):
manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(factor = 1.2)  # Raise pitch 20%
manip$replace_pitch_tier(pitch_tier)
modified <- manip$get_resynthesis_overlap_add()
modified$save("higher_pitch.wav")
```

## Complete Praat Object Hierarchy

Based on analysis of Praat source code (`src/praat.github.io/fon/`):

### Foundation Classes

```
Thing (base class in sys/Thing.h)
├── Function (fon/Function.h)
│   ├── Sampled
│   │   ├── Sound (fon/Sound.h) ⭐
│   │   ├── Pitch (fon/Pitch.h) ⭐
│   │   ├── Intensity (fon/Intensity.h) ⭐
│   │   ├── Formant (fon/Formant.h) ⭐
│   │   ├── Harmonicity (fon/Harmonicity.h) ⭐
│   │   ├── Spectrum (fon/Spectrum.h) ⭐
│   │   ├── Spectrogram (fon/Spectrogram.h) ⭐
│   │   ├── Ltas (fon/Ltas.h)
│   │   ├── Excitation (fon/Excitation.h)
│   │   └── Cochleagram (fon/Cochleagram.h)
│   ├── PointProcess (fon/PointProcess_def.h) ⭐
│   └── TextGrid (fon/TextGrid_def.h) ⭐ CRITICAL
│       ├── IntervalTier
│       └── TextTier (PointTier)
├── Manipulation (fon/Manipulation_def.h) ⭐
│   ├── Sound
│   ├── PointProcess
│   ├── PitchTier
│   └── DurationTier
└── Tier objects
    ├── PitchTier (fon/PitchTier.h)
    ├── FormantTier (fon/FormantTier.h)
    ├── FormantGrid (fon/FormantGrid.h)
    ├── IntensityTier (fon/IntensityTier.h)
    ├── DurationTier (fon/DurationTier.h)
    └── AmplitudeTier (fon/AmplitudeTier.h)
```

⭐ = Priority objects to implement

## Complete Implementation Specification

### Phase 1: Foundation (Weeks 1-2)

#### Infrastructure Setup

**Goal**: Establish R6-based architecture with proper Praat integration

**Deliverables**:

1. **Base PraatObject R6 Class** (`R/praat-object-base.R`)
   ```r
   PraatObject <- R6Class("PraatObject",
     public = list(
       initialize = function(.xptr = NULL) {
         if (!is.null(.xptr)) {
           private$ptr <- .xptr
         }
       },
       
       is_valid = function() {
         !is.null(private$ptr)
       },
       
       get_class_name = function() {
         .praat_thing_get_class_name(private$ptr)
       },
       
       get_name = function() {
         .praat_thing_get_name(private$ptr)
       },
       
       set_name = function(name) {
         .praat_thing_set_name(private$ptr, name)
         invisible(self)
       }
     ),
     
     private = list(
       ptr = NULL
     )
   )
   ```

2. **C++ Infrastructure** (`src/praat_infrastructure.cpp`)
   ```cpp
   // Base Thing methods
   // [[Rcpp::export(.praat_thing_get_class_name)]]
   std::string praat_thing_get_class_name(SEXP xptr);
   
   // [[Rcpp::export(.praat_thing_get_name)]]
   std::string praat_thing_get_name(SEXP xptr);
   
   // [[Rcpp::export(.praat_thing_set_name)]]
   void praat_thing_set_name(SEXP xptr, std::string name);
   
   // Memory management
   template<typename T>
   void praat_finalizer(T* obj) {
       if (obj != nullptr) {
           forget(obj);
       }
   }
   
   template<typename T>
   Rcpp::XPtr<T> make_xptr(T* ptr) {
       return Rcpp::XPtr<T>(ptr, true, praat_finalizer<T>);
   }
   ```

3. **Error Handling Bridge** (`src/praat_error_bridge.cpp`)
   ```cpp
   // Wrap Praat operations with error handling
   template<typename Func>
   auto praat_try(Func&& func) -> decltype(func()) {
       try {
           return func();
       } catch (MelderError) {
           const char* error = Melder_getError();
           Melder_clearError();
           Rcpp::stop("Praat error: %s", error);
       }
   }
   ```

**Testing**:
- Memory leak tests with valgrind
- XPtr lifecycle tests
- Error propagation tests

---

### Phase 2: Sound Object (Week 2-3)

**Goal**: Complete Sound implementation as the template for all other objects

**R6 Class** (`R/sound-r6.R`):

```r
Sound <- R6Class("Sound",
  inherit = PraatObject,
  
  public = list(
    # ---- CREATION ----
    initialize = function(path = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        private$ptr <- .xptr
      } else if (!is.null(path)) {
        private$ptr <- .sound_read_from_file(path)
      } else {
        stop("Provide either path or .xptr")
      }
    },
    
    # ---- QUERY METHODS (get_*) ----
    get_duration = function() {
      .sound_get_duration(private$ptr)
    },
    
    get_sampling_frequency = function() {
      .sound_get_sampling_frequency(private$ptr)
    },
    
    get_number_of_samples = function() {
      .sound_get_number_of_samples(private$ptr)
    },
    
    get_number_of_channels = function() {
      .sound_get_number_of_channels(private$ptr)
    },
    
    get_value_at_time = function(time, channel = 1) {
      .sound_get_value_at_time(private$ptr, time, channel)
    },
    
    get_energy = function(from_time = 0, to_time = 0) {
      .sound_get_energy(private$ptr, from_time, to_time)
    },
    
    get_power = function(from_time = 0, to_time = 0) {
      .sound_get_power(private$ptr, from_time, to_time)
    },
    
    get_rms = function(from_time = 0, to_time = 0) {
      .sound_get_rms(private$ptr, from_time, to_time)
    },
    
    get_intensity_db = function() {
      .sound_get_intensity_db(private$ptr)
    },
    
    # ---- TRANSFORMATION METHODS (to_*) ----
    to_pitch = function(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600) {
      pitch_ptr <- .sound_to_pitch(private$ptr, time_step, pitch_floor, pitch_ceiling)
      Pitch$new(.xptr = pitch_ptr)
    },
    
    to_pitch_ac = function(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600,
                           very_accurate = FALSE, silence_threshold = 0.03,
                           voicing_threshold = 0.45, octave_cost = 0.01,
                           octave_jump_cost = 0.35, voiced_unvoiced_cost = 0.14) {
      pitch_ptr <- .sound_to_pitch_ac(private$ptr, time_step, pitch_floor, pitch_ceiling,
                                      very_accurate, silence_threshold, voicing_threshold,
                                      octave_cost, octave_jump_cost, voiced_unvoiced_cost)
      Pitch$new(.xptr = pitch_ptr)
    },
    
    to_formant_burg = function(time_step = 0.0, max_num_formants = 5.0, 
                               max_formant_hz = 5500.0, window_length = 0.025,
                               pre_emphasis_from = 50.0) {
      formant_ptr <- .sound_to_formant_burg(private$ptr, time_step, max_num_formants,
                                            max_formant_hz, window_length, pre_emphasis_from)
      Formant$new(.xptr = formant_ptr)
    },
    
    to_intensity = function(min_pitch = 100.0, time_step = 0.0, subtract_mean = TRUE) {
      intensity_ptr <- .sound_to_intensity(private$ptr, min_pitch, time_step, subtract_mean)
      Intensity$new(.xptr = intensity_ptr)
    },
    
    to_harmonicity_cc = function(time_step = 0.01, min_pitch = 75.0, 
                                 silence_threshold = 0.1, periods_per_window = 1.0) {
      harmonicity_ptr <- .sound_to_harmonicity_cc(private$ptr, time_step, min_pitch,
                                                   silence_threshold, periods_per_window)
      Harmonicity$new(.xptr = harmonicity_ptr)
    },
    
    to_spectrogram = function(window_length = 0.005, max_frequency = 5000,
                             time_step = 0.002, frequency_step = 20,
                             window_shape = "Gaussian") {
      spectrogram_ptr <- .sound_to_spectrogram(private$ptr, window_length, max_frequency,
                                               time_step, frequency_step, window_shape)
      Spectrogram$new(.xptr = spectrogram_ptr)
    },
    
    to_spectrum = function(fast = TRUE) {
      spectrum_ptr <- .sound_to_spectrum(private$ptr, fast)
      Spectrum$new(.xptr = spectrum_ptr)
    },
    
    to_manipulation = function(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600) {
      manipulation_ptr <- .sound_to_manipulation(private$ptr, time_step, pitch_floor, pitch_ceiling)
      Manipulation$new(.xptr = manipulation_ptr)
    },
    
    to_point_process_periodic_cc = function(pitch_floor = 75, pitch_ceiling = 600) {
      pp_ptr <- .sound_to_point_process_periodic_cc(private$ptr, pitch_floor, pitch_ceiling)
      PointProcess$new(.xptr = pp_ptr)
    },
    
    to_textgrid = function(tier_name = "segments") {
      tg_ptr <- .sound_to_textgrid(private$ptr, tier_name)
      TextGrid$new(.xptr = tg_ptr)
    },
    
    # ---- MODIFICATION METHODS ----
    scale_intensity = function(new_intensity_db) {
      .sound_scale_intensity(private$ptr, new_intensity_db)
      invisible(self)
    },
    
    scale_peak = function(new_peak = 0.99) {
      .sound_scale_peak(private$ptr, new_peak)
      invisible(self)
    },
    
    pre_emphasize = function(from_frequency = 50.0) {
      .sound_pre_emphasize(private$ptr, from_frequency)
      invisible(self)
    },
    
    de_emphasize = function(from_frequency = 50.0) {
      .sound_de_emphasize(private$ptr, from_frequency)
      invisible(self)
    },
    
    # ---- EXTRACTION METHODS ----
    extract_channel = function(channel = 1) {
      sound_ptr <- .sound_extract_channel(private$ptr, channel)
      Sound$new(.xptr = sound_ptr)
    },
    
    extract_part = function(from_time, to_time, window_shape = "rectangular", 
                           relative_width = 1.0, preserve_times = FALSE) {
      sound_ptr <- .sound_extract_part(private$ptr, from_time, to_time, 
                                       window_shape, relative_width, preserve_times)
      Sound$new(.xptr = sound_ptr)
    },
    
    # ---- EXPORT METHODS (as_*) ----
    as_matrix = function() {
      .sound_as_matrix(private$ptr)
    },
    
    as_data_frame = function() {
      mat <- self$as_matrix()
      time <- seq(from = 0, by = 1/self$get_sampling_frequency(), length.out = ncol(mat))
      
      if (nrow(mat) == 1) {
        data.frame(time = time, amplitude = as.vector(mat[1,]))
      } else {
        df <- data.frame(time = time)
        for (ch in 1:nrow(mat)) {
          df[[paste0("channel_", ch)]] <- mat[ch,]
        }
        df
      }
    },
    
    # ---- I/O ----
    save = function(path, format = "WAV") {
      .sound_save(private$ptr, path, format)
      invisible(self)
    },
    
    # ---- PRINT ----
    print = function() {
      cat("<Praat Sound>\n")
      cat(sprintf("  Duration: %.3f s\n", self$get_duration()))
      cat(sprintf("  Sampling frequency: %.0f Hz\n", self$get_sampling_frequency()))
      cat(sprintf("  Number of samples: %d\n", self$get_number_of_samples()))
      cat(sprintf("  Number of channels: %d\n", self$get_number_of_channels()))
      invisible(self)
    }
  ),
  
  # ---- STATIC FACTORY METHODS ----
  active = list(
    duration = function() self$get_duration(),
    sampling_frequency = function() self$get_sampling_frequency(),
    n_samples = function() self$get_number_of_samples(),
    n_channels = function() self$get_number_of_channels()
  )
)

# Static factory methods
Sound$from_values <- function(values, sampling_rate = 44100, start_time = 0) {
  ptr <- .sound_create_from_values(values, sampling_rate, start_time)
  Sound$new(.xptr = ptr)
}

Sound$create_tone = function(duration = 1.0, sampling_rate = 44100, frequency = 440, amplitude = 0.2) {
  ptr <- .sound_create_tone(duration, sampling_rate, frequency, amplitude)
  Sound$new(.xptr = ptr)
}

Sound$create_silence = function(duration = 1.0, sampling_rate = 44100) {
  ptr <- .sound_create_silence(duration, sampling_rate)
  Sound$new(.xptr = ptr)
}
```

**C++ Wrappers** (`src/sound_wrappers.cpp`): ~40 functions covering all methods above

**Testing**:
- File I/O tests
- All query methods
- All transformations
- Memory management
- Edge cases (mono/stereo, different sample rates)

---

### Phase 3: TextGrid Object (Weeks 4-5) ⭐ CRITICAL

**Why Critical**: TextGrid is essential for:
- Linguistic annotation
- Segmentation and alignment
- Integration with forced alignment tools
- Most phonetic research workflows

**R6 Class** (`R/textgrid-r6.R`):

```r
TextGrid <- R6Class("TextGrid",
  inherit = PraatObject,
  
  public = list(
    # ---- CREATION ----
    initialize = function(path = NULL, xmin = NULL, xmax = NULL, 
                         tier_names = NULL, point_tier_names = NULL,
                         .xptr = NULL) {
      if (!is.null(.xptr)) {
        private$ptr <- .xptr
      } else if (!is.null(path)) {
        private$ptr <- .textgrid_read(path)
      } else if (!is.null(xmin) && !is.null(xmax)) {
        private$ptr <- .textgrid_create(xmin, xmax, tier_names, point_tier_names)
      } else {
        stop("Provide path, time range, or .xptr")
      }
    },
    
    # ---- TIER QUERIES ----
    get_number_of_tiers = function() {
      .textgrid_get_number_of_tiers(private$ptr)
    },
    
    get_tier_names = function() {
      .textgrid_get_tier_names(private$ptr)
    },
    
    get_tier_type = function(tier) {
      .textgrid_get_tier_type(private$ptr, tier)
    },
    
    # ---- INTERVAL TIER METHODS ----
    get_number_of_intervals = function(tier) {
      .textgrid_get_number_of_intervals(private$ptr, tier)
    },
    
    get_interval_start_time = function(tier, interval_number) {
      .textgrid_get_interval_start_time(private$ptr, tier, interval_number)
    },
    
    get_interval_end_time = function(tier, interval_number) {
      .textgrid_get_interval_end_time(private$ptr, tier, interval_number)
    },
    
    get_interval_text = function(tier, interval_number) {
      .textgrid_get_interval_text(private$ptr, tier, interval_number)
    },
    
    get_interval_at_time = function(tier, time) {
      .textgrid_get_interval_at_time(private$ptr, tier, time)
    },
    
    get_label_at_time = function(tier, time) {
      .textgrid_get_label_at_time(private$ptr, tier, time)
    },
    
    set_interval_text = function(tier, interval_number, text) {
      .textgrid_set_interval_text(private$ptr, tier, interval_number, text)
      invisible(self)
    },
    
    insert_boundary = function(tier, time) {
      .textgrid_insert_boundary(private$ptr, tier, time)
      invisible(self)
    },
    
    remove_boundary = function(tier, time) {
      .textgrid_remove_boundary(private$ptr, tier, time)
      invisible(self)
    },
    
    # ---- POINT TIER METHODS ----
    get_number_of_points = function(tier) {
      .textgrid_get_number_of_points(private$ptr, tier)
    },
    
    get_point_time = function(tier, point_number) {
      .textgrid_get_point_time(private$ptr, tier, point_number)
    },
    
    get_point_text = function(tier, point_number) {
      .textgrid_get_point_text(private$ptr, tier, point_number)
    },
    
    insert_point = function(tier, time, text = "") {
      .textgrid_insert_point(private$ptr, tier, time, text)
      invisible(self)
    },
    
    remove_point = function(tier, point_number) {
      .textgrid_remove_point(private$ptr, tier, point_number)
      invisible(self)
    },
    
    # ---- TIER MANAGEMENT ----
    add_interval_tier = function(tier_name) {
      .textgrid_add_interval_tier(private$ptr, tier_name)
      invisible(self)
    },
    
    add_point_tier = function(tier_name) {
      .textgrid_add_point_tier(private$ptr, tier_name)
      invisible(self)
    },
    
    remove_tier = function(tier) {
      .textgrid_remove_tier(private$ptr, tier)
      invisible(self)
    },
    
    # ---- EXPORT ----
    as_data_frame = function(tiers = NULL) {
      .textgrid_as_data_frame(private$ptr, tiers)
    },
    
    save = function(path, format = "text") {
      .textgrid_save(private$ptr, path, format)
      invisible(self)
    },
    
    print = function() {
      cat("<Praat TextGrid>\n")
      cat(sprintf("  Number of tiers: %d\n", self$get_number_of_tiers()))
      cat(sprintf("  Tier names: %s\n", paste(self$get_tier_names(), collapse = ", ")))
      invisible(self)
    }
  )
)
```

**C++ Wrappers** (`src/textgrid_wrappers.cpp`): ~35 functions

**Testing**:
- Read/write TextGrid files (text and binary formats)
- Tier manipulation
- Interval and point operations
- Integration with Sound objects

---

### Phase 4: Analysis Objects (Weeks 5-7)

Implement in order:

1. **Pitch** (`R/pitch-r6.R`, `src/pitch_wrappers.cpp`)
2. **Formant** (`R/formant-r6.R`, `src/formant_wrappers.cpp`)
3. **Intensity** (`R/intensity-r6.R`, `src/intensity_wrappers.cpp`)
4. **Harmonicity** (`R/harmonicity-r6.R`, `src/harmonicity_wrappers.cpp`)

**Pitch Methods** (example - similar pattern for others):
```r
Pitch <- R6Class("Pitch",
  inherit = PraatObject,
  public = list(
    get_value_at_time = function(time, unit = "hertz", interpolation = "linear"),
    get_mean = function(from_time = 0, to_time = 0, unit = "hertz"),
    get_minimum = function(from_time = 0, to_time = 0, unit = "hertz", interpolation = "parabolic"),
    get_maximum = function(from_time = 0, to_time = 0, unit = "hertz", interpolation = "parabolic"),
    get_quantile = function(from_time = 0, to_time = 0, quantile = 0.5, unit = "hertz"),
    get_standard_deviation = function(from_time = 0, to_time = 0, unit = "hertz"),
    get_time_of_minimum = function(from_time = 0, to_time = 0, unit = "hertz"),
    get_time_of_maximum = function(from_time = 0, to_time = 0, unit = "hertz"),
    count_voiced_frames = function(),
    to_pitch_tier = function(),
    smooth = function(bandwidth = 5.0),
    as_data_frame = function(),
    save = function(path)
  )
)
```

---

### Phase 5: Spectral Objects (Weeks 7-8)

1. **Spectrum** (`R/spectrum-r6.R`)
2. **Spectrogram** (`R/spectrogram-r6.R`)
3. **Ltas** (`R/ltas-r6.R`)

---

### Phase 6: Advanced Objects (Weeks 8-9)

1. **PointProcess** (`R/pointprocess-r6.R`)
   - Essential for voice quality metrics
   
2. **Manipulation** (`R/manipulation-r6.R`)
   - PSOLA-based pitch/duration modification
   - Integrates Sound, Pitch, PointProcess, PitchTier, DurationTier

3. **VoiceReport** (`R/voice-report-r6.R`)
   - Comprehensive voice quality analysis
   - Methods: jitter, shimmer, HNR, etc.

---

### Phase 7: Tier Objects (Week 9)

1. **PitchTier** (`R/pitchtier-r6.R`)
2. **IntensityTier** (`R/intensitytier-r6.R`)
3. **FormantTier** (`R/formantier-r6.R`)
4. **DurationTier** (`R/durationtier-r6.R`)

These enable precise control over manipulation operations.

---

### Phase 8: Re-implement superassp Examples (Week 10)

**Goal**: Demonstrate equivalence with Parselmouth Python code

**Analyze and re-implement**:
- `/Users/frkkan96/Documents/src/superassp/inst/python/*.py`

**Create** (`inst/examples/`):

1. `voice_report.R` - From `praat_voice_report_memory.py`
2. `pitch_tracking.R` - From `praat_pitch.py`
3. `formant_tracking.R` - From `praat_formant_burg.py`
4. `formant_path.R` - From `praat_formantpath_burg.py`
5. `intensity_analysis.R` - From `praat_intensity.py`
6. `spectral_moments.R` - From `praat_spectral_moments.py`
7. `avqi.R` - From `praat_avqi_memory.py` (Acoustic Voice Quality Index)
8. `dsi.R` - From `praat_dsi_memory.py` (Dysphonia Severity Index)
9. `sauce.R` - From `praat_sauce_memory.py`

**Each example should include**:
- Original Python code (commented)
- Equivalent R code using speaker package
- Explanation of differences
- Test that results match

**Example**:
```r
# inst/examples/voice_report.R

# ========================================
# ORIGINAL PYTHON (parselmouth):
# ========================================
# import parselmouth
# sound = parselmouth.Sound("voice.wav")
# report = parselmouth.praat.call(sound, "Voice report", 0, 0, 75, 600, 1.3, 1.6, 0.03, 0.45)
# jitter = parselmouth.praat.call(sound, "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)

# ========================================
# EQUIVALENT R (speaker):
# ========================================
library(speaker)

sound <- Sound$new("voice.wav")

# Option 1: Full voice report
report <- sound$voice_report(
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6,
  silence_threshold = 0.03,
  voicing_threshold = 0.45
)

# Extract specific metrics
jitter_local <- report$get_jitter_local()
shimmer_local <- report$get_shimmer_local()
mean_hnr <- report$get_mean_hnr()

# Option 2: Individual calculations
pitch <- sound$to_pitch()
point_process <- sound$to_point_process_periodic_cc()
jitter <- point_process$get_jitter_local(
  sound,
  from_time = 0,
  to_time = 0,
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3
)

print(paste("Jitter (local):", jitter))
```

---

### Phase 9: Documentation (Week 11)

**Vignettes** (`vignettes/`):

1. **Getting Started** - Basic workflow
2. **Working with Sound** - Audio I/O, manipulation
3. **Pitch Analysis** - F0 extraction and analysis
4. **Formant Tracking** - Vowel analysis
5. **TextGrid Annotation** - Creating and manipulating annotations
6. **Voice Quality** - Jitter, shimmer, HNR
7. **Pitch Manipulation** - PSOLA-based modification
8. **From Praat Scripts to R** - Translation guide
9. **From Parselmouth to speaker** - Migration guide

**Reference Documentation**:
- Complete Rd files for all R6 classes
- Method-level docs with examples
- Package overview

---

### Phase 10: Testing & Validation (Week 12)

**Test Coverage Goals**:
- R code: >95%
- C++ code: >85%

**Test Types**:
1. **Unit tests** - Each method individually
2. **Integration tests** - Complete workflows
3. **Memory tests** - Valgrind, no leaks
4. **Performance tests** - Benchmark vs Praat desktop
5. **Validation tests** - Compare output with Praat/Parselmouth
6. **Edge case tests** - Empty sounds, invalid parameters, etc.

---

## Naming Convention Standard

**Consistency is key for R users to easily translate Praat code**

| Praat Command | R6 Method | Category |
|---------------|-----------|----------|
| `Get duration` | `get_duration()` | Query |
| `Get sampling frequency` | `get_sampling_frequency()` | Query |
| `Get value at time...` | `get_value_at_time(time, ...)` | Query |
| `Get minimum...` | `get_minimum(...)` | Query |
| `Get maximum...` | `get_maximum(...)` | Query |
| `To Pitch...` | `to_pitch(...)` | Transform |
| `To Formant (burg)...` | `to_formant_burg(...)` | Transform |
| `To Intensity...` | `to_intensity(...)` | Transform |
| `To Spectrogram...` | `to_spectrogram(...)` | Transform |
| `Extract part...` | `extract_part(...)` | Extract |
| `Extract channel...` | `extract_channel(...)` | Extract |
| `Scale intensity...` | `scale_intensity(...)` | Modify |
| `Scale peak...` | `scale_peak(...)` | Modify |
| `Pre-emphasize...` | `pre_emphasize(...)` | Modify |
| `Filter (pass Hann band)...` | `filter_pass_hann_band(...)` | Modify |
| `Down to Matrix` | `as_matrix()` | Export |
| `Down to Table` | `as_data_frame()` | Export |
| `Save as WAV file...` | `save(path)` | I/O |
| `Read from file...` | `$new(path)` | I/O |

**Patterns**:
- **Query**: `get_*` → returns scalar/vector
- **Transform**: `to_*` → returns new object of different class
- **Extract**: `extract_*` → returns new object of same class
- **Modify**: verb (e.g., `scale`, `filter`) → modifies in place, returns self
- **Export**: `as_*` → converts to R native type (data.frame, matrix, vector)
- **I/O**: `save()`, `$new(path)`

---

## Success Criteria

### Technical Excellence
- ✅ 12+ Praat objects as R6 classes
- ✅ 200+ methods covering full Praat functionality
- ✅ Zero memory leaks (valgrind clean)
- ✅ Test coverage >90% (R), >80% (C++)
- ✅ Performance within 10% of Praat desktop
- ✅ Works on Windows, macOS, Linux

### Usability
- ✅ Intuitive OOP API matching Praat's design
- ✅ 50+ documented examples
- ✅ 9+ comprehensive vignettes
- ✅ Migration guides (Praat scripts, Parselmouth)
- ✅ Consistent naming conventions

### Completeness
- ✅ All superassp Python examples re-implemented in R
- ✅ TextGrid full support (read, write, manipulate)
- ✅ Voice quality analysis (jitter, shimmer, HNR, etc.)
- ✅ Pitch manipulation (PSOLA via Manipulation)
- ✅ Spectral analysis (Spectrogram, Spectrum, Ltas)
- ✅ All major Praat workflows supported

---

## Timeline

**12 weeks to 100% completion**

| Week | Phase | Milestone |
|------|-------|-----------|
| 1-2 | Foundation | R6 infrastructure, base classes, error handling |
| 2-3 | Sound | Complete Sound object with all methods |
| 4-5 | TextGrid | Full TextGrid support (CRITICAL) |
| 5-6 | Pitch | Pitch object with all analysis methods |
| 6 | Formant | Formant object |
| 6 | Intensity | Intensity object |
| 7 | Harmonicity | Harmonicity object |
| 7-8 | Spectral | Spectrum, Spectrogram, Ltas |
| 8-9 | Advanced | PointProcess, Manipulation, VoiceReport |
| 9 | Tiers | PitchTier, FormantTier, IntensityTier, DurationTier |
| 10 | Examples | Re-implement all superassp Python code |
| 11 | Documentation | Vignettes, reference docs, migration guides |
| 12 | Testing | Comprehensive tests, validation, CRAN prep |

---

## Implementation Strategy

### Incremental Approach

1. **Start with Sound** - Most foundational, establishes patterns
2. **Add TextGrid early** - Critical missing feature
3. **Build analysis objects** - Pitch, Formant, Intensity (most used)
4. **Add advanced features** - Manipulation, voice quality
5. **Complete tier objects** - For fine control
6. **Demonstrate equivalence** - Re-implement Python examples
7. **Document thoroughly** - Vignettes and reference
8. **Test rigorously** - Ensure correctness and performance

### Each Object Implementation

1. Create R6 class file
2. Create C++ wrapper file
3. Write unit tests
4. Create documentation
5. Add to NAMESPACE
6. Build and test
7. Commit with clear message

---

## Conclusion

This plan transforms speaker from a procedure-based package to a comprehensive, object-oriented Praat interface that:

1. **Mirrors Praat's native C++ design** - R6 objects ↔ Praat objects
2. **Matches Parselmouth's capabilities** - But without Python dependency
3. **Exposes 12+ objects with 200+ methods** - Full Praat functionality
4. **Enables natural R-Praat workflows** - Intuitive method chaining
5. **Provides clear migration paths** - From Praat scripts and Parselmouth

**This is the comprehensive, production-ready phonetic analysis toolkit R has been missing!** 🎉
