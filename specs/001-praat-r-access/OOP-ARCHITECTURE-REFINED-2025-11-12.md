# Refined OOP Architecture Plan - 2025-11-12
## Full Praat Object Model in R

**Status**: Refinement of Existing OOP Approach  
**Current Version**: 0.4.0  
**Progress**: 13/19 core objects (68%), 270/394 methods (69%)  
**Architecture**: ✅ R6 + External Pointers to Praat C++ Objects

---

## Executive Summary

This refined plan acknowledges that the `speaker` package has **already embraced the object-oriented paradigm** that mirrors Praat's C++ architecture and Parselmouth's Python design. The current implementation successfully exposes Praat objects as R6 classes with external pointers to native Praat C++ objects.

### Key Insight from Review

**The original spec-kit approach** was procedure-focused (implement specific functions), but **the actual implementation** correctly shifted to an object-oriented design. This plan formalizes and completes that shift.

### What Makes This Different from Parselmouth

**Parselmouth** (Python):
```python
import parselmouth
sound = parselmouth.Sound("file.wav")
pitch = parselmouth.praat.call(sound, "To Pitch", 0.01, 75, 600)
mean_f0 = parselmouth.praat.call(pitch, "Get mean", 0, 0, "Hertz")
```

**Speaker** (R) - Direct Object Methods:
```r
library(speaker)
sound <- Sound$new("file.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
```

**Key differences**:
1. **No `praat.call()` indirection** - Direct method calls
2. **R6 classes** - True OOP in R (vs. Python wrapper objects)
3. **Type safety** - Methods return strongly-typed R6 objects
4. **Method discovery** - Autocomplete works in RStudio
5. **Direct C++ binding** - No Python interpreter overhead

---

## Current Implementation Status (v0.4.0)

### ✅ Fully Implemented Objects (13)

| # | Object | Methods | Key Capabilities |
|---|--------|---------|------------------|
| 1 | **Sound** | ~50 | File I/O, generation, all query methods, conversions to all analysis objects, modifications (scale, filter, pre-emphasize), channel operations |
| 2 | **Pitch** | ~30 | All query methods (mean, min, max, quantile, std dev), time-of-extrema, voiced frame count, to_pitch_tier(), to_point_process() |
| 3 | **Formant** | ~20 | Formant value queries by time/formant number, bandwidth queries, statistics, export |
| 4 | **Intensity** | ~15 | Intensity queries, statistics, to_intensity_tier() |
| 5 | **Harmonicity** | ~15 | HNR queries, statistics, export |
| 6 | **Spectrogram** | ~15 | Time-frequency queries, slice extraction, to_spectrum(), to_ltas() |
| 7 | **Spectrum** | ~18 | FFT queries, power/energy/density, spectral moments (COG, spread, skewness, kurtosis), filtering, to_sound() |
| 8 | **Ltas** | ~12 | Long-term average spectrum, queries, statistics, slope calculation |
| 9 | **PointProcess** | ~20 | **Voice quality metrics** (all jitter types, all shimmer types), point manipulation, interval queries |
| 10 | **Manipulation** | ~12 | **PSOLA pitch modification** - extract/replace pitch_tier, duration_tier, intensity_tier, resynthesize (overlap-add, LPC) |
| 11 | **PitchTier** | ~12 | Modifiable pitch contour - add/remove points, multiply/shift frequencies, stylize |
| 12 | **IntensityTier** | ~10 | Modifiable intensity - add/remove points, multiply values |
| 13 | **DurationTier** | ~10 | Duration modification - add/remove points, relative durations |

**Total: ~270 methods across 13 objects** ✅

### 🚧 Partially Implemented (1)

| Object | Progress | What Works | Missing |
|--------|----------|------------|---------|
| **TextGrid** | 28/35 (80%) | File I/O (text/binary), tier queries, interval/point queries, basic modification (set labels, insert/remove boundaries/points), export to data frame | Tier management (add/remove/duplicate/rename tiers), extract_part(), comprehensive tests |

### ❌ Not Yet Implemented (5)

| Object | Priority | Methods | Why Needed |
|--------|----------|---------|------------|
| **LPC** | ⭐⭐ | ~10 | Linear predictive coding - to_formant(), to_spectrum(), coefficient access |
| **FormantPath** | ⭐⭐ | ~15 | Modern multi-candidate formant tracking (better than classic Burg) |
| **FormantGrid** | ⭐ | ~15 | Modifiable formant contours for voice transformation |
| **Matrix** | ⭐ | ~20 | 2D numerical data operations (base class for many Praat objects) |
| **Table** | ⭐ | ~50 | Praat's data frame - useful but R already has data.frame/tibble |

---

## The Praat Object Hierarchy (Implemented vs. Remaining)

```
Thing (base: praat-object.R)
├── Function
│   ├── Sampled
│   │   ├── ✅ Sound
│   │   ├── ✅ Pitch  
│   │   ├── ✅ Intensity
│   │   ├── ✅ Harmonicity
│   │   ├── ✅ Formant
│   │   ├── ✅ PointProcess
│   │   ├── ✅ Spectrogram
│   │   ├── ✅ Spectrum
│   │   ├── ✅ Ltas
│   │   ├── ❌ LPC (stubbed, needs completion)
│   │   └── ❌ FormantPath (not started)
│   ├── ✅ PitchTier (RealTier)
│   ├── ✅ IntensityTier (RealTier)
│   ├── ✅ DurationTier (RealTier)
│   ├── ❌ FormantGrid (complex tier)
│   └── 🚧 TextGrid (80% done)
├── ✅ Manipulation (complex object)
├── ❌ Matrix (2D data)
└── ❌ Table (tabular data)
```

**Progress**: 13 ✅ | 1 🚧 | 5 ❌

---

## Architectural Principles (Already Established)

### 1. R6 Classes with External Pointers

**Pattern**:
```r
Sound <- R6Class("Sound",
  inherit = PraatObject,  # Base class
  private = list(
    ptr = NULL  # Rcpp::XPtr<structSound>
  ),
  public = list(
    # Methods that call C++ wrappers
    to_pitch = function(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600) {
      pitch_ptr <- .sound_to_pitch(private$ptr, time_step, pitch_floor, pitch_ceiling)
      Pitch$new(.xptr = pitch_ptr)
    }
  )
)
```

**Benefits**:
- ✅ True object persistence (not just data snapshots)
- ✅ Method chaining
- ✅ Memory managed by R's GC + C++ finalizers
- ✅ Zero-copy operations when possible

### 2. Consistent Naming Conventions

**Mapping Praat Commands to R6 Methods**:

| Praat Command | R6 Method | Pattern |
|---------------|-----------|---------|
| `Get duration` | `get_duration()` | Query → `get_*()` |
| `Get value at time...` | `get_value_at_time(time, ...)` | Query with params |
| `Get mean...` | `get_mean(from_time, to_time, ...)` | Statistical query |
| `To Pitch...` | `to_pitch(...)` | Transform → `to_*()` returns new object |
| `To Formant (burg)...` | `to_formant_burg(...)` | Transform with method variant |
| `Extract part...` | `extract_part(...)` | Extract → `extract_*()` returns same type |
| `Scale intensity...` | `scale_intensity(...)` | Modify → verb, returns self |
| `Down to Matrix` | `as_matrix()` | Export → `as_*()` returns R type |
| `Save as WAV file...` | `save(path)` | I/O |
| `Read from file...` | `Sound$new(path)` | Constructor |

**This makes Praat code easy to translate to R!**

### 3. Direct C++ Praat Integration

**No intermediate layer** - Direct use of Praat source code:

```cpp
// src/sound_wrappers.cpp
#include "fon/Sound.h"
#include "fon/Pitch.h"

// [[Rcpp::export(.sound_to_pitch)]]
Rcpp::XPtr<structPitch> sound_to_pitch(
    Rcpp::XPtr<structSound> sound,
    double time_step,
    double pitch_floor,
    double pitch_ceiling
) {
    try {
        autoPitch pitch = Sound_to_Pitch(
            sound.get(),
            time_step,
            pitch_floor,
            pitch_ceiling
        );
        return create_xptr_from_auto<structPitch>(pitch);
    } catch (MelderError) {
        Melder_throw("Failed to create Pitch");
    }
}
```

**Advantages**:
- ✅ Same algorithms as Praat desktop
- ✅ Identical numerical results
- ✅ Maintained by Praat developers
- ✅ Performance equivalent to native Praat

---

## Implementation Roadmap (Complete the Vision)

### Phase 1: Complete TextGrid (Week 1) ⭐⭐⭐ CRITICAL

**Why Critical**: 90% of phonetic research uses TextGrids for annotation.

#### Tasks

**A. Tier Management Methods (5 new methods)**

Add to `src/textgrid_wrappers.cpp`:
- `textgrid_add_interval_tier(xptr, name, position?)`
- `textgrid_add_point_tier(xptr, name, position?)`
- `textgrid_remove_tier(xptr, tier_number)`
- `textgrid_duplicate_tier(xptr, tier_number, new_name)`
- `textgrid_set_tier_name(xptr, tier_number, name)`

Add to `R/textgrid-r6.R`:
```r
add_interval_tier = function(name, position = NULL),
add_point_tier = function(name, position = NULL),
remove_tier = function(tier),
duplicate_tier = function(tier, new_name),
set_tier_name = function(tier, name)
```

**B. Extraction Method (2 new methods)**

```cpp
// Extract time range
textgrid_extract_part(xptr, tmin, tmax, preserve_times)
```

```r
extract_part = function(tmin, tmax, preserve_times = TRUE)
```

**C. Comprehensive Testing**

Create `tests/testthat/test-textgrid-comprehensive.R`:
- ✅ Read TextGrid from file
- ✅ Create TextGrid from scratch
- ✅ Add/remove/rename tiers
- ✅ Insert/remove boundaries
- ✅ Set interval labels
- ✅ Add/remove points
- ✅ Query at time
- ✅ Extract part
- ✅ Save to file
- ✅ Integration with Sound (extract segments)
- ✅ Use benchmark TextGrid files (benchmarkdata*.TextGrid)

**D. Documentation**

Create `vignettes/textgrid-annotation.Rmd`:
- Reading TextGrids from forced alignment (MFA, WebMAUS)
- Creating TextGrids programmatically
- Editing annotations
- Segment extraction workflow
- Tidyverse integration
- Example: vowel analysis from annotated data

**Deliverables**:
- [ ] 7 new methods complete
- [ ] Comprehensive tests (20+ test cases)
- [ ] Vignette tutorial
- [ ] Updated man pages
- [ ] Version → 0.4.1

---

### Phase 2: Complete LPC Object (Week 2) ⭐⭐

**Status**: Stubbed but not functional

**Why Needed**: LPC is fundamental for:
- Alternative formant extraction method
- Speech coding
- Spectral envelope estimation

#### Tasks

Transform `src/lpc_stub.cpp` → `src/lpc_wrappers.cpp`:

```cpp
#include "LPC/LPC.h"

// [[Rcpp::export(.lpc_get_number_of_frames)]]
int lpc_get_number_of_frames(Rcpp::XPtr<structLPC> xptr);

// [[Rcpp::export(.lpc_get_number_of_coefficients)]]
int lpc_get_number_of_coefficients(Rcpp::XPtr<structLPC> xptr, int frame);

// [[Rcpp::export(.lpc_get_coefficient)]]
double lpc_get_coefficient(Rcpp::XPtr<structLPC> xptr, int frame, int coefficient);

// [[Rcpp::export(.lpc_to_formant)]]
Rcpp::XPtr<structFormant> lpc_to_formant(Rcpp::XPtr<structLPC> xptr, int num_formants);

// [[Rcpp::export(.lpc_to_spectrum)]]
Rcpp::XPtr<structSpectrum> lpc_to_spectrum(
    Rcpp::XPtr<structLPC> xptr,
    double time,
    double sampling_frequency,
    double bandwidth
);

// [[Rcpp::export(.lpc_as_matrix)]]
Rcpp::NumericMatrix lpc_as_matrix(Rcpp::XPtr<structLPC> xptr);
```

Create `R/lpc-r6.R`:
```r
LPC <- R6Class("LPC",
  inherit = PraatObject,
  public = list(
    get_number_of_frames = function(),
    get_number_of_coefficients = function(frame),
    get_coefficient = function(frame, coefficient),
    to_formant = function(num_formants = 5),
    to_spectrum = function(time, sampling_frequency, bandwidth),
    as_matrix = function(),
    as_data_frame = function()
  )
)
```

Update `Sound$to_lpc_burg()` to actually work.

**Deliverables**:
- [ ] Functional LPC object (~10 methods)
- [ ] Tests comparing LPC-derived formants with Burg formants
- [ ] Documentation
- [ ] Version → 0.4.2

---

### Phase 3: Advanced Formant Objects (Weeks 3-4) ⭐⭐

#### Week 3: FormantPath

**Why**: Modern formant tracking with candidate selection (better accuracy than classic algorithms).

**R6 Class** (`R/formantpath-r6.R`):
```r
FormantPath <- R6Class("FormantPath",
  inherit = PraatObject,
  public = list(
    get_number_of_candidates = function(),
    get_ceiling = function(candidate_number),
    extract_formant = function(),  # Get the chosen path as Formant
    get_optimal_formant_at = function(time, formant_number),
    get_optimal_bandwidth_at = function(time, formant_number),
    as_data_frame = function()  # All candidates
  )
)
```

**C++ Wrappers** (`src/formantpath_wrappers.cpp`):
- Use `fon/FormantPath.h`
- Wrap FormantPath query and extraction methods

**Add to Sound**:
```r
to_formant_path = function(
    time_step = 0.0,
    max_num_formants = 5,
    mid_formant_ceiling = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50,
    ...
)
```

#### Week 4: FormantGrid

**Why**: Enables precise formant modification for voice transformation.

**R6 Class** (`R/formantgrid-r6.R`):
```r
FormantGrid <- R6Class("FormantGrid",
  inherit = PraatObject,
  public = list(
    get_number_of_formants = function(),
    add_formant_point = function(formant_number, time, value),
    add_bandwidth_point = function(formant_number, time, value),
    remove_formant_points_between = function(formant_number, t1, t2),
    remove_bandwidth_points_between = function(formant_number, t1, t2),
    get_formant_at_time = function(formant_number, time),
    get_bandwidth_at_time = function(formant_number, time),
    as_data_frame = function()
  )
)
```

**Integration**: FormantGrid + Manipulation for formant manipulation.

**Deliverables**:
- [ ] FormantPath object (~15 methods)
- [ ] FormantGrid object (~15 methods)
- [ ] Tests
- [ ] Vignette: "Modern Formant Tracking"
- [ ] Version → 0.4.3

---

### Phase 4: Matrix and Table (Optional - Week 5) ⭐

**Note**: These are lower priority since R has excellent native data structures.

#### Matrix

**Limited implementation** - Just enough for completeness:
```r
Matrix <- R6Class("Matrix",
  inherit = PraatObject,
  public = list(
    get_number_of_rows = function(),
    get_number_of_columns = function(),
    get_value = function(row, col),
    as_matrix = function()  # Convert to R matrix
  )
)
```

#### Table

**Very limited** - R users prefer data.frame/tibble:
```r
Table <- R6Class("Table",
  inherit = PraatObject,
  public = list(
    as_data_frame = function()  # Main use case
  )
)
```

**Recommendation**: Document that users should use R's data.frame/dplyr instead of Praat Table.

---

### Phase 5: Re-implement superassp Examples (Weeks 6-7)

**Goal**: Demonstrate migration from Parselmouth (Python) to speaker (R)

**Create**: `inst/examples/`

For each file in `/Users/frkkan96/Documents/src/superassp/inst/python/praat_*.py`:

1. **`examples/pitch_tracking.R`** (from `praat_pitch.py`)
2. **`examples/formant_tracking.R`** (from `praat_formant_burg.py`)  
3. **`examples/formant_path.R`** (from `praat_formantpath_burg.py`)
4. **`examples/intensity_analysis.R`** (from `praat_intensity.py`)
5. **`examples/spectral_moments.R`** (from `praat_spectral_moments.py`)
6. **`examples/voice_report.R`** (from `praat_voice_report_memory.py`)
7. **`examples/avqi.R`** (from `praat_avqi_memory.py`)
8. **`examples/dsi.R`** (from `praat_dsi_memory.py`)
9. **`examples/praatsauce.R`** (from `praat_praatsauce_memory.py`)
10. **`examples/sauce.R`** (from `praat_sauce_memory.py`)
11. **`examples/voice_tremor.R`** (from `praat_voice_tremor_memory.py`)

**Format**:
```r
#' ---
#' title: "Pitch Tracking"
#' subtitle: "Migration from Parselmouth (Python) to speaker (R)"
#' ---

#' ## Original Python (Parselmouth)
#' 
#' ```python
#' import parselmouth as pm
#' sound = pm.Sound("audio.wav")
#' pitch_ac = sound.to_pitch_ac(0.01, 75, 600)
#' pitch_cc = sound.to_pitch_cc(0.01, 75, 600)
#' mean_f0 = pm.praat.call(pitch_ac, "Get mean", 0, 0, "Hertz")
#' ```

#' ## Equivalent R (speaker)
library(speaker)

sound <- Sound$new("audio.wav")
pitch_ac <- sound$to_pitch_ac(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
pitch_cc <- sound$to_pitch_cc(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch_ac$get_mean(unit = "hertz")

#' ## Key Differences
#' 
#' 1. **Direct method calls** instead of `pm.praat.call()`
#' 2. **Named parameters** in snake_case
#' 3. **R6 objects** with autocomplete support
#' 4. **Type safety** - methods return typed objects

# [Full example implementation...]
```

Create `inst/examples/README.md`:
- Overview of all examples
- How to run them
- Expected outputs
- Migration guide highlights

**Deliverables**:
- [ ] 11 complete R examples
- [ ] Side-by-side Python/R comparison
- [ ] README with migration guide
- [ ] Sample audio files in `inst/extdata/`
- [ ] Version → 0.5.0 (feature-complete)

---

### Phase 6: Comprehensive Documentation (Week 8)

#### Vignettes

1. ✅ **getting-started.Rmd** - Installation, basic usage
2. ✅ **sound-objects.Rmd** - Audio I/O and manipulation
3. ✅ **pitch-analysis.Rmd** - Pitch extraction and analysis
4. ✅ **formant-tracking.Rmd** - Formant analysis
5. 🆕 **textgrid-annotation.Rmd** - Annotation workflows
6. ✅ **voice-quality.Rmd** - Jitter, shimmer, HNR
7. ✅ **spectral-analysis.Rmd** - Spectrogram, spectrum, LTAS
8. ✅ **pitch-manipulation.Rmd** - PSOLA modification
9. 🆕 **praat-to-r.Rmd** - Praat script translation guide
10. 🆕 **parselmouth-to-speaker.Rmd** - Python migration guide

#### Reference Docs

- [ ] Complete Rd files for all 19 R6 classes
- [ ] Method-level examples
- [ ] Cross-references
- [ ] Package overview

#### Package Website

```bash
pkgdown::build_site()
```

- [ ] GitHub Pages deployment
- [ ] Search functionality
- [ ] Example gallery

**Deliverables**:
- [ ] 10 comprehensive vignettes
- [ ] Complete reference documentation
- [ ] Package website online
- [ ] Version → 0.5.1

---

### Phase 7: Testing & Validation (Week 9)

#### Comprehensive Tests

**Coverage targets**:
- R code: >95%
- C++ code: >85%

**Test files** (`tests/testthat/`):
```
test-sound.R (50+ tests)
test-pitch.R (40+ tests)
test-formant.R (30+ tests)
test-textgrid.R (40+ tests)
test-manipulation.R (30+ tests)
test-pointprocess.R (25+ tests)
test-spectral.R (30+ tests)
test-tiers.R (30+ tests)
test-voice-quality.R (30+ tests)
test-integration.R (40+ tests) - Complete workflows
test-memory.R (10+ tests) - Leak detection
```

#### Validation Tests

Create `tests/validation/`:
```r
test_that("Pitch values match Praat desktop", {
  sound <- Sound$new("reference/vowel.wav")
  pitch <- sound$to_pitch_ac(pitch_floor = 75, pitch_ceiling = 600)
  mean_f0 <- pitch$get_mean(unit = "hertz")
  
  # Compare with known value from Praat desktop
  expect_equal(mean_f0, 123.45, tolerance = 0.01)
})
```

Use benchmark TextGrid files:
- `inst/extdata/benchmarkdata*.TextGrid`
- Validate read/write accuracy

#### Performance Benchmarks

Create `tests/benchmarks/`:
```r
library(bench)

bench::mark(
  speaker = {
    sound <- Sound$new("audio.wav")
    pitch <- sound$to_pitch()
  },
  check = FALSE
)
```

Compare with Praat desktop timings.

**Deliverables**:
- [ ] 300+ unit tests
- [ ] Validation against Praat/Parselmouth
- [ ] Performance benchmarks
- [ ] Memory leak tests (valgrind clean)
- [ ] Version → 0.6.0 (validated)

---

### Phase 8: CRAN Submission (Week 10)

#### Pre-submission Checklist

- [ ] `R CMD check --as-cran` → 0 errors, 0 warnings, 0 notes
- [ ] All examples run successfully
- [ ] Vignettes build successfully
- [ ] Package size <5 MB (source)
- [ ] License: MIT + file LICENSE
- [ ] DESCRIPTION complete
- [ ] NEWS.md updated
- [ ] README.md with badges
- [ ] CITATION file
- [ ] cran-comments.md

#### DESCRIPTION Updates

```r
Package: speaker
Title: Interface to Praat for Phonetic Analysis
Version: 1.0.0
Authors@R: c(
    person("Fredrik", "Nylén", , "fredrik.nylen@umu.se", 
           role = c("aut", "cre"),
           comment = c(ORCID = "0000-0003-3373-0934"))
)
Description: Provides an object-oriented interface to the Praat phonetic
    analysis software. Exposes Praat's C++ objects (Sound, Pitch, Formant,
    TextGrid, etc.) as R6 classes with direct method access, enabling
    phonetic analysis workflows without requiring Python.
License: MIT + file LICENSE
URL: https://github.com/humlab-speech/speaker
BugReports: https://github.com/humlab-speech/speaker/issues
Depends: R (>= 4.0.0)
Imports: Rcpp, R6
LinkingTo: Rcpp
Suggests: testthat, knitr, rmarkdown
SystemRequirements: C++17
```

#### Submission

```r
# Run all checks
devtools::check()

# Build package
devtools::build()

# Submit to CRAN
devtools::release()
```

**Deliverables**:
- [ ] CRAN submission
- [ ] Version → 1.0.0 🎉

---

## Object Implementation Summary

### Current Status (v0.4.0)

| Category | Objects | Status |
|----------|---------|--------|
| ✅ **Complete** | Sound, Pitch, Formant, Intensity, Harmonicity, Spectrogram, Spectrum, Ltas, PointProcess, Manipulation, PitchTier, IntensityTier, DurationTier | **13 objects, ~270 methods** |
| 🚧 **Partial** | TextGrid | **28/35 methods (80%)** |
| ❌ **To Do** | LPC, FormantPath, FormantGrid, Matrix, Table | **5 objects, ~110 methods** |

### Target Status (v1.0.0)

| Category | Count | Methods |
|----------|-------|---------|
| **Core Objects** | 19 | ~390 |
| **Methods** | ~390 | Comprehensive Praat functionality |
| **Test Coverage** | >95% | R code |
| **Test Coverage** | >85% | C++ code |
| **Documentation** | 10 vignettes | Complete tutorials |
| **Examples** | 11 | Python→R migrations |

---

## Key Design Principles

### 1. Objects Over Procedures

❌ **Old approach** (procedure-based):
```r
pitch_data <- extract_pitch(file, min = 75, max = 600)
formant_data <- extract_formant(file, max_formant = 5500)
```

✅ **Current approach** (object-based):
```r
sound <- Sound$new(file)
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant_hz = 5500)
```

### 2. Method Chaining and Object Interaction

```r
# Natural workflow
sound <- Sound$new("voice.wav")
manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(factor = 1.2)  # Raise pitch 20%
manip$replace_pitch_tier(pitch_tier)
modified <- manip$get_resynthesis_overlap_add()
modified$save("voice_higher.wav")
```

### 3. Consistent Naming for Easy Translation

**Praat Script**:
```praat
sound = Read from file: "voice.wav"
pitch = To Pitch: 0.01, 75, 600
mean_f0 = Get mean: 0, 0, "Hertz"
```

**speaker R Code**:
```r
sound <- Sound$new("voice.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
```

**Pattern matching is 1:1!**

### 4. Direct C++ Integration (No Python)

- ✅ Native Praat C++ code
- ✅ Same algorithms as Praat desktop
- ✅ Identical numerical results
- ✅ No Python interpreter overhead
- ✅ Memory managed by R + C++ finalizers

---

## Success Criteria (v1.0.0)

### Completeness
- [ ] 19 Praat objects as R6 classes
- [ ] ~390 methods
- [ ] All superassp Python examples re-implemented
- [ ] TextGrid fully functional
- [ ] Voice quality metrics complete
- [ ] Pitch manipulation via Manipulation/PSOLA
- [ ] Spectral analysis suite

### Quality
- [ ] Zero memory leaks (valgrind)
- [ ] Test coverage >95% (R), >85% (C++)
- [ ] Performance within 10% of Praat
- [ ] Validated against Praat desktop
- [ ] Cross-platform (Windows, macOS, Linux)

### Documentation
- [ ] 10 comprehensive vignettes
- [ ] Complete reference docs
- [ ] Migration guides (Praat, Parselmouth)
- [ ] Package website
- [ ] 11 example scripts

### Distribution
- [ ] CRAN accepted
- [ ] GitHub releases
- [ ] DOI via Zenodo
- [ ] Publication in Journal of Open Source Software (JOSS)

---

## Timeline

| Week | Phase | Deliverable |
|------|-------|-------------|
| 1 | TextGrid completion | v0.4.1 - TextGrid 100% |
| 2 | LPC object | v0.4.2 - LPC functional |
| 3 | FormantPath | v0.4.3 - Modern formant tracking |
| 4 | FormantGrid, Matrix, Table | v0.4.4 - All objects implemented |
| 5-6 | Examples implementation | v0.5.0 - All Python examples in R |
| 7 | Documentation | v0.5.1 - Complete vignettes |
| 8-9 | Testing & validation | v0.6.0 - Validated & benchmarked |
| 10 | CRAN preparation | v1.0.0 - CRAN submission 🎉 |

---

## Conclusion

The `speaker` package has **already successfully adopted the object-oriented paradigm** that mirrors Praat's architecture. The current implementation (v0.4.0) provides:

- ✅ **13 fully functional Praat objects** with ~270 methods
- ✅ **R6 + external pointer architecture** proven and stable
- ✅ **Consistent naming** for easy Praat code translation
- ✅ **Direct C++ integration** without Python overhead
- ✅ **Complete voice quality analysis** (jitter, shimmer, HNR)
- ✅ **PSOLA pitch manipulation** via Manipulation object

**Remaining work** (10 weeks to v1.0.0):
- 🚧 Complete TextGrid (7 methods)
- ❌ Implement 5 advanced objects (LPC, FormantPath, FormantGrid, Matrix, Table)
- ❌ Re-implement 11 Python examples in R
- ❌ Complete documentation (vignettes, guides)
- ❌ Comprehensive testing and validation
- ❌ CRAN submission

**This plan completes the vision**: A comprehensive, object-oriented Praat interface for R that enables phonetic researchers to work entirely in R without Python dependencies while maintaining full compatibility with Praat's design and algorithms.
