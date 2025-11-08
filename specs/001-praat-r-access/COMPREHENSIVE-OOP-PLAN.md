# Comprehensive Object-Oriented Praat R Package Implementation Plan

## Executive Summary

This document provides a comprehensive plan to fully implement the Praat codebase functionality in R using an object-oriented approach that mirrors Praat's native C++ structure and the proven Parselmouth Python library design. The focus is on exposing Praat **objects** and their **methods** rather than implementing isolated procedures.

## Current State Analysis

### What's Currently Implemented (S3 Approach)
- **Sound**: Basic read/write, stats (minimal)
- **Pitch**: Basic extraction via autocorrelation
- **Formant**: Basic extraction via Burg's method
- **Intensity**: Basic extraction

### Critical Gaps
1. **No TextGrid support** - Essential for annotation and segmentation
2. **No advanced Praat objects**: Spectrogram, Spectrum, Manipulation, LPC, PointProcess, Harmonicity
3. **Limited method coverage** - Only extraction, no modification or advanced analysis
4. **Functional approach** - Doesn't reflect Praat's object-oriented nature
5. **Data copying overhead** - Inefficient for chained operations

## Architectural Foundation

### Design Principle: Mirror Praat's Object Model

Praat is fundamentally object-oriented with:
- **Thing** base class hierarchy
- Objects with persistent state
- Methods that query, modify, or transform objects
- Object-to-object transformations

Our R package must reflect this structure using **R6 classes** with **external pointers** to C++ Praat objects.

### Core Architecture

```
R Layer (R6 Classes)          C++ Layer (Praat Objects)
─────────────────────────────────────────────────────────
PraatObject (base)     <───>  Thing* (base)
  └─ Sound             <───>  Sound*
  └─ Pitch             <───>  Pitch*
  └─ Formant           <───>  Formant*
  └─ Intensity         <───>  Intensity*
  └─ TextGrid          <───>  TextGrid*
  └─ Spectrogram       <───>  Spectrogram*
  └─ Spectrum          <───>  Spectrum*
  └─ Manipulation      <───>  Manipulation*
  └─ PointProcess      <───>  PointProcess*
  └─ Harmonicity       <───>  Harmonicity*
  └─ LPC               <───>  LPC*
  └─ etc.
```

## Complete Object Hierarchy Implementation

### 1. Sound (Foundation Object)

**Purpose**: Represents audio waveform data

**R6 Class**: `Sound`

**Creation Methods**:
```r
# From file
sound <- Sound$new("audio.wav")

# From values
sound <- Sound$from_values(values, sampling_rate = 44100)

# From formula (generate)
sound <- Sound$create_tone(duration = 1.0, frequency = 440)
sound <- Sound$create_noise(duration = 1.0)
```

**Query Methods**:
```r
sound$get_duration()
sound$get_sampling_frequency()
sound$get_number_of_samples()
sound$get_number_of_channels()
sound$get_value_at_time(time, channel = 1)
sound$get_value_at_sample(sample, channel = 1)
sound$get_energy()
sound$get_power()
sound$get_rms()
sound$get_intensity_db()
```

**Modification Methods**:
```r
sound$scale_intensity(new_intensity_db)
sound$scale_peak(new_peak)
sound$resample(new_rate)
sound$reverse()
sound$lengthen(factor)
sound$deepen_band_modulation(...)
sound$filter_pass_hann_band(from_freq, to_freq, bandwidth)
sound$pre_emphasize(from_frequency = 50.0)
sound$de_emphasize(from_frequency = 50.0)
```

**Extraction Methods**:
```r
sound$extract_channel(channel)
sound$extract_part(start, end, window_shape = "rectangular")
sound$extract_part_for_overlap(start, end)
```

**Transformation Methods** (returns new objects):
```r
pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(time_step = 0.005, max_formants = 5, max_hz = 5500)
intensity <- sound$to_intensity(min_pitch = 100, time_step = 0.0)
spectrogram <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
spectrum <- sound$to_spectrum(fast = TRUE)
textgrid <- sound$to_textgrid(tier_name = "segments")
manipulation <- sound$to_manipulation(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
harmonicity <- sound$to_harmonicity_cc(time_step = 0.01, min_pitch = 75)
point_process <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)
lpc <- sound$to_lpc_autocorrelation(order = 16, window_length = 0.025, time_step = 0.005)
```

**Export Methods**:
```r
sound$save("output.wav")
sound$as_data_frame()
sound$as_matrix()
```

**C++ Functions Needed**:
```cpp
// [[Rcpp::export(.sound_read_from_file)]]
Rcpp::XPtr<structSound> sound_read_from_file(std::string path);

// [[Rcpp::export(.sound_create_from_values)]]
Rcpp::XPtr<structSound> sound_create_from_values(NumericVector values, double sampling_rate);

// [[Rcpp::export(.sound_to_pitch)]]
Rcpp::XPtr<structPitch> sound_to_pitch(XPtr<structSound> sound, double time_step, double pitch_floor, double pitch_ceiling);

// ... etc for all transformation methods
```

---

### 2. Pitch (F0 Contour Object)

**Purpose**: Represents fundamental frequency trajectory

**R6 Class**: `Pitch`

**Creation Methods**:
```r
# From file
pitch <- Pitch$new("pitch.Pitch")

# From sound (preferred)
pitch <- sound$to_pitch()
```

**Query Methods**:
```r
pitch$get_value_at_time(time, unit = "hertz")  # unit: "hertz" or "semitones"
pitch$get_value_in_frame(frame, unit = "hertz")
pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
pitch$get_median(from_time = 0, to_time = 0, unit = "hertz")
pitch$get_quantile(from_time = 0, to_time = 0, quantile = 0.25, unit = "hertz")
pitch$get_minimum(from_time = 0, to_time = 0, unit = "hertz")
pitch$get_maximum(from_time = 0, to_time = 0, unit = "hertz")
pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")
pitch$get_time_of_minimum(from_time = 0, to_time = 0)
pitch$get_time_of_maximum(from_time = 0, to_time = 0)
pitch$count_voiced_frames()
```

**Modification Methods**:
```r
pitch$interpolate()
pitch$smooth(bandwidth = 10.0)
pitch$shift_frequencies(from_frequency, to_frequency, scale_factor)
pitch$scale_frequencies(scale_factor)
```

**Transformation Methods**:
```r
sound <- pitch$to_sound(sampling_frequency = 44100)  # Resynthesize
point_process <- pitch$to_point_process()
pitch_tier <- pitch$down_to_pitch_tier()
```

**Voice Quality Methods** (requires Sound + Pitch):
```r
# These would be methods on a combined VoiceReport object
jitter_local <- pitch$get_jitter_local(sound, from_time, to_time)
jitter_rap <- pitch$get_jitter_rap(sound, from_time, to_time)
shimmer_local <- pitch$get_shimmer_local(sound, from_time, to_time)
```

**Export Methods**:
```r
pitch$save("output.Pitch")
pitch$as_data_frame()
```

---

### 3. Formant (Resonance Trajectory Object)

**Purpose**: Represents formant frequency trajectories

**R6 Class**: `Formant`

**Creation Methods**:
```r
# From file
formant <- Formant$new("formant.Formant")

# From sound
formant <- sound$to_formant_burg(time_step = 0.005, max_formants = 5, max_hz = 5500, window_length = 0.025, pre_emphasis = 50)
```

**Query Methods**:
```r
formant$get_value_at_time(formant_number, time, unit = "hertz")  # unit: "hertz" or "bark"
formant$get_bandwidth_at_time(formant_number, time, unit = "hertz")
formant$get_mean(formant_number, from_time = 0, to_time = 0, unit = "hertz")
formant$get_standard_deviation(formant_number, from_time = 0, to_time = 0, unit = "hertz")
formant$get_minimum(formant_number, from_time = 0, to_time = 0, unit = "hertz")
formant$get_maximum(formant_number, from_time = 0, to_time = 0, unit = "hertz")
formant$get_quantile(formant_number, from_time = 0, to_time = 0, quantile = 0.5, unit = "hertz")
formant$get_time_of_maximum(formant_number, from_time = 0, to_time = 0)
formant$get_time_of_minimum(formant_number, from_time = 0, to_time = 0)
```

**Modification Methods**:
```r
formant$formula(formula_text)  # Advanced formula manipulation
```

**Transformation Methods**:
```r
formant_grid <- formant$down_to_formant_grid()
table <- formant$down_to_table(include_frame_number = TRUE, include_time = TRUE, 
                               time_decimals = 6, include_intensity = TRUE, 
                               intensity_decimals = 3, include_formants = TRUE, 
                               formant_decimals = 3, include_bandwidths = TRUE, 
                               bandwidth_decimals = 3)
```

**Tracking Methods**:
```r
formant_tracked <- formant$track(num_tracks = 3, ref_f1 = 550, ref_f2 = 1650, 
                                 ref_f3 = 2750, ref_f4 = 3850, ref_f5 = 4950,
                                 frequency_cost = 1.0, bandwidth_cost = 1.0, 
                                 transition_cost = 1.0)
```

**Export Methods**:
```r
formant$save("output.Formant")
formant$as_data_frame()
```

---

### 4. Intensity (Loudness Contour Object)

**Purpose**: Represents sound intensity over time

**R6 Class**: `Intensity`

**Creation Methods**:
```r
# From file
intensity <- Intensity$new("intensity.Intensity")

# From sound
intensity <- sound$to_intensity(min_pitch = 100, time_step = 0.0, subtract_mean = TRUE)
```

**Query Methods**:
```r
intensity$get_value_at_time(time)
intensity$get_mean(from_time = 0, to_time = 0)
intensity$get_minimum(from_time = 0, to_time = 0)
intensity$get_maximum(from_time = 0, to_time = 0)
intensity$get_standard_deviation(from_time = 0, to_time = 0)
intensity$get_quantile(from_time = 0, to_time = 0, quantile = 0.5)
intensity$get_time_of_minimum(from_time = 0, to_time = 0)
intensity$get_time_of_maximum(from_time = 0, to_time = 0)
```

**Transformation Methods**:
```r
intensity_tier <- intensity$down_to_intensity_tier()
```

**Export Methods**:
```r
intensity$save("output.Intensity")
intensity$as_data_frame()
```

---

### 5. TextGrid (Annotation Object) - CRITICAL MISSING FEATURE

**Purpose**: Time-aligned linguistic annotations with interval and point tiers

**R6 Class**: `TextGrid`

**Creation Methods**:
```r
# From file
tg <- TextGrid$new("annotation.TextGrid")

# Create from sound
tg <- sound$to_textgrid(tier_names = c("words", "phones"))

# Create from scratch
tg <- TextGrid$create(xmin = 0, xmax = 10, tier_names = c("words", "phones"), 
                      point_tiers = c("events"))
```

**Tier Query Methods**:
```r
tg$get_number_of_tiers()
tg$get_tier_names()
tg$get_tier(tier_number_or_name)
tg$tier_exists(tier_name)
tg$get_tier_index(tier_name)
```

**Interval Tier Methods**:
```r
# Get intervals
intervals <- tg$get_intervals(tier_name = "words")
interval <- tg$get_interval_at_time(tier_name = "words", time = 0.5)
text <- tg$get_label_at_time(tier_name = "words", time = 0.5)

# Add/modify intervals
tg$insert_boundary(tier_name = "words", time = 1.5)
tg$set_interval_text(tier_name = "words", interval_number = 1, text = "hello")
tg$remove_boundary(tier_name = "words", time = 1.5)
```

**Point Tier Methods**:
```r
# Get points
points <- tg$get_points(tier_name = "events")
point <- tg$get_point_at_time(tier_name = "events", time = 0.5)

# Add/modify points
tg$insert_point(tier_name = "events", time = 0.5, text = "vowel_onset")
tg$remove_point(tier_name = "events", time = 0.5)
```

**Tier Management**:
```r
tg$add_interval_tier(tier_name = "syllables")
tg$add_point_tier(tier_name = "landmarks")
tg$remove_tier(tier_name_or_number)
tg$duplicate_tier(tier_number, new_name)
```

**Extraction Methods**:
```r
tg_part <- tg$extract_part(from_time = 0, to_time = 5)
```

**Export Methods**:
```r
tg$save("output.TextGrid", format = "text")  # format: "text" or "binary"
tg$as_data_frame()  # Long format with tier, time, label columns
```

**C++ Functions Needed**:
```cpp
// [[Rcpp::export(.textgrid_read_from_file)]]
Rcpp::XPtr<structTextGrid> textgrid_read_from_file(std::string path);

// [[Rcpp::export(.textgrid_get_tier_names)]]
CharacterVector textgrid_get_tier_names(XPtr<structTextGrid> tg);

// [[Rcpp::export(.textgrid_get_label_at_time)]]
String textgrid_get_label_at_time(XPtr<structTextGrid> tg, int tier, double time);

// ... etc
```

---

### 6. Spectrogram (Time-Frequency Representation)

**Purpose**: Short-time Fourier transform representation

**R6 Class**: `Spectrogram`

**Creation Methods**:
```r
# From file
spec <- Spectrogram$new("spectrogram.Spectrogram")

# From sound
spec <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000, 
                             time_step = 0.002, frequency_step = 20, 
                             window_shape = "Gaussian")
```

**Query Methods**:
```r
spec$get_power_at(time, frequency)
spec$get_time_from_frame_number(frame)
spec$get_frequency_from_bin_number(bin)
```

**Transformation Methods**:
```r
ltas <- spec$to_ltas(bandwidth = 100)  # Long-term average spectrum
spectrum <- spec$to_spectrum(time)
```

**Export Methods**:
```r
spec$save("output.Spectrogram")
spec$as_matrix()  # Time x Frequency matrix
spec$as_data_frame()  # Long format
```

---

### 7. Spectrum (Frequency Domain)

**Purpose**: FFT representation at a single time point

**R6 Class**: `Spectrum`

**Creation Methods**:
```r
# From file
spectrum <- Spectrum$new("spectrum.Spectrum")

# From sound
spectrum <- sound$to_spectrum(fast = TRUE)
```

**Query Methods**:
```r
spectrum$get_power_at(frequency)
spectrum$get_real_at(frequency)
spectrum$get_imaginary_at(frequency)
spectrum$get_mean()
spectrum$get_standard_deviation()
spectrum$get_band_energy(from_freq, to_freq)
spectrum$get_band_density(from_freq, to_freq)
spectrum$get_centre_of_gravity(power = 2)
```

**Modification Methods**:
```r
spectrum$filter(from_freq, to_freq)
spectrum$passband_filter(from_freq, to_freq, smoothing)
```

**Transformation Methods**:
```r
sound <- spectrum$to_sound()
ltas <- spectrum$to_ltas(bandwidth = 100)
excitation <- spectrum$to_excitation(erb_density = 0.1)
```

**Export Methods**:
```r
spectrum$save("output.Spectrum")
spectrum$as_data_frame()
```

---

### 8. Manipulation (Pitch/Duration Modification Object)

**Purpose**: PSOLA-based pitch and duration modification

**R6 Class**: `Manipulation`

**Creation Methods**:
```r
# From sound
manip <- sound$to_manipulation(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
```

**Query Methods**:
```r
pitch_tier <- manip$extract_pitch_tier()
duration_tier <- manip$extract_duration_tier()
original_sound <- manip$extract_original_sound()
point_process <- manip$extract_pulses()
```

**Modification Methods**:
```r
manip$replace_pitch_tier(new_pitch_tier)
manip$replace_duration_tier(new_duration_tier)
```

**Transformation Methods**:
```r
modified_sound <- manip$get_resynthesis_overlap_add()
```

**Example Workflow**:
```r
sound <- Sound$new("voice.wav")
manip <- sound$to_manipulation()

# Get pitch tier and modify it
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(time_range_start = 0, time_range_end = 0, factor = 1.2)

# Replace and resynthesize
manip$replace_pitch_tier(pitch_tier)
modified_sound <- manip$get_resynthesis_overlap_add()
modified_sound$save("voice_higher.wav")
```

---

### 9. PointProcess (Time Points)

**Purpose**: Sequence of time points (e.g., pitch pulses, glottal closures)

**R6 Class**: `PointProcess`

**Creation Methods**:
```r
# From file
pp <- PointProcess$new("points.PointProcess")

# From sound
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

# From pitch
pp <- pitch$to_point_process()
```

**Query Methods**:
```r
pp$get_number_of_points()
pp$get_time_from_index(index)
pp$get_nearest_index(time)
pp$get_low_index(time)
pp$get_high_index(time)
```

**Voice Quality Methods** (requires Sound):
```r
jitter_local <- pp$get_jitter_local(sound, from_time, to_time, period_floor, period_ceiling, max_period_factor)
jitter_rap <- pp$get_jitter_rap(sound, from_time, to_time, period_floor, period_ceiling, max_period_factor)
jitter_ppq5 <- pp$get_jitter_ppq5(sound, from_time, to_time, period_floor, period_ceiling, max_period_factor)
shimmer_local <- pp$get_shimmer_local(sound, from_time, to_time, period_floor, period_ceiling, max_amplitude_factor)
```

**Export Methods**:
```r
pp$save("output.PointProcess")
pp$as_data_frame()
```

---

### 10. Harmonicity (HNR Object)

**Purpose**: Harmonics-to-noise ratio over time

**R6 Class**: `Harmonicity`

**Creation Methods**:
```r
# From file
hnr <- Harmonicity$new("harmonicity.Harmonicity")

# From sound
hnr <- sound$to_harmonicity_cc(time_step = 0.01, min_pitch = 75, silence_threshold = 0.1, periods_per_window = 1.0)
```

**Query Methods**:
```r
hnr$get_value_at_time(time)
hnr$get_mean(from_time = 0, to_time = 0)
hnr$get_minimum(from_time = 0, to_time = 0)
hnr$get_maximum(from_time = 0, to_time = 0)
hnr$get_standard_deviation(from_time = 0, to_time = 0)
```

**Export Methods**:
```r
hnr$save("output.Harmonicity")
hnr$as_data_frame()
```

---

### 11. LPC (Linear Predictive Coding)

**Purpose**: LPC filter coefficients and analysis

**R6 Class**: `LPC`

**Creation Methods**:
```r
# From sound
lpc <- sound$to_lpc_autocorrelation(order = 16, window_length = 0.025, time_step = 0.005, pre_emphasis = 50)
```

**Query Methods**:
```r
lpc$get_number_of_coefficients()
```

**Transformation Methods**:
```r
formant <- lpc$to_formant()
spectrum <- lpc$to_spectrum(time, sampling_frequency)
```

**Export Methods**:
```r
lpc$save("output.LPC")
lpc$as_data_frame()
```

---

### 12. VoiceReport (Voice Quality Metrics)

**Purpose**: Comprehensive voice quality analysis combining multiple measures

**R6 Class**: `VoiceReport` (special combined object)

**Creation Method**:
```r
# From sound
report <- sound$voice_report(pitch_floor = 75, pitch_ceiling = 600, time_step = 0.0, 
                            period_floor = 0.0001, period_ceiling = 0.02, 
                            max_period_factor = 1.3, max_amplitude_factor = 1.6)
```

**Query Methods**:
```r
report$get_mean_pitch()
report$get_median_pitch()
report$get_jitter_local()
report$get_jitter_rap()
report$get_jitter_ppq5()
report$get_shimmer_local()
report$get_shimmer_apq3()
report$get_shimmer_apq5()
report$get_shimmer_apq11()
report$get_mean_hnr()
report$get_mean_autocorrelation()
report$get_fraction_unvoiced()
report$get_number_of_voice_breaks()
```

**Export Methods**:
```r
report$as_list()
report$as_data_frame()  # Single-row data frame with all metrics
```

---

## Complete Implementation Roadmap

### Phase 1: Foundation Infrastructure (Week 1-2)

**Goal**: Set up R6 infrastructure with proper memory management

**Tasks**:
1. Add R6 to DESCRIPTION dependencies
2. Create base `PraatObject` R6 class with XPtr management
3. Implement C++ finalizer infrastructure
4. Create utility functions for XPtr validation
5. Set up proper exception handling bridge (C++ MelderError → R errors)
6. Update Makevars for C++17 support
7. Write comprehensive memory management tests

**Deliverables**:
- `R/praat-object-base.R` - Base PraatObject R6 class
- `src/praat_xptr_utils.cpp` - XPtr finalizers and utilities
- `src/praat_error_handling.cpp` - Error bridge
- `tests/testthat/test-memory.R` - Memory leak tests

---

### Phase 2: Core Sound Object (Week 2-3)

**Goal**: Complete Sound class with all methods

**Tasks**:
1. Implement Sound R6 class
2. C++ wrappers for Sound creation (file, values, generate)
3. All query methods (duration, sampling rate, values, energy, etc.)
4. All modification methods (scale, filter, resample, etc.)
5. All extraction methods (channel, part)
6. All transformation methods (to_pitch, to_formant, to_intensity, etc.)
7. Export methods (save, as_data_frame, as_matrix)
8. Comprehensive tests

**Deliverables**:
- `R/sound-r6.R` - Complete Sound R6 class
- `src/sound_wrappers.cpp` - All Sound C++ wrappers
- `tests/testthat/test-sound.R` - Sound tests
- `man/Sound.Rd` - Documentation

---

### Phase 3: Analysis Objects (Week 3-5)

**Goal**: Implement Pitch, Formant, Intensity, Harmonicity

**Tasks per object**:
1. R6 class definition
2. C++ wrappers for creation and all methods
3. Tests
4. Documentation

**Priority Order**:
1. **Pitch** - Most commonly used
2. **Formant** - Critical for vowel analysis
3. **Intensity** - Simple, good for testing patterns
4. **Harmonicity** - Voice quality metric

**Deliverables**:
- `R/pitch-r6.R`, `src/pitch_wrappers.cpp`, tests, docs
- `R/formant-r6.R`, `src/formant_wrappers.cpp`, tests, docs
- `R/intensity-r6.R`, `src/intensity_wrappers.cpp`, tests, docs
- `R/harmonicity-r6.R`, `src/harmonicity_wrappers.cpp`, tests, docs

---

### Phase 4: TextGrid (Week 5-6) - CRITICAL

**Goal**: Full TextGrid support

**Tasks**:
1. TextGrid R6 class
2. IntervalTier and PointTier helper classes
3. C++ wrappers for all tier operations
4. Interval and point manipulation
5. Tier management (add, remove, duplicate)
6. I/O (read, save, export to data.frame)
7. Integration with Sound (extract parts based on intervals)
8. Comprehensive tests with real TextGrid files

**Deliverables**:
- `R/textgrid-r6.R` - TextGrid, IntervalTier, PointTier classes
- `src/textgrid_wrappers.cpp` - All TextGrid operations
- `tests/testthat/test-textgrid.R` - Extensive tests
- `man/TextGrid.Rd` - Complete documentation
- Example TextGrid files in `inst/extdata/`

---

### Phase 5: Spectral Objects (Week 6-7)

**Goal**: Implement Spectrogram, Spectrum, LPC

**Tasks**:
1. Spectrogram R6 class and C++ wrappers
2. Spectrum R6 class and C++ wrappers
3. LPC R6 class and C++ wrappers
4. Transformations between spectral types
5. Tests and documentation

**Deliverables**:
- `R/spectrogram-r6.R`, `src/spectrogram_wrappers.cpp`
- `R/spectrum-r6.R`, `src/spectrum_wrappers.cpp`
- `R/lpc-r6.R`, `src/lpc_wrappers.cpp`
- Tests and docs for each

---

### Phase 6: Advanced Objects (Week 7-8)

**Goal**: Implement Manipulation, PointProcess, VoiceReport

**Tasks**:
1. PointProcess R6 class (needed for voice quality)
2. Manipulation R6 class for PSOLA
3. PitchTier, DurationTier for Manipulation
4. VoiceReport special class combining multiple analyses
5. Integration tests showing complete workflows

**Deliverables**:
- `R/pointprocess-r6.R`, `src/pointprocess_wrappers.cpp`
- `R/manipulation-r6.R`, `src/manipulation_wrappers.cpp`
- `R/voice-report-r6.R`, `src/voice_report_wrappers.cpp`
- Workflow vignettes

---

### Phase 7: Tier Objects (Week 8-9)

**Goal**: Implement modifiable tier objects

**Tasks**:
1. PitchTier R6 class
2. FormantTier R6 class  
3. IntensityTier R6 class
4. DurationTier R6 class
5. Methods to modify tier points
6. Integration with Manipulation

**Deliverables**:
- R6 classes for all tier types
- C++ wrappers
- Tests and docs

---

### Phase 8: Example Re-implementations (Week 9-10)

**Goal**: Re-implement superassp Python examples in R

**Tasks**:
1. Analyze all Python files in `/Users/frkkan96/Documents/src/superassp/inst/python/`
2. Identify which use Parselmouth
3. Re-implement in R using speaker package
4. Create examples/ directory in package
5. Document equivalences (Python Parselmouth → R speaker)

**Python files to re-implement**:
- `praat_voice_report_memory.py` → `examples/voice_report.R`
- `praat_pitch.py` → `examples/pitch_tracking.R`
- `praat_formant_burg.py` → `examples/formant_tracking.R`
- `praat_formantpath_burg.py` → `examples/formant_path.R`
- `praat_intensity.py` → `examples/intensity_analysis.R`
- `praat_spectral_moments.py` → `examples/spectral_moments.R`
- `praat_avqi_memory.py` → `examples/avqi.R`
- `praat_dsi_memory.py` → `examples/dsi.R`
- `praat_sauce_memory.py` → `examples/sauce.R`

**Deliverables**:
- `inst/examples/` directory with R scripts
- `inst/examples/README.md` explaining Python → R conversions
- Vignette: "Migrating from Parselmouth to speaker"

---

### Phase 9: Documentation & Vignettes (Week 10-11)

**Goal**: Comprehensive documentation

**Vignettes**:
1. **Getting Started**: Basic Sound → Pitch → Formant workflow
2. **TextGrid Tutorial**: Creating and manipulating annotations
3. **Voice Quality Analysis**: Complete voice report
4. **Pitch Manipulation**: Using Manipulation objects
5. **From Praat Scripts to R**: Translation guide
6. **From Parselmouth to speaker**: Python → R migration
7. **Advanced Workflows**: Chaining operations efficiently

**Reference Documentation**:
- Complete Rd files for all R6 classes
- Method-level documentation with examples
- Package-level documentation

**Deliverables**:
- `vignettes/` with 7+ vignettes
- Complete `man/` documentation
- README with quickstart examples

---

### Phase 10: Testing & Validation (Week 11-12)

**Goal**: Ensure correctness and performance

**Tasks**:
1. Comprehensive unit tests for all objects and methods
2. Integration tests with real-world workflows
3. Memory leak testing with valgrind
4. Performance benchmarks vs Praat desktop
5. Comparison tests vs Parselmouth (ensure parity)
6. Edge case testing (empty sounds, missing values, etc.)
7. Stress testing (large files, long operations)

**Test Coverage Goals**:
- R code: >95%
- C++ code: >85%

**Deliverables**:
- `tests/testthat/` with 50+ test files
- `tests/benchmarks/` with performance tests
- `tests/validation/` comparing to Praat/Parselmouth output
- CI/CD setup with GitHub Actions

---

## Naming Conventions (Praat → R)

### Method Naming Pattern

| Praat Command | R6 Method | Example |
|---------------|-----------|---------|
| `Get duration` | `get_duration()` | `sound$get_duration()` |
| `Get sampling frequency` | `get_sampling_frequency()` | `sound$get_sampling_frequency()` |
| `To Pitch...` | `to_pitch()` | `sound$to_pitch()` |
| `To Formant (burg)...` | `to_formant_burg()` | `sound$to_formant_burg()` |
| `Extract part...` | `extract_part()` | `sound$extract_part()` |
| `Scale intensity...` | `scale_intensity()` | `sound$scale_intensity()` |
| `Down to Matrix` | `as_matrix()` | `spectrogram$as_matrix()` |
| `Save as WAV file...` | `save()` | `sound$save()` |

### Consistency Rules

1. **Query methods**: `get_*` → returns value
2. **Transformation methods**: `to_*` → returns new object
3. **Extraction methods**: `extract_*` → returns new object of same type
4. **Modification methods**: `*` (no prefix) → modifies in place
5. **Export methods**: `as_*` → converts to R type (data.frame, matrix)
6. **I/O methods**: `save()` → writes to file, `$new(path)` reads from file

---

## C++ Implementation Patterns

### XPtr Pattern

```cpp
// Finalizer
void sound_finalizer(structSound* sound) {
    if (sound != nullptr) {
        forget(sound);
    }
}

// Creation
// [[Rcpp::export(.sound_new)]]
Rcpp::XPtr<structSound> sound_new(std::string path) {
    try {
        autoSound sound = Sound_readFromSoundFile(Melder_peek8to32(path.c_str()));
        structSound* ptr = sound.releaseToAmbiguousOwner();
        return Rcpp::XPtr<structSound>(ptr, true, sound_finalizer);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to read sound from: " + path);
    }
}

// Query
// [[Rcpp::export(.sound_get_duration)]]
double sound_get_duration(Rcpp::XPtr<structSound> xptr) {
    if (!xptr) Rcpp::stop("Invalid Sound pointer");
    structSound* sound = xptr.get();
    return sound->xmax - sound->xmin;
}

// Transformation
// [[Rcpp::export(.sound_to_pitch)]]
Rcpp::XPtr<structPitch> sound_to_pitch(
    Rcpp::XPtr<structSound> sound_xptr,
    double time_step,
    double pitch_floor,
    double pitch_ceiling
) {
    if (!sound_xptr) Rcpp::stop("Invalid Sound pointer");
    
    try {
        autoPitch pitch = Sound_to_Pitch(
            sound_xptr.get(),
            time_step,
            pitch_floor,
            pitch_ceiling
        );
        structPitch* ptr = pitch.releaseToAmbiguousOwner();
        return Rcpp::XPtr<structPitch>(ptr, true, pitch_finalizer);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract pitch");
    }
}
```

### R6 Pattern

```r
Sound <- R6Class("Sound",
    inherit = PraatObject,
    
    public = list(
        initialize = function(path = NULL, .xptr = NULL) {
            if (!is.null(.xptr)) {
                private$ptr <- .xptr
            } else if (!is.null(path)) {
                private$ptr <- .sound_new(path)
            } else {
                stop("Provide either path or .xptr")
            }
        },
        
        get_duration = function() {
            .sound_get_duration(private$ptr)
        },
        
        to_pitch = function(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600) {
            pitch_ptr <- .sound_to_pitch(private$ptr, time_step, pitch_floor, pitch_ceiling)
            Pitch$new(.xptr = pitch_ptr)
        },
        
        print = function() {
            cat("<Praat Sound>\n")
            cat(sprintf("  Duration: %.3f s\n", self$get_duration()))
            cat(sprintf("  Sampling frequency: %.0f Hz\n", self$get_sampling_frequency()))
            invisible(self)
        }
    ),
    
    private = list(
        ptr = NULL,
        finalize = function() {
            private$ptr <- NULL  # XPtr finalizer handles cleanup
        }
    )
)
```

---

## Success Criteria

### Technical
- ✅ All 12+ core Praat objects implemented as R6 classes
- ✅ 200+ methods exposed across all objects
- ✅ Zero memory leaks (valgrind clean)
- ✅ Test coverage >90% (R) and >80% (C++)
- ✅ Performance within 10% of native Praat

### Usability
- ✅ Intuitive OOP API matching Praat's object model
- ✅ Clear documentation with 50+ examples
- ✅ 7+ comprehensive vignettes
- ✅ Migration guides from Praat scripts and Parselmouth

### Completeness
- ✅ All Python Parselmouth examples from superassp re-implemented
- ✅ TextGrid full support (read, write, manipulate)
- ✅ Voice quality analysis (jitter, shimmer, HNR)
- ✅ Pitch manipulation (PSOLA via Manipulation)
- ✅ Spectral analysis (Spectrogram, Spectrum, LPC)

---

## Maintenance Plan

### Code Organization
```
R/
  praat-object-base.R          # Base PraatObject class
  sound-r6.R                   # Sound class
  pitch-r6.R                   # Pitch class
  formant-r6.R                 # Formant class
  intensity-r6.R               # Intensity class
  textgrid-r6.R                # TextGrid + tier classes
  spectrogram-r6.R             # Spectrogram class
  spectrum-r6.R                # Spectrum class
  manipulation-r6.R            # Manipulation class
  pointprocess-r6.R            # PointProcess class
  harmonicity-r6.R             # Harmonicity class
  lpc-r6.R                     # LPC class
  voice-report-r6.R            # VoiceReport class
  utils-r6.R                   # Shared utilities

src/
  praat_xptr_utils.cpp         # XPtr management
  praat_error_handling.cpp     # Error bridge
  sound_wrappers.cpp           # Sound methods
  pitch_wrappers.cpp           # Pitch methods
  formant_wrappers.cpp         # Formant methods
  intensity_wrappers.cpp       # Intensity methods
  textgrid_wrappers.cpp        # TextGrid methods
  spectrogram_wrappers.cpp     # Spectrogram methods
  spectrum_wrappers.cpp        # Spectrum methods
  manipulation_wrappers.cpp    # Manipulation methods
  pointprocess_wrappers.cpp    # PointProcess methods
  harmonicity_wrappers.cpp     # Harmonicity methods
  lpc_wrappers.cpp             # LPC methods
  voice_report_wrappers.cpp    # VoiceReport methods

inst/
  examples/                    # Re-implemented Python examples
  extdata/                     # Sample audio and TextGrid files
  
tests/
  testthat/                    # Unit tests
  benchmarks/                  # Performance tests
  validation/                  # Comparison with Praat/Parselmouth
```

---

## Timeline Summary

| Week | Phase | Deliverable |
|------|-------|-------------|
| 1-2 | Foundation | Base PraatObject, XPtr infrastructure |
| 2-3 | Sound | Complete Sound R6 class |
| 3-5 | Analysis Objects | Pitch, Formant, Intensity, Harmonicity |
| 5-6 | TextGrid | Full TextGrid support |
| 6-7 | Spectral | Spectrogram, Spectrum, LPC |
| 7-8 | Advanced | Manipulation, PointProcess, VoiceReport |
| 8-9 | Tiers | PitchTier, FormantTier, etc. |
| 9-10 | Examples | Re-implement superassp Python code |
| 10-11 | Documentation | Vignettes and reference docs |
| 11-12 | Validation | Testing, benchmarks, CRAN prep |

**Total: 12 weeks to 100% implementation**

---

## Conclusion

This plan transforms the speaker package into a complete, object-oriented interface to Praat that:

1. **Mirrors Praat's native design**: R6 objects with persistent C++ state
2. **Matches Parselmouth's approach**: Proven architecture, adapted for R
3. **Exposes full functionality**: 12+ objects, 200+ methods
4. **Enables R-native Praat workflows**: No Python dependency
5. **Provides migration paths**: From both Praat scripts and Parselmouth

The focus shifts from "implementing procedures" to "exposing objects and their methods", making the package intuitive for users familiar with Praat while leveraging R's strengths.
