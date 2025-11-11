# OOP Paradigm Assessment and Comprehensive Amendment
**Date**: 2025-11-11  
**Status**: Strategic Re-alignment  
**Purpose**: Reassess implementation against Praat's native OOP architecture

## Executive Summary

The current implementation has made excellent progress with R6 classes for core Praat objects (Sound, Pitch, Formant, Intensity, TextGrid, Manipulation, etc.). However, a systematic review reveals areas where the approach needs refinement to better mirror Praat's object-oriented design and enable seamless code transcoding from Praat scripts to R.

## Current State Assessment

### ✅ What's Working Well

1. **R6 Architecture**: All major classes use R6 with external pointers to C++ Praat objects
2. **Memory Management**: XPtr finalizers properly manage Praat object lifecycle
3. **Core Objects Implemented**:
   - Sound (comprehensive, ~40+ methods)
   - Pitch (~20 methods)
   - Formant (~15 methods)
   - Intensity (~12 methods)
   - Harmonicity
   - TextGrid (full tier/interval/point management)
   - Manipulation (pitch/duration modification)
   - PointProcess
   - PitchTier, IntensityTier, DurationTier
   - Ltas
   - Spectrogram (partial)

4. **Integration with R Ecosystem**: av package integration for media loading
5. **Naming Conventions**: Generally consistent get_*/to_* pattern

### ⚠️ Areas Needing Alignment

1. **Incomplete Object Coverage**: Missing critical Praat objects
   - Spectrum (spectral analysis)
   - FormantGrid (formant manipulation)
   - Table (data export/manipulation)
   - Some Tier types (FormantTier)

2. **Method Coverage Gaps**: Some objects missing key methods
   - Sound: Missing some modification methods (filtering variants, etc.)
   - Pitch: Missing smoothing/interpolation methods
   - Formant: Missing formant tracking
   - TextGrid: Potentially missing some boundary manipulation methods

3. **Naming Consistency**: Need systematic review to ensure all methods match Praat's conventions
   - Some methods may use R-style names instead of Praat-style names
   - Need consistent unit handling (Hertz vs Hz, etc.)

4. **Documentation of Praat Equivalents**: Each method should document the equivalent Praat menu command or script function

5. **Parselmouth Migration Path**: Need clear examples showing Python → R conversion

## Praat's Object-Oriented Structure

### Core Principle

Praat is fundamentally OOP with a class hierarchy:

```
Thing (base class)
├── Daata
│   ├── Function
│   │   ├── Sampled
│   │   │   ├── Sound
│   │   │   ├── Pitch
│   │   │   ├── Intensity
│   │   │   ├── Formant
│   │   │   ├── Spectrogram
│   │   │   ├── Harmonicity
│   │   │   └── Ltas
│   │   └── Matrix
│   ├── Collection
│   │   └── Ordered
│   │       └── SortedSetOfObject
│   │           └── TextGrid
│   └── PointProcess
└── Data
    ├── Manipulation
    ├── PitchTier
    ├── IntensityTier
    ├── DurationTier
    ├── FormantGrid
    └── Spectrum
```

### Object Methods in Praat

Each Praat object has three types of operations:

1. **Query methods**: Extract information (e.g., `Get duration`, `Get mean`, `Get value at time`)
2. **Modification methods**: Change the object (e.g., `Scale intensity`, `Filter (pass Hann band)`)
3. **Transformation methods**: Create new objects (e.g., `To Pitch...`, `To Spectrogram...`)

## Praat Script → R Code Mapping

### Desired Translation Pattern

**Praat Script**:
```praat
sound = Read from file: "audio.wav"
pitch = To Pitch: 0.0, 75, 600
meanF0 = Get mean: 0, 0, "Hertz"
```

**R (speaker package)**:
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600)
meanF0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
```

### Key Principles for Mapping

1. **Praat objects → R6 classes**: `sound` variable in Praat ↔ `sound` variable in R
2. **Praat commands → R6 methods**: `To Pitch` → `$to_pitch()`
3. **Praat query → get_* methods**: `Get mean` → `$get_mean()`
4. **Parameter names**: Use descriptive R-style names (pitch_floor vs pitchFloor)
5. **Return types**: Praat objects return R6 objects, values return R scalars/vectors

## Parselmouth → speaker Migration

### Python (Parselmouth) Style

```python
import parselmouth as pm

# Load sound
sound = pm.Sound("audio.wav")

# Extract features
pitch = sound.to_pitch(pitch_floor=75, pitch_ceiling=600)
formant = sound.to_formant_burg(max_formant=5500)

# Query values
mean_f0 = pitch.get_mean(unit='Hertz')
f1_at_500ms = formant.get_value_at_time(1, 0.5)

# Use call interface for complex operations
point_process = pm.praat.call(sound, "To PointProcess (periodic, cc)", 75, 600)
jitter = pm.praat.call([sound, point_process], "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)
```

### R (speaker) Equivalent

```r
library(speaker)

# Load sound (any format via av)
sound <- Sound$new("audio.wav")

# Extract features - same methods as Parselmouth
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant = 5500)

# Query values - same methods as Parselmouth
mean_f0 <- pitch$get_mean(unit = "Hertz")
f1_at_500ms <- formant$get_value_at_time(formant_number = 1, time = 0.5)

# Native methods instead of call interface
point_process <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)
jitter <- point_process$get_jitter_local(sound, 
                                          period_floor = 0.0001, 
                                          period_ceiling = 0.02, 
                                          max_period_factor = 1.3)
```

## Method Naming Convention Standard

### Comprehensive Rules

| Praat Pattern | R6 Method Pattern | Example |
|---------------|-------------------|---------|
| `Get [property]` | `get_[property]()` | `Get duration` → `get_duration()` |
| `Get [property] at time` | `get_[property]_at_time(time, ...)` | `Get value at time` → `get_value_at_time(time)` |
| `Get [property] at [location]` | `get_[property]_at_[location](...)` | `Get value at sample` → `get_value_at_sample(sample)` |
| `Get mean [property]` | `get_mean_[property]()` or `get_mean()` | `Get mean` → `get_mean()` |
| `Get minimum [property]` | `get_minimum_[property]()` or `get_minimum()` | `Get minimum` → `get_minimum()` |
| `Get maximum [property]` | `get_maximum_[property]()` or `get_maximum()` | `Get maximum` → `get_maximum()` |
| `Get standard deviation` | `get_standard_deviation()` | Praat: `Get standard deviation` |
| `Get quantile` | `get_quantile(q)` | Praat: `Get quantile` |
| `Get time of minimum` | `get_time_of_minimum()` | Praat: `Get time of minimum` |
| `Get time of maximum` | `get_time_of_maximum()` | Praat: `Get time of maximum` |
| `To [Object]` | `to_[object]()` | `To Pitch` → `to_pitch()` |
| `To [Object] ([method])` | `to_[object]_[method]()` | `To Formant (burg)` → `to_formant_burg()` |
| `To [Object] ([method], [variant])` | `to_[object]_[method]_[variant]()` | `To Pitch (ac)` → `to_pitch_ac()` |
| `Extract [subset]` | `extract_[subset]()` | `Extract part` → `extract_part()` |
| `Extract [tier/component]` | `extract_[component]()` | `Extract pitch tier` → `extract_pitch_tier()` |
| `Scale [property]` | `scale_[property](value)` | `Scale intensity` → `scale_intensity(db)` |
| `Multiply [property]` | `multiply_[property](factor)` | `Multiply frequencies` → `multiply_frequencies(factor)` |
| `Filter [type]` | `filter_[type]()` | `Filter (pass Hann band)` → `filter_pass_hann_band()` |
| `Set [property]` | `set_[property](value)` | `Set interval text` → `set_interval_text()` |
| `Insert [item]` | `insert_[item](...)` | `Insert boundary` → `insert_boundary()` |
| `Remove [item]` | `remove_[item](...)` | `Remove boundary` → `remove_boundary()` |
| `Add [item]` | `add_[item](...)` | `Add interval tier` → `add_interval_tier()` |
| `Down to [R type]` | `as_[type]()` | `Down to Table` → `as_data_frame()` |
| `Down to [Praat type]` | `down_to_[type]()` | `Down to PitchTier` → `down_to_pitch_tier()` |
| `Save as [format] file` | `save(path, format)` | `Save as WAV file` → `save(path, "wav")` |
| `Write to [format] file` | `save(path, format)` | `Write to WAV file` → `save(path, "wav")` |
| `Read from file` | `$new(path)` | Constructor |
| `Create [type]` | `$create_[type](...)` | Static factory method |

### Parameter Naming

Convert Praat's UI-friendly names to R-friendly names:

| Praat Parameter | R Parameter | Notes |
|-----------------|-------------|-------|
| `Time range (s)` | `from_time`, `to_time` | Split range into two parameters |
| `Pitch floor (Hz)` | `pitch_floor` | Lowercase with underscore |
| `Pitch ceiling (Hz)` | `pitch_ceiling` | Include unit in docs, not name |
| `Maximum formant (Hz)` | `max_formant` or `max_formant_hz` | Shorter is better if unambiguous |
| `Number of formants` | `num_formants` or `number_of_formants` | Prefer num_ for counts |
| `Time step (s)` | `time_step` | |
| `Window length (s)` | `window_length` | |
| `Pre-emphasis from (Hz)` | `pre_emphasis_from` | |

### Unit Handling

- Document units in parameter descriptions
- Accept common variations: "Hertz", "Hz", "hertz", "hz" (convert internally)
- Return values should have units in attributes where applicable

## Missing Objects and Methods - Priority List

### Priority 1: Critical Missing Objects

#### 1. Spectrum (Frequency domain analysis)
**Methods needed**:
- `$new(.xptr)` - From transformation
- `$get_power_at(frequency)` - Power at frequency
- `$get_real_at(frequency)`, `$get_imaginary_at(frequency)`
- `$get_band_energy(from_freq, to_freq)`
- `$get_centre_of_gravity()` - Spectral moments
- `$get_standard_deviation()`, `$get_skewness()`, `$get_kurtosis()`
- `$filter(from_freq, to_freq)` - Filter spectrum
- `$to_sound()` - Inverse FFT
- `$to_ltas()` - Long-term average
- `$as_data_frame()`, `$as_matrix()`

**Praat equivalent**: Spectrum object, created by `To Spectrum...`

#### 2. FormantGrid (Formant manipulation)
**Methods needed**:
- `$new(.xptr)` - From Formant
- `$add_formant_point(formant_number, time, frequency)`
- `$add_bandwidth_point(formant_number, time, bandwidth)`
- `$remove_formant_points_between(formant_number, from_time, to_time)`
- `$get_formant_at_time(formant_number, time)`
- `$get_bandwidth_at_time(formant_number, time)`
- `$to_formant(time_step)`

**Praat equivalent**: FormantGrid object

#### 3. Table (Data export)
**Methods needed**:
- `$new(.xptr)` - From Down to Table operations
- `$get_number_of_rows()`, `$get_number_of_columns()`
- `$get_column_names()`
- `$get_value(row, column)`
- `$set_value(row, column, value)`
- `$as_data_frame()` - Primary export method
- `$save(path)` - Save as text table

**Praat equivalent**: Table object

### Priority 2: Method Completions

#### Sound - Missing Methods
- `$get_minimum()`, `$get_maximum()` - Amplitude extrema
- `$get_absolute_extremum()` - Max absolute value
- `$get_nearest_zero_crossing(time)` - For segmentation
- `$set_value_at_sample(sample, channel, value)` - Modification
- `$formula(expression, from_time, to_time)` - Praat's Formula... command
- `$combine_to_stereo(other_sound)` - Create stereo from two mono
- `$convert_to_mono()` - Mix down to mono
- `$resample(new_rate)` - Change sampling rate
- `$lengthen_overlap_add(factor, max_freq)` - Duration modification
- `$deepen_band_modulation(...)` - Advanced modification

#### Pitch - Missing Methods
- `$interpolate()` - Fill unvoiced frames
- `$smooth(bandwidth)` - Smooth F0 contour
- `$subtract_linear_fit()` - Detrending
- `$kill_octave_jumps()` - Octave error correction
- `$down_to_pitch_tier()` - Convert to editable tier
- `$to_pointprocess()` - Extract voiced frames as points

#### Formant - Missing Methods
- `$track(num_tracks, ref_f1, ref_f2, ref_f3, ref_f4, ref_f5, ...)` - Formant tracking
- `$down_to_formant_grid()` - Convert to editable grid
- `$extract_one_formant(formant_number)` - Extract single formant as Intensity-like object
- `$formula(formant_number, expression)` - Apply formula to formant

#### Intensity - Missing Methods
- `$subtract_mean()` - Center at 0
- `$multiply(factor)` - Scale intensity
- `$down_to_matrix()` - Convert to matrix

#### TextGrid - Additional Methods
- `$insert_interval_tier(position, name)` - Insert at specific position
- `$replace_interval_text(tier_name, search, replace, regex)` - Bulk text replacement
- `$extend_time(duration, end)` - Extend time range
- `$scale_times(factor)` - Scale all times
- `$count_labels(tier_name, label)` - Count matching labels

#### Manipulation - Additional Methods
- `$get_duration()` - Get duration
- `$set_duration(duration)` - Set duration
- `$replace_intensity_tier(tier)` - Intensity modification
- `$get_resynthesis_lpc()` - LPC resynthesis (alternative to PSOLA)

### Priority 3: Advanced Objects (Future)

#### LPC (Linear Predictive Coding)
- For advanced speech analysis
- Less commonly used, lower priority

#### Excitation (Source modeling)
- Specialized voice quality analysis
- Lower priority

#### Cochleagram (Auditory model)
- Perceptual modeling
- Lower priority

## Implementation Action Plan

### Phase 1: Method Documentation Audit (Week 1)
**Goal**: Ensure all existing methods are properly documented with Praat equivalents

**Tasks**:
1. Review every R6 method in all classes
2. Add `@section Praat Equivalent:` to Roxygen docs showing the Praat menu path or script command
3. Ensure parameter names and descriptions match Praat's conventions
4. Add examples showing Praat script → R translation

**Example documentation format**:
```r
#' @description
#' Get the mean pitch value over a time range
#' 
#' @param from_time Start time in seconds (0 = start of object)
#' @param to_time End time in seconds (0 = end of object)
#' @param unit Unit: "Hertz", "semitones", "mel", "erb"
#' 
#' @return Mean pitch value in specified unit
#' 
#' @section Praat Equivalent:
#' ```praat
#' meanF0 = Get mean: from_time, to_time, "Hertz"
#' ```
#' Or via menu: Query → Get mean...
#' 
#' @examples
#' pitch <- sound$to_pitch()
#' mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
```

### Phase 2: Complete Missing Methods (Weeks 2-3)
**Goal**: Fill in missing methods for existing objects

**Priority order**:
1. Sound methods (filtering, resampling, modification)
2. Pitch methods (interpolate, smooth, correction)
3. Formant methods (tracking - high priority for phonetics research)
4. Other object methods

**Deliverables**:
- Updated R6 class files with new methods
- Corresponding C++ wrappers
- Unit tests for each new method
- Documentation with Praat equivalents

### Phase 3: Implement Missing Objects (Weeks 3-5)
**Goal**: Add critical missing objects

**Implementation order**:
1. **Spectrum** (Week 3) - Essential for spectral analysis
   - C++ wrappers for all Spectrum methods
   - R6 class with full method coverage
   - Integration with Sound$to_spectrum() and Spectrogram$to_spectrum()
   - Unit tests and documentation

2. **Table** (Week 4) - Essential for data export
   - C++ wrappers for Table manipulation
   - R6 class with get/set/export methods
   - Integration with "Down to Table" operations from other objects
   - Unit tests and documentation

3. **FormantGrid** (Week 5) - For formant manipulation
   - C++ wrappers for FormantGrid methods
   - R6 class for formant editing
   - Integration with Formant$down_to_formant_grid()
   - Unit tests and documentation

### Phase 4: Parselmouth Migration Examples (Week 6)
**Goal**: Create comprehensive migration guide with examples

**Tasks**:
1. Create `inst/examples/` directory structure:
   ```
   inst/examples/
   ├── README.md                          # Overview of examples
   ├── PYTHON_TO_R_GUIDE.md              # Comprehensive translation guide
   ├── basic/
   │   ├── 01_loading_audio.R
   │   ├── 02_pitch_extraction.R
   │   ├── 03_formant_extraction.R
   │   └── 04_textgrid_annotation.R
   ├── intermediate/
   │   ├── voice_quality_analysis.R       # From praat_voice_report_memory.py
   │   ├── pitch_tracking_comparison.R    # From praat_pitch.py
   │   ├── formant_tracking.R             # From praat_formant_burg.py
   │   ├── intensity_analysis.R           # From praat_intensity.py
   │   └── spectral_moments.R             # From praat_spectral_moments.py
   └── advanced/
       ├── pitch_manipulation.R
       ├── avqi_calculation.R             # From praat_avqi_memory.py
       ├── dsi_calculation.R              # From praat_dsi_memory.py
       ├── formant_path.R                 # From praat_formantpath_burg.py
       └── voice_tremor.R                 # From praat_voice_tremor_memory.py
   ```

2. Each example file includes:
   - Original Python code (commented)
   - Equivalent R code
   - Explanation of differences
   - Performance notes

**Example template** (voice_quality_analysis.R):
```r
#' Voice Quality Analysis
#' 
#' This example demonstrates how to compute comprehensive voice quality metrics
#' using the speaker package. It replicates the functionality of 
#' praat_voice_report_memory.py from the superassp package.
#' 
#' @section Original Python (Parselmouth):
#' ```python
#' import parselmouth as pm
#' 
#' sound = pm.Sound("voice.wav")
#' pitch = sound.to_pitch()
#' point_process = pm.praat.call(sound, "To PointProcess (periodic, cc)", 75, 600)
#' 
#' jitter_local = pm.praat.call([sound, point_process], "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)
#' shimmer_local = pm.praat.call([sound, point_process], "Get shimmer (local)", 0, 0, 0.0001, 0.02, 1.3, 1.6)
#' ```
#' 
#' @section Equivalent R (speaker):

library(speaker)

# Load sound (supports any format via av package)
sound <- Sound$new("voice.wav")

# Method 1: Use integrated voice report
# This computes all metrics at once (more efficient)
report <- sound$voice_report(
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_period_factor = 1.3
)

# Access individual metrics
jitter_local <- report$get_jitter_local()
shimmer_local <- report$get_shimmer_local()
mean_hnr <- report$get_mean_hnr()

# Print all metrics
print(report$as_data_frame())

# Method 2: Compute metrics individually
# This provides more control over each step
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
point_process <- sound$to_point_process_periodic_cc(
  pitch_floor = 75,
  pitch_ceiling = 600
)

# Jitter calculations (multiple variants)
jitter_local <- point_process$get_jitter_local(
  sound,
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3
)

jitter_rap <- point_process$get_jitter_rap(sound, 0.0001, 0.02, 1.3)
jitter_ppq5 <- point_process$get_jitter_ppq5(sound, 0.0001, 0.02, 1.3)

# Shimmer calculations
shimmer_local <- point_process$get_shimmer_local(
  sound,
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)

shimmer_apq3 <- point_process$get_shimmer_apq3(sound, 0.0001, 0.02, 1.3, 1.6)
shimmer_apq5 <- point_process$get_shimmer_apq5(sound, 0.0001, 0.02, 1.3, 1.6)

# Harmonics-to-Noise Ratio
harmonicity <- sound$to_harmonicity_cc(time_step = 0.01, min_pitch = 75)
mean_hnr <- harmonicity$get_mean()

# Combine into data frame
results <- data.frame(
  jitter_local = jitter_local,
  jitter_rap = jitter_rap,
  jitter_ppq5 = jitter_ppq5,
  shimmer_local = shimmer_local,
  shimmer_apq3 = shimmer_apq3,
  shimmer_apq5 = shimmer_apq5,
  mean_hnr = mean_hnr,
  mean_f0 = pitch$get_mean()
)

print(results)

#' @section Key Differences:
#' 
#' 1. **No pm.praat.call() needed**: All functionality is available as native R6 methods
#' 2. **Type safety**: R6 methods provide better autocomplete and type checking
#' 3. **Integrated reports**: VoiceReport object computes all metrics efficiently
#' 4. **Format flexibility**: Sound$new() accepts any audio format via av package
#' 5. **Memory efficiency**: Objects are managed automatically via R6 finalizers
```

### Phase 5: Create Migration Guide Vignette (Week 6)
**Goal**: Comprehensive vignette for Praat and Parselmouth users

**Vignette outline**:
```
vignettes/migrating-to-speaker.Rmd
├── Introduction
├── From Praat Scripts
│   ├── Basic syntax mapping
│   ├── Object creation and manipulation
│   ├── Common workflows
│   └── Script translation examples
├── From Parselmouth (Python)
│   ├── Import → library() mapping
│   ├── Object creation comparison
│   ├── Method calling conventions
│   ├── The praat.call() interface (why it's not needed)
│   └── Complete example translations
├── Audio Format Support
│   ├── Native Praat formats (WAV)
│   ├── av package integration (MP3, OGG, FLAC, etc.)
│   └── Performance considerations
├── Advanced Topics
│   ├── Memory management differences
│   ├── Error handling
│   ├── Performance optimization
│   └── Extending with custom methods
└── Common Pitfalls and Solutions
```

### Phase 6: Systematic Testing and Validation (Week 7)
**Goal**: Ensure all functionality matches Praat's behavior

**Tasks**:
1. **Cross-validation tests**:
   - Run same analysis in Praat Desktop, Parselmouth, and speaker
   - Compare output numerically (within floating-point tolerance)
   - Document any differences

2. **Edge case testing**:
   - Empty/silent sounds
   - Very short sounds
   - Extreme parameter values
   - Unvoiced speech

3. **Integration testing**:
   - Complete analysis pipelines
   - Multi-object workflows
   - Large file handling

4. **Benchmark testing**:
   - Compare performance to Praat Desktop
   - Compare performance to Parselmouth
   - Identify and optimize bottlenecks

### Phase 7: Documentation Polish (Week 8)
**Goal**: Comprehensive, user-friendly documentation

**Deliverables**:
1. **Update all Rd files**:
   - Add Praat equivalent sections
   - Include more examples
   - Cross-reference related methods

2. **Create/update vignettes**:
   - Getting started
   - Pitch analysis workflows
   - Formant analysis workflows  
   - TextGrid annotation
   - Voice quality analysis
   - Pitch manipulation
   - Spectral analysis
   - Migration guides (Praat, Parselmouth)

3. **Update README.md**:
   - Clear feature comparison vs Praat/Parselmouth
   - Installation instructions
   - Quick start examples
   - Link to vignettes and examples

4. **Create CITATION file**:
   - Proper citation format
   - Link to paper (when published)

## Success Criteria

### Technical Completeness
- [ ] All core Praat objects implemented as R6 classes (16+ objects)
- [ ] 90%+ method coverage for implemented objects
- [ ] All methods documented with Praat equivalents
- [ ] Zero memory leaks (valgrind clean)
- [ ] All tests passing on Windows, macOS, Linux

### Usability
- [ ] Every method has clear Praat equivalent in docs
- [ ] 20+ working examples in inst/examples/
- [ ] 8+ comprehensive vignettes
- [ ] Clear migration guides for Praat and Parselmouth users
- [ ] Consistent naming across all objects

### Validation
- [ ] Output matches Praat Desktop (within tolerance)
- [ ] Output matches Parselmouth (within tolerance)
- [ ] All superassp Python examples have R equivalents
- [ ] Performance within 20% of Praat Desktop

## Timeline Summary

| Week | Phase | Deliverable |
|------|-------|-------------|
| 1 | Documentation Audit | All methods documented with Praat equivalents |
| 2-3 | Method Completion | Missing methods added to existing objects |
| 3-5 | New Objects | Spectrum, Table, FormantGrid implemented |
| 6 | Examples | All superassp examples reimplemented in R |
| 6 | Migration Guide | Comprehensive Praat/Parselmouth → R guide |
| 7 | Testing/Validation | Cross-validation, benchmarks, edge cases |
| 8 | Documentation | Vignettes, README, CITATION |

**Total**: 8 weeks to complete OOP-aligned implementation

## Decision Log

### Key Decisions for Future Integration

1. **Object Addition Process**:
   - Always start with Praat source code analysis (fon/*.h files)
   - Identify complete method set before implementation
   - Implement R6 class with all methods, not incremental
   - Document Praat equivalent for every method
   - Write tests comparing to Praat Desktop output

2. **Naming Convention Enforcement**:
   - Use automated checks for naming consistency
   - Maintain mapping table: Praat command → R method
   - Review all method names for consistency quarterly

3. **Praat Script Interpreter** (Future Extension):
   - **Status**: Deferred
   - **Rationale**: Focus on native R6 API first
   - **Future**: Could add `praat_script()` function to execute Praat scripts directly
   - **Implementation approach**: Embed Praat's script interpreter, map objects to R6 instances
   - **Priority**: Low (most users prefer native R code)

4. **Picture/Plotting Functionality** (Future Extension):
   - **Status**: Deferred
   - **Rationale**: R has superior plotting (ggplot2, etc.)
   - **Future**: Could add `$draw()` methods that use R graphics
   - **Implementation approach**: Convert Praat's Picture commands to R graphics calls
   - **Priority**: Low (R plotting ecosystem is sufficient)

5. **Audio Format Support**:
   - **Decision**: Use av package for all non-WAV formats
   - **Rationale**: Leverages FFmpeg, supports 100+ formats
   - **Implementation**: Sound$new() detects format and routes to av if needed
   - **Performance**: Negligible overhead, FFmpeg is highly optimized

6. **Memory Management**:
   - **Decision**: XPtr with finalizers for all Praat objects
   - **Rationale**: Automatic, safe, R-like behavior
   - **Implementation**: Every R6 class has private$ptr that's XPtr with finalizer
   - **Testing**: Use valgrind to verify no leaks

7. **Error Handling**:
   - **Decision**: Catch MelderError in C++, convert to Rcpp::stop()
   - **Rationale**: R users expect R errors, not C++ crashes
   - **Implementation**: try/catch around all Praat calls
   - **Messages**: Preserve Praat's error messages when helpful

## Next Steps

1. **Immediate** (Today):
   - Review this amendment with stakeholders
   - Prioritize Phase 1 (documentation audit) vs Phase 2 (method completion)
   - Identify which missing object is most critical (likely Spectrum)

2. **This Week**:
   - Begin Phase 1 or Phase 2 based on priority decision
   - Set up systematic review process for method naming
   - Create example template files

3. **Next Week**:
   - Continue implementation phases
   - Begin validation testing setup
   - Draft first migration guide examples

## Conclusion

This amendment refines the implementation strategy to ensure the speaker package:

1. **Faithfully mirrors Praat's OOP architecture** - Making code translation natural
2. **Provides complete object coverage** - Not just isolated procedures
3. **Maintains consistent naming** - Enabling predictable API usage
4. **Supports seamless migration** - From both Praat and Parselmouth
5. **Remains well-documented** - Every method ties back to Praat
6. **Enables R-native workflows** - While preserving Praat's design

The goal is to make speaker the definitive Praat interface for R, just as Parselmouth is for Python, with the added benefit of direct C++ integration without Python dependency.

---

**Document Status**: Ready for implementation  
**Next Review**: After Phase 1 completion  
**Updated**: 2025-11-11
