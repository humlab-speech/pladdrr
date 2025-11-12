# Final OOP Implementation Plan
## Complete Praat Object Model in R

**Date**: 2025-11-12  
**Current Version**: 0.4.0  
**Target Version**: 1.0.0  
**Architecture**: ✅ R6 + External Pointers (Established & Proven)

---

## Executive Summary

The `speaker` package has **successfully adopted an object-oriented paradigm** that mirrors Praat's C++ architecture. Unlike Python's Parselmouth which uses `praat.call()` indirection, speaker provides **direct R6 method access** to Praat objects.

###Current Progress

- ✅ **13/19 objects fully implemented** (68%)
- ✅ **~270/390 methods** (69%)
- ✅ **OOP architecture established** and proven
- 🚧 **TextGrid** 95% complete (missing: duplicate_tier, set_tier_name)
- ❌ **5 objects remaining**: LPC, FormantPath, FormantGrid, Matrix, Table

### Key Architectural Wins

1. **No Python dependency** - Direct C++ Praat integration
2. **True OOP in R** - R6 classes with external pointers
3. **1:1 Praat command mapping** - Easy script translation
4. **Method chaining** - Natural workflows
5. **Type safety** - Methods return strongly-typed R6 objects

---

## Implementation Roadmap

### Phase 1: Complete TextGrid (Priority: ⭐⭐⭐ CRITICAL)

**Status**: 95% complete  
**Time**: 1-2 days  
**Target Version**: 0.4.1

#### Missing Methods

1. `duplicate_tier(tier, new_name)` - Duplicate a tier with new name
2. `set_tier_name(tier, name)` - Rename a tier

Already have:
- ✅ `add_interval_tier()`
- ✅ `add_point_tier()`  
- ✅ `remove_tier()`
- ✅ `extract_part()`

#### Tasks

**A. Add Missing C++ Wrappers** (`src/textgrid_wrappers.cpp`):

```cpp
// [[Rcpp::export(.textgrid_duplicate_tier)]]
void textgrid_duplicate_tier(
    Rcpp::XPtr<structTextGrid> xptr,
    int tier_number,
    const std::string& new_name
);

// [[Rcpp::export(.textgrid_set_tier_name)]]
void textgrid_set_tier_name(
    Rcpp::XPtr<structTextGrid> xptr,
    int tier_number,
    const std::string& name
);
```

**B. Add R6 Methods** (`R/textgrid-r6.R`):

```r
duplicate_tier = function(tier, new_name) {
  tier_num <- private$resolve_tier_number(tier)
  .textgrid_duplicate_tier(private$ptr, tier_num, as.character(new_name))
  invisible(self)
},

set_tier_name = function(tier, name) {
  tier_num <- private$resolve_tier_number(tier)
  .textgrid_set_tier_name(private$ptr, tier_num, as.character(name))
  invisible(self)
}
```

**C. Comprehensive Testing with Benchmark Files**

Use the new benchmark TextGrids:
- `inst/extdata/benchmarkdata60min.TextGrid` (77MB)
- `inst/extdata/benchmarkdata90min.TextGrid` (116MB)

Create `tests/testthat/test-textgrid-benchmark.R`:

```r
test_that("TextGrid handles large benchmark files", {
  # Read large TextGrid
  tg <- TextGrid$new("inst/extdata/benchmarkdata60min.TextGrid")
  
  # Verify structure
  expect_gt(tg$get_number_of_tiers(), 0)
  expect_gt(tg$get_end_time(), 0)
  
  # Test all tier operations
  # ... extensive tests
})
```

**D. Documentation**

- Update man pages
- Add benchmark file examples
- Create vignette: `vignettes/textgrid-workflows.Rmd`

**Deliverables**:
- [ ] 2 new methods (duplicate_tier, set_tier_name)
- [ ] Comprehensive benchmark tests
- [ ] Complete documentation
- [ ] Version bump → 0.4.1
- [ ] Git commit & push

---

### Phase 2: Complete LPC Object (Priority: ⭐⭐)

**Status**: Stubbed but non-functional  
**Time**: 2-3 days  
**Target Version**: 0.4.2

#### Why Needed

- Alternative formant extraction
- Speech coding applications
- Spectral envelope estimation
- Completeness (referenced by Sound methods)

#### Implementation

**A. Transform `src/lpc_stub.cpp` → `src/lpc_wrappers.cpp`**

Include proper Praat headers:
```cpp
#include "LPC/LPC.h"
#include "fon/Formant.h"
#include "fon/Spectrum.h"
```

Implement wrappers:
```cpp
// [[Rcpp::export(.lpc_get_number_of_frames)]]
int lpc_get_number_of_frames(Rcpp::XPtr<structLPC> xptr);

// [[Rcpp::export(.lpc_get_number_of_coefficients)]]
int lpc_get_number_of_coefficients(Rcpp::XPtr<structLPC> xptr, int frame);

// [[Rcpp::export(.lpc_get_coefficient)]]
double lpc_get_coefficient(Rcpp::XPtr<structLPC> xptr, int frame, int coef);

// [[Rcpp::export(.lpc_to_formant)]]
Rcpp::XPtr<structFormant> lpc_to_formant(
    Rcpp::XPtr<structLPC> xptr,
    int max_formants
);

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

**B. Create Full R6 Class** (`R/lpc-r6.R`)

```r
LPC <- R6Class("LPC",
  inherit = PraatObject,
  
  public = list(
    # Queries
    get_number_of_frames = function(),
    get_number_of_coefficients = function(frame),
    get_coefficient = function(frame, coefficient),
    get_sampling_interval = function(),
    
    # Transformations
    to_formant = function(max_formants = 5),
    to_spectrum = function(time, sampling_frequency, bandwidth),
    
    # Export
    as_matrix = function(),
    as_data_frame = function()
  )
)
```

**C. Fix Sound → LPC Connection**

Update `R/sound-r6-new.R`:
```r
to_lpc_burg = function(
    prediction_order = 16,
    analysis_window_duration = 0.025,
    time_step = 0.005,
    pre_emphasis_frequency = 50.0
) {
  lpc_ptr <- .sound_to_lpc_burg(
    private$ptr,
    as.integer(prediction_order),
    as.numeric(analysis_window_duration),
    as.numeric(time_step),
    as.numeric(pre_emphasis_frequency)
  )
  LPC$new(.xptr = lpc_ptr)
}
```

**D. Tests & Documentation**

- `tests/testthat/test-lpc.R` - Full test suite
- Validate LPC→Formant against Burg formants
- Documentation with examples

**Deliverables**:
- [ ] Functional LPC object (~10 methods)
- [ ] Integration tests
- [ ] Documentation
- [ ] Version → 0.4.2
- [ ] Git commit

---

### Phase 3: FormantPath (Priority: ⭐⭐)

**Status**: Not started  
**Time**: 3-4 days  
**Target Version**: 0.4.3

#### Why Important

Modern multi-candidate formant tracking - more accurate than classic Burg method.

#### Implementation

**A. C++ Wrappers** (`src/formantpath_wrappers.cpp`)

```cpp
#include "fon/FormantPath.h"

// Creation
// [[Rcpp::export(.sound_to_formant_path)]]
Rcpp::XPtr<structFormantPath> sound_to_formant_path(...);

// Queries
// [[Rcpp::export(.formantpath_get_number_of_candidates)]]
int formantpath_get_number_of_candidates(Rcpp::XPtr<structFormantPath> xptr);

// [[Rcpp::export(.formantpath_get_ceiling)]]
double formantpath_get_ceiling(
    Rcpp::XPtr<structFormantPath> xptr,
    int candidate
);

// Extract chosen path
// [[Rcpp::export(.formantpath_extract_formant)]]
Rcpp::XPtr<structFormant> formantpath_extract_formant(
    Rcpp::XPtr<structFormantPath> xptr
);

// Get optimal values
// [[Rcpp::export(.formantpath_get_optimal_formant)]]
double formantpath_get_optimal_formant(
    Rcpp::XPtr<structFormantPath> xptr,
    double time,
    int formant_number
);
```

**B. R6 Class** (`R/formantpath-r6.R`)

```r
FormantPath <- R6Class("FormantPath",
  inherit = PraatObject,
  
  public = list(
    get_number_of_candidates = function(),
    get_ceiling = function(candidate),
    extract_formant = function(),
    get_optimal_formant_at = function(time, formant_number),
    get_optimal_bandwidth_at = function(time, formant_number),
    as_data_frame = function()
  )
)
```

**C. Add to Sound**

```r
to_formant_path = function(
    time_step = 0.0,
    max_num_formants = 5,
    mid_formant_ceiling = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
) {
  # Implementation
}
```

**Deliverables**:
- [ ] FormantPath object (~15 methods)
- [ ] Tests comparing with Burg method
- [ ] Documentation & examples
- [ ] Version → 0.4.3
- [ ] Git commit

---

### Phase 4: FormantGrid (Priority: ⭐⭐)

**Status**: Not started  
**Time**: 3-4 days  
**Target Version**: 0.4.4

#### Why Needed

Enables precise formant modification for voice transformation.

#### Implementation

Similar structure to PitchTier, IntensityTier:

**A. C++ Wrappers** (`src/formantgrid_wrappers.cpp`)

**B. R6 Class** (`R/formantgrid-r6.R`)

```r
FormantGrid <- R6Class("FormantGrid",
  inherit = PraatObject,
  
  public = list(
    get_number_of_formants = function(),
    add_formant_point = function(formant_number, time, value),
    add_bandwidth_point = function(formant_number, time, value),
    remove_formant_points_between = function(formant_number, t1, t2),
    get_formant_at_time = function(formant_number, time),
    get_bandwidth_at_time = function(formant_number, time),
    as_data_frame = function()
  )
)
```

**Deliverables**:
- [ ] FormantGrid object (~15 methods)
- [ ] Integration with Manipulation
- [ ] Tests & documentation
- [ ] Version → 0.4.4
- [ ] Git commit

---

### Phase 5: Matrix & Table (Priority: ⭐ OPTIONAL)

**Status**: Not started  
**Time**: 2 days  
**Target Version**: 0.4.5

#### Note

Low priority - R already has excellent native structures (matrix, data.frame, tibble).

#### Minimal Implementation

**Matrix** - Just enough for completeness:
```r
Matrix <- R6Class("Matrix",
  public = list(
    get_number_of_rows = function(),
    get_number_of_columns = function(),
    get_value = function(row, col),
    as_matrix = function()  # Main use case
  )
)
```

**Table** - Very limited:
```r
Table <- R6Class("Table",
  public = list(
    as_data_frame = function()  # Main use case
  )
)
```

**Recommendation**: Document that R users should prefer native R data structures.

**Deliverables**:
- [ ] Minimal Matrix & Table objects
- [ ] Documentation recommending R alternatives
- [ ] Version → 0.4.5
- [ ] Git commit

---

### Phase 6: Implement superassp Examples (Priority: ⭐⭐⭐)

**Status**: Not started  
**Time**: 1 week  
**Target Version**: 0.5.0

#### Goal

Demonstrate Python (Parselmouth) → R (speaker) migration.

#### Source

Analyze `/Users/frkkan96/Documents/src/superassp/inst/python/*.py` files.

#### Output Structure

Create `inst/examples/` with:

1. **pitch_tracking.R** - From `praat_pitch.py`
2. **formant_tracking.R** - From `praat_formant_burg.py`
3. **formant_path.R** - From `praat_formantpath_burg.py`
4. **intensity_analysis.R** - From `praat_intensity.py`
5. **spectral_moments.R** - From `praat_spectral_moments.py`
6. **voice_report.R** - From `praat_voice_report_memory.py`
7. **avqi.R** - From `praat_avqi_memory.py`
8. **dsi.R** - From `praat_dsi_memory.py`
9. **praatsauce.R** - From `praat_praatsauce_memory.py`
10. **sauce.R** - From `praat_sauce_memory.py`
11. **voice_tremor.R** - From `praat_voice_tremor_memory.py`

#### Format

Each file shows Python → R translation:

```r
#' ---
#' title: "Example: Pitch Tracking"
#' subtitle: "Migration from Parselmouth to speaker"
#' ---

#' ## Original Python (Parselmouth)
#' ```python
#' import parselmouth as pm
#' sound = pm.Sound("audio.wav")
#' pitch = sound.to_pitch_ac(0.01, 75, 600)
#' mean_f0 = pm.praat.call(pitch, "Get mean", 0, 0, "Hertz")
#' ```

#' ## Equivalent R (speaker)
library(speaker)

sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch_ac(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(unit = "hertz")

# Full implementation...
```

Create `inst/examples/README.md` with migration guide.

**Deliverables**:
- [ ] 11 complete example scripts
- [ ] Side-by-side Python/R comparisons
- [ ] Migration guide README
- [ ] Sample data in `inst/extdata/`
- [ ] Version → 0.5.0 (Feature Complete)
- [ ] Git commit

---

### Phase 7: Comprehensive Documentation (Priority: ⭐⭐⭐)

**Time**: 1 week  
**Target Version**: 0.5.1

#### Vignettes

Create/update in `vignettes/`:

1. ✅ `getting-started.Rmd`
2. ✅ `sound-objects.Rmd`
3. ✅ `pitch-analysis.Rmd`
4. ✅ `formant-tracking.Rmd`
5. 🆕 `textgrid-workflows.Rmd` - Annotation & segmentation
6. ✅ `voice-quality.Rmd`
7. ✅ `spectral-analysis.Rmd`
8. ✅ `pitch-manipulation.Rmd`
9. 🆕 `praat-script-translation.Rmd` - Praat → R guide
10. 🆕 `parselmouth-migration.Rmd` - Python → R guide

#### Reference Documentation

- Complete all Rd files (19 R6 classes)
- Method-level examples
- Cross-references
- Package overview

#### Package Website

```bash
pkgdown::build_site()
```

Deploy to GitHub Pages.

**Deliverables**:
- [ ] 10 comprehensive vignettes
- [ ] Complete reference docs
- [ ] Package website online
- [ ] Version → 0.5.1
- [ ] Git commit

---

### Phase 8: Testing & Validation (Priority: ⭐⭐⭐)

**Time**: 1 week  
**Target Version**: 0.6.0

#### Coverage Targets

- R code: >95%
- C++ code: >85%

#### Test Files

Expand in `tests/testthat/`:

- `test-textgrid-benchmark.R` - Use 60min & 90min benchmark files
- `test-lpc.R` - Full LPC tests
- `test-formantpath.R` - FormantPath tests
- `test-formantgrid.R` - FormantGrid tests
- `test-integration.R` - Complete workflows
- `test-memory.R` - Memory leak detection

#### Validation Tests

Create `tests/validation/`:

```r
test_that("Values match Praat desktop", {
  sound <- Sound$new("reference/vowel.wav")
  pitch <- sound$to_pitch()
  mean_f0 <- pitch$get_mean(unit = "hertz")
  
  # Compare with known Praat value
  expect_equal(mean_f0, 123.45, tolerance = 0.01)
})
```

#### Benchmarking

Create `tests/benchmarks/`:

```r
library(bench)

bench::mark(
  speaker_pitch = {
    sound <- Sound$new("audio.wav")
    pitch <- sound$to_pitch()
  },
  check = FALSE
)
```

**Deliverables**:
- [ ] 300+ unit tests
- [ ] Validation against Praat
- [ ] Performance benchmarks
- [ ] Memory leak tests (valgrind)
- [ ] Version → 0.6.0
- [ ] Git commit

---

### Phase 9: CRAN Submission (Priority: ⭐⭐⭐)

**Time**: 1 week  
**Target Version**: 1.0.0

#### Pre-submission

```bash
R CMD check --as-cran
# Target: 0 errors, 0 warnings, 0 notes
```

#### DESCRIPTION Updates

```r
Package: speaker
Title: Object-Oriented Interface to Praat for Phonetic Analysis
Version: 1.0.0
Authors@R: c(
    person("Fredrik", "Nylén", , "fredrik.nylen@umu.se", 
           role = c("aut", "cre"),
           comment = c(ORCID = "0000-0003-3373-0934"))
)
Description: Provides a comprehensive object-oriented interface to the Praat
    phonetic analysis software. Exposes Praat's C++ objects (Sound, Pitch,
    Formant, TextGrid, etc.) as R6 classes with direct method access, enabling
    complete phonetic analysis workflows in R without Python dependencies.
License: MIT + file LICENSE
URL: https://github.com/humlab-speech/speaker
BugReports: https://github.com/humlab-speech/speaker/issues
Depends: R (>= 4.0.0)
Imports: Rcpp (>= 1.0.0), R6 (>= 2.5.0)
LinkingTo: Rcpp
Suggests: testthat (>= 3.0.0), knitr, rmarkdown, bench, av
SystemRequirements: C++17
```

#### Submission Checklist

- [ ] All examples run
- [ ] All vignettes build
- [ ] Package size reasonable
- [ ] LICENSE file correct
- [ ] NEWS.md complete
- [ ] README.md with badges
- [ ] CITATION file
- [ ] cran-comments.md

#### Submit

```r
devtools::release()
```

**Deliverables**:
- [ ] CRAN submission
- [ ] Version → 1.0.0 🎉
- [ ] Publication announcement
- [ ] Git tag & release

---

## Object Completion Status

### ✅ Complete (13 objects, ~270 methods)

| Object | Methods | Status |
|--------|---------|--------|
| Sound | ~50 | ✅ Complete |
| Pitch | ~30 | ✅ Complete |
| Formant | ~20 | ✅ Complete |
| Intensity | ~15 | ✅ Complete |
| Harmonicity | ~15 | ✅ Complete |
| Spectrogram | ~15 | ✅ Complete |
| Spectrum | ~18 | ✅ Complete |
| Ltas | ~12 | ✅ Complete |
| PointProcess | ~20 | ✅ Complete |
| Manipulation | ~12 | ✅ Complete |
| PitchTier | ~12 | ✅ Complete |
| IntensityTier | ~10 | ✅ Complete |
| DurationTier | ~10 | ✅ Complete |

### 🚧 Nearly Complete (1 object)

| Object | Progress | Missing |
|--------|----------|---------|
| TextGrid | 33/35 (94%) | duplicate_tier, set_tier_name |

### ❌ To Implement (5 objects)

| Object | Priority | Methods | Estimated Time |
|--------|----------|---------|----------------|
| LPC | ⭐⭐ | ~10 | 2-3 days |
| FormantPath | ⭐⭐ | ~15 | 3-4 days |
| FormantGrid | ⭐⭐ | ~15 | 3-4 days |
| Matrix | ⭐ | ~5 | 1 day |
| Table | ⭐ | ~3 | 1 day |

---

## Timeline to v1.0.0

| Week | Phase | Deliverable | Version |
|------|-------|-------------|---------|
| 1 | TextGrid completion | 100% TextGrid | 0.4.1 |
| 2 | LPC implementation | Functional LPC | 0.4.2 |
| 3 | FormantPath | Modern formant tracking | 0.4.3 |
| 4 | FormantGrid | Formant modification | 0.4.4 |
| 5 | Matrix & Table | All objects complete | 0.4.5 |
| 6-7 | Examples | 11 Python→R examples | 0.5.0 |
| 8 | Documentation | Complete vignettes & website | 0.5.1 |
| 9 | Testing | Validation & benchmarks | 0.6.0 |
| 10 | CRAN prep | CRAN submission | 1.0.0 🎉 |

---

## Success Criteria for v1.0.0

### Completeness
- [ ] 19 Praat objects as R6 classes
- [ ] ~390 methods implemented
- [ ] All superassp examples re-implemented
- [ ] Complete Praat functionality coverage

### Quality
- [ ] Zero memory leaks (valgrind clean)
- [ ] Test coverage >95% (R), >85% (C++)
- [ ] Performance within 10% of Praat
- [ ] Validated against Praat desktop
- [ ] Cross-platform (macOS, Linux, Windows)

### Documentation
- [ ] 10 comprehensive vignettes
- [ ] Complete reference documentation
- [ ] Migration guides (Praat & Parselmouth)
- [ ] Package website deployed
- [ ] 11 example scripts

### Distribution
- [ ] CRAN accepted
- [ ] GitHub releases
- [ ] DOI via Zenodo
- [ ] JOSS publication

---

## Next Steps (Immediate)

1. ✅ Document this plan → `OOP_IMPLEMENTATION_PLAN_FINAL.md`
2. 🔄 **START Phase 1**: Complete TextGrid
   - Add duplicate_tier() method
   - Add set_tier_name() method
   - Create benchmark tests
   - Update documentation
   - Bump version to 0.4.1
   - Commit & push

3. Continue with Phase 2-9 sequentially

---

## Notes on Design Decisions

### Why R6 over S3/S4?

- ✅ True OOP with encapsulation
- ✅ External pointer management
- ✅ Method chaining support
- ✅ Familiar to users from other OOP languages
- ✅ Better RStudio autocomplete

### Why Not Pipe Praat Through System Calls?

- ❌ Would require Praat installation
- ❌ File I/O overhead
- ❌ No access to intermediate objects
- ❌ Hard to integrate in R workflows
- ✅ Direct C++ binding is faster & cleaner

### Why Not Use Parselmouth via reticulate?

- ❌ Requires Python installation
- ❌ Two-language dependency hell
- ❌ Overhead of Python interpreter
- ❌ Awkward R ↔ Python data conversion
- ✅ Native R solution is cleaner

### Integration Strategy for Future Objects

When adding new Praat objects:

1. Check Praat source in `inst/include/praat/`
2. Identify C++ struct and methods
3. Create C++ wrappers in `src/*_wrappers.cpp`
4. Create R6 class in `R/*-r6.R` inheriting from `PraatObject`
5. Follow naming conventions (see below)
6. Add tests in `tests/testthat/test-*.R`
7. Document in Rd files
8. Add vignette examples if major object

### Naming Convention Reference

| Praat Command | R6 Method | Pattern |
|---------------|-----------|---------|
| `Get <property>` | `get_<property>()` | Query |
| `Get <property>...` (with params) | `get_<property>(...)` | Parametric query |
| `To <Object>...` | `to_<object>(...)` | Transformation |
| `Extract <thing>...` | `extract_<thing>(...)` | Extraction |
| `<Verb> <object>...` | `<verb>_<object>(...)` | Action |
| `Down to <Type>` | `as_<type>()` | Conversion |
| `Save as...` | `save(path, ...)` | I/O |
| `Read from file...` | `$new(path)` | Constructor |
| `Create <Object>...` | `$create(...)` | Static constructor |

**Examples**:
- `Get mean...` → `get_mean(from_time, to_time, unit)`
- `To Pitch (ac)...` → `to_pitch_ac(...)`
- `To Pitch (cc)...` → `to_pitch_cc(...)`
- `Extract part...` → `extract_part(start, end, preserve_times)`
- `Scale intensity...` → `scale_intensity(new_level)`
- `Down to Matrix` → `as_matrix()`
- `Create Sound from formula...` → `Sound$create_from_formula(...)`

This ensures:
- ✅ Praat scripts translate easily to R
- ✅ Consistent API across all objects
- ✅ Predictable method names
- ✅ Good autocomplete experience

---

## Conclusion

The `speaker` package has successfully established an object-oriented architecture that directly mirrors Praat's C++ design. With 13 of 19 core objects complete (~270 methods), we are 68% complete. 

The remaining work follows a clear roadmap:
- **Weeks 1-5**: Complete remaining objects
- **Weeks 6-7**: Implement example migrations
- **Week 8**: Documentation
- **Week 9**: Testing & validation
- **Week 10**: CRAN submission

**Target**: v1.0.0 on CRAN in 10 weeks 🎉
