# Complete OOP Roadmap for speaker Package
## Object-Oriented Praat in R - Final Plan
**Date**: 2025-11-12  
**Current Version**: 0.4.1  
**Target Version**: 1.0.0  
**Architecture**: R6 + External Pointers to Praat C++ Objects

---

## Executive Summary

This roadmap finalizes the transformation of the `speaker` package into a **complete object-oriented interface to Praat**, mirroring Praat's own C++ architecture and improving upon Python's Parselmouth library.

### Key Insight: OOP Over Procedures

**Original Spec Approach** (Procedure-Focused):
- Implement `extract_pitch()` function
- Implement `analyze_formants()` function
- Implement `calculate_intensity()` function

**Correct Approach** (Object-Oriented):
- Implement `Sound` object with methods
- Implement `Pitch` object with methods
- Implement `Formant` object with methods
- Enable: `sound$to_pitch()$get_mean()`

### Why This Matters

**Praat Script**:
```praat
sound = Read from file: "audio.wav"
pitch = To Pitch: 0.01, 75, 600
mean_f0 = Get mean: 0, 0, "Hertz"
formant = select sound
To Formant (burg): 5, 5000, 0.025, 50
f1 = Get value at time: 1, 0.5, "Hertz"
```

**Direct R Translation** (Our Approach):
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
formant <- sound$to_formant_burg(num_formants = 5, max_formant = 5000, 
                                  window_length = 0.025, pre_emphasis = 50)
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5, unit = "hertz")
```

**Advantages Over Parselmouth**:
1. ✅ No `praat.call()` string dispatcher
2. ✅ Type-safe parameters with autocomplete
3. ✅ No Python interpreter overhead
4. ✅ Native R integration
5. ✅ Better error messages

---

## Current Status (v0.4.1)

### ✅ Completed Objects: 15/19 (79%)

| Object | Methods | Key Capabilities |
|--------|---------|------------------|
| **Sound** | 54 | File I/O, generation, all analysis conversions, filtering, modification |
| **Pitch** | 30 | All query methods, statistics, conversion to tier/point process |
| **Formant** | 23 | Query by time/formant number, tracking, statistics, export |
| **Intensity** | 15 | Intensity queries, statistics, conversion to tier |
| **Harmonicity** | 15 | HNR analysis, statistics, export |
| **Spectrogram** | 15 | Time-frequency analysis, slice extraction, conversions |
| **Spectrum** | 18 | FFT operations, spectral moments, filtering |
| **Ltas** | 12 | Long-term average spectrum, slope analysis |
| **PointProcess** | 20 | **Jitter/shimmer** (all types), point manipulation |
| **Manipulation** | 12 | **PSOLA** pitch/duration modification, resynthesis |
| **PitchTier** | 12 | Modifiable pitch contour, stylization |
| **IntensityTier** | 10 | Modifiable intensity envelope |
| **DurationTier** | 10 | Duration modification points |
| **LPC** | 15 | Linear predictive coding, coefficient access |
| **TextGrid** | 34 | **Linguistic annotation** - full tier management |

**Total**: ~305 methods implemented

### ❌ Remaining Objects: 4/19 (21%)

| Priority | Object | Est. Methods | Why Needed |
|----------|--------|--------------|------------|
| ⭐⭐⭐ | **FormantPath** | 20 | Modern multi-candidate formant tracking (Praat 6.1+) |
| ⭐⭐⭐ | **Table** | 40 | Data export structure (many methods return Tables) |
| ⭐⭐ | **Matrix** | 15 | 2D numerical operations, base for many objects |
| ⭐ | **FormantGrid** | 20 | Modifiable formant contours for voice transformation |

---

## The Praat Object Hierarchy

### Implemented Structure

```
Thing (base: PraatObject in praat-object.R)
├── Function
│   ├── Sampled
│   │   ├── ✅ Sound (waveform data)
│   │   ├── ✅ Pitch (F0 contour)
│   │   ├── ✅ Intensity (intensity contour)
│   │   ├── ✅ Harmonicity (HNR contour)
│   │   ├── ✅ Formant (formant tracks)
│   │   ├── ❌ FormantPath (modern formant tracking)
│   │   ├── ✅ PointProcess (time points - glottal pulses)
│   │   ├── ✅ Spectrogram (time-frequency matrix)
│   │   ├── ✅ Spectrum (frequency domain)
│   │   ├── ✅ Ltas (long-term spectrum)
│   │   ├── ✅ LPC (linear prediction)
│   │   └── ❌ Matrix (2D data)
│   ├── Function1 (time-varying tiers)
│   │   ├── ✅ PitchTier (modifiable F0)
│   │   ├── ✅ IntensityTier (modifiable intensity)
│   │   ├── ✅ DurationTier (modifiable duration)
│   │   └── ❌ FormantGrid (modifiable formants)
│   └── ✅ Manipulation (PSOLA synthesis)
├── ✅ TextGrid (linguistic annotation)
└── ❌ Table (tabular data)
```

### Coverage Analysis

**Core Analysis Objects**: 11/12 (92%) ✅
- Missing: FormantPath

**Modification/Synthesis**: 4/5 (80%) ✅
- Missing: FormantGrid

**Data Structures**: 1/2 (50%) ⚠️
- Missing: Table

**Annotation**: 1/1 (100%) ✅

---

## Phase-by-Phase Implementation Plan

### Phase 2: FormantPath (NEXT - Week 1)

**Priority**: CRITICAL ⭐⭐⭐

**Why**: Modern formant tracking with multiple candidates. Praat 6.1+ recommends this over classic Burg method.

**Implementation**:

1. **C++ Wrapper** (`src/formantpath_wrappers.cpp`):
```cpp
// [[Rcpp::export(".sound_to_formant_path_burg")]]
XPtr<structFormantPath> sound_to_formant_path_burg(
  XPtr<structSound> sound,
  double time_step,
  int max_num_formants,
  double max_formant,
  double window_length,
  double pre_emphasis,
  double margin
);

// [[Rcpp::export(".formantpath_extract_formant")]]
XPtr<structFormant> formantpath_extract_formant(XPtr<structFormantPath> fp);

// [[Rcpp::export(".formantpath_get_num_candidates")]]
int formantpath_get_num_candidates(XPtr<structFormantPath> fp, int iframe);
```

2. **R6 Class** (`R/formantpath-r6.R`):
```r
FormantPath <- R6::R6Class(
  "FormantPath",
  inherit = PraatObject,
  
  public = list(
    # Creation
    initialize = function(.xptr) { ... },
    
    # Query methods
    get_number_of_candidates = function(time) { ... },
    get_candidate_frequency = function(candidate, formant_number, time) { ... },
    get_optimal_ceiling = function() { ... },
    
    # Extraction
    extract_formant = function() {
      # Returns Formant R6 object
      xptr <- .formantpath_extract_formant(private$.xptr)
      Formant$new(.xptr = xptr)
    },
    
    # Export
    as_data_frame = function() { ... }
  )
)
```

3. **Sound Integration** (`R/sound-r6-new.R`):
```r
# Add to Sound class
to_formant_path_burg = function(
  time_step = 0.0,
  max_num_formants = 5,
  max_formant = 5500.0,
  window_length = 0.025,
  pre_emphasis = 50.0,
  margin = 50.0
) {
  xptr <- .sound_to_formant_path_burg(
    private$.xptr, time_step, max_num_formants, 
    max_formant, window_length, pre_emphasis, margin
  )
  FormantPath$new(.xptr = xptr)
}
```

4. **Tests** (`tests/testthat/test-formantpath.R`):
- Compare FormantPath vs. classic Formant
- Multiple ceiling candidates
- Export to data frame
- Integration with real speech data

**Estimated Time**: 3-4 days

**Version Bump**: 0.4.1 → 0.5.0 (new object = minor version)

---

### Phase 3: Table (Week 2)

**Priority**: CRITICAL ⭐⭐⭐

**Why**: Many Praat methods return Tables. Already needed by `formant$down_to_table()`.

**Implementation**:

1. **C++ Wrapper** (`src/table_wrappers.cpp`):
```cpp
// Creation
// [[Rcpp::export(".table_create")]]
XPtr<structTable> table_create(int num_rows, CharacterVector col_names);

// Query
// [[Rcpp::export(".table_get_num_rows")]]
int table_get_num_rows(XPtr<structTable> table);

// [[Rcpp::export(".table_get_num_cols")]]
int table_get_num_cols(XPtr<structTable> table);

// [[Rcpp::export(".table_get_value")]]
double table_get_value(XPtr<structTable> table, int row, String col);

// [[Rcpp::export(".table_get_string_value")]]
String table_get_string_value(XPtr<structTable> table, int row, String col);

// Modification
// [[Rcpp::export(".table_set_value")]]
void table_set_value(XPtr<structTable> table, int row, String col, double value);

// I/O
// [[Rcpp::export(".table_read")]]
XPtr<structTable> table_read(String path);

// [[Rcpp::export(".table_save")]]
void table_save(XPtr<structTable> table, String path);

// Export to R
// [[Rcpp::export(".table_to_dataframe")]]
DataFrame table_to_dataframe(XPtr<structTable> table);
```

2. **R6 Class** (`R/table-r6.R`):
```r
Table <- R6::R6Class(
  "Table",
  inherit = PraatObject,
  
  public = list(
    # Creation
    initialize = function(.xptr = NULL, num_rows = NULL, col_names = NULL) {
      if (!is.null(.xptr)) {
        private$.xptr <- .xptr
      } else {
        private$.xptr <- .table_create(num_rows, col_names)
      }
      private$set_finalizer()
    },
    
    # Query
    get_number_of_rows = function() { ... },
    get_number_of_columns = function() { ... },
    get_column_label = function(col) { ... },
    get_value = function(row, col) { ... },
    get_string_value = function(row, col) { ... },
    
    # Modification
    set_value = function(row, col, value) { ... },
    insert_row = function(position) { ... },
    remove_row = function(row) { ... },
    append_column = function(name) { ... },
    
    # Search
    find_row = function(column, value) { ... },
    
    # Statistics
    get_mean = function(column) { ... },
    get_stdev = function(column) { ... },
    
    # Export
    as_data_frame = function() {
      .table_to_dataframe(private$.xptr)
    },
    
    save = function(path) { ... }
  )
)

# S3 method for conversion
as.data.frame.Table <- function(x, ...) {
  x$as_data_frame()
}
```

3. **Tests** (`tests/testthat/test-table.R`):
- Create from scratch
- Read from file
- Get/set values
- Statistics
- Export to data.frame
- Integration with Formant$down_to_table()

**Estimated Time**: 4-5 days (40 methods)

**Version Bump**: 0.5.0 → 0.6.0

---

### Phase 4: Matrix (Week 3)

**Priority**: MEDIUM ⭐⭐

**Why**: Base class for many Praat objects. Useful for custom numerical analyses.

**Implementation**:

1. **C++ Wrapper** (`src/matrix_wrappers.cpp`):
```cpp
// [[Rcpp::export(".matrix_create")]]
XPtr<structMatrix> matrix_create(
  double xmin, double xmax, int nx, double dx, double x1,
  double ymin, double ymax, int ny, double dy, double y1
);

// [[Rcpp::export(".matrix_get_value")]]
double matrix_get_value(XPtr<structMatrix> mat, int row, int col);

// [[Rcpp::export(".matrix_to_rmatrix")]]
NumericMatrix matrix_to_rmatrix(XPtr<structMatrix> mat);
```

2. **R6 Class** (`R/matrix-r6.R`):
```r
Matrix <- R6::R6Class(
  "Matrix",
  inherit = PraatObject,
  
  public = list(
    # Query
    get_number_of_rows = function() { ... },
    get_number_of_columns = function() { ... },
    get_value = function(row, col) { ... },
    get_value_at_xy = function(x, y) { ... },
    
    # Statistics
    get_row_sum = function(row) { ... },
    get_column_sum = function(col) { ... },
    get_mean = function() { ... },
    
    # Export
    as_matrix = function() {
      .matrix_to_rmatrix(private$.xptr)
    },
    
    save = function(path) { ... }
  )
)
```

**Estimated Time**: 2-3 days

**Version Bump**: 0.6.0 → 0.7.0

---

### Phase 5: FormantGrid (Week 4)

**Priority**: LOW ⭐ (Advanced synthesis users only)

**Why**: Modifiable formant contours for voice transformation. Similar to PitchTier but for formants.

**Implementation**:

1. **C++ Wrapper** (`src/formantgrid_wrappers.cpp`):
```cpp
// [[Rcpp::export(".formant_to_formant_grid")]]
XPtr<structFormantGrid> formant_to_formant_grid(XPtr<structFormant> formant);

// [[Rcpp::export(".formantgrid_add_formant_point")]]
void formantgrid_add_formant_point(
  XPtr<structFormantGrid> fg,
  int formant_number,
  double time,
  double value
);

// [[Rcpp::export(".formantgrid_to_formant")]]
XPtr<structFormant> formantgrid_to_formant(
  XPtr<structFormantGrid> fg,
  double time_step
);
```

2. **R6 Class** (`R/formantgrid-r6.R`):
```r
FormantGrid <- R6::R6Class(
  "FormantGrid",
  inherit = PraatObject,
  
  public = list(
    # Modification
    add_formant_point = function(formant_number, time, value) { ... },
    remove_formant_point = function(formant_number, index) { ... },
    
    # Query
    get_formant_at_time = function(formant_number, time) { ... },
    
    # Conversion
    to_formant = function(time_step = 0.01) {
      xptr <- .formantgrid_to_formant(private$.xptr, time_step)
      Formant$new(.xptr = xptr)
    }
  )
)
```

**Estimated Time**: 3-4 days

**Version Bump**: 0.7.0 → 0.8.0

---

## Phase 6: Examples from superassp (Week 5)

**Goal**: Reimplement all Python examples using `speaker`

**Location**: Create `inst/examples/` directory

**Strategy**:

1. Analyze each Python file in `/Users/frkkan96/Documents/src/superassp/inst/python/`
2. Create equivalent R code using `speaker` objects
3. Demonstrate advantages of native R approach
4. Benchmark performance (R should be faster - no Python interpreter)

**Examples to Convert**:

### Example 1: Voice Report
**Python** (`praat_voice_report_memory.py`):
```python
import parselmouth
from parselmouth.praat import call

sound = parselmouth.Sound(audio_path)
point_process = call(sound, "To PointProcess (periodic, cc)", 75, 600)
jitter = call([sound, point_process], "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)
shimmer = call([sound, point_process], "Get shimmer (local)", 0, 0, 0.0001, 0.02, 1.3, 1.6)
hnr = call(sound, "To Harmonicity (cc)", 0.01, 75, 0.1, 1.0)
mean_hnr = call(hnr, "Get mean", 0, 0)
```

**R** (`inst/examples/voice_report.R`):
```r
library(speaker)

sound <- Sound$new(audio_path)

# Get point process
point_process <- sound$to_point_process_periodic_cc(
  pitch_floor = 75,
  pitch_ceiling = 600
)

# Voice quality metrics (direct methods!)
jitter <- point_process$get_jitter_local(
  sound,
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3
)

shimmer <- point_process$get_shimmer_local(
  sound,
  period_floor = 0.0001,
  period_ceiling = 0.02,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)

# Harmonicity
harmonicity <- sound$to_harmonicity_cc(
  time_step = 0.01,
  minimum_pitch = 75,
  silence_threshold = 0.1,
  periods_per_window = 1.0
)
mean_hnr <- harmonicity$get_mean(from_time = 0, to_time = 0)

# Create report
voice_report <- list(
  jitter_local = jitter,
  shimmer_local = shimmer,
  mean_hnr = mean_hnr
)
```

### Example 2: Formant Extraction
**Python**:
```python
formant = sound.to_formant_burg()
f1 = call(formant, "Get value at time", 1, 0.5, "Hertz", "Linear")
```

**R**:
```r
formant <- sound$to_formant_burg()
f1 <- formant$get_value_at_time(
  formant_number = 1,
  time = 0.5,
  unit = "hertz",
  interpolation = "linear"
)
```

### Example 3: Pitch Manipulation
**Python**:
```python
manipulation = call(sound, "To Manipulation", 0.01, 75, 600)
pitch_tier = call(manipulation, "Extract pitch tier")
call(pitch_tier, "Multiply frequencies", 0, 0, 1.2)  # Raise by 20%
call([manipulation, pitch_tier], "Replace pitch tier")
output = call(manipulation, "Get resynthesis (overlap-add)")
```

**R**:
```r
manipulation <- sound$to_manipulation(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)

pitch_tier <- manipulation$extract_pitch_tier()
pitch_tier$multiply_frequencies(
  from_time = 0,
  to_time = 0,
  factor = 1.2  # Raise by 20%
)

manipulation$replace_pitch_tier(pitch_tier)
output <- manipulation$get_resynthesis_overlap_add()
```

**Deliverables**:
- `inst/examples/voice_quality_report.R`
- `inst/examples/formant_tracking.R`
- `inst/examples/pitch_manipulation.R`
- `inst/examples/spectral_analysis.R`
- `inst/examples/textgrid_annotation.R`
- `inst/examples/README.md` - Comparison with Parselmouth

**Estimated Time**: 1 week

**Version Bump**: 0.8.0 → 0.9.0

---

## Phase 7: Documentation & Vignettes (Week 6)

### Vignettes to Create

1. **Introduction to speaker** (`vignettes/introduction.Rmd`)
   - OOP philosophy
   - Comparison with Praat
   - Comparison with Parselmouth
   - Basic workflow

2. **Acoustic Analysis** (`vignettes/acoustic-analysis.Rmd`)
   - Pitch extraction
   - Formant tracking
   - Intensity analysis
   - Voice quality metrics

3. **Speech Synthesis** (`vignettes/speech-synthesis.Rmd`)
   - PSOLA pitch modification
   - Duration modification
   - Filtering and pre-emphasis

4. **Linguistic Annotation** (`vignettes/textgrids.Rmd`)
   - Reading/writing TextGrids
   - Tier management
   - Forced alignment workflows

5. **Advanced Topics** (`vignettes/advanced.Rmd`)
   - Custom analyses
   - Batch processing
   - Integration with tidyverse
   - Performance optimization

6. **Migrating from Parselmouth** (`vignettes/from-parselmouth.Rmd`)
   - Side-by-side code comparison
   - Performance benchmarks
   - Feature coverage table

**Estimated Time**: 1 week

**Version Bump**: 0.9.0 → 0.9.5

---

## Phase 8: Testing & Polish (Week 7)

### Comprehensive Test Coverage

**Target**: 90%+ code coverage

**Test Suites**:
1. ✅ Unit tests for all 19 objects
2. Integration tests (multi-object workflows)
3. Benchmark tests (using `inst/extdata/benchmarkdata*.TextGrid`)
4. Memory leak tests
5. Error handling tests
6. Edge case tests (empty files, extreme parameters)

### Performance Benchmarks

Compare `speaker` vs. Parselmouth on:
- File loading speed
- Analysis computation time
- Memory usage
- Batch processing throughput

**Expected Results**: `speaker` should be 2-5x faster (no Python overhead)

### Package Validation

- ✅ R CMD check --as-cran (zero warnings)
- ✅ All tests pass
- ✅ Documentation complete
- ✅ Examples run successfully
- ✅ Vignettes build

**Version Bump**: 0.9.5 → 1.0.0

---

## Naming Conventions (Systematic Mapping)

### Praat → R Method Names

**Praat command structure**:
```
[Source Object]: [Action] [Target/Parameter]: [Arguments]
```

**R method naming**:
```r
# Creation/Conversion: to_<object>()
sound$to_pitch()
sound$to_formant_burg()
pitch$to_pitch_tier()

# Queries: get_<property>()
pitch$get_mean()
formant$get_value_at_time()
textgrid$get_interval_text()

# Modifications: set_<property>() or <verb>_<noun>()
textgrid$set_interval_text()
pitch_tier$multiply_frequencies()
sound$pre_emphasize()

# Extraction: extract_<object>()
manipulation$extract_pitch_tier()
textgrid$extract_part()

# Boolean queries: is_<condition>() or has_<feature>()
pitch$is_voiced()
textgrid$has_tier()

# Counts: get_number_of_<items>()
textgrid$get_number_of_tiers()
formant$get_number_of_frames()
```

### Systematic Examples

| Praat Command | R Method |
|---------------|----------|
| To Pitch... | `$to_pitch()` |
| To Formant (burg)... | `$to_formant_burg()` |
| Get mean... | `$get_mean()` |
| Get value at time... | `$get_value_at_time()` |
| To PointProcess (periodic, cc)... | `$to_point_process_periodic_cc()` |
| Extract pitch tier | `$extract_pitch_tier()` |
| Multiply frequencies... | `$multiply_frequencies()` |
| Insert boundary... | `$insert_boundary()` |
| Remove tier... | `$remove_tier()` |

---

## Architecture Documentation

### For Future Object Additions

**Template for New Objects** (`CLAUDE.md` integration):

```markdown
## Adding a New Praat Object to speaker

### 1. Identify the Object

- **Praat class name**: e.g., `FormantPath`
- **Praat source files**: e.g., `fon/FormantPath.cpp`
- **Common use cases**: Modern formant tracking

### 2. Create C++ Wrapper

**File**: `src/<object>_wrappers.cpp`

```cpp
#include <Rcpp.h>
#include "praat_wrapper.h"

// Forward declaration
typedef struct struct<Object> *<Object>;

// Creation
// [[Rcpp::export(".<source>_to_<object>")]]
Rcpp::XPtr<struct<Object>> <source>_to_<object>(
  Rcpp::XPtr<struct<Source>> source,
  // parameters...
) {
  try {
    praat::initialize_if_needed();
    
    auto<Object> result = <Source>_to_<Object>(
      source.get(),
      // args...
    );
    
    return praat::make_xptr(result);
  } catch (...) {
    praat::handle_praat_error();
  }
}

// Query methods
// [[Rcpp::export(".<object>_get_value")]]
double <object>_get_value(Rcpp::XPtr<struct<Object>> obj) {
  try {
    return <Object>_getValue(obj.get());
  } catch (...) {
    praat::handle_praat_error();
  }
}
```

### 3. Create R6 Class

**File**: `R/<object>-r6.R`

```r
#' @export
<Object> <- R6::R6Class(
  "<Object>",
  inherit = PraatObject,
  
  public = list(
    #' @description Create from external pointer
    initialize = function(.xptr) {
      if (missing(.xptr)) stop("Cannot create directly")
      private$.xptr <- .xptr
      private$set_finalizer()
    },
    
    #' @description Get a value
    get_value = function() {
      .<object>_get_value(private$.xptr)
    }
  )
)
```

### 4. Integration with Source Objects

Add creation methods to source objects (e.g., `Sound`):

```r
# In R/sound-r6-new.R
to_<object> = function(...) {
  xptr <- .<sound>_to_<object>(private$.xptr, ...)
  <Object>$new(.xptr = xptr)
}
```

### 5. Tests

**File**: `tests/testthat/test-<object>.R`

```r
test_that("<Object> creation works", {
  sound <- Sound$new(test_audio_path)
  obj <- sound$to_<object>()
  expect_s3_class(obj, "<Object>")
})

test_that("<Object> methods work", {
  obj <- create_test_<object>()
  value <- obj$get_value()
  expect_true(is.numeric(value))
})
```

### 6. Documentation

- Add to relevant vignettes
- Update NEWS.md
- Add examples to `inst/examples/`
```

---

## Success Criteria for v1.0.0

### Object Coverage
- ✅ 19/19 core Praat objects implemented (100%)
- ✅ ~400 methods across all objects
- ✅ All creation, query, and modification methods

### Code Quality
- ✅ 90%+ test coverage
- ✅ Zero R CMD check warnings
- ✅ Consistent naming conventions
- ✅ Complete documentation

### User Experience
- ✅ 6 comprehensive vignettes
- ✅ 5+ worked examples
- ✅ Migration guide from Parselmouth
- ✅ Performance benchmarks

### Performance
- ✅ 2-5x faster than Parselmouth
- ✅ No memory leaks
- ✅ Efficient batch processing

---

## Timeline Summary

| Week | Phase | Version | Deliverable |
|------|-------|---------|-------------|
| 1 | FormantPath | 0.5.0 | Modern formant tracking |
| 2 | Table | 0.6.0 | Data export infrastructure |
| 3 | Matrix | 0.7.0 | 2D numerical operations |
| 4 | FormantGrid | 0.8.0 | Formant manipulation |
| 5 | Examples | 0.9.0 | superassp migration examples |
| 6 | Documentation | 0.9.5 | Vignettes & guides |
| 7 | Polish | 1.0.0 | **RELEASE** |

**Total Time**: 7 weeks to v1.0.0

---

## Beyond v1.0.0: Future Extensions

### Potential v1.1.0+ Features

1. **Praat Script Interpreter** (HIGH DEMAND)
   - Execute Praat scripts directly from R
   - `run_praat_script("script.praat")`
   - Would require embedding Praat's interpreter

2. **Picture/Graphics System** (MEDIUM DEMAND)
   - Praat's picture window commands
   - Integration with R graphics
   - `pitch$draw()` → ggplot2 object

3. **Advanced Objects** (LOW PRIORITY)
   - Cochleagram (auditory modeling)
   - Excitation (auditory modeling)
   - MFCC (speech recognition)
   - VoiceReport (comprehensive report class)

4. **Streaming API** (LOW PRIORITY)
   - Process audio streams in real-time
   - Useful for live speech analysis

### Notes on Deferred Features

**Praat Script Interpreter**:
- Would allow: `praat_run("To Pitch... 75 600")`
- **Complexity**: High (need to embed Praat's parser)
- **Benefit**: Backward compatibility with existing scripts
- **Decision**: Defer to v1.1.0+
- **Reason**: OOP approach is superior for new code

**Picture System**:
- Praat's drawing commands (Draw..., Paint...)
- **Complexity**: Medium (integrate with R graphics)
- **Benefit**: Publication-quality plots in Praat style
- **Decision**: Defer to v1.1.0+
- **Reason**: R already has excellent plotting (ggplot2, etc.)
- **Alternative**: Provide `$as_data_frame()` for all objects → plot in ggplot2

---

## Key Architectural Decisions

### 1. R6 + External Pointers (✅ CONFIRMED)

**Decision**: Use R6 classes wrapping XPtr to C++ Praat objects

**Rationale**:
- Zero-copy operations (data stays in C++)
- Automatic memory management
- Natural OOP syntax
- Fast method dispatch

**Alternative Considered**: Pure Rcpp with S3 classes
- **Rejected**: Less natural OOP, manual memory management

### 2. Direct Method Calls (✅ CONFIRMED)

**Decision**: Expose each Praat method as a named R6 method

**Rationale**:
- Type-safe parameters
- Autocomplete in RStudio
- Better documentation
- Clear error messages

**Alternative Considered**: Generic `praat_call()` dispatcher (like Parselmouth)
- **Rejected**: Loses type safety, autocomplete, documentation

### 3. No Python Dependency (✅ CONFIRMED)

**Decision**: Direct C++ binding to Praat source code

**Rationale**:
- Faster (no Python interpreter)
- Simpler installation
- Native R integration
- Better debugging

**Alternative Considered**: Wrap Parselmouth
- **Rejected**: Adds unnecessary layer, Python dependency

### 4. Consistent Naming (✅ CONFIRMED)

**Decision**: Systematic Praat command → R method mapping

**Rationale**:
- Easy to learn for Praat users
- Predictable API
- Clear documentation
- Enables automatic transcoding

**Pattern**: `to_<object>()`, `get_<property>()`, `set_<property>()`

### 5. Minimal Redundancy (✅ CONFIRMED)

**Decision**: Don't duplicate R's existing capabilities

**Examples**:
- ✅ Implement `Table` (Praat-specific data structure)
- ❌ Don't implement basic statistics (use R's `mean()`, `sd()`, etc.)
- ✅ Implement `$as_data_frame()` for seamless R integration
- ❌ Don't reimplement plotting (use ggplot2)

### 6. AV Package for Media I/O (✅ CONFIRMED)

**Decision**: Use `av` package (humlab-speech fork) for audio/video loading

**Rationale**:
- Already used in ecosystem
- Handles many formats
- Actively maintained
- Integration point: `Sound$new()` accepts `av::read_audio()` output

**Reference**: https://github.com/humlab-speech/av

---

## Conclusion

This roadmap transforms the `speaker` package from a collection of procedures into a **complete object-oriented interface to Praat**. By following Praat's native C++ architecture, we provide:

1. ✅ **Natural transcoding** - Praat scripts → R code
2. ✅ **Better than Parselmouth** - Type-safe, autocomplete, faster
3. ✅ **Pure R solution** - No Python dependency
4. ✅ **Complete coverage** - All 19 core objects
5. ✅ **Production-ready** - Tested, documented, performant

**Current Status**: 79% complete (15/19 objects)  
**Target**: 100% complete (19/19 objects) in 7 weeks  
**Version 1.0.0**: Full Praat object model in R

The architecture is sound, the pattern is established, and the path forward is clear. Each remaining object follows the same template, making completion systematic and predictable.
