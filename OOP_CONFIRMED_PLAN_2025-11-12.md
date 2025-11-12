# OOP-First Architecture - Confirmed and Refined Plan
**Date**: 2025-11-12  
**Package Version**: 0.4.1  
**Status**: Phase 2 (Examples) - Week 1-2 of 4-week path to v1.0.0

---

## Executive Summary

The `speaker` package successfully implements an **object-oriented paradigm** that directly mirrors Praat's C++ architecture and improves upon Python's Parselmouth library. This document confirms the OOP-first approach and outlines the path to v1.0.0.

### What Makes speaker Different

**Praat Script** (procedural):
```praat
sound = Read from file: "file.wav"
pitch = To Pitch: 0.01, 75, 600
mean_f0 = Get mean: 0, 0, "Hertz"
```

**Parselmouth** (Python - indirect OOP via `praat.call`):
```python
import parselmouth
sound = parselmouth.Sound("file.wav")
pitch = parselmouth.praat.call(sound, "To Pitch", 0.01, 75, 600)
mean_f0 = parselmouth.praat.call(pitch, "Get mean", 0, 0, "Hertz")
```

**speaker** (R - Direct OOP with R6):
```r
library(speaker)
sound <- Sound$new("file.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
```

### Key Advantages of speaker's Approach

1. **Direct Method Calls**: No `praat.call()` indirection
2. **True OOP in R**: R6 classes with proper encapsulation
3. **Type Safety**: Methods return strongly-typed R6 objects
4. **IDE Support**: Method autocomplete works in RStudio/VS Code
5. **Direct C++ Binding**: No Python interpreter overhead
6. **Consistent Naming**: Praat script code easily transcodes to R
7. **Method Discovery**: `sound$` + Tab shows all available methods

---

## Architecture Confirmed ✅

### Three-Layer Design

```
┌────────────────────────────────────┐
│  User R Code                        │
│  - Sound, Pitch, Formant objects   │
│  - Method calls: $to_pitch()       │
│  - Consistent with Praat naming    │
└────────────────┬───────────────────┘
                 │
┌────────────────▼───────────────────┐
│  R6 Classes (R/)                    │
│  - Sound, Pitch, Formant, etc.     │
│  - Methods wrapping C++ calls      │
│  - Memory management via XPtr      │
│  - Field validation                │
└────────────────┬───────────────────┘
                 │
┌────────────────▼───────────────────┐
│  C++ Wrappers (src/)               │
│  - Rcpp [[Rcpp::export]]           │
│  - XPtr<T> for object lifetime     │
│  - Type conversion (R ↔ C++)       │
│  - Error handling                  │
└────────────────┬───────────────────┘
                 │
┌────────────────▼───────────────────┐
│  Praat C++ Objects                 │
│  - Native Praat implementations    │
│  - Sound, Pitch, Formant classes   │
│  - All analysis algorithms         │
│  - Memory managed by autoThing     │
└────────────────────────────────────┘
```

### Object Inheritance Pattern

All Praat objects inherit from `PraatObject` base class:

```r
PraatObject <- R6Class(
  "PraatObject",
  public = list(
    initialize = function(ptr = NULL),
    is_valid = function(),
    print = function()
  ),
  private = list(
    ptr = NULL,  # XPtr to C++ Praat object
    validate_pointer = function(ptr),
    finalize = function()
  )
)
```

Example derived class:
```r
Sound <- R6Class(
  "Sound",
  inherit = PraatObject,
  public = list(
    # Conversion methods
    to_pitch = function(...),
    to_formant = function(...),
    to_intensity = function(...),
    
    # Query methods
    get_duration = function(),
    get_sample_rate = function(),
    
    # Modification methods
    scale = function(factor),
    filter = function(...)
  )
)
```

---

## Current Implementation Status (v0.4.1)

### ✅ Complete: 16/17 Praat Objects (94%)

| # | Object | Methods | Status | Use Cases |
|---|--------|---------|--------|-----------|
| 1 | **Sound** | 54 | ✅ | File I/O, generation, preprocessing, conversions |
| 2 | **Pitch** | 30 | ✅ | F0 extraction, intonation analysis, prosody |
| 3 | **Formant** | 23 | ✅ | Formant tracking, vowel analysis, articulation |
| 4 | **Intensity** | 15 | ✅ | Loudness contours, amplitude analysis |
| 5 | **Harmonicity** | 15 | ✅ | HNR (Harmonics-to-Noise Ratio), voice quality |
| 6 | **Spectrogram** | 15 | ✅ | Time-frequency representation, visualization |
| 7 | **Spectrum** | 18 | ✅ | FFT analysis, spectral moments, filtering |
| 8 | **Ltas** | 12 | ✅ | Long-term average spectrum, spectral balance |
| 9 | **PointProcess** | 20 | ✅ | Jitter, shimmer, voice quality metrics |
| 10 | **Manipulation** | 12 | ✅ | PSOLA pitch modification, resynthesis |
| 11 | **PitchTier** | 12 | ✅ | Modifiable pitch contours for synthesis |
| 12 | **IntensityTier** | 10 | ✅ | Modifiable intensity contours |
| 13 | **DurationTier** | 10 | ✅ | Duration modification, time warping |
| 14 | **LPC** | 15 | ✅ | Linear predictive coding, formant estimation |
| 15 | **TextGrid** | 34 | ✅ | Annotations, tiers, intervals, points |
| 16 | **Matrix** | 18 | ✅ | 2D data operations, base for many objects |

**Total**: ~311 methods across 16 objects ✅

### 🔨 Remaining: 1/17 (6%)

| Object | Methods | Source Files | Priority | Notes |
|--------|---------|--------------|----------|-------|
| **FormantGrid** | ~20 | `fon/FormantGrid.cpp` | ⭐⭐ | Modifiable formant contours for voice transformation |

### ❌ Not Available in Praat Source

| Object | Status | Alternative |
|--------|--------|-------------|
| **FormantPath** | Requires Praat 6.1+ | Not in current source |
| **Table** | Not in current source | Use R's `data.frame` |

---

## Naming Conventions (Praat → speaker)

To enable easy transcoding of Praat scripts to R, we follow consistent naming:

### Praat Command Format
```praat
result = [Object action]: param1, param2, param3
```

### speaker Method Format
```r
result <- object$method(param1, param2, param3)
```

### Conversion Rules

1. **"To X" → `to_x()`**
   - Praat: `To Pitch: 0.01, 75, 600`
   - R: `sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)`

2. **"Get X" → `get_x()`**
   - Praat: `Get mean: 0, 0, "Hertz"`
   - R: `pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")`

3. **"Set X" / "Replace X" → `set_x()` or `replace_x()`**
   - Praat: `Set value: 1, "label", "hello"`
   - R: `textgrid$set_interval_text(tier = 1, interval = 1, text = "hello")`

4. **"Extract X" → `extract_x()`**
   - Praat: `Extract part: 0, 1, "rectangular", 1.0, "yes"`
   - R: `sound$extract_part(from_time = 0, to_time = 1)`

5. **Multi-word commands → snake_case**
   - Praat: `Down to IntensityTier`
   - R: `intensity$to_intensity_tier()`

### Examples from Each Object

```r
# Sound
sound <- Sound$new("file.wav")
sound$get_duration()
sound$to_pitch()
sound$to_formant()
sound$extract_channel(1)

# Pitch  
pitch <- sound$to_pitch(time_step = 0.01)
pitch$get_mean(unit = "hertz")
pitch$get_minimum(unit = "hertz")
pitch$to_pitch_tier()

# Formant
formant <- sound$to_formant()
formant$get_value_at_time(formant_number = 1, time = 0.5)
formant$get_bandwidth_at_time(formant_number = 1, time = 0.5)

# TextGrid
tg <- TextGrid$new(xmin = 0, xmax = 1, tier_names = "phones", point_tiers = c())
tg$insert_boundary(tier = 1, time = 0.5)
tg$set_interval_text(tier = 1, interval = 1, text = "iy")
```

---

## Path to v1.0.0 (4 Weeks)

### ✅ Phase 1: Objects Complete (Week 0)
- 16/17 objects implemented
- All C++ wrappers working
- Memory management proven

### 🔨 Phase 2: Examples from superassp (Weeks 1-2) **← CURRENT**

**Goal**: Reimplement Python Parselmouth examples in native speaker R

**Location**: `/inst/examples/`  
**Source**: `/Users/frkkan96/Documents/src/superassp/inst/python/`

**Files to Create**:

1. **`01_basic_analyses.R`** - Core workflows
   ```r
   # Pitch extraction
   # Formant tracking  
   # Intensity analysis
   # Basic spectral analysis
   ```

2. **`02_voice_quality.R`** - Voice quality metrics
   ```r
   # Jitter calculations (local, rap, ppq5)
   # Shimmer calculations (local, apq3, apq5, apq11)
   # HNR (Harmonicity)
   # Voice quality comparison across recordings
   ```

3. **`03_formant_analysis.R`** - Advanced formant tracking
   ```r
   # Formant extraction with different methods
   # Formant statistics over time
   # Vowel space analysis
   # Formant tracking optimization
   ```

4. **`04_pitch_manipulation.R`** - PSOLA synthesis
   ```r
   # Create Manipulation object
   # Modify pitch with PitchTier
   # Modify duration with DurationTier
   # Resynthesize with modifications
   ```

5. **`05_spectral_analysis.R`** - Spectral features
   ```r
   # Spectral moments (COG, spread, skewness, kurtosis)
   # Filtering operations
   # LTAS (Long-term average spectrum)
   # Band energy calculations
   ```

6. **`06_textgrids.R`** - Annotation workflows
   ```r
   # Create TextGrids programmatically
   # Read and modify existing TextGrids
   # Extract labels and intervals
   # Align annotations with acoustic data
   ```

7. **`07_integration_pipeline.R`** - Complete workflow
   ```r
   # Multi-object analysis pipeline
   # Batch processing multiple files
   # Export results to data.frame/CSV
   # Visualization with ggplot2
   ```

8. **`README.md`** - Examples overview
   - How to run examples
   - Comparison with Parselmouth approach
   - Performance notes
   - Expected outputs

**Comparison Focus**:
- Show direct method calls vs `praat.call()`
- Demonstrate R idioms (tidyverse integration)
- Highlight performance benefits
- Prove all Parselmouth workflows possible in speaker

### 📚 Phase 3: Documentation (Week 2-3)

#### Six Comprehensive Vignettes

1. **`vignettes/introduction.Rmd`** - Getting Started (Week 2)
   - Package philosophy (OOP-first, direct Praat access)
   - Installation instructions
   - Basic workflow demonstration
   - Object model overview with diagram
   - First analysis example (pitch extraction)

2. **`vignettes/acoustic-analysis.Rmd`** - Core Analyses (Week 2)
   - Pitch: extraction, statistics, to_pitch_tier()
   - Formants: tracking, statistics, vowel analysis
   - Intensity: contours, statistics
   - Harmonicity: HNR calculation
   - Voice quality: jitter, shimmer from PointProcess
   - Spectral: Spectrum, Spectrogram, Ltas

3. **`vignettes/speech-synthesis.Rmd`** - Manipulation (Week 3)
   - Manipulation object overview
   - PSOLA algorithm explanation
   - Pitch modification with PitchTier
   - Duration modification with DurationTier
   - Intensity modification with IntensityTier
   - FormantGrid for formant synthesis
   - Complete synthesis examples

4. **`vignettes/textgrids.Rmd`** - Annotations (Week 3)
   - TextGrid creation from scratch
   - Reading/writing TextGrid files
   - Interval tiers vs point tiers
   - Adding/removing boundaries and points
   - Setting labels
   - Integration with acoustic analyses
   - Batch annotation processing

5. **`vignettes/advanced-topics.Rmd`** - Expert Use (Week 3)
   - Custom analysis functions
   - Integration with tidyverse (dplyr, ggplot2)
   - Memory management best practices
   - Performance optimization tips
   - Extending speaker with new methods
   - Integration with other R packages (phonTools, rPraat)

6. **`vignettes/from-parselmouth.Rmd`** - Migration Guide (Week 3)
   - Python Parselmouth vs R speaker comparison
   - Side-by-side code examples
   - Advantages of speaker package
   - Common patterns translation
   - Performance comparisons
   - Workflow migration examples

#### Additional Documentation

- **README.md** - Comprehensive package overview with examples
- **NEWS.md** - Complete changelog since project start
- **CITATION** - How to cite the package
- **pkgdown website** - Configuration for package website
- **Function docs** - Ensure all ~311 methods fully documented

### 🧪 Phase 4: Testing & Quality (Week 3-4)

#### Test Coverage Goals

- **Target**: 90%+ test coverage
- All object creation tests (16 objects)
- All method tests (~311 methods)
- Edge cases (empty inputs, invalid parameters, NULL values)
- Memory leak tests (valgrind)
- Integration tests (multi-object workflows)
- TextGrid file I/O (text and binary formats)

#### Performance Benchmarking

- Create benchmarks vs Parselmouth (where comparable)
- Profile critical paths (pitch extraction, formant tracking)
- Document performance characteristics
- Test with large files (>1 hour audio)
- Memory usage profiling

#### CRAN Readiness Checklist

- [ ] `R CMD check --as-cran` → 0 errors, 0 warnings, 0 notes
- [ ] All examples run successfully
- [ ] All vignettes build without errors
- [ ] Check on Windows (win-builder)
- [ ] Check on multiple R versions (R-hub: oldrel, release, devel)
- [ ] Spell check all documentation
- [ ] Verify all URLs work
- [ ] DESCRIPTION metadata complete and accurate
- [ ] LICENSE file correct

#### Code Quality

- [ ] Consistent code style (styler + lintr)
- [ ] Remove all debug code and comments
- [ ] Clean up temporary/experimental files
- [ ] Verify NAMESPACE exports correct
- [ ] Remove unused imports
- [ ] Final pass on all error messages (clarity + helpfulness)

### 🚀 Phase 5: Release (Week 4)

#### Version Bump
- Update DESCRIPTION: `Version: 1.0.0`
- Update Date field to release date
- Final NEWS.md entry for v1.0.0

#### Pre-Release Checks
- All vignettes proofread and tested
- README accurate and comprehensive
- All links working
- All examples tested
- License verified (MIT)

#### CRAN Submission
1. Create GitHub release v1.0.0
2. Tag commit: `git tag v1.0.0`
3. Build source package: `R CMD build .`
4. Final check: `R CMD check --as-cran speaker_1.0.0.tar.gz`
5. Submit to CRAN via web form
6. Prepare responses to potential CRAN feedback

---

## Future: FormantGrid (Post v1.0.0 or v1.1.0)

**FormantGrid** is the only remaining object not yet implemented.

### Why Low Priority for v1.0.0
- Used primarily for voice transformation/synthesis
- Less common than other objects
- Requires formant manipulation expertise
- Can use FormantTier-like structure if needed

### Implementation Plan (v1.1.0)

**Source Files**:
- `src/praat/fon/FormantGrid.h`
- `src/praat/fon/FormantGrid.cpp`

**Methods to Implement** (~20):

**Creation**:
- `FormantGrid$new(tmin, tmax, n_formants)`
- `praat_formantgrid_create()`

**Query**:
- `get_number_of_formants()`
- `get_formant_points(formant_number, tier_number)`
- `get_formant_at_time(formant_number, time)`
- `get_bandwidth_at_time(formant_number, time)`

**Modification**:
- `add_formant_point(formant_number, time, value)`
- `add_bandwidth_point(formant_number, time, value)`
- `remove_formant_point(formant_number, time)`
- `remove_bandwidth_point(formant_number, time)`

**Conversion**:
- `to_formant(time_step, duration)`
- `to_sound(sound, time_step, scale_peak)`

**File I/O**:
- `read()`
- `write()`

---

## R7 Migration (v2.0.0 - Future)

### Current Status
- R7/S7 prototypes exist in `dev/r7-prototypes/`
- Harmonicity_S7 fully implemented as proof-of-concept
- Base PraatObject_S7 class complete
- **Not included in v1.0.0**

### Timeline
- **v1.0.0** (4 weeks): Stable R6 implementation
- **Monitoring** (3-6 months): Watch S7 ecosystem mature
- **v2.0.0** (6-9 months post v1.0.0): Full R7 migration

### Why Wait for v2.0.0
1. R6 is proven and stable
2. S7 package still evolving
3. Learn from other packages' R7 migrations
4. Give users stable v1.0.0 first
5. R7 migration is breaking change (major version bump)

### Benefits of R7 (v2.0.0)
- Automatic S3 generics (print, plot, summary)
- Better integration with base R
- Multiple dispatch
- More R-like feel
- Potential performance improvements

---

## Success Metrics for v1.0.0

### Functionality ✅
- [x] 16/17 Praat objects implemented (~311 methods)
- [ ] 7-8 comprehensive examples
- [ ] 6 complete vignettes
- [ ] Full method documentation

### Quality 🎯
- [ ] 90%+ test coverage
- [ ] 0 CRAN warnings/notes/errors
- [ ] All vignettes build cleanly
- [ ] Performance benchmarked
- [ ] Memory safety verified (valgrind clean)

### Documentation 📚
- [ ] 6 vignettes complete
- [ ] All ~311 methods documented
- [ ] README comprehensive
- [ ] Migration guide from Parselmouth
- [ ] pkgdown website configured

### Release 🚀
- [ ] GitHub release v1.0.0
- [ ] CRAN submission accepted
- [ ] Package website live
- [ ] Announcement prepared
- [ ] Community outreach

---

## Comparison: speaker vs Parselmouth

### Advantages of speaker

| Feature | speaker (R) | Parselmouth (Python) |
|---------|-------------|---------------------|
| **Method Calls** | Direct: `sound$to_pitch()` | Indirect: `praat.call(sound, "To Pitch")` |
| **Type Safety** | Strong: Returns R6 objects | Weak: praat.call returns various types |
| **IDE Support** | Full autocomplete | Limited autocomplete |
| **Performance** | Direct C++ binding | Python → C++ overhead |
| **Language** | R (statistical analysis) | Python (general purpose) |
| **Integration** | tidyverse, ggplot2 | pandas, matplotlib |
| **Learning Curve** | R6 familiar to R users | praat.call syntax unique |
| **Error Messages** | R-style with context | Praat-style forwarded |

### Example Comparison

**Task**: Extract F0 and calculate mean

**Parselmouth**:
```python
import parselmouth
sound = parselmouth.Sound("file.wav")
pitch = parselmouth.praat.call(sound, "To Pitch", 0.01, 75, 600)
mean_f0 = parselmouth.praat.call(pitch, "Get mean", 0, 0, "Hertz")
```

**speaker**:
```r
library(speaker)
sound <- Sound$new("file.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
```

**Benefits**:
- No `praat.call()` indirection
- Named parameters (clearer intent)
- Method autocomplete in IDE
- Consistent with R6 patterns
- Type-safe return values

---

## Integration with R Ecosystem

### Tidyverse Workflow

```r
library(speaker)
library(tidyverse)

# Batch process multiple files
results <- tibble(file = list.files("audio", "*.wav", full.names = TRUE)) %>%
  mutate(
    sound = map(file, ~Sound$new(.x)),
    pitch = map(sound, ~.x$to_pitch()),
    mean_f0 = map_dbl(pitch, ~.x$get_mean(unit = "hertz")),
    formant = map(sound, ~.x$to_formant()),
    f1_mean = map_dbl(formant, ~.x$get_mean(formant_number = 1)),
    f2_mean = map_dbl(formant, ~.x$get_mean(formant_number = 2))
  )

# Visualize
ggplot(results, aes(x = f1_mean, y = f2_mean)) +
  geom_point() +
  scale_x_reverse() +
  scale_y_reverse() +
  labs(title = "Vowel Space", x = "F1 (Hz)", y = "F2 (Hz)")
```

### Integration with Other Packages

- **phonTools**: Formant analysis and vowel plots
- **rPraat**: TextGrid compatibility
- **tuneR**: Audio I/O and processing
- **av**: Media format support (via humlab-speech fork)
- **seewave**: Bioacoustic analysis

---

## Architecture Documentation for Future Development

### Adding New Objects (Template)

When Praat adds new objects or when FormantGrid is implemented:

1. **C++ Wrapper** (`src/formantgrid_wrappers.cpp`):
```cpp
#include <Rcpp.h>
using namespace Rcpp;

// [[Rcpp::export]]
SEXP praat_formantgrid_create(double tmin, double tmax, int n_formants) {
  try {
    autoFormantGrid grid = FormantGrid_create(tmin, tmax, n_formants, 0.002, 0.01);
    return Rcpp::XPtr<structFormantGrid>(grid.releaseToAmbiguousOwner());
  } catch (MelderError) {
    throw std::runtime_error("Failed to create FormantGrid");
  }
}

// [[Rcpp::export]]
void praat_formantgrid_add_formant_point(SEXP ptr, int formant_number, 
                                          double time, double value) {
  Rcpp::XPtr<structFormantGrid> grid(ptr);
  FormantGrid_addFormantPoint(grid, formant_number, time, value);
}
```

2. **R6 Class** (`R/formantgrid-r6.R`):
```r
FormantGrid <- R6::R6Class(
  "FormantGrid",
  inherit = PraatObject,
  
  public = list(
    initialize = function(tmin = 0, tmax = 1, n_formants = 5) {
      ptr <- praat_formantgrid_create(tmin, tmax, n_formants)
      super$initialize(ptr)
    },
    
    add_formant_point = function(formant_number, time, value) {
      praat_formantgrid_add_formant_point(private$ptr, formant_number, time, value)
      invisible(self)
    },
    
    to_sound = function(sound, time_step = 0.01, scale_peak = 0.99) {
      ptr <- praat_formantgrid_to_sound(private$ptr, sound$get_ptr(), 
                                         time_step, scale_peak)
      Sound$new(ptr = ptr)
    }
  )
)
```

3. **Tests** (`tests/testthat/test-formantgrid.R`):
```r
test_that("FormantGrid creation works", {
  fg <- FormantGrid$new(tmin = 0, tmax = 1, n_formants = 5)
  expect_true(fg$is_valid())
})

test_that("FormantGrid can add points", {
  fg <- FormantGrid$new(tmin = 0, tmax = 1)
  fg$add_formant_point(formant_number = 1, time = 0.5, value = 500)
  # Add assertions
})
```

4. **Documentation** (`man/FormantGrid.Rd`):
```roxygen
#' @title FormantGrid Class
#' @description R6 class representing a Praat FormantGrid object
#' @export
```

---

## Known Limitations and Future Extensions

### Current Limitations

1. **No Praat Script Interpreter**
   - Cannot execute raw Praat scripts directly
   - Must transcode to R using object methods
   - **Future**: Add interpreter in v1.5.0 or v2.0.0

2. **No Praat Picture Window**
   - Cannot use Praat's built-in plotting
   - Use R plotting (ggplot2, base graphics)
   - **Future**: Bridge to Praat graphics in v2.0.0

3. **FormantPath Not Available**
   - Requires Praat 6.1+ source
   - Use classic Formant object
   - **Future**: Update to newer Praat source

4. **Limited to Current Praat Version**
   - Bound to included Praat source version
   - **Future**: Regular Praat source updates

### Planned Extensions

#### v1.1.0 (Post-release)
- FormantGrid implementation
- Additional Sound generation methods
- Performance optimizations
- Expanded TextGrid utilities

#### v1.5.0 (6 months)
- Praat script interpreter
- Direct script execution: `praat_run_script("script.praat")`
- Enhanced error reporting
- More Sound I/O formats

#### v2.0.0 (9-12 months)
- Full R7 migration
- Praat Picture window integration
- Updated to newer Praat source
- FormantPath support
- Multi-threading support

---

## Development Guidelines

### Code Style

- **R code**: Follow tidyverse style guide
- **C++ code**: Follow Praat's style conventions  
- **Naming**: snake_case for methods (from Praat's Title Case)
- **Documentation**: Roxygen2 for all exported functions

### Testing Philosophy

- Test all public methods
- Test edge cases (empty, NULL, invalid)
- Test memory management (no leaks)
- Test file I/O (various formats)
- Integration tests for workflows

### Documentation Standards

- All methods documented with examples
- Vignettes for common workflows
- Clear error messages with solutions
- Links to Praat manual where applicable

---

## Conclusion

The `speaker` package successfully implements an **OOP-first architecture** that:

1. ✅ **Mirrors Praat's C++ object model** - Not just procedure wrappers
2. ✅ **Improves upon Parselmouth** - Direct methods, no `praat.call()`
3. ✅ **Enables easy transcoding** - Praat scripts → R code naturally
4. ✅ **Provides 94% coverage** - 16/17 objects, ~311 methods
5. ✅ **Integrates with R ecosystem** - tidyverse, ggplot2, etc.

### Current Status
- **Version**: 0.4.1
- **Phase**: Week 1-2 of 4-week path to v1.0.0
- **Focus**: Reimplementing superassp Python examples in R

### Next Steps
1. Analyze Python Parselmouth examples in `/Users/frkkan96/Documents/src/superassp/inst/python/`
2. Create 7-8 comprehensive R examples in `/inst/examples/`
3. Demonstrate all workflows possible in speaker
4. Proceed to Phase 3 (Documentation)

---

**Status**: Plan Confirmed and Refined  
**Approach**: OOP-First (Objects over Procedures)  
**Architecture**: R6 + External Pointers → Praat C++  
**Timeline**: 4 weeks to v1.0.0  
**Date**: 2025-11-12
