# Comprehensive Object-Oriented Implementation Plan - Amendment

**Created**: 2025-11-08  
**Status**: Master Amendment - Complete Praat OOP Coverage  
**Purpose**: Expand package to cover full Praat object hierarchy

## Executive Summary

This amendment transitions the speaker package from a limited implementation to a **comprehensive, object-oriented interface to the entire Praat codebase**. The current implementation has established a solid foundation with Sound, Pitch, Formant, Harmonicity, Intensity, and TextGrid objects. This plan expands to cover all major Praat object types and their methods.

## Current Implementation Status (v0.1.0)

### ✅ Implemented Objects

1. **Sound** (~50 methods) - Complete
   - File I/O, generation, queries, transformations
   - Core transform methods (to_pitch, to_formant_burg, to_intensity, to_harmonicity_cc)
   
2. **Pitch** (~30 methods) - Complete
   - Query methods (get_value_at_time, get_mean, get_minimum, get_maximum, etc.)
   - Statistical methods
   - Export methods

3. **Formant** (~20 methods) - Complete
   - Formant tracking queries
   - Statistical methods
   - Export methods

4. **Harmonicity** (~15 methods) - Complete
   - HNR queries
   - Statistical methods

5. **Intensity** (~15 methods) - Complete
   - Intensity contour queries
   - Statistical methods

6. **TextGrid** (Partial) - Structure defined
   - Basic tier queries
   - Needs full implementation of interval/point manipulation

### ❌ Missing Critical Objects

Based on analysis of Praat source (src/praat.github.io/) and Parselmouth design:

#### Priority 1: Essential for Complete Workflows

1. **PointProcess** (fon/PointProcess.cpp)
   - Represents time points (e.g., glottal pulses)
   - **Critical for**: Voice quality (jitter/shimmer calculations)
   - Methods: ~20 (query points, voice quality metrics with Sound)

2. **Manipulation** (fon/Manipulation.cpp) ⭐⭐⭐
   - PSOLA-based pitch/duration modification
   - **Critical for**: Speech synthesis, prosody modification
   - Methods: ~12 (extract/replace pitch tier, duration tier, resynthesize)

3. **Spectrum** (fon/Spectrum.cpp)
   - FFT frequency-domain representation
   - **Critical for**: Spectral analysis, filtering
   - Methods: ~18 (query power, filter, transform)

4. **Spectrogram** (fon/Spectrogram.cpp)
   - Time-frequency representation
   - **Critical for**: Visualization, spectral tracking
   - Methods: ~15 (query power at time/frequency, to_spectrum)

5. **LPC** (LPC/LPC.cpp)
   - Linear predictive coding coefficients
   - **Critical for**: Formant extraction, speech coding
   - Methods: ~10 (to_formant, to_spectrum)

6. **Ltas** (fon/Ltas.cpp)
   - Long-term average spectrum
   - **Critical for**: Voice quality, speaker characteristics
   - Methods: ~12 (query, statistics)

#### Priority 2: Tier Objects (Manipulation Support)

7. **PitchTier** (fon/PitchTier.cpp)
   - Modifiable pitch contour (for Manipulation)
   - Methods: ~12 (add/remove points, multiply frequencies, shift)

8. **DurationTier** (fon/DurationTier.cpp)
   - Duration modification control
   - Methods: ~10 (add/remove points, scaling)

9. **IntensityTier** (fon/IntensityTier.cpp)
   - Modifiable intensity contour
   - Methods: ~10 (add/remove points, scaling)

10. **FormantTier / FormantGrid** (fon/FormantGrid.cpp)
    - Modifiable formant contours
    - Methods: ~15 (tier management, value modification)

#### Priority 3: Advanced Analysis

11. **Matrix** (dwsys/Matrix.cpp)
    - Base class for 2D data (inherited by Spectrogram, etc.)
    - Methods: ~20 (query, statistics, transformations)

12. **Table** (stat/Table.cpp)
    - Tabular data structure (Praat's data frame)
    - Methods: ~50+ (query, statistics, formulas)

13. **FormantPath** (fon/FormantPath.cpp)
    - Multi-candidate formant tracking (modern approach)
    - Methods: ~15 (query candidates, select optimal path)

14. **Excitation** (fon/Excitation.cpp)
    - Auditory excitation pattern
    - Methods: ~8 (to_formant, query)

15. **Cochleagram** (fon/Cochleagram.cpp)
    - Auditory filterbank output
    - Methods: ~10 (to_excitation)

16. **MelFilter / BarkFilter** (fon/MelFilter.cpp)
    - Perceptual frequency scales
    - Methods: ~8 (to_MFCC)

17. **MFCC** (fon/MFCC.cpp)
    - Mel-frequency cepstral coefficients
    - Methods: ~10 (query, to_table)

18. **SpeechSynthesizer** (espeak integration)
    - Text-to-speech (if including espeak-ng)
    - Methods: ~5 (synthesize, configure)

## Praat Object Hierarchy

```
Thing (base class)
├── Daata
│   ├── Function
│   │   ├── Sampled
│   │   │   ├── Sound
│   │   │   ├── Pitch
│   │   │   ├── Intensity
│   │   │   ├── Harmonicity
│   │   │   ├── Formant
│   │   │   ├── PointProcess
│   │   │   ├── Spectrogram
│   │   │   ├── Spectrum
│   │   │   ├── Ltas
│   │   │   ├── LPC
│   │   │   ├── Cochleagram
│   │   │   ├── Excitation
│   │   │   ├── MelFilter / BarkFilter
│   │   │   ├── MFCC
│   │   │   └── FormantPath
│   │   ├── PitchTier (Function → AnyTier → RealTier → PitchTier)
│   │   ├── DurationTier
│   │   ├── IntensityTier
│   │   ├── FormantGrid
│   │   └── TextGrid
│   │       ├── IntervalTier
│   │       └── TextTier (PointTier)
│   ├── Manipulation (complex object containing multiple sub-objects)
│   ├── Matrix (2D data, base for many objects)
│   ├── Table (tabular data)
│   └── Collection (contains multiple objects)
└── ... (many other types)
```

## Implementation Strategy

### Phase 1: Complete Critical Objects (Weeks 1-3)

**Goal**: Enable complete voice quality and manipulation workflows

#### Week 1: PointProcess + Voice Quality

**PointProcess** - Essential for voice quality
- `PointProcess$new(.xptr)` - Internal creation
- `get_number_of_points()` - Query count
- `get_time_from_index(i)` - Get time of point i
- `get_nearest_index(time)` - Find nearest point to time
- `get_interval(i)` - Time between points i and i+1
- **Voice quality with Sound**:
  - `get_jitter_local(sound, ...)` - Local jitter
  - `get_jitter_rap(sound, ...)` - RAP jitter
  - `get_jitter_ppq5(sound, ...)` - PPQ5 jitter
  - `get_jitter_ddp(sound, ...)` - DDP jitter
  - `get_shimmer_local(sound, ...)` - Local shimmer
  - `get_shimmer_apq3(sound, ...)` - APQ3 shimmer
  - `get_shimmer_apq5(sound, ...)` - APQ5 shimmer
  - `get_shimmer_apq11(sound, ...)` - APQ11 shimmer
  - `get_shimmer_dda(sound, ...)` - DDA shimmer
  - `get_mean_period(...)` - Mean period
- `add_point(time)` - Add time point
- `remove_point(i)` - Remove point
- `remove_point_near(time)` - Remove nearest point
- `remove_points_between(t1, t2)` - Remove range
- `as_data_frame()` - Export to R
- `save(path)` - Write to file

**Add to Sound**:
- `to_point_process_periodic_cc(...)` - Extract glottal pulses
- `to_point_process_extrema(...)` - Extract peaks/valleys
- `to_point_process_zeroes(...)` - Extract zero crossings

**Add to Pitch**:
- `to_point_process()` - Convert pitch candidates to points

**Deliverables**:
- `R/pointprocess-r6.R` - Complete PointProcess R6 class (~20 methods)
- `src/pointprocess_wrappers.cpp` - C++ wrappers
- `tests/testthat/test-pointprocess.R` - Unit tests
- `man/PointProcess.Rd` - Documentation
- Voice quality vignette update

#### Week 2: Tier Objects (for Manipulation)

**PitchTier** - Modifiable pitch contour
- `PitchTier$new(.xptr)` - Internal creation
- `get_number_of_points()` - Point count
- `get_time_from_index(i)` - Time of point i
- `get_value_at_index(i)` - Pitch value at point i
- `get_value_at_time(t)` - Interpolated pitch at time
- `add_point(time, value)` - Add pitch point
- `remove_point(i)` - Remove point
- `remove_points_between(t1, t2)` - Remove range
- `multiply_frequencies(from_t, to_t, factor)` - Scale pitch
- `shift_frequencies(from_t, to_t, shift_hz)` - Shift pitch
- `stylize(freq_res, useSemitones)` - Smooth contour
- `as_data_frame()` - Export to R
- `save(path)` - Write to file

**DurationTier** - Duration modification
- `DurationTier$new(.xptr)` - Internal creation
- `get_number_of_points()` - Point count
- `get_value_at_time(t)` - Duration factor at time
- `add_point(time, relative_duration)` - Add duration point (1.0 = normal, 2.0 = twice as slow)
- `remove_point(i)` - Remove point
- `as_data_frame()` - Export to R

**IntensityTier** - Modifiable intensity
- `IntensityTier$new(.xptr)` - Internal creation
- `get_number_of_points()` - Point count
- `get_value_at_time(t)` - Intensity at time
- `add_point(time, intensity_db)` - Add intensity point
- `remove_point(i)` - Remove point
- `multiply_intensities(factor)` - Scale all intensities
- `as_data_frame()` - Export to R

**Add to Pitch**:
- `to_pitch_tier()` - Convert to modifiable tier

**Add to Intensity**:
- `to_intensity_tier()` - Convert to modifiable tier

**Deliverables**:
- `R/pitchtier-r6.R`, `R/durationtier-r6.R`, `R/intensitytier-r6.R`
- `src/pitchtier_wrappers.cpp`, `src/durationtier_wrappers.cpp`, `src/intensitytier_wrappers.cpp`
- Tests, documentation

#### Week 3: Manipulation Object ⭐⭐⭐

**Manipulation** - PSOLA pitch/duration modification
- `Manipulation$new(.xptr)` - Internal creation
- `get_start_time()`, `get_end_time()` - Time range
- **Extraction**:
  - `extract_original_sound()` → Sound
  - `extract_pulses()` → PointProcess
  - `extract_pitch_tier()` → PitchTier
  - `extract_duration_tier()` → DurationTier
- **Replacement**:
  - `replace_pitch_tier(pitch_tier)` - Replace pitch contour
  - `replace_duration_tier(duration_tier)` - Replace duration
  - `replace_pulses(point_process)` - Replace glottal pulses
- **Synthesis**:
  - `get_resynthesis_overlap_add()` → Sound - PSOLA resynthesis (most common)
  - `get_resynthesis_lpc()` → Sound - LPC-based resynthesis
- `play()` - Play modified sound (if audio backend available)

**Add to Sound**:
- `to_manipulation(...)` - Create Manipulation object
- `to_manipulation_pitch_duration(pitch_floor, pitch_ceiling, ...)` - Specific method

**Example Workflow**:
```r
# Load sound
sound <- Sound$new("voice.wav")

# Create manipulation object
manip <- sound$to_manipulation(pitch_floor = 75, pitch_ceiling = 600)

# Extract pitch tier
pitch_tier <- manip$extract_pitch_tier()

# Modify pitch (raise by 20%)
pitch_tier$multiply_frequencies(from_t = 0, to_t = 100, factor = 1.2)

# Replace modified pitch
manip$replace_pitch_tier(pitch_tier)

# Resynthesize
modified_sound <- manip$get_resynthesis_overlap_add()

# Save result
modified_sound$save("voice_higher_pitch.wav")
```

**Deliverables**:
- `R/manipulation-r6.R` - Complete Manipulation R6 class (~12 methods)
- `src/manipulation_wrappers.cpp` - C++ wrappers
- `tests/testthat/test-manipulation.R` - Unit tests
- `man/Manipulation.Rd` - Documentation
- `vignettes/pitch-manipulation.Rmd` - Tutorial vignette

**Milestone**: Complete voice quality + pitch manipulation workflows ✅

---

### Phase 2: Spectral Objects (Weeks 4-5)

**Goal**: Complete spectral analysis pipeline

#### Week 4: Spectrum, Spectrogram, LPC

**Spectrum** - FFT frequency-domain representation
- `Spectrum$new(.xptr)` - Internal creation
- `get_lowest_frequency()`, `get_highest_frequency()` - Frequency range
- `get_number_of_bins()` - Bin count
- `get_frequency_from_bin(bin)` - Bin → frequency
- `get_bin_from_frequency(freq)` - Frequency → bin
- `get_real_value_at_bin(bin)` - Real part
- `get_imaginary_value_at_bin(bin)` - Imaginary part
- `get_power_at_frequency(freq)` - Power at frequency
- `get_band_energy(fmin, fmax)` - Energy in frequency band
- `get_band_density(fmin, fmax)` - Energy density
- `get_centre_of_gravity(power)` - Spectral center of gravity
- `get_standard_deviation(power)` - Spectral spread
- `get_skewness(power)` - Spectral skewness
- `get_kurtosis(power)` - Spectral kurtosis
- `get_central_moment(power, moment)` - Spectral moments
- `filter(fmin, fmax)` - Bandpass filter (modifies in place)
- `to_sound()` → Sound - Inverse FFT
- `to_ltas(bandwidth)` → Ltas - Long-term average
- `as_matrix()` - Export to R (frequency × complex values)
- `as_data_frame()` - Export (frequency, real, imaginary, power, phase)

**Spectrogram** - Time-frequency representation
- `Spectrogram$new(.xptr)` - Internal creation
- `get_start_time()`, `get_end_time()` - Time range
- `get_time_step()`, `get_frequency_step()` - Resolution
- `get_number_of_time_bins()`, `get_number_of_frequency_bins()` - Dimensions
- `get_time_from_frame(frame)` - Frame → time
- `get_frequency_from_bin(bin)` - Bin → frequency
- `get_power_at(time, freq)` - Power at time/frequency
- `get_time_slice(time)` → Spectrum - Extract spectrum at time
- `to_spectrum(time)` → Spectrum - Alias for get_time_slice
- `to_ltas(bandwidth)` → Ltas - Long-term average
- `as_matrix()` - Export (time × frequency power matrix)
- `as_data_frame()` - Long format (time, frequency, power)
- `paint(...)` - Plot spectrogram (using R graphics)

**LPC** - Linear Predictive Coding
- `LPC$new(.xptr)` - Internal creation
- `get_number_of_frames()` - Frame count
- `get_number_of_coefficients(frame)` - Coefficient count
- `get_sampling_period()` - Frame step
- `to_formant(n_formants)` → Formant - Extract formants from LPC
- `to_spectrum(time, sampling_freq, bandwidth)` → Spectrum - LPC spectrum
- `as_matrix()` - Export coefficients (frame × coefficient)
- `as_data_frame()` - Long format

**Add to Sound**:
- `to_spectrum(fast)` → Spectrum - FFT of entire sound
- `to_spectrogram(window_length, max_frequency, ...)` → Spectrogram
- `to_lpc_burg(n_poles, window_length, time_step, pre_emphasis)` → LPC

**Add to Spectrum**:
- `to_excitation(df)` → Excitation - Auditory filtering

**Deliverables**:
- `R/spectrum-r6.R`, `R/spectrogram-r6.R`, `R/lpc-r6.R`
- `src/spectrum_wrappers.cpp`, `src/spectrogram_wrappers.cpp`, `src/lpc_wrappers.cpp`
- Tests, documentation
- `vignettes/spectral-analysis.Rmd` - Tutorial

#### Week 5: Ltas, Excitation, Cochleagram, MelFilter, MFCC

**Ltas** - Long-term average spectrum
- `Ltas$new(.xptr)` - Internal creation
- `get_lowest_frequency()`, `get_highest_frequency()` - Range
- `get_bin_width()` - Frequency resolution
- `get_value_at_frequency(freq)` - Power density at frequency
- `get_mean(fmin, fmax)` - Mean in band
- `get_standard_deviation(fmin, fmax)` - SD in band
- `get_slope(fmin_fit, fmax_fit, fmin_energy, fmax_energy)` - Spectral slope
- `as_data_frame()` - Export

**Excitation** - Auditory excitation pattern
- `Excitation$new(.xptr)` - Internal creation
- `to_formant(n_formants)` → Formant

**Cochleagram** - Auditory filterbank output
- `Cochleagram$new(.xptr)` - Internal creation
- `to_excitation(time)` → Excitation

**MelFilter / BarkFilter** - Perceptual scales
- `MelFilter$new(.xptr)` - Internal creation
- `to_mfcc(n_coefficients)` → MFCC

**MFCC** - Mel-frequency cepstral coefficients
- `MFCC$new(.xptr)` - Internal creation
- `get_number_of_coefficients()` - Coefficient count
- `as_data_frame()` - Export
- `to_table()` → Table (if Table implemented)

**Add to Sound**:
- `to_ltas(bandwidth)` → Ltas
- `to_cochleagram(...)` → Cochleagram
- `to_mel_spectrogram(...)` → MelFilter
- `to_mfcc(...)` → MFCC

**Deliverables**:
- 5 R6 classes + wrappers + tests + docs
- Updated vignettes

**Milestone**: Complete spectral analysis capabilities ✅

---

### Phase 3: Advanced Objects (Weeks 6-7)

#### Week 6: FormantPath, FormantGrid, Matrix

**FormantPath** - Modern formant tracking
- `FormantPath$new(.xptr)` - Internal creation
- `get_number_of_candidates()` - Candidate count
- `get_optimal_formant(time, formant_number)` - Selected formant value
- `extract_formant()` → Formant - Extract chosen path
- `as_data_frame()` - Export all candidates

**FormantGrid** - Modifiable formant contours
- `FormantGrid$new(.xptr)` - Internal creation
- `get_number_of_formants()` - Formant count
- `add_formant_point(formant_num, time, value)` - Add point
- `add_bandwidth_point(formant_num, time, value)` - Add bandwidth point
- `remove_formant_points_between(formant_num, t1, t2)` - Remove range
- `as_data_frame()` - Export

**Matrix** - 2D numerical data
- `Matrix$new(.xptr)` - Internal creation
- `get_number_of_rows()`, `get_number_of_columns()` - Dimensions
- `get_value(row, col)` - Get cell
- `get_row(row)` - Get row as vector
- `get_column(col)` - Get column as vector
- `as_matrix()` - Export to R matrix
- `formula(expression)` - Apply formula to cells

**Add to Sound**:
- `to_formant_path_burg(...)` → FormantPath

**Deliverables**:
- 3 R6 classes + wrappers + tests + docs

#### Week 7: Table, Collection

**Table** - Praat's data frame equivalent
- `Table$new(.xptr)` - Internal creation
- `Table$create(column_names)` - Create empty table
- `get_number_of_rows()`, `get_number_of_columns()` - Dimensions
- `get_column_label(col)` - Column name
- `get_column_index(label)` - Find column by name
- `get_numeric_value(row, col)` - Get number
- `get_string_value(row, col)` - Get string
- `set_numeric_value(row, col, value)` - Set number
- `set_string_value(row, col, value)` - Set string
- `append_row()` - Add row
- `remove_row(row)` - Delete row
- `insert_column(col, label)` - Add column
- `remove_column(col)` - Delete column
- `get_column_mean(col)` - Statistics
- `get_column_stdev(col)` - Statistics
- `formula(col, expression)` - Apply formula
- `as_data_frame()` - Export to R
- `save(path)` - Write to file

**Collection** - Container for multiple objects
- `Collection$new()` - Create empty
- `add_item(item)` - Add object
- `get_item(i)` - Get object i
- `get_number_of_items()` - Count
- `remove_item(i)` - Remove object

**Deliverables**:
- 2 R6 classes + wrappers + tests + docs

**Milestone**: Advanced objects complete ✅

---

### Phase 4: Complete TextGrid Implementation (Week 8)

**Goal**: Full TextGrid functionality (currently partially implemented)

Complete all TextGrid methods:
- ✅ Basic structure and tier queries (already done)
- ✅ Interval tier queries (already done)
- ❌ **Interval tier modification** (needs implementation):
  - `set_interval_text(tier, interval, text)` - Modify label
  - `insert_boundary(tier, time)` - Add boundary
  - `remove_boundary(tier, time)` - Remove boundary
  - `remove_left_boundary(tier, interval)` - Remove left edge
  - `remove_right_boundary(tier, interval)` - Remove right edge
- ❌ **Point tier operations** (needs implementation):
  - `get_number_of_points(tier)` - Point count
  - `get_point_time(tier, point)` - Time of point
  - `get_point_text(tier, point)` - Label of point
  - `insert_point(tier, time, mark)` - Add point
  - `set_point_text(tier, point, text)` - Modify label
  - `remove_point(tier, point)` - Delete point
  - `remove_points_between(tier, t1, t2)` - Delete range
- ❌ **Tier management** (needs implementation):
  - `add_interval_tier(name)` - Create new interval tier
  - `add_point_tier(name)` - Create new point tier
  - `remove_tier(tier)` - Delete tier
  - `duplicate_tier(tier, new_name)` - Copy tier
  - `set_tier_name(tier, name)` - Rename tier
- ❌ **Extraction**:
  - `extract_part(tmin, tmax, preserve_times)` → TextGrid - Extract time range
- ✅ `as_data_frame(tiers)` - Export (check if complete)
- ✅ `save(path)` - Write (check if complete)

**Add TextGrid creation**:
- `TextGrid$create(tmin, tmax, tier_names, point_tiers)` - Static factory

**Deliverables**:
- Complete `src/textgrid_wrappers.cpp` (currently disabled!)
- Update `R/textgrid-r6.R` with all methods
- Comprehensive tests
- Example workflows with forced alignment data

**Milestone**: TextGrid fully functional ✅

---

### Phase 5: Re-implement superassp Examples (Weeks 9-10)

**Goal**: Demonstrate migration from Parselmouth to speaker

Create R versions of all Python files in `/Users/frkkan96/Documents/src/superassp/inst/python/`:

#### Week 9: Core Analysis Examples

1. **`examples/praat_pitch.R`** (from praat_pitch.py)
   - Pitch extraction with multiple algorithms
   - Comparison of autocorrelation vs cross-correlation
   - Statistical summaries

2. **`examples/praat_formant_burg.R`** (from praat_formant_burg.py)
   - Formant tracking with Burg algorithm
   - Parameter optimization
   - Vowel space visualization

3. **`examples/praat_formantpath_burg.R`** (from praat_formantpath_burg.py)
   - Modern formant tracking with candidate selection
   - Path optimization
   - Comparison with standard tracking

4. **`examples/praat_intensity.R`** (from praat_intensity.py)
   - Intensity contour extraction
   - Statistical measures
   - Integration with pitch

5. **`examples/praat_spectral_moments.R`** (from praat_spectral_moments.py)
   - Spectral center of gravity
   - Spectral spread, skewness, kurtosis
   - Time-varying spectral measures

#### Week 10: Voice Quality & Advanced Examples

6. **`examples/praat_voice_report.R`** (from praat_voice_report_memory.py)
   - Comprehensive voice quality report
   - Jitter (local, RAP, PPQ5)
   - Shimmer (local, APQ3, APQ5, APQ11)
   - HNR, NHR, voice breaks
   - Integration with PointProcess

7. **`examples/praat_avqi.R`** (from praat_avqi_memory.py)
   - Acoustic Voice Quality Index
   - Multiple voice quality metrics
   - Scoring algorithm

8. **`examples/praat_dsi.R`** (from praat_dsi_memory.py)
   - Dysphonia Severity Index
   - Integration of multiple measures

9. **`examples/praat_praatsauce.R`** (from praat_praatsauce_memory.py)
   - Voice quality measures (PraatSauce style)
   - H1-H2, H1-A1, H1-A2, H1-A3
   - CPP (Cepstral Peak Prominence)

10. **`examples/praat_sauce.R`** (from praat_sauce_memory.py)
    - Voice quality measures (VoiceSauce style)
    - Spectral tilt measures
    - Energy measures

11. **`examples/praat_voice_tremor.R`** (from praat_voice_tremor_memory.py)
    - Voice tremor analysis
    - Amplitude and frequency modulation

**Each example should include**:
- Side-by-side comparison with Python code (in comments)
- Explanation of API differences
- Performance notes
- Output comparison (verify same results)

**Format**:
```r
#' Pitch Extraction Example
#'
#' Re-implementation of praat_pitch.py using speaker package.
#' This demonstrates the migration from Parselmouth (Python) to speaker (R).
#'
#' Python (Parselmouth):
#' ```python
#' import parselmouth
#' sound = parselmouth.Sound("audio.wav")
#' pitch = sound.to_pitch_ac(time_step=0.01, pitch_floor=75, pitch_ceiling=600)
#' mean_f0 = parselmouth.praat.call(pitch, "Get mean", 0, 0, "Hertz")
#' ```
#'
#' R (speaker):
#' ```r
#' library(speaker)
#' sound <- Sound$new("audio.wav")
#' pitch <- sound$to_pitch_ac(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
#' mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
#' ```
#'
#' Key differences:
#' - R6 methods instead of parselmouth.praat.call()
#' - Named parameters in snake_case
#' - Direct method calls on objects
#' - No separate praat.call() function needed

library(speaker)

# [Implementation here]
```

**Deliverables**:
- `inst/examples/*.R` - 11 complete R scripts
- `inst/examples/README.md` - Overview and usage guide
- `inst/examples/PYTHON_TO_R_MAPPING.md` - API comparison table
- `inst/examples/data/` - Sample audio files for testing
- `inst/examples/output/` - Expected output for validation

**Milestone**: All Python examples have R equivalents ✅

---

### Phase 6: Documentation & Vignettes (Week 11)

**Goal**: Comprehensive user documentation

#### Vignettes to Create

1. **`vignettes/getting-started.Rmd`**
   - Installation (CRAN, GitHub)
   - Basic workflow example
   - Package philosophy
   - Comparison with Praat, Parselmouth

2. **`vignettes/sound-objects.Rmd`**
   - Reading/writing audio files
   - Creating synthetic sounds
   - Audio manipulation
   - Multi-channel handling

3. **`vignettes/pitch-analysis.Rmd`**
   - Pitch extraction algorithms
   - Statistical measures
   - Visualization
   - Pitch manipulation

4. **`vignettes/formant-tracking.Rmd`**
   - Formant extraction
   - Parameter selection
   - FormantPath vs classic tracking
   - Vowel space analysis

5. **`vignettes/textgrid-annotation.Rmd`**
   - Creating TextGrids
   - Importing from forced alignment
   - Editing tiers and labels
   - Segment extraction based on labels
   - Integration with tidyverse

6. **`vignettes/voice-quality.Rmd`**
   - Voice quality metrics (jitter, shimmer, HNR)
   - PointProcess analysis
   - Clinical voice assessment
   - AVQI, DSI implementations

7. **`vignettes/spectral-analysis.Rmd`**
   - Spectrogram visualization
   - Spectrum analysis
   - LPC analysis
   - Spectral moments

8. **`vignettes/pitch-manipulation.Rmd`**
   - PSOLA-based modification
   - Manipulation object workflow
   - PitchTier editing
   - Duration modification
   - Resynthesis

9. **`vignettes/praat-to-r.Rmd`**
   - Praat script → R translation guide
   - Common patterns
   - Object naming conventions
   - Examples from Praat manual

10. **`vignettes/parselmouth-to-speaker.Rmd`**
    - Python → R migration guide
    - API differences
    - Code examples side-by-side
    - Performance comparison

#### Reference Documentation

- Complete Rd files for all R6 classes (20+ classes)
- Method-level documentation with examples
- Cross-references between related objects
- Package overview (`speaker-package.Rd`)
- NEWS.md with version history
- README.md with badges, installation, quick start

**Deliverables**:
- 10 comprehensive vignettes
- 100+ Rd files (complete reference)
- Updated README, NEWS
- Package website (pkgdown)

---

### Phase 7: Testing & Validation (Week 12)

**Goal**: Production-ready, validated package

#### Testing Strategy

1. **Unit Tests** (>300 tests)
   - Each method tested individually
   - Edge cases, boundary conditions
   - Error handling
   - Target: >95% code coverage (R), >85% (C++)

2. **Integration Tests** (30+ workflows)
   - Complete analysis pipelines
   - Multi-object interactions
   - Real-world use cases from literature

3. **Validation Tests** (compare with Praat)
   - Same input → same output
   - Use reference audio files with known values
   - Numerical precision tests (tolerance for floating-point)
   - Compare with Praat desktop output

4. **Validation Tests** (compare with Parselmouth)
   - Verify API parity
   - Same results from same methods
   - Performance benchmarks

5. **Memory Tests**
   - valgrind on Linux
   - Address Sanitizer (ASAN)
   - Leak detection for all objects
   - Stress tests (10,000+ object creations)
   - Long-running tests (hours)

6. **Performance Benchmarks**
   - Compare to Praat desktop
   - Compare to Parselmouth
   - Target: within 10% of native Praat
   - Profile hot paths (Rprof, profvis)

7. **Platform Tests**
   - macOS (x86_64, arm64 / Apple Silicon)
   - Linux (Ubuntu, Fedora, Debian)
   - Windows (x86_64, mingw-w64)
   - R versions: 4.0, 4.1, 4.2, 4.3, 4.4

#### CRAN Preparation

- `R CMD check --as-cran` with zero errors, warnings, notes
- Fix all CRAN policy violations
- Reduce package size if needed (<5 MB source)
- Add CITATION file (with BibTeX entry)
- Update DESCRIPTION (Authors@R, License, URL, BugReports)
- Prepare CRAN submission comments
- `cran-comments.md`

**Deliverables**:
- `tests/testthat/test-*.R` - 60+ test files
- `tests/benchmarks/*.R` - Performance benchmarks
- `tests/validation/*.R` - Validation against Praat/Parselmouth
- `.github/workflows/R-CMD-check.yaml` - GitHub Actions CI
- `.github/workflows/test-coverage.yaml` - Code coverage CI
- CRAN submission materials

**Milestone**: Package ready for CRAN submission ✅

---

## Implementation Summary

### Object Count

| Status | Count | Objects |
|--------|-------|---------|
| ✅ Implemented | 6 | Sound, Pitch, Formant, Intensity, Harmonicity, TextGrid (partial) |
| 🚧 In Progress | 1 | TextGrid (complete) |
| ❌ To Implement | 17 | PointProcess, Manipulation, PitchTier, DurationTier, IntensityTier, Spectrum, Spectrogram, LPC, Ltas, Excitation, Cochleagram, MelFilter, MFCC, FormantPath, FormantGrid, Matrix, Table |
| **TOTAL** | **24** | **Complete Praat OOP interface** |

### Method Count (Estimated)

| Object | Methods | Status |
|--------|---------|--------|
| Sound | ~50 | ✅ Complete |
| Pitch | ~30 | ✅ Complete |
| Formant | ~20 | ✅ Complete |
| Intensity | ~15 | ✅ Complete |
| Harmonicity | ~15 | ✅ Complete |
| TextGrid | ~35 | 🚧 Partial (~20 implemented, ~15 remaining) |
| PointProcess | ~20 | ❌ To implement |
| Manipulation | ~12 | ❌ To implement |
| PitchTier | ~12 | ❌ To implement |
| DurationTier | ~10 | ❌ To implement |
| IntensityTier | ~10 | ❌ To implement |
| Spectrum | ~18 | ❌ To implement |
| Spectrogram | ~15 | ❌ To implement |
| LPC | ~10 | ❌ To implement |
| Ltas | ~12 | ❌ To implement |
| FormantPath | ~10 | ❌ To implement |
| FormantGrid | ~15 | ❌ To implement |
| Excitation | ~5 | ❌ To implement |
| Cochleagram | ~8 | ❌ To implement |
| MelFilter | ~6 | ❌ To implement |
| MFCC | ~10 | ❌ To implement |
| Matrix | ~20 | ❌ To implement |
| Table | ~50 | ❌ To implement |
| **TOTAL** | **~408** | **~195 done, ~213 remaining** |

### Timeline

| Week | Phase | Focus |
|------|-------|-------|
| 1 | Critical Objects | PointProcess + voice quality |
| 2 | Critical Objects | Tier objects (Pitch, Duration, Intensity) |
| 3 | Critical Objects | Manipulation (PSOLA) |
| 4 | Spectral | Spectrum, Spectrogram, LPC |
| 5 | Spectral | Ltas, Excitation, MFCC, etc. |
| 6 | Advanced | FormantPath, FormantGrid, Matrix |
| 7 | Advanced | Table, Collection |
| 8 | TextGrid | Complete implementation |
| 9 | Examples | Core analysis (5 examples) |
| 10 | Examples | Voice quality & advanced (6 examples) |
| 11 | Documentation | Vignettes, reference docs |
| 12 | Testing | Validation, benchmarks, CRAN prep |

**Total**: 12 weeks to complete OOP implementation

---

## Success Criteria

### Technical Excellence
- [ ] 24 Praat objects as R6 classes
- [ ] ~400+ methods covering comprehensive Praat functionality
- [ ] Zero memory leaks (valgrind clean)
- [ ] Test coverage >95% (R), >85% (C++)
- [ ] Performance within 10% of Praat desktop
- [ ] Builds cleanly on Windows, macOS (Intel + ARM), Linux
- [ ] R CMD check with zero errors, warnings, notes

### Usability
- [ ] Intuitive OOP API matching Praat's design
- [ ] Consistent naming conventions (get_*, to_*, as_*)
- [ ] 100+ documented examples
- [ ] 10 comprehensive vignettes
- [ ] Clear migration guides (Praat scripts, Parselmouth)
- [ ] Package website (pkgdown)

### Completeness
- [ ] All 11 superassp Python examples re-implemented
- [ ] TextGrid full support (read, write, edit, annotate)
- [ ] Voice quality analysis (jitter, shimmer, HNR, AVQI, DSI)
- [ ] Pitch manipulation (PSOLA via Manipulation)
- [ ] Spectral analysis (Spectrogram, Spectrum, LPC, MFCC)
- [ ] Formant tracking (classic + FormantPath)
- [ ] All major Praat workflows supported
- [ ] Ready for CRAN submission

---

## Naming Conventions (Maintained)

To enable easy Praat → R translation, maintain consistent naming:

| Praat Pattern | R6 Pattern | Example |
|---------------|------------|---------|
| `Get [property]` | `get_[property]()` | `get_duration()` |
| `Get [property] at time` | `get_[property]_at_time(t)` | `get_value_at_time(t)` |
| `Get mean [property]` | `get_mean_[property]()` or `get_mean()` | `get_mean()` |
| `To [Object]` | `to_[object]()` | `to_pitch()` |
| `To [Object] ([method])` | `to_[object]_[method]()` | `to_formant_burg()` |
| `Extract [subset]` | `extract_[subset]()` | `extract_part()` |
| `Down to [R type]` | `as_[type]()` | `as_data_frame()` |
| `Save as [format]` | `save(path, format)` | `save("out.wav")` |

---

## Next Immediate Steps

1. ✅ Review and approve this amendment
2. ❌ **Begin PointProcess implementation** (Week 1 focus)
3. ❌ Create comprehensive project tracking (GitHub issues/milestones)
4. ❌ Set up enhanced testing infrastructure
5. ❌ Begin weekly progress summaries
6. ❌ Update version to 0.2.0-dev (development version)

---

## Conclusion

This amendment transforms speaker from a foundational implementation into a **complete, production-ready Praat interface for R**. By focusing on Praat's object-oriented architecture and implementing 24 core objects with ~400 methods, we create:

1. **The definitive R phonetic analysis toolkit** - No Python dependency
2. **A bridge between Praat and R** - Easy migration from Praat scripts
3. **A Parselmouth alternative** - Full API parity with clearer design
4. **A research-grade tool** - Validated, tested, documented
5. **The future of phonetics in R** - Modern, extensible, performant

**Let's build the comprehensive phonetic analysis ecosystem R deserves!** 🎉🎤📊
