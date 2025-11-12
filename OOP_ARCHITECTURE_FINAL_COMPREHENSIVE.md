# Comprehensive OOP Architecture Assessment & Amendment
## Final Roadmap for Complete Praat Integration

**Date**: 2025-11-12  
**Package Version**: 0.4.0  
**Assessment Type**: Deep codebase review with Parselmouth comparison

---

## Executive Summary

The `speaker` package has **successfully** adopted an object-oriented architecture that mirrors Praat's C++ design. This document provides a comprehensive assessment of:

1. What is **already implemented** (13 objects, ~270 methods)
2. What **needs completion** (gaps in existing objects)
3. What is **missing entirely** (5 additional objects needed)
4. How to achieve **100% Praat functionality** in R

### Current Achievement (v0.4.0)

✅ **68% of core objects implemented** (13/19)  
✅ **69% of methods implemented** (~270/394)  
✅ **R6 + External Pointers architecture** - proven and stable  
✅ **Consistent naming** - enables easy Praat script transcoding  
✅ **Direct C++ integration** - no Python dependency

---

## Architecture Assessment

### Design Pattern: CORRECT ✅

The package correctly uses:
- **R6 classes** for object-oriented design
- **External pointers** (`Rcpp::XPtr`) to Praat C++ objects
- **Finalizers** for automatic memory management
- **Method naming** that mirrors Praat's conventions

**Example** (current implementation is correct):
```r
# Praat script
sound = Read from file: "audio.wav"
pitch = To Pitch: 0.01, 75, 600
mean_f0 = Get mean: 0, 0, "Hertz"

# speaker R code (direct translation)
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
```

This approach is **fundamentally correct** and should be continued.

---

## Current Implementation Status

### ✅ Tier 1: Fully Implemented Objects (High Quality)

| Object | Lines | Methods | Completeness | Notes |
|--------|-------|---------|--------------|-------|
| **Sound** | 756 | ~50 | 95% | Excellent - query, transform, modify, export all work |
| **Pitch** | 312 | ~30 | 90% | Very good - all statistics, extrema, conversions |
| **PointProcess** | 607 | ~25 | 90% | Excellent - all jitter/shimmer types, manipulation |
| **Manipulation** | 208 | ~12 | 85% | Good - PSOLA pitch modification works |
| **PitchTier** | 252 | ~12 | 85% | Good - modifiable pitch contours |
| **IntensityTier** | 212 | ~10 | 85% | Good - modifiable intensity |
| **DurationTier** | 199 | ~10 | 85% | Good - duration modification |
| **Intensity** | 274 | ~15 | 85% | Good - all queries and conversions |
| **Spectrum** | 255 | ~18 | 85% | Good - FFT queries, spectral moments, filtering |
| **Ltas** | 248 | ~12 | 85% | Good - long-term average spectrum |

**Subtotal**: 10 objects, ~220 methods ✅

### 🚧 Tier 2: Partially Implemented (Needs Completion)

| Object | Lines | Methods | Completeness | What's Missing |
|--------|-------|---------|--------------|----------------|
| **TextGrid** | 485 | 28/35 | 80% | Tier management (add/remove/rename tiers), extract_part() |
| **Formant** | 206 | 15/25 | 60% | Statistical queries (std dev, quantiles), tracking methods |
| **Spectrogram** | 184 | 10/20 | 50% | Query methods incomplete, transformations missing |

**Subtotal**: 3 objects, ~50 implemented methods, ~30 missing ⚠️

### ❌ Tier 3: Not Implemented

| Object | Priority | Est. Methods | Why Critical |
|--------|----------|--------------|--------------|
| **LPC** | ⭐⭐⭐ | ~10 | Linear predictive coding - alternative formant extraction |
| **FormantPath** | ⭐⭐ | ~15 | Modern multi-candidate formant tracking (Praat 6.1+) |
| **FormantGrid** | ⭐⭐ | ~15 | Formant manipulation for voice transformation |
| **Harmonicity** | ⭐⭐ | ~12 | HNR (harmonics-to-noise ratio) for voice quality |
| **Matrix** | ⭐ | ~20 | 2D numerical data (base class for many objects) |
| **Table** | ⭐ | ~10 | Praat's data frame (low priority - R has data.frame) |

**Subtotal**: 6 objects, ~82 methods ❌

---

## Critical Gaps Analysis

### 1. TextGrid (80% complete) - HIGHEST PRIORITY

**What works**:
- ✅ Read/write (text and binary formats)
- ✅ Query tier names, count
- ✅ Get intervals and points
- ✅ Insert/remove boundaries and points
- ✅ Set labels
- ✅ Export to data frame

**What's missing** (7 methods needed):
```r
# Tier management
textgrid$add_interval_tier(name, position = NULL)
textgrid$add_point_tier(name, position = NULL)
textgrid$remove_tier(tier_number_or_name)
textgrid$duplicate_tier(tier, new_name)
textgrid$set_tier_name(tier, new_name)

# Extraction
textgrid$extract_part(from_time, to_time, preserve_times = TRUE)

# Conversion
textgrid$to_table()  # Export to Praat Table format
```

**Impact**: TextGrid is used in 90%+ of phonetic research workflows. Tier management is essential for:
- Creating annotations from scratch
- Merging/splitting tiers
- Extracting time segments
- Forced alignment post-processing

**Estimated work**: 2-3 days

---

### 2. Formant (60% complete)

**What works**:
- ✅ Extract from Sound (Burg's method)
- ✅ Basic queries (get_value_at_time, get_bandwidth_at_time)
- ✅ Read/write files
- ✅ Export to data frame

**What's missing** (10 methods needed):
```r
# Statistics (like Pitch has)
formant$get_mean(formant_number, from_time = 0, to_time = 0, unit = "hertz")
formant$get_standard_deviation(formant_number, from_time = 0, to_time = 0)
formant$get_minimum(formant_number, from_time = 0, to_time = 0)
formant$get_maximum(formant_number, from_time = 0, to_time = 0)
formant$get_quantile(formant_number, quantile = 0.5, from_time = 0, to_time = 0)

# Extrema
formant$get_time_of_minimum(formant_number, from_time = 0, to_time = 0)
formant$get_time_of_maximum(formant_number, from_time = 0, to_time = 0)

# Conversions
formant$down_to_table(...)  # Full formant trajectory to table
formant$to_formant_grid()   # Convert to editable FormantGrid

# Tracking (advanced)
formant$track(num_tracks = 3, ref_f1 = 550, ref_f2 = 1650, ref_f3 = 2750)
```

**Impact**: Formant analysis is core to vowel research. Statistical methods enable:
- Vowel space analysis
- Speaker normalization
- Formant trajectory characterization

**Estimated work**: 3-4 days

---

### 3. Spectrogram (50% complete)

**What works**:
- ✅ Create from Sound
- ✅ Basic structure exists
- ⚠️ Most methods are stubs

**What's missing** (10 methods needed):
```r
# Time-frequency queries
spectrogram$get_power_at(time, frequency)
spectrogram$get_time_from_frame(frame)
spectrogram$get_frequency_from_bin(bin)
spectrogram$get_bin_from_frequency(frequency)

# Slice extraction
spectrogram$to_spectrum(time)  # Extract spectrum at time point

# Conversions
spectrogram$to_ltas(bandwidth = 100)  # Long-term average
spectrogram$to_matrix()  # Time × Frequency matrix
spectrogram$as_data_frame()  # Long format (time, freq, power)

# Modifications
spectrogram$paint(graphics_object)  # For plotting (low priority)
```

**Impact**: Spectrograms are essential for:
- Acoustic phonetics visualization
- Formant tracking verification
- Spectral analysis

**Estimated work**: 2-3 days

---

### 4. Harmonicity - NOT IMPLEMENTED ⭐⭐

**Current status**: Not started

**Why critical**: Harmonics-to-noise ratio (HNR) is a key voice quality measure used in:
- Clinical voice assessment
- Voice quality research (breathy/creaky voice)
- Voice disorder diagnosis
- AVQI, DSI, and other composite voice metrics

**Methods needed** (~12):
```r
# Creation
sound$to_harmonicity_cc(time_step = 0.01, min_pitch = 75, 
                        silence_threshold = 0.1, periods_per_window = 1.0)
sound$to_harmonicity_ac(time_step = 0.01, min_pitch = 75,
                        silence_threshold = 0.1, periods_per_window = 4.5)

# Queries
harmonicity$get_value_at_time(time)
harmonicity$get_mean(from_time = 0, to_time = 0)
harmonicity$get_minimum(from_time = 0, to_time = 0)
harmonicity$get_maximum(from_time = 0, to_time = 0)
harmonicity$get_standard_deviation(from_time = 0, to_time = 0)
harmonicity$get_quantile(quantile = 0.5, from_time = 0, to_time = 0)

# Extrema
harmonicity$get_time_of_minimum(from_time = 0, to_time = 0)
harmonicity$get_time_of_maximum(from_time = 0, to_time = 0)

# Export
harmonicity$as_data_frame()
harmonicity$save(path)
```

**Parselmouth comparison**:
```python
# Python (Parselmouth)
harmonicity = sound.to_harmonicity()
mean_hnr = parselmouth.praat.call(harmonicity, "Get mean", 0, 0)

# R (speaker) - should be:
harmonicity <- sound$to_harmonicity_cc()
mean_hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)
```

**Estimated work**: 2-3 days

---

### 5. LPC - NOT IMPLEMENTED ⭐⭐⭐

**Current status**: Stub file exists (`src/lpc_stub.cpp`) but not functional

**Why critical**: 
- Alternative to Burg's method for formant extraction
- More stable for certain voice types (e.g., children, pathological voice)
- Used in speech coding and synthesis
- Many researchers prefer LPC over Burg

**Methods needed** (~10):
```r
# Creation
sound$to_lpc_autocorrelation(order = 16, window_length = 0.025, 
                              time_step = 0.005, pre_emphasis = 50)
sound$to_lpc_covariance(order = 16, window_length = 0.025,
                        time_step = 0.005, pre_emphasis = 50)
sound$to_lpc_burg(order = 16, window_length = 0.025,
                  time_step = 0.005, pre_emphasis = 50)

# Queries
lpc$get_number_of_frames()
lpc$get_number_of_coefficients(frame)
lpc$get_coefficient(frame, coefficient_number)
lpc$get_sampling_frequency()

# Transformations
lpc$to_formant(num_formants = 5)  # Main use case
lpc$to_spectrum(time, bandwidth = 20)
lpc$as_matrix()  # Coefficient matrix
```

**Impact**: Enables alternative formant tracking pipelines.

**Estimated work**: 3-4 days

---

### 6. FormantPath - NOT IMPLEMENTED ⭐⭐

**Current status**: Not started

**Why needed**: 
- Introduced in Praat 6.1 (2020) as improved formant tracking
- Uses multiple candidates and optimal path selection
- More accurate than classic Burg method for difficult cases
- Becoming standard in modern Praat workflows

**Methods needed** (~15):
```r
# Creation
sound$to_formant_path(time_step = 0.005, max_num_formants = 5,
                      mid_formant_ceiling = 5500, window_length = 0.025,
                      pre_emphasis = 50, ceiling_step_size = 0.05,
                      num_ceilings = 30, ...)

# Queries
formant_path$get_number_of_candidates()
formant_path$get_ceiling(candidate_number)
formant_path$get_stress(candidate_number, ...)

# Extraction
formant_path$extract_formant()  # Get optimal path as Formant object
formant <- formant_path$to_formant()  # Alias

# Optimal path queries
formant_path$get_optimized_formant(formant_number, time)
formant_path$get_optimized_bandwidth(formant_number, time)

# Export
formant_path$as_data_frame()  # Include all candidates
```

**Impact**: Provides state-of-the-art formant tracking.

**Estimated work**: 4-5 days

---

### 7. FormantGrid - NOT IMPLEMENTED ⭐⭐

**Current status**: Not started

**Why needed**:
- Enables formant manipulation (voice transformation)
- Modifiable formant contours (like PitchTier but for formants)
- Used in voice conversion, formant synthesis, accent modification

**Methods needed** (~15):
```r
# Creation
FormantGrid$new(start_time, end_time, num_formants)
formant$to_formant_grid()  # Convert Formant to editable FormantGrid

# Formant tier manipulation
formant_grid$add_formant_point(formant_number, time, value)
formant_grid$add_bandwidth_point(formant_number, time, value)
formant_grid$remove_formant_points_between(formant_number, t1, t2)
formant_grid$remove_bandwidth_points_between(formant_number, t1, t2)

# Queries
formant_grid$get_formant_at_time(formant_number, time)
formant_grid$get_bandwidth_at_time(formant_number, time)
formant_grid$get_number_of_formants()

# Modifications
formant_grid$multiply_formant_frequencies(formant_number, factor, t1, t2)

# Integration with Sound
sound$filter_with_formant_grid(formant_grid)  # Apply formant modification

# Export
formant_grid$as_data_frame()
```

**Impact**: Enables voice transformation workflows.

**Estimated work**: 4-5 days

---

### 8. Matrix - NOT IMPLEMENTED ⭐

**Current status**: Not started

**Why needed**:
- Base class for many Praat objects (Spectrogram, Formant, etc.)
- 2D numerical data container
- Some Praat operations return Matrix objects

**Methods needed** (~10):
```r
# Creation
Matrix$new(num_rows, num_cols, row_min, row_max, col_min, col_max)
Matrix$from_matrix(r_matrix)

# Queries
matrix$get_number_of_rows()
matrix$get_number_of_columns()
matrix$get_value(row, col)
matrix$get_row_min()
matrix$get_row_max()
matrix$get_col_min()
matrix$get_col_max()

# Export
matrix$as_matrix()  # Convert to R matrix
matrix$as_data_frame()

# Transformations
matrix$to_sound(sampling_frequency)  # If it's audio data
```

**Priority**: Lower - R already has excellent matrix support. Only implement if needed for completeness.

**Estimated work**: 2-3 days

---

### 9. Table - NOT IMPLEMENTED ⭐

**Current status**: Not started

**Why low priority**:
- Praat's Table is essentially a data frame
- R's `data.frame` / `tibble` are superior
- Only needed for Praat file format compatibility

**Minimal implementation** (~5 methods):
```r
# Just enough for I/O
Table$new(path)  # Read Praat Table file
table$as_data_frame()  # Convert to R data frame
Table$from_data_frame(df)  # Create from R data frame
table$save(path)  # Write Praat Table file
```

**Recommendation**: Document that users should use R's data.frame, only provide converters.

**Estimated work**: 1-2 days

---

## Comparison with Parselmouth (Python)

### Parselmouth's Approach

Parselmouth wraps Praat objects but uses an **indirect method call** pattern:

```python
import parselmouth

sound = parselmouth.Sound("audio.wav")
pitch = sound.to_pitch()
mean_f0 = parselmouth.praat.call(pitch, "Get mean", 0, 0, "Hertz")  # Indirect!
```

### speaker's Superior Approach

speaker provides **direct method access** (true OOP):

```r
library(speaker)

sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch()
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")  # Direct!
```

### Advantages of speaker's Approach

1. **Method discovery**: RStudio autocomplete shows all available methods
2. **Type safety**: Methods return strongly-typed R6 objects
3. **Documentation**: Each method has proper Rd documentation
4. **No indirection**: Direct calls are faster and clearer
5. **R-native**: Feels like native R, not a wrapper

---

## Complete Implementation Roadmap

### Phase 1: Complete Existing Objects (Weeks 1-2)

**Goal**: Bring partial implementations to 100%

#### Week 1: TextGrid Completion ⭐⭐⭐ CRITICAL
- [ ] Add tier management methods (add, remove, rename, duplicate)
- [ ] Implement extract_part()
- [ ] Comprehensive testing with benchmarkdata*.TextGrid files
- [ ] Update documentation
- [ ] **Deliverable**: TextGrid 100% complete

#### Week 2: Formant & Spectrogram Completion
- [ ] Add statistical methods to Formant (mean, std dev, quantiles)
- [ ] Add tracking methods to Formant
- [ ] Complete Spectrogram query methods
- [ ] Add Spectrogram conversions (to_spectrum, to_ltas, as_matrix)
- [ ] **Deliverable**: Formant 100%, Spectrogram 100%

**Milestone**: All existing objects feature-complete

---

### Phase 2: Critical Missing Objects (Weeks 3-4)

#### Week 3: Harmonicity & LPC
- [ ] Implement Harmonicity R6 class (~12 methods)
- [ ] Convert lpc_stub.cpp to lpc_wrappers.cpp
- [ ] Implement LPC R6 class (~10 methods)
- [ ] Test LPC → Formant pipeline vs. Burg method
- [ ] **Deliverable**: Harmonicity + LPC functional

#### Week 4: FormantPath
- [ ] Implement FormantPath R6 class (~15 methods)
- [ ] Add sound$to_formant_path()
- [ ] Test optimal path extraction
- [ ] Compare with classic Burg formants
- [ ] **Deliverable**: Modern formant tracking available

**Milestone**: All core acoustic analysis objects complete

---

### Phase 3: Advanced Objects (Weeks 5-6)

#### Week 5: FormantGrid
- [ ] Implement FormantGrid R6 class (~15 methods)
- [ ] Add formant/bandwidth point manipulation
- [ ] Integrate with Manipulation for voice transformation
- [ ] **Deliverable**: Formant modification capability

#### Week 6: Matrix & Table (Optional)
- [ ] Implement minimal Matrix class (~10 methods)
- [ ] Implement minimal Table class (~5 methods)
- [ ] Document preference for R's native data structures
- [ ] **Deliverable**: Full Praat object coverage

**Milestone**: All 19 Praat objects implemented (100%)

---

### Phase 4: superassp Migration (Weeks 7-8)

**Goal**: Re-implement all Python examples in R

Analyze `/Users/frkkan96/Documents/src/superassp/inst/python/` and create:

```
inst/examples/
├── README.md                     # Migration guide
├── pitch_tracking.R              # praat_pitch.py → R
├── formant_tracking_burg.R       # praat_formant_burg.py → R
├── formant_tracking_path.R       # praat_formantpath_burg.py → R
├── intensity_analysis.R          # praat_intensity.py → R
├── spectral_moments.R            # praat_spectral_moments.py → R
├── voice_report.R                # praat_voice_report_memory.py → R
├── avqi.R                        # praat_avqi_memory.py → R
├── dsi.R                         # praat_dsi_memory.py → R
├── praatsauce.R                  # praat_praatsauce_memory.py → R
├── sauce.R                       # praat_sauce_memory.py → R
└── voice_tremor.R                # praat_voice_tremor_memory.py → R
```

Each file should include:
```r
#' # Original Python (Parselmouth)
#' ```python
#' [original Python code]
#' ```
#' 
#' # R Implementation (speaker)
[R code with comments showing equivalences]
```

**Deliverable**: 11 complete example files demonstrating Python → R migration

---

### Phase 5: Documentation (Week 9)

#### Vignettes

Create comprehensive tutorials:

1. **getting-started.Rmd** - Installation, basic workflow
2. **sound-analysis.Rmd** - Audio I/O, basic queries
3. **pitch-formant-intensity.Rmd** - Core acoustic features
4. **textgrid-workflows.Rmd** - Annotation and segmentation ⭐⭐⭐
5. **voice-quality.Rmd** - Jitter, shimmer, HNR, voice reports
6. **spectral-analysis.Rmd** - Spectrogram, spectrum, LTAS, LPC
7. **pitch-manipulation.Rmd** - PSOLA modification with Manipulation
8. **formant-tracking-advanced.Rmd** - FormantPath, tracking, FormantGrid
9. **praat-to-r.Rmd** - Translating Praat scripts to R ⭐⭐⭐
10. **parselmouth-to-speaker.Rmd** - Migrating from Python ⭐⭐⭐

#### Reference Documentation

- [ ] Complete Rd files for all 19 R6 classes
- [ ] Method-level documentation with examples
- [ ] Package-level documentation (`?speaker`)
- [ ] CITATION file

#### Package Website

```bash
pkgdown::build_site()
```

- [ ] Deploy to GitHub Pages
- [ ] Example gallery
- [ ] Search functionality

**Deliverable**: Professional documentation suite

---

### Phase 6: Testing & Validation (Week 10)

#### Comprehensive Test Suite

**Target coverage**:
- R code: >95%
- C++ code: >85%

**Test categories**:
```
tests/testthat/
├── test-sound.R              # 50+ tests
├── test-pitch.R              # 40+ tests
├── test-formant.R            # 30+ tests
├── test-textgrid.R           # 50+ tests (use benchmarkdata*.TextGrid)
├── test-manipulation.R       # 30+ tests
├── test-pointprocess.R       # 25+ tests
├── test-spectral.R           # 30+ tests
├── test-harmonicity.R        # 20+ tests
├── test-lpc.R                # 20+ tests
├── test-formantpath.R        # 25+ tests
├── test-formantgrid.R        # 25+ tests
├── test-tiers.R              # 30+ tests
├── test-integration.R        # 50+ tests (complete workflows)
├── test-memory.R             # 10+ tests (leak detection)
└── test-edge-cases.R         # 30+ tests
```

#### Validation

Compare results with:
- **Praat desktop**: Ensure identical numerical results
- **Parselmouth**: Ensure parity

Use benchmark TextGrid files from `inst/extdata/benchmarkdata*.TextGrid` for validation.

#### Performance

Benchmark against Praat desktop:
- Pitch extraction
- Formant extraction
- TextGrid I/O
- Voice quality metrics

**Target**: Within 10% of Praat's performance

**Deliverable**: 400+ tests, validated, benchmarked

---

### Phase 7: CRAN Preparation (Week 11)

#### Pre-submission Checklist

- [ ] `R CMD check --as-cran` → 0 errors, 0 warnings, 0 notes
- [ ] All vignettes build
- [ ] All examples run
- [ ] Package size <5 MB
- [ ] Cross-platform testing (Windows, macOS, Linux)
- [ ] Memory leak free (valgrind)

#### DESCRIPTION File

```r
Package: speaker
Title: Interface to Praat for Phonetic Analysis  
Version: 1.0.0
Authors@R: c(
    person("Fredrik", "Nylén", , "fredrik.nylen@umu.se", 
           role = c("aut", "cre"),
           comment = c(ORCID = "0000-0003-3373-0934"))
)
Maintainer: Fredrik Nylén <fredrik.nylen@umu.se>
Date: 2025-11-12
Description: Provides an object-oriented interface to Praat phonetic analysis
    software <https://www.praat.org>. Exposes Praat's C++ objects (Sound, Pitch, 
    Formant, TextGrid, etc.) as R6 classes with direct method access, enabling 
    comprehensive phonetic analysis workflows in pure R without Python dependencies.
    Implements Praat's algorithms for pitch tracking, formant analysis, voice 
    quality assessment, spectral analysis, and PSOLA-based manipulation.
License: MIT + file LICENSE
URL: https://github.com/humlab-speech/speaker
BugReports: https://github.com/humlab-speech/speaker/issues
Depends: R (>= 4.0.0)
Imports: 
    Rcpp,
    R6
LinkingTo: Rcpp
Suggests: 
    testthat (>= 3.0.0),
    knitr,
    rmarkdown,
    av
SystemRequirements: C++17
VignetteBuilder: knitr
Encoding: UTF-8
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.2.0
```

#### NEWS.md

Document all changes from v0.4.0 to v1.0.0.

#### cran-comments.md

Prepare submission notes.

**Deliverable**: CRAN-ready package

---

### Phase 8: Release (Week 12)

1. **Version bump**: 0.4.0 → 1.0.0
2. **Final checks**: All tests pass
3. **GitHub release**: Tag v1.0.0
4. **CRAN submission**: Submit package
5. **Documentation**: Publish website
6. **Announcement**: R-sig-phonetics, R-bloggers
7. **Publication**: Submit to JOSS (Journal of Open Source Software)
8. **Zenodo**: Obtain DOI

**Deliverable**: Published package 🎉

---

## Implementation Priority Matrix

| Object | Priority | Effort | Impact | Phase |
|--------|----------|--------|--------|-------|
| TextGrid completion | ⭐⭐⭐ | 2-3 days | HIGH | 1 (Week 1) |
| Formant completion | ⭐⭐⭐ | 3-4 days | HIGH | 1 (Week 2) |
| Spectrogram completion | ⭐⭐ | 2-3 days | MEDIUM | 1 (Week 2) |
| Harmonicity | ⭐⭐⭐ | 2-3 days | HIGH | 2 (Week 3) |
| LPC | ⭐⭐⭐ | 3-4 days | HIGH | 2 (Week 3-4) |
| FormantPath | ⭐⭐ | 4-5 days | MEDIUM | 2 (Week 4) |
| FormantGrid | ⭐⭐ | 4-5 days | MEDIUM | 3 (Week 5) |
| Matrix | ⭐ | 2-3 days | LOW | 3 (Week 6) |
| Table | ⭐ | 1-2 days | LOW | 3 (Week 6) |

---

## Naming Consistency Check ✅

The current package **correctly** follows Praat naming conventions:

| Praat Command | speaker Method | Status |
|---------------|----------------|--------|
| `Read from file` | `Object$new(path)` | ✅ |
| `Get duration` | `$get_duration()` | ✅ |
| `Get mean` | `$get_mean(...)` | ✅ |
| `To Pitch` | `$to_pitch(...)` | ✅ |
| `To Formant (burg)` | `$to_formant_burg(...)` | ✅ |
| `Extract part` | `$extract_part(...)` | ✅ |
| `Scale intensity` | `$scale_intensity(...)` | ✅ |
| `Down to Matrix` | `$as_matrix()` | ✅ |
| `Save as WAV file` | `$save(path)` | ✅ |

**Conclusion**: Naming scheme is **excellent** and enables direct transcoding from Praat scripts.

---

## Success Criteria (v1.0.0)

### Completeness
- [ ] 19/19 Praat objects as R6 classes (100%)
- [ ] ~394 methods across all objects
- [ ] TextGrid fully functional (tier management, extraction)
- [ ] All voice quality metrics (jitter, shimmer, HNR)
- [ ] PSOLA manipulation working
- [ ] Spectral analysis complete (Spectrogram, Spectrum, LPC)
- [ ] Modern formant tracking (FormantPath)

### Quality
- [ ] Zero memory leaks (valgrind clean)
- [ ] Test coverage >95% (R), >85% (C++)
- [ ] Performance within 10% of Praat
- [ ] Validated against Praat desktop
- [ ] Cross-platform (Windows, macOS, Linux)

### Documentation
- [ ] 10 comprehensive vignettes
- [ ] Complete Rd documentation for all classes/methods
- [ ] Migration guides (Praat scripts → R, Parselmouth → speaker)
- [ ] Package website with search
- [ ] 11 example files (superassp re-implementations)

### Distribution
- [ ] CRAN published
- [ ] GitHub releases
- [ ] DOI (Zenodo)
- [ ] JOSS publication

---

## Timeline Summary

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| 1 - Complete existing objects | 2 weeks | TextGrid, Formant, Spectrogram 100% |
| 2 - Critical missing objects | 2 weeks | Harmonicity, LPC, FormantPath |
| 3 - Advanced objects | 2 weeks | FormantGrid, Matrix, Table |
| 4 - superassp migration | 2 weeks | 11 Python examples → R |
| 5 - Documentation | 1 week | 10 vignettes, website |
| 6 - Testing & validation | 1 week | 400+ tests, benchmarks |
| 7 - CRAN preparation | 1 week | CRAN-ready |
| 8 - Release | 1 week | v1.0.0 published |

**Total: 12 weeks to v1.0.0** 🎉

---

## Conclusion

The `speaker` package has a **strong foundation** with the correct OOP architecture already in place. The path to 100% Praat functionality is clear:

1. **Complete existing objects** (TextGrid, Formant, Spectrogram)
2. **Add missing critical objects** (Harmonicity, LPC, FormantPath)
3. **Add advanced objects** (FormantGrid, Matrix, Table)
4. **Migrate Python examples** (demonstrate Python → R equivalence)
5. **Document comprehensively** (vignettes, guides, website)
6. **Test thoroughly** (validation, benchmarks, memory)
7. **Release to CRAN** (v1.0.0)

The current implementation is **not wrong** - it's **incomplete**. This roadmap provides a systematic plan to achieve 100% coverage while maintaining the excellent OOP design already established.

**Recommendation**: Proceed with Phase 1 (complete existing objects), starting with TextGrid tier management as the highest priority.
