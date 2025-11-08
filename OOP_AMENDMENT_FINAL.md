# FINAL OOP AMENDMENT: Complete Praat Object-Oriented Implementation

**Date**: 2025-11-08  
**Version**: Post-Analysis Amendment  
**Status**: MASTER PLAN - Supersedes all previous plans

## Executive Summary

After thorough analysis of:
1. The Praat C++ source code object hierarchy
2. Parselmouth's Python binding architecture
3. Current speaker package implementation (v0.1.0)
4. The superassp Python code using Parselmouth

This amendment establishes the **definitive approach** for implementing the speaker package as a **complete, native R interface to Praat's object-oriented architecture**.

## Core Problem Statement

### What Was Wrong

The original specification and early implementation focused on **procedure-based wrappers**:
- Extract pitch → return data frame
- Extract formants → return data frame  
- Extract intensity → return data frame

This approach:
- ❌ Ignores Praat's fundamental OOP design
- ❌ Forces constant data copying between R and C++
- ❌ Prevents method chaining and object persistence
- ❌ Misses 80% of Praat's functionality (TextGrid, Manipulation, Tiers, etc.)
- ❌ Makes Praat script translation difficult
- ❌ Doesn't allow direct replacement of Parselmouth

### What We Need

A **complete object-oriented binding** that:
- ✅ Exposes Praat's ~30 object types as R6 classes
- ✅ Uses external pointers for zero-copy operations
- ✅ Implements consistent `to_*`, `get_*`, `extract_*` method naming
- ✅ Enables full phonetic analysis workflows in pure R
- ✅ Allows trivial translation from Praat scripts
- ✅ Completely replaces Parselmouth dependency

## Praat's Complete Object Hierarchy

Based on analysis of Praat source (`fon/` directory):

```
Thing (base class for ALL Praat objects)
├── Data
│   ├── Function
│   │   ├── Sampled (time-sampled functions)
│   │   │   ├── Sound ⭐ FOUNDATION (40+ methods)
│   │   │   ├── Pitch ⭐ CORE (30+ methods)
│   │   │   ├── Formant ⭐ CORE (25+ methods)
│   │   │   ├── Intensity ⭐ CORE (15+ methods)
│   │   │   ├── Harmonicity (15+ methods)
│   │   │   ├── PointProcess ⭐⭐⭐ CRITICAL (25+ methods - jitter/shimmer)
│   │   │   ├── Spectrogram (20+ methods)
│   │   │   ├── Ltas (12+ methods)
│   │   │   ├── Excitation (8+ methods)
│   │   │   ├── Cochleagram (10+ methods)
│   │   │   └── Matrix (30+ methods - base for many)
│   │   ├── PitchTier ⭐⭐⭐ CRITICAL (15+ methods - manipulation)
│   │   ├── IntensityTier (12+ methods)
│   │   ├── DurationTier ⭐⭐⭐ CRITICAL (12+ methods - manipulation)
│   │   ├── FormantGrid (20+ methods)
│   │   └── AmplitudeTier (10+ methods)
│   ├── Spectrum (25+ methods)
│   ├── LPC (15+ methods)
│   ├── MFCC (12+ methods)
│   └── FormantPath (15+ methods - modern formant tracking)
├── TextGrid ⭐⭐⭐ CRITICAL (35+ methods - annotation)
│   ├── IntervalTier (20+ methods)
│   └── TextTier/PointTier (15+ methods)
├── Manipulation ⭐⭐⭐ CRITICAL (18+ methods - PSOLA modification)
├── Table (50+ methods - Praat's DataFrame)
├── Collection (10+ methods - object containers)
├── VoiceReport (composite analysis)
└── StringsIndex, Permutation, etc. (utility objects)
```

**Total**: ~30 object classes with ~400+ methods

## Current Implementation Status (v0.1.0)

### ✅ Completed (6 objects, ~150 methods, 37% coverage)

1. **Sound** (sound-r6-new.R, sound_wrappers.cpp)
   - ✅ ~45/50 methods implemented
   - ✅ I/O, generation, query, transformation
   - ✅ Converts to: Pitch, Formant, Intensity, Harmonicity
   - ✅ Core workflows working

2. **Pitch** (pitch-r6.R, pitch_wrappers.cpp)  
   - ✅ ~28/30 methods implemented
   - ✅ Query statistics, manipulation, export
   - ✅ Integration with Sound, PointProcess

3. **Formant** (formant.R, formant_wrappers.cpp)
   - ✅ ~20/25 methods implemented
   - ✅ Query formants, bandwidth, statistics
   - ✅ Data frame export

4. **Intensity** (intensity.R, intensity_wrappers.cpp)
   - ✅ ~15/18 methods implemented
   - ✅ Query statistics, export

5. **Harmonicity** (harmonicity.R, harmonicity_wrappers.cpp)
   - ✅ ~15/15 methods implemented  
   - ✅ HNR analysis complete

6. **TextGrid** (textgrid-r6.R, textgrid_wrappers.cpp)
   - 🚧 ~20/35 methods (READ-ONLY)
   - ✅ Reading, tier access, label queries
   - ❌ NO modification methods (insert_boundary, set_text, etc.)
   - ❌ NO tier manipulation (add_tier, remove_tier)

### 🚧 Partially Implemented (1 object, ~20%)

7. **PointProcess** (pointprocess-r6.R, pointprocess_wrappers.cpp)
   - 🚧 ~5/25 methods (~20%)
   - ✅ Basic structure and pointer management
   - ❌ Missing jitter calculations
   - ❌ Missing shimmer calculations  
   - ❌ Missing voice quality metrics
   - ❌ Missing creation from Sound/Pitch

### ❌ Not Started (23 objects, 0% coverage)

**CRITICAL MISSING** (blocks complete workflows):
- Manipulation (PSOLA pitch/duration modification)
- PitchTier (modifiable pitch contours)
- DurationTier (duration control)
- IntensityTier (intensity modification)
- TextGrid modification methods

**HIGH PRIORITY** (essential analysis):
- Spectrum (frequency domain)
- Spectrogram (time-frequency)
- LPC (linear prediction)
- Ltas (long-term spectrum)
- FormantPath (modern tracking)
- FormantGrid (formant manipulation)

**MEDIUM PRIORITY** (advanced features):
- Matrix, Table, Collection
- Cochleagram, Excitation, MFCC
- VoiceReport
- Utility objects

## Implementation Roadmap

### Phase 1: Complete Critical Objects (Weeks 1-3) ⭐⭐⭐

**Goal**: Enable complete voice quality analysis + pitch manipulation workflows

#### Week 1: PointProcess Completion
- **File**: `R/pointprocess-r6.R`, `src/pointprocess_wrappers.cpp`
- **Methods to add** (~20):
  - Creation: `from_sound_*()`, `from_pitch_*()`, `to_sound_*()` 
  - Voice quality: `get_jitter_*()` (local, rap, ppq5, ddp)
  - Voice quality: `get_shimmer_*()` (local, apq3, apq5, apq11, dda)
  - Period queries: `get_number_of_periods()`, `get_mean_period()`
  - Interval queries: `get_interval()`, `get_intervals()`
  - Modification: `add_point()`, `remove_point()`, `remove_points_between()`
- **Integration**: Full Sound + Pitch + PointProcess voice analysis
- **Tests**: Voice quality metrics validation
- **Vignette**: Update `vignettes/voice-quality.Rmd`

#### Week 2: Tier Objects (PitchTier, DurationTier, IntensityTier)
- **Files**: `R/pitchtier-r6.R`, `R/durationtier-r6.R`, `R/intensitytier-r6.R`
- **Files**: `src/pitchtier_wrappers.cpp`, `src/durationtier_wrappers.cpp`, `src/intensitytier_wrappers.cpp`

**PitchTier** (~15 methods):
  - Creation: `new()`, `from_pointprocess_*()`, `from_pitch_*()` 
  - Query: `get_value_at_time()`, `get_number_of_points()`
  - Modification: `add_point()`, `remove_point()`, `remove_points_between()`
  - Transform: `multiply_frequencies()`, `shift_frequencies()`, `stylize()`
  - Export: `as_data_frame()`, `down_to_pointprocess()`, `down_to_table_of_real()`

**DurationTier** (~12 methods):
  - Creation: `new()`, `create()`
  - Query: `get_value_at_time()`, `get_target_duration()`
  - Modification: `add_point()`, `remove_point()`
  - Export: `as_data_frame()`

**IntensityTier** (~12 methods):
  - Creation: `new()`, `from_intensity_*()`, `from_amplitude_tier()`
  - Query: `get_value_at_time()`, `get_number_of_points()`
  - Modification: `add_point()`, `remove_point()`
  - Transform: `multiply()`, `add()` 
  - Export: `as_data_frame()`, `down_to_pointprocess()`, `down_to_table_of_real()`, `down_to_intensity()`

**Tests**: Tier creation, modification, integration
**Vignette**: `vignettes/pitch-tiers.Rmd`

#### Week 3: Manipulation Object ⭐⭐⭐ HIGHEST PRIORITY
- **File**: `R/manipulation-r6.R`, `src/manipulation_wrappers.cpp`
- **Methods** (~18):
  - Creation: `new()` (from Sound), constructor with parameters
  - Extract: `extract_pitch_tier()`, `extract_duration_tier()`, `extract_pulses()`
  - Replace: `replace_pitch_tier()`, `replace_duration_tier()`, `replace_pulses()`
  - Synthesis: `get_resynthesis_overlap_add()`, `get_resynthesis_psola()`
  - Modification: `shift_pitch_frequencies()`, `multiply_pitch_frequencies()`
  - Query: `get_minimum_pitch()`, `get_maximum_pitch()`, `get_time_step()`
  - Play: `play()`, `play_pulses()`
- **Integration**: Sound → Manipulation → modified Sound
- **Tests**: PSOLA modification validation
- **Vignette**: `vignettes/pitch-manipulation.Rmd` ⭐⭐⭐

**Milestone 1**: Complete voice analysis + manipulation pipeline

### Phase 2: Spectral Analysis Objects (Weeks 4-6) ⭐⭐

**Goal**: Complete frequency-domain analysis capabilities

#### Week 4: Core Spectral Objects
**Spectrum** (~25 methods):
- **File**: `R/spectrum-r6.R`, `src/spectrum_wrappers.cpp`
- Creation: `from_sound_*()`, `create()`
- Query: `get_center_of_gravity()`, `get_standard_deviation()`, `get_skewness()`, `get_kurtosis()`
- Query: `get_band_energy()`, `get_band_density()`, `get_value_at_frequency()`
- Transform: `to_spectrogram()`, `to_sound()`, `cepstral_smoothing()`
- Modification: `filter()`, `multiply_by_*()`, `subtract_from_*()` 
- Export: `as_matrix()`, `as_data_frame()`

**Spectrogram** (~20 methods):
- **File**: `R/spectrogram-r6.R`, `src/spectrogram_wrappers.cpp`
- Creation: `from_sound_*()`, `create()`
- Query: `get_value_at_time_and_frequency()`, `get_power_at_*()`, `get_time_of_maximum()`, `get_frequency_of_maximum()`
- Transform: `to_spectrum()`, `to_sound()`, `to_matrix()`, `paint()`
- Analysis: `get_moment_of_*()`, `get_centre_of_gravity_*()`, `get_standard_deviation_*()` 
- Export: `as_matrix()`, `as_data_frame()`

**LPC** (~15 methods):
- **File**: `R/lpc-r6.R`, `src/lpc_wrappers.cpp`
- Creation: `from_sound_*()`, `create()`
- Query: `get_number_of_coefficients()`, `get_sampling_period()`
- Transform: `to_formant()`, `to_spectrum()`, `to_spectrogram()`
- Export: `as_matrix()`

#### Week 5: Long-Term Spectral Analysis
**Ltas** (~12 methods):
- **File**: `R/ltas-r6.R`, `src/ltas_wrappers.cpp`
- Creation: `from_sound()`, `from_spectrum()`, `create()`
- Query: `get_bin_number_from_frequency()`, `get_frequency_from_bin_number()`
- Query: `get_value_at_frequency()`, `get_value_in_bin()`, `get_minimum()`, `get_maximum()`, `get_mean()`
- Query: `get_local_peak_height()`, `get_slope()` 
- Export: `as_matrix()`, `as_data_frame()`

**Cochleagram** (~10 methods):
- **File**: `R/cochleagram-r6.R`, `src/cochleagram_wrappers.cpp`
- Creation: `from_sound()`, `create()`
- Query: `get_value_at_time_and_frequency()`
- Transform: `to_excitation()`
- Export: `as_matrix()`

**Excitation** (~8 methods):
- **File**: `R/excitation-r6.R`, `src/excitation_wrappers.cpp`
- Creation: `from_sound()`, `create()`
- Query: `get_loudness()`
- Transform: `to_formant()` 
- Export: `as_matrix()`

#### Week 6: MFCC and Modern Formant Tracking
**MFCC** (~12 methods):
- **File**: `R/mfcc-r6.R`, `src/mfcc_wrappers.cpp`
- Creation: `from_sound()`, `create()`
- Query: `get_value_in_frame()`, `get_coefficient_in_frame()`
- Transform: `to_matrix()`, `to_table_of_real()`
- Export: `as_matrix()`, `as_data_frame()`

**FormantPath** (~15 methods):
- **File**: `R/formantpath-r6.R`, `src/formantpath_wrappers.cpp`
- Creation: `from_sound()` (modern robust tracking)
- Query: `get_optimal_ceiling()`, `get_number_of_candidates()`
- Extract: `extract_formant()` (best path)
- Export: `as_data_frame()`

**Tests**: Spectral analysis validation
**Vignette**: `vignettes/spectral-analysis.Rmd`

**Milestone 2**: Complete spectral analysis pipeline

### Phase 3: Advanced Formant & Data Objects (Weeks 7-8) ⭐

**Goal**: Advanced formant manipulation and data handling

#### Week 7: FormantGrid
**FormantGrid** (~20 methods):
- **File**: `R/formantgrid-r6.R`, `src/formantgrid_wrappers.cpp`
- Creation: `new()`, `from_formant()`, `create()`
- Query: `get_formant_at_time()`, `get_bandwidth_at_time()`, `get_number_of_formants()`
- Modification: `add_formant_point()`, `add_bandwidth_point()`, `remove_formant_point()`
- Transform: `to_formant()`
- Export: `as_data_frame()`

**Tests**: Formant synthesis validation
**Vignette**: Update `vignettes/formant-analysis.Rmd`

#### Week 8: Matrix and Table
**Matrix** (~30 methods - base class):
- **File**: `R/matrix-r6.R`, `src/matrix_wrappers.cpp`
- Creation: `create()`, `from_values()`
- Query: `get_value_at_xy()`, `get_row()`, `get_column()`, `get_sum()`, `get_mean()`, `get_standard_deviation()`
- Modification: `set_value()`, `formula()`
- Transform: `transpose()`, `solve()`
- Export: `as_matrix()`, `as_data_frame()`

**Table** (~50 methods - Praat's DataFrame):
- **File**: `R/table-r6.R`, `src/table_wrappers.cpp`
- Creation: `create()`, `read_from_table_file()`
- Query: `get_number_of_rows()`, `get_number_of_columns()`, `get_column_label()`
- Query: `get_value()`, `search_column()`, `get_column_mean()`, `get_column_stdev()`
- Modification: `set_column_label()`, `set_string_value()`, `set_numeric_value()`
- Modification: `append_row()`, `remove_row()`, `insert_row()`, `insert_column()`
- Analysis: `sort_rows()`, `randomize_rows()`, `group_rows()`
- Statistics: `columns_to_table_of_real()`, `get_quantile()`, `report_*_normality()`
- I/O: `write_to_table_file()`, `save()`
- Export: `as_data_frame()`

**Tests**: Matrix operations, table manipulation
**Vignette**: `vignettes/data-tables.Rmd`

**Milestone 3**: Advanced analysis complete

### Phase 4: Complete TextGrid Modification (Week 9) ⭐⭐⭐

**Goal**: Full annotation capabilities

#### Week 9: TextGrid Modification Methods
- **File**: `R/textgrid-r6.R` (extend existing)
- **File**: `src/textgrid_wrappers.cpp` (currently disabled - enable and extend)

**Methods to add** (~15):
- **Tier management**:
  - `insert_interval_tier()`, `insert_point_tier()`
  - `remove_tier()`, `duplicate_tier()`, `extract_tier()`
- **Interval tier modification**:
  - `insert_boundary()`, `remove_boundary()`, `remove_left_boundary()`, `remove_right_boundary()`
  - `set_interval_text()`, `replace_interval_text()`
  - `insert_interval()` 
- **Point tier modification**:
  - `insert_point()`, `remove_point()`, `remove_points()`
  - `set_point_text()` 
- **Global operations**:
  - `extract_part()`, `scale_times()`, `shift_times()`
  - `merge()`, `concatenate()`
- **Search/replace**:
  - `find_interval_by_text()`, `replace_all_text()`

**Integration**: Sound + Pitch + Formant + TextGrid workflows
**Tests**: Annotation creation and modification
**Vignette**: `vignettes/textgrid-annotation.Rmd` ⭐⭐⭐

**Milestone 4**: Complete annotation system

### Phase 5: Utility & Composite Objects (Week 10)

**Goal**: Support objects and special analyses

#### Week 10: Supporting Objects
**Collection** (~10 methods):
- **File**: `R/collection-r6.R`, `src/collection_wrappers.cpp`
- Management: `add_item()`, `remove_item()`, `get_item()`, `get_size()`
- Query: `get_item_names()`, `item_exists()`

**VoiceReport** (composite analysis):
- **File**: `R/voicereport-r6.R`, `src/voicereport_wrappers.cpp`
- Creation: `from_sound()`, `from_sound_and_pitch_and_pointprocess()`
- Comprehensive voice quality report generation

**AmplitudeTier** (~10 methods):
- **File**: `R/amplitudetier-r6.R`, `src/amplitudetier_wrappers.cpp`
- Similar to IntensityTier

**Tests**: Utility object validation
**Vignette**: Update `vignettes/voice-quality.Rmd`

**Milestone 5**: Complete object hierarchy

## Naming Conventions (MANDATORY)

To enable trivial translation from Praat scripts to R:

### Method Naming Rules

1. **Query methods** → `get_*()`:
   - Praat: `Get duration` → R: `sound$get_duration()`
   - Praat: `Get mean` → R: `pitch$get_mean()`
   - Praat: `Get value at time` → R: `pitch$get_value_at_time(time = 0.5)`

2. **Transformation methods** → `to_*()`:
   - Praat: `To Pitch...` → R: `sound$to_pitch()`
   - Praat: `To Formant (burg)...` → R: `sound$to_formant_burg()`
   - Praat: `To Spectrogram...` → R: `sound$to_spectrogram()`

3. **Extraction methods** → `extract_*()`:
   - Praat: `Extract part...` → R: `sound$extract_part(from_time = 0, to_time = 1)`
   - Praat: `Extract tier...` → R: `textgrid$extract_tier(tier_number = 1)`

4. **Modification methods** → verb-based:
   - Praat: `Scale intensity...` → R: `sound$scale_intensity()`
   - Praat: `Multiply frequencies` → R: `pitchtier$multiply_frequencies(factor = 1.2)`
   - Praat: `Set value at time...` → R: `pitchtier$set_value_at_time()`

5. **Export methods** → `as_*()`:
   - R: `pitch$as_data_frame()`
   - R: `formant$as_data_frame()`
   - R: `spectrum$as_matrix()`

6. **I/O methods**:
   - Read: `Sound$new("file.wav")`, `TextGrid$new("file.TextGrid")`
   - Write: `sound$save("output.wav")`, `textgrid$save("output.TextGrid")`

### Parameter Naming

Follow Praat GUI parameter names exactly:
- `pitch_floor`, `pitch_ceiling` (not `min_pitch`, `max_pitch`)
- `time_step` (not `step_size`)
- `max_formant_hz` (not `max_formant`)
- `window_length` (not `window_size`)
- `from_time`, `to_time` (not `start`, `end`)

## Implementation Guidelines

### Technical Architecture

1. **External Pointers (XPtr)**:
   ```cpp
   // C++ wrapper
   // [[Rcpp::export]]
   SEXP praat_sound_to_pitch(SEXP sound_ptr, double time_step, double pitch_floor, double pitch_ceiling) {
       auto sound = Rcpp::as<Rcpp::XPtr<struct Sound>>(sound_ptr);
       auto pitch = Sound_to_Pitch(*sound, time_step, pitch_floor, pitch_ceiling);
       return Rcpp::XPtr<struct Pitch>(pitch, true); // true = manage memory
   }
   ```

2. **R6 Classes**:
   ```r
   Pitch <- R6Class("Pitch",
     private = list(
       .ptr = NULL  # External pointer to Praat Pitch object
     ),
     public = list(
       initialize = function(ptr) {
         private$.ptr <- ptr
       },
       get_mean = function(from_time = 0, to_time = 0, unit = c("hertz", "bark", "mel", "semitones")) {
         unit <- match.arg(unit)
         praat_pitch_get_mean(private$.ptr, from_time, to_time, unit)
       },
       to_pointprocess = function() {
         ptr <- praat_pitch_to_pointprocess(private$.ptr)
         PointProcess$new(ptr)
       }
     )
   )
   ```

3. **Memory Management**:
   - Use `Rcpp::XPtr` with finalizers
   - Call Praat's `forget()` function on object deletion
   - R's garbage collector handles cleanup automatically

4. **Error Handling**:
   - Wrap all Praat calls in try-catch
   - Convert Praat errors to R errors with `Rcpp::stop()`
   - Validate parameters before calling Praat functions

### Testing Requirements

Each object must have:
1. **Unit tests** (`tests/testthat/test-{object}.R`):
   - Object creation
   - Method functionality
   - Edge cases and error handling
   - Integration with related objects

2. **Integration tests**:
   - Complete workflows (Sound → Pitch → PointProcess → jitter)
   - Round-trip operations (Sound → Spectrum → Sound)

3. **Example data**:
   - Store in `inst/extdata/`
   - Include various audio formats, TextGrids

### Documentation Requirements

Each object must have:
1. **Method documentation** (roxygen2):
   ```r
   #' Get mean pitch
   #'
   #' @param from_time Start time in seconds (default: 0 = start of sound)
   #' @param to_time End time in seconds (default: 0 = end of sound)  
   #' @param unit Unit for the result: "hertz" (default), "bark", "mel", or "semitones"
   #' @return Mean pitch value in the specified unit
   #' @examples
   #' \dontrun{
   #' sound <- Sound$new("audio.wav")
   #' pitch <- sound$to_pitch()
   #' mean_f0 <- pitch$get_mean(unit = "hertz")
   #' }
   #' @export
   ```

2. **Object documentation** (dedicated .Rd file)

3. **Vignette examples**:
   - Practical workflows
   - Comparison with Praat scripts
   - Translation examples from Parselmouth

## Success Criteria

### Version 0.2.0 (End of Phase 5)

- ✅ 30+ Praat object types implemented as R6 classes
- ✅ 400+ methods across all objects
- ✅ Complete voice quality analysis pipeline
- ✅ Complete pitch/duration manipulation (PSOLA)
- ✅ Complete TextGrid annotation system
- ✅ Complete spectral analysis capabilities
- ✅ Zero Python dependencies
- ✅ 100% test coverage of implemented methods
- ✅ Comprehensive vignettes for all major workflows
- ✅ Can reproduce all superassp Parselmouth workflows in pure R

### Deliverables

1. **Core Package**:
   - All object R6 classes
   - All C++ wrappers
   - Complete test suite
   - Full documentation

2. **Vignettes** (in `vignettes/`):
   - `getting-started.Rmd` (basic Sound → Pitch → Formant)
   - `voice-quality.Rmd` (jitter, shimmer, HNR)
   - `pitch-manipulation.Rmd` (PSOLA modification) ⭐⭐⭐
   - `textgrid-annotation.Rmd` (complete annotation workflow) ⭐⭐⭐
   - `spectral-analysis.Rmd` (frequency-domain analysis)
   - `formant-analysis.Rmd` (formant tracking and synthesis)
   - `praat-translation.Rmd` (translating Praat scripts to R)
   - `parselmouth-migration.Rmd` (replacing Python code)

3. **Example Implementations** (in `inst/examples/`):
   - Re-implementations of all superassp Python functions
   - Direct comparisons showing Parselmouth → speaker translation

4. **Documentation**:
   - Complete API reference
   - Migration guides (Praat scripts, Parselmouth)
   - Object hierarchy diagram
   - Method lookup table

## Comparison: Parselmouth Python vs. speaker R

### Before (superassp with Parselmouth):
```python
# Python - requires Parselmouth
import parselmouth

sound = parselmouth.Sound("audio.wav")
pitch = sound.to_pitch(pitch_floor=75, pitch_ceiling=600)
mean_f0 = pitch.get_mean()

pointprocess = parselmouth.praat.call(sound, "To PointProcess (periodic, cc)", 75, 600)
jitter = parselmouth.praat.call(pointprocess, "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)

# Pitch manipulation
manipulation = parselmouth.praat.call(sound, "To Manipulation", 0.01, 75, 600)
pitch_tier = parselmouth.praat.call(manipulation, "Extract pitch tier")
parselmouth.praat.call(pitch_tier, "Multiply frequencies", 0, 0, 1.2)
parselmouth.praat.call(manipulation, "Replace pitch tier", pitch_tier)
modified = parselmouth.praat.call(manipulation, "Get resynthesis (overlap-add)")
```

### After (speaker R):
```r
# R - pure R package, no Python
library(speaker)

sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean()

pointprocess <- sound$to_pointprocess_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)
jitter <- pointprocess$get_jitter_local()

# Pitch manipulation  
manipulation <- sound$to_manipulation(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
pitch_tier <- manipulation$extract_pitch_tier()
pitch_tier$multiply_frequencies(factor = 1.2)
manipulation$replace_pitch_tier(pitch_tier)
modified <- manipulation$get_resynthesis_overlap_add()
```

**Result**: Cleaner, more idiomatic, no Python dependency, better performance

## Migration Path for Existing Code

### Step 1: Analyze superassp Python Code
- **Location**: `/Users/frkkan96/Documents/src/superassp/inst/python`
- **Action**: Catalog all Parselmouth function calls
- **Output**: Function mapping table

### Step 2: Implement Missing Objects
- Follow priority order in roadmap
- Focus on objects actually used by superassp first

### Step 3: Create Translation Examples
- **Location**: `inst/examples/` in speaker package
- For each superassp Python function:
  - Create equivalent R function
  - Add side-by-side comparison documentation
  - Add validation tests

### Step 4: Vignette for Migration
- **File**: `vignettes/parselmouth-migration.Rmd`
- Show before/after for common workflows
- Provide lookup table for method translation

## Timeline Summary

- **Week 1**: PointProcess completion
- **Week 2**: Tier objects (PitchTier, DurationTier, IntensityTier)
- **Week 3**: Manipulation (PSOLA) ⭐⭐⭐
- **Week 4**: Core spectral (Spectrum, Spectrogram, LPC)
- **Week 5**: Ltas, Cochleagram, Excitation
- **Week 6**: MFCC, FormantPath
- **Week 7**: FormantGrid
- **Week 8**: Matrix, Table
- **Week 9**: TextGrid modification ⭐⭐⭐
- **Week 10**: Utility objects, VoiceReport

**Total**: 10 weeks to complete implementation

## Next Steps

1. **Immediate** (Week 1):
   - Complete PointProcess implementation
   - Add all jitter/shimmer methods
   - Test voice quality workflows
   - Update `vignettes/voice-quality.Rmd`

2. **Short-term** (Weeks 2-3):
   - Implement Tier objects
   - Implement Manipulation (CRITICAL)
   - Create `vignettes/pitch-manipulation.Rmd`

3. **Medium-term** (Weeks 4-6):
   - Implement spectral objects
   - Create `vignettes/spectral-analysis.Rmd`

4. **Long-term** (Weeks 7-10):
   - Complete advanced objects
   - Finish TextGrid modification
   - Analyze and re-implement superassp functions
   - Create complete example library

## Conclusion

This amendment establishes the **definitive roadmap** for implementing the speaker package as a **complete, native R interface to Praat**. By focusing on Praat's object-oriented architecture rather than isolated procedures, we create a powerful, performant, and intuitive API that:

- ✅ Mirrors Praat's design philosophy
- ✅ Eliminates Python dependencies  
- ✅ Enables trivial Praat script translation
- ✅ Provides complete phonetic analysis workflows
- ✅ Replaces Parselmouth with better performance
- ✅ Scales to Praat's full 400+ method catalog

**Status**: Ready to proceed with Week 1 implementation
