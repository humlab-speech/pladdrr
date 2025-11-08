# Complete Object-Oriented Implementation Plan for Praat R Package

**Date**: 2025-11-08  
**Focus**: Expose Praat's complete object hierarchy in R, not just specific procedures  
**Inspiration**: Parselmouth Python library + Praat's native C++ architecture

## Executive Summary

This plan shifts from implementing specific acoustic procedures to **exposing Praat objects and their methods** in R. The goal is to allow R users to write code that mirrors Praat scripting directly, accessing the full power of the Praat codebase without going through Python.

### Key Insight from Parselmouth Analysis

The Python `parselmouth` library succeeds because it:
1. **Wraps Praat objects** (Sound, Pitch, Formant, etc.) as Python classes
2. **Exposes object methods** (`.to_pitch()`, `.get_mean()`, etc.) not standalone functions
3. **Uses `pm.praat.call()`** to access any Praat command generically
4. **Maintains object references** via pointers to C++ Praat objects

Our R package should follow this exact pattern using R6 classes and external pointers.

## Current Implementation Status

### ✅ Completed (Partial OOP Implementation)
- **PraatObject** base class (R6) with external pointer management
- **Sound** R6 class with:
  - Creation from file/values
  - Basic query methods (`get_duration()`, `get_sampling_frequency()`)
  - Transformation methods (`to_pitch()`, `to_formant_burg()`, `to_intensity()`)
- **Pitch** R6 class with:
  - Query methods (`get_mean()`, `get_value_at_time()`, etc.)
  - Export to data.frame
- C++ wrappers for Sound, Pitch, Formant operations

### ❌ Missing Critical Objects

From the Parselmouth examples and Praat codebase, we need:

1. **TextGrid** - Annotation/segmentation (CRITICAL for phonetic research)
2. **Spectrogram** - Time-frequency analysis
3. **Spectrum** - Frequency domain representation
4. **Harmonicity** - HNR analysis
5. **PointProcess** - Event detection (glottal pulses, etc.)
6. **Manipulation** - PSOLA pitch/duration modification
7. **LPC** - Linear predictive coding
8. **Formant advanced objects**:
   - FormantPath (optimal ceiling finding)
   - FormantTier (pitch-synchronous formants)
9. **Tier objects** for annotation:
   - PitchTier
   - IntensityTier
   - DurationTier
10. **Voice quality metrics**:
    - Jitter/Shimmer calculations
    - Voice reports
11. **Spectral moments** (COG, spectral tilt, etc.)

### ❌ Missing Generic Praat Call Mechanism

Parselmouth has `pm.praat.call(object, "Command", args...)` which allows:
- Calling ANY Praat command on any object
- Future-proofing (new Praat features work automatically)
- Fallback for edge cases

We need: `praat_call(object, command, ...args)`

## Amended Implementation Roadmap

### Phase 1: Complete Core Objects (2 weeks)

#### 1.1 Formant Object (Complete Implementation)
**Current**: Basic extraction only  
**Needed**:

```r
# R6 Class: Formant
formant <- sound$to_formant_burg(...)

# Query methods
formant$get_number_of_formants()
formant$get_number_of_frames()
formant$get_value_at_time(formant_number, time, unit = "Hertz")
formant$get_bandwidth_at_time(formant_number, time)
formant$get_mean(formant_number, from_time = 0, to_time = 0)
formant$get_minimum(formant_number, from_time = 0, to_time = 0)
formant$get_maximum(formant_number, from_time = 0, to_time = 0)
formant$get_quantile(formant_number, quantile, from_time = 0, to_time = 0)

# Transformation methods
formant_grid <- formant$to_formant_grid()
table <- formant$to_table(include_frame_numbers, include_times, ...)

# Export
df <- formant$as_data_frame()  # time, f1-f5, b1-b5
```

**C++ Implementation**:
- `formant_wrappers.cpp`: Add missing query methods
- Link to Praat's `Formant_getValueAtTime`, `Formant_getBandwidthAtTime`, etc.

#### 1.2 Intensity Object (Complete Implementation)
**Current**: Basic extraction only  
**Needed**:

```r
# R6 Class: Intensity
intensity <- sound$to_intensity(min_pitch = 100, time_step = 0)

# Query methods
intensity$get_value_at_time(time, interpolation = "Cubic")
intensity$get_mean(from_time = 0, to_time = 0)
intensity$get_minimum(from_time = 0, to_time = 0, interpolation = "Parabolic")
intensity$get_maximum(from_time = 0, to_time = 0, interpolation = "Parabolic")
intensity$get_quantile(quantile, from_time = 0, to_time = 0)
intensity$get_time_of_minimum(from_time = 0, to_time = 0)
intensity$get_time_of_maximum(from_time = 0, to_time = 0)

# Transformation methods
intensity_tier <- intensity$to_intensity_tier()

# Export
df <- intensity$as_data_frame()  # time, intensity_db
```

**C++ Implementation**:
- `intensity_wrappers.cpp`: Create new file
- Link to Praat's `Intensity` class methods

#### 1.3 Harmonicity Object (NEW)
**Purpose**: Harmonics-to-Noise Ratio analysis

```r
# R6 Class: Harmonicity
harmonicity <- sound$to_harmonicity_ac(time_step = 0.01, 
                                       min_pitch = 75, 
                                       silence_threshold = 0.1,
                                       periods_per_window = 1.0)

harmonicity <- sound$to_harmonicity_cc(time_step = 0.01,
                                       min_pitch = 75,
                                       silence_threshold = 0.1,
                                       periods_per_window = 1.0)

# Query methods
harmonicity$get_value_at_time(time, interpolation = "Cubic")
harmonicity$get_mean(from_time = 0, to_time = 0)
harmonicity$get_minimum(from_time = 0, to_time = 0)
harmonicity$get_maximum(from_time = 0, to_time = 0)

# Export
df <- harmonicity$as_data_frame()  # time, hnr_db
```

**C++ Implementation**:
- `harmonicity_wrappers.cpp`: Create new file
- Link to Praat's `Sound_to_Harmonicity_ac`, `Sound_to_Harmonicity_cc`

### Phase 2: Spectral Objects (2 weeks)

#### 2.1 Spectrum Object (NEW)
**Purpose**: Frequency-domain representation

```r
# R6 Class: Spectrum
spectrum <- sound$to_spectrum(fast = TRUE)

# Query methods
spectrum$get_center_of_gravity(power = 2)
spectrum$get_central_moment(moment, power = 2)
spectrum$get_standard_deviation(power = 2)
spectrum$get_skewness(power = 2)
spectrum$get_kurtosis(power = 2)
spectrum$get_band_energy(from_freq, to_freq)
spectrum$get_band_density(from_freq, to_freq)

# Transformation methods
ltas <- spectrum$to_ltas()
spectrogram <- spectrum$to_spectrogram()

# Export
df <- spectrum$as_data_frame()  # frequency, real, imaginary, power
```

**C++ Implementation**:
- `spectrum_wrappers.cpp`: Create new file
- Link to Praat's `Spectrum` class and spectral moment calculations

#### 2.2 Spectrogram Object (NEW)
**Purpose**: Time-frequency analysis

```r
# R6 Class: Spectrogram
spectrogram <- sound$to_spectrogram(window_length = 0.005,
                                    maximum_frequency = 5000,
                                    time_step = 0.002,
                                    frequency_step = 20,
                                    window_shape = "Gaussian")

# Query methods
spectrogram$get_power_at(time, frequency)
spectrogram$get_time_from_column(column)
spectrogram$get_frequency_from_row(row)

# Transformation methods
spectrum <- spectrogram$to_spectrum_slice(time)
ltas <- spectrogram$to_ltas()

# Export as matrix (time x frequency)
mat <- spectrogram$as_matrix()
```

**C++ Implementation**:
- `spectrogram_wrappers.cpp`: Create new file
- Link to Praat's `Sound_to_Spectrogram`

#### 2.3 LTAS Object (NEW)
**Purpose**: Long-term average spectrum

```r
# R6 Class: Ltas
ltas <- sound$to_ltas(bandwidth = 100)
ltas <- spectrogram$to_ltas()

# Query methods
ltas$get_bin_number_from_frequency(frequency)
ltas$get_frequency_from_bin_number(bin)
ltas$get_value_at_frequency(frequency)
ltas$get_minimum(from_freq, to_freq)
ltas$get_maximum(from_freq, to_freq)

# Export
df <- ltas$as_data_frame()  # frequency, power_db
```

### Phase 3: Annotation Objects (2 weeks) - CRITICAL

#### 3.1 TextGrid Object (NEW - HIGH PRIORITY)
**Purpose**: Time-aligned annotations (intervals and points)

From Praat codebase structure, TextGrid contains:
- **IntervalTier**: Segments with labels (e.g., phonemes, words)
- **PointTier**: Time points with labels (e.g., events)

```r
# R6 Class: TextGrid
textgrid <- TextGrid$new("annotation.TextGrid")
textgrid <- sound$to_textgrid(tier_names)

# Query methods
textgrid$get_number_of_tiers()
textgrid$get_tier_names()
textgrid$get_tier_type(tier_number)  # "interval" or "point"

# Interval tier queries
n_intervals <- textgrid$get_number_of_intervals(tier_number)
interval <- textgrid$get_interval_at_time(tier_number, time)
label <- textgrid$get_label_at_time(tier_number, time)
start_time <- textgrid$get_interval_start(tier_number, interval_number)
end_time <- textgrid$get_interval_end(tier_number, interval_number)

# Point tier queries
n_points <- textgrid$get_number_of_points(tier_number)
time <- textgrid$get_point_time(tier_number, point_number)
label <- textgrid$get_point_label(tier_number, point_number)

# Modification methods
textgrid$insert_interval_tier(name, position)
textgrid$insert_point_tier(name, position)
textgrid$set_interval_label(tier, interval, label)
textgrid$set_point_label(tier, point, label)
textgrid$insert_boundary(tier, time)

# Extraction
tier <- textgrid$extract_tier(tier_number)

# Export
df <- textgrid$as_data_frame(tier_number)  # start, end, label OR time, label
textgrid$save("output.TextGrid")
```

**C++ Implementation**:
- `textgrid_wrappers.cpp`: Create new file
- Link to Praat's `TextGrid`, `IntervalTier`, `TextTier` classes
- **Critical for phonetic research workflows**

#### 3.2 Tier Objects (NEW)
Support for modification tiers:

```r
# R6 Classes: PitchTier, IntensityTier, DurationTier, etc.
pitch_tier <- PitchTier$new()
pitch_tier$add_point(time, frequency)
pitch_tier$remove_point(point_number)
```

### Phase 4: Advanced Analysis Objects (2 weeks)

#### 4.1 PointProcess Object (NEW)
**Purpose**: Represent events in time (e.g., glottal pulses)

```r
# R6 Class: PointProcess
point_process <- sound$to_point_process_periodic_cc(min_pitch, max_pitch)

# Query methods
point_process$get_number_of_points()
point_process$get_time_from_index(index)
point_process$get_interval(point_index)
point_process$get_jitter_local(from_time, to_time, min_period, max_period)
point_process$get_jitter_rap(from_time, to_time, min_period, max_period)
point_process$get_jitter_ppq5(from_time, to_time, min_period, max_period)
point_process$get_shimmer_local(from_time, to_time, min_period, max_period)
point_process$get_shimmer_apq3(from_time, to_time, min_period, max_period)

# Export
df <- point_process$as_data_frame()  # point_number, time
```

**C++ Implementation**:
- `pointprocess_wrappers.cpp`: Create new file
- Link to Praat's jitter/shimmer calculations

#### 4.2 Manipulation Object (NEW)
**Purpose**: PSOLA-based pitch and duration modification

```r
# R6 Class: Manipulation
manipulation <- sound$to_manipulation(time_step, min_pitch, max_pitch)

# Extract components
pitch_tier <- manipulation$extract_pitch_tier()
duration_tier <- manipulation$extract_duration_tier()
point_process <- manipulation$extract_pulses()

# Modify
manipulation$replace_pitch_tier(new_pitch_tier)
manipulation$replace_duration_tier(new_duration_tier)

# Synthesize
modified_sound <- manipulation$to_sound()

# Export
manipulation$save("manipulation.Manipulation")
```

**C++ Implementation**:
- `manipulation_wrappers.cpp`: Create new file
- Link to Praat's `Sound_to_Manipulation`, PSOLA synthesis

#### 4.3 LPC Object (NEW)
**Purpose**: Linear Predictive Coding analysis

```r
# R6 Class: LPC
lpc <- sound$to_lpc_auto(order, window_length, time_step, pre_emphasis)

# Query methods
lpc$get_number_of_coefficients()
lpc$get_sampling_period()

# Transformation
formant <- lpc$to_formant(max_formant)
spectrum <- lpc$to_spectrum_slice(time, min_freq, max_freq)

# Export
df <- lpc$as_data_frame()
```

### Phase 5: FormantPath and Advanced Formant Analysis (1 week)

#### 5.1 FormantPath Object (NEW)
**Purpose**: Optimal formant ceiling finding (as used in Parselmouth example)

```r
# R6 Class: FormantPath
formant_path <- sound$to_formant_path_burg(
  time_step = 0.005,
  max_formant = 5500,
  window_length = 0.025,
  pre_emphasis = 50,
  ceiling_step_size = 0.05,
  number_of_steps = 4
)

# Query optimal ceiling
optimal_ceiling <- formant_path$get_optimal_ceiling()

# Extract formant with tracking
formant <- formant_path$extract_formant()
tracked_formant <- formant_path$track_formant(
  n_tracks = 3,
  ref_f1 = 550, ref_f2 = 1650, ref_f3 = 2750,
  frequency_cost = 1, bandwidth_cost = 1, transition_cost = 1
)
```

**C++ Implementation**:
- `formantpath_wrappers.cpp`: Create new file
- Link to Praat's `Sound_to_FormantPath_burg`

### Phase 6: Voice Quality and Composite Metrics (1 week)

#### 6.1 Voice Report (NEW)
**Purpose**: Comprehensive voice quality assessment

```r
# Composite analysis function
voice_report <- sound$get_voice_report(
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_period_factor = 1.3
)

# Returns list with:
# - Mean pitch, SD, min, max
# - Jitter (local, RAP, PPQ5)
# - Shimmer (local, APQ3, APQ5, APQ11)
# - HNR
# - Fraction of unvoiced frames
```

**C++ Implementation**:
- Add to `sound_wrappers.cpp`
- Combine multiple Praat analyses

### Phase 7: Generic Praat Call Interface (1 week)

#### 7.1 Universal `praat_call()` Function
**Purpose**: Call ANY Praat command generically (like Parselmouth)

```r
# Generic interface
result <- praat_call(object, "Command Name", arg1, arg2, ...)

# Examples matching Parselmouth pattern:
intensity <- praat_call(sound, "To Intensity", 100, 0, TRUE)
table <- praat_call(formant, "Down to Table", TRUE, TRUE, 6, TRUE, 3, TRUE)
filtered_sound <- praat_call(sound, "Filter (pass Hann band)", 500, 4000, 100)
```

**Implementation**:
- Use Praat's command interpreter
- Map R arguments to Praat types
- Return appropriate R6 object or value

**Benefits**:
- Future-proof: New Praat features work automatically
- Fallback for edge cases
- Allows direct Praat script translation

### Phase 8: Sound Modification Methods (1 week)

Complete the Sound object with modification methods:

```r
# Filtering
sound$filter_pass_hann_band(from_freq, to_freq, smoothing)
sound$filter_stop_hann_band(from_freq, to_freq, smoothing)
sound$filter_pre_emphasize(from_frequency)
sound$filter_de_emphasize(from_frequency)

# Amplitude modification
sound$scale_intensity(new_intensity_db)
sound$scale_peak(new_peak)
sound$multiply(factor)
sound$add(value)

# Time modification
sound$lengthen(factor)
sound$deepen_band_modulation(...)

# Conversion
sound$resample(new_frequency, precision)
sound$convert_to_mono()
sound$convert_to_stereo()

# Combining
combined <- sound1$concatenate(sound2)
mixed <- sound1$mix(sound2)
```

## Implementation Priority Order

### Immediate (Next 2 weeks):
1. **TextGrid** (CRITICAL - blocking phonetic research)
2. **Harmonicity** (needed for voice quality)
3. **Complete Formant** (missing query methods)
4. **Complete Intensity** (missing query methods)

### Short-term (Weeks 3-4):
5. **Spectrum** + **Spectrogram** (spectral analysis)
6. **PointProcess** (jitter/shimmer)
7. **FormantPath** (optimal formant tracking)

### Medium-term (Weeks 5-6):
8. **Manipulation** (PSOLA)
9. **LPC** analysis
10. **Generic praat_call()** interface

### Final polish (Week 7-8):
11. **Sound modification methods**
12. **Voice reports**
13. **Tier objects**
14. **Examples replicating superassp Python code**

## Technical Implementation Strategy

### C++ Architecture
Each Praat object type gets its own wrapper file:
- `textgrid_wrappers.cpp`
- `harmonicity_wrappers.cpp`
- `spectrum_wrappers.cpp`
- `spectrogram_wrappers.cpp`
- `pointprocess_wrappers.cpp`
- `manipulation_wrappers.cpp`
- `lpc_wrappers.cpp`
- `formantpath_wrappers.cpp`

### R6 Class Structure
```r
# Base class (already exists)
PraatObject <- R6Class("PraatObject",
  private = list(ptr = NULL),
  public = list(
    initialize = function(ptr) { private$ptr <- ptr },
    get_class_name = function() { ... }
  )
)

# Each derived class
Harmonicity <- R6Class("Harmonicity",
  inherit = PraatObject,
  public = list(
    get_value_at_time = function(...) { ... },
    get_mean = function(...) { ... },
    as_data_frame = function() { ... }
  )
)
```

### Consistent Naming Pattern (Already Established)
- **Query**: `get_[property]()` → `pitch$get_mean()`
- **Transform**: `to_[type]()` → `sound$to_pitch()`
- **Extract**: `extract_[subset]()` → `sound$extract_part()`
- **Export**: `as_[format]()` → `pitch$as_data_frame()`
- **Modify**: `[action]()` → `sound$scale_intensity()`

## Testing Strategy

### Unit Tests
For each object, test:
1. Creation from various sources
2. All query methods against known values
3. Transformations produce correct object types
4. Export produces correct data structures

### Integration Tests
1. Replicate Praat script examples from manual
2. Match output with Praat GUI results
3. Compare with Parselmouth Python results

### Examples from superassp Python Code
Reimplement each Python function using the R6 API:
- `praat_intensity.py` → R example using `Intensity` class
- `praat_formantpath_burg.py` → R example using `FormantPath` class
- Voice quality measures → R examples using composite functions

## Success Criteria

✅ **Complete OOP Coverage**: All major Praat object types accessible  
✅ **Praat Script Transcoding**: Praat scripts translate directly to R  
✅ **Zero Python Dependency**: No need for reticulate/parselmouth  
✅ **Efficient**: Zero-copy operations via external pointers  
✅ **Consistent API**: Predictable naming matching Praat's semantics  
✅ **Well-documented**: Roxygen2 docs with Praat → R examples  
✅ **Tested**: Comprehensive tests matching Praat/Parselmouth results  

## Documentation Requirements

For each R6 class, provide:
1. Class description linking to Praat manual section
2. Creation examples (from file, from analysis, from values)
3. Method documentation with Praat equivalents
4. Complete workflow examples
5. Praat script → R translation guide

Example documentation pattern:
```r
#' Harmonicity Object
#'
#' Represents the Harmonics-to-Noise Ratio (HNR) of a sound over time.
#' 
#' @section Praat Equivalent:
#' This class wraps Praat's Harmonicity object, created via:
#' - "To Harmonicity (ac)..."
#' - "To Harmonicity (cc)..."
#' 
#' @section Usage:
#' ```
#' # From Sound object
#' hnr <- sound$to_harmonicity_ac(time_step = 0.01, min_pitch = 75)
#' 
#' # Query values
#' mean_hnr <- hnr$get_mean()
#' hnr_at_1s <- hnr$get_value_at_time(1.0)
#' ```
#' 
#' @export
Harmonicity <- R6Class(...)
```

## Deliverables

1. **Complete R6 class hierarchy** for all Praat objects
2. **C++ wrappers** linking to Praat codebase
3. **Comprehensive tests** matching Praat/Parselmouth
4. **Vignettes** showing:
   - Praat script translation
   - Phonetic analysis workflows
   - Voice quality assessment
   - Spectral analysis
5. **Examples** folder replicating superassp Python functionality in pure R

## Timeline Summary

- **Week 1-2**: TextGrid, Harmonicity, Complete Formant/Intensity
- **Week 3-4**: Spectrum, Spectrogram, PointProcess, FormantPath  
- **Week 5-6**: Manipulation, LPC, praat_call()
- **Week 7-8**: Sound modifications, Voice reports, Examples, Polish

**Total**: 8 weeks to complete OOP implementation

## Next Steps

1. Implement TextGrid class (highest priority)
2. Add Harmonicity class
3. Complete Formant/Intensity query methods
4. Create comprehensive tests
5. Begin Spectrum/Spectrogram implementation
6. Document with translation examples
7. Replicate superassp examples in R
8. Iterate based on user feedback

---

This plan ensures the R package becomes a **complete, idiomatic wrapper** of Praat's object-oriented codebase, allowing R users to access Praat's full functionality without Python dependencies while maintaining consistency with Praat scripting conventions.
