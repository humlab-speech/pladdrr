# Complete Object-Oriented Praat R Package Implementation Plan

**Date**: 2025-11-10  
**Status**: Amended Plan - Focus on Praat Object Completeness  
**Goal**: Mirror Praat's full OOP architecture for seamless Praat-to-R code translation

## Executive Summary

The current implementation has successfully established an R6-based object-oriented architecture that mirrors Praat's design. However, comparing against Parselmouth (Python) examples from `/Users/frkkan96/Documents/src/superassp/inst/python`, we need to:

1. **Complete missing object types** (TextGrid, Spectrum, Ltas, etc.)
2. **Add missing methods** to existing objects to match Praat's API
3. **Ensure consistent naming conventions** for easy Praat code transcoding
4. **Add object manipulation capabilities** (modify, combine, transform)

## Current Implementation Status

### ✅ Completed Objects (with R6 classes)

- **Sound** - Core audio object with most methods
- **Pitch** - F0 extraction and querying
- **Formant** - Formant extraction and tracking
- **Intensity** - Intensity/loudness contour
- **Harmonicity** - HNR calculation
- **PointProcess** - Event marking/timing
- **Manipulation** - Pitch/duration modification
- **PitchTier** - F0 manipulation contour
- **IntensityTier** - Intensity manipulation
- **DurationTier** - Duration modification

### ⚠️ Partially Implemented

- **Spectrogram** - Needs more query methods
- **FormantPath** - Needs implementation (used in Parselmouth examples)

### ❌ Missing Critical Objects

Based on Parselmouth usage in superassp:

1. **TextGrid** - Annotation/segmentation (CRITICAL - widely used)
   - IntervalTier (phoneme/word boundaries)
   - TextTier/PointTier (point labels)
2. **Spectrum** - Frequency domain representation
3. **Ltas** - Long-term average spectrum
4. **FormantGrid** - Detailed formant manipulation
5. **Cochleagram** - Auditory filterbank representation
6. **Excitation** - Excitation pattern

## Parselmouth Usage Analysis

### Key Patterns from `praat_formantpath_burg.py`

```python
# Parselmouth approach:
sound = pm.Sound(file_path)
formant_path = pm.praat.call(sound, "To FormantPath (burg)", ...)
formant = pm.praat.call(formant_path, "Extract Formant")
spectrogram = pm.praat.call(sound, "To Spectrogram", ...)
```

**R Equivalent Should Be**:
```r
sound <- Sound$new(file_path)
formant_path <- sound$to_formant_path_burg(...)
formant <- formant_path$extract_formant()
spectrogram <- sound$to_spectrogram(...)
```

### Key Patterns from `praat_intensity.py`

```python
# Parselmouth approach:
intensity = pm.praat.call(sound, "To Intensity", min_pitch, time_step, subtract_mean)
intensity_tier = pm.praat.call(intensity, "Down to IntensityTier")
table_of_real = pm.praat.call(intensity_tier, "Down to TableOfReal")
table = pm.praat.call(table_of_real, "To Table", "dummy")
```

**R Equivalent Should Be**:
```r
intensity <- sound$to_intensity(min_pitch, time_step, subtract_mean)
intensity_tier <- intensity$down_to_intensity_tier()
table_of_real <- intensity_tier$down_to_table_of_real()
table <- table_of_real$to_table()
```

## Naming Convention Standards

### Principle: Direct Praat Translation

Praat menu/script commands should map 1:1 to R methods using snake_case:

| Praat Command | R Method |
|--------------|----------|
| `To Pitch...` | `to_pitch()` |
| `To Formant (burg)...` | `to_formant_burg()` |
| `To Intensity...` | `to_intensity()` |
| `Down to IntensityTier` | `down_to_intensity_tier()` |
| `Get mean...` | `get_mean()` |
| `Get value at time...` | `get_value_at_time()` |
| `Extract part...` | `extract_part()` |
| `Multiply frequencies...` | `multiply_frequencies()` |
| `To FormantPath (burg)...` | `to_formant_path_burg()` |
| `Extract Formant` | `extract_formant()` |

### Method Categories

1. **Creation/Conversion** - `to_*()`, `from_*()`, `create_*()`
2. **Query** - `get_*()`, `count_*()`
3. **Modification** - `set_*()`, `add_*()`, `remove_*()`, `multiply_*()`, `scale_*()`
4. **Extraction/Reduction** - `extract_*()`, `down_to_*()`
5. **Export** - `as_*()`, `save()`

## Complete Implementation Roadmap

### Phase 1: Complete Critical Missing Objects (Priority 1)

#### 1.1 TextGrid Implementation

**Rationale**: TextGrid is THE most important missing object - essential for annotation-based analysis.

**Files to Create**:
- `R/textgrid-r6.R` - Main TextGrid class
- `R/intervaltier-r6.R` - Interval tier class
- `R/texttier-r6.R` - Point tier class
- `src/praat_textgrid.cpp` - C++ bindings

**Core Methods**:

```r
TextGrid <- R6Class("TextGrid",
  inherit = PraatObject,
  public = list(
    # Creation
    initialize = function(path = NULL, .xptr = NULL),
    
    # Tier management
    get_number_of_tiers = function(),
    get_tier_name = function(tier_number),
    get_tier = function(tier_name_or_number),
    add_interval_tier = function(name),
    add_point_tier = function(name),
    remove_tier = function(tier_name_or_number),
    
    # Querying
    get_label_at_time = function(tier, time),
    get_interval_at_time = function(tier, time),
    get_start_time_of_interval = function(tier, interval_number),
    get_end_time_of_interval = function(tier, interval_number),
    count_labels = function(tier, label),
    
    # Modification
    insert_boundary = function(tier, time),
    remove_boundary = function(tier, time),
    set_interval_text = function(tier, interval_number, text),
    insert_point = function(tier, time, text),
    
    # Export
    save = function(path),
    as_data_frame = function()
  )
)

IntervalTier <- R6Class("IntervalTier",
  inherit = PraatObject,
  public = list(
    get_number_of_intervals = function(),
    get_interval = function(index),
    get_label = function(index),
    get_start_time = function(index),
    get_end_time = function(index),
    as_data_frame = function()
  )
)

TextTier <- R6Class("TextTier",
  inherit = PraatObject,
  public = list(
    get_number_of_points = function(),
    get_time = function(index),
    get_label = function(index),
    as_data_frame = function()
  )
)
```

#### 1.2 FormantPath Implementation

**Rationale**: Used in Parselmouth examples for robust formant tracking.

**Files to Create**:
- `R/formantpath-r6.R`
- `src/praat_formantpath.cpp`

**Core Methods**:

```r
FormantPath <- R6Class("FormantPath",
  inherit = PraatObject,
  public = list(
    extract_formant = function(),
    get_optimal_ceiling = function(),
    as_data_frame = function()
  )
)
```

**Add to Sound class**:
```r
to_formant_path_burg = function(
  time_step = 0.005,
  max_formant = 5500,
  num_formants = 5,
  window_length = 0.025,
  pre_emphasis = 50,
  ceiling_step_size = 0.05,
  num_steps = 4
)
```

#### 1.3 Spectrum Implementation

**Files to Create**:
- `R/spectrum-r6.R`
- `src/praat_spectrum.cpp`

**Core Methods**:

```r
Spectrum <- R6Class("Spectrum",
  inherit = PraatObject,
  public = list(
    get_bin_from_frequency = function(frequency),
    get_frequency_from_bin = function(bin),
    get_real_value_at_frequency = function(frequency),
    get_imaginary_value_at_frequency = function(frequency),
    get_band_energy = function(fmin, fmax),
    get_band_density = function(fmin, fmax),
    get_centre_of_gravity = function(power = 2),
    get_standard_deviation = function(power = 2),
    get_skewness = function(power = 2),
    get_kurtosis = function(power = 2),
    to_ltas = function(),
    as_data_frame = function()
  )
)
```

#### 1.4 Ltas Implementation

**Files to Create**:
- `R/ltas-r6.R`
- `src/praat_ltas.cpp`

**Core Methods**:

```r
Ltas <- R6Class("Ltas",
  inherit = PraatObject,
  public = list(
    get_bin_from_frequency = function(frequency),
    get_frequency_from_bin = function(bin),
    get_value_at_frequency = function(frequency),
    get_minimum = function(fmin, fmax),
    get_maximum = function(fmin, fmax),
    get_mean = function(fmin, fmax),
    get_slope = function(fmin_low, fmax_low, fmin_high, fmax_high),
    as_data_frame = function()
  )
)
```

**Add to Sound class**:
```r
to_ltas = function(bandwidth = 100)
```

### Phase 2: Enhance Existing Objects (Priority 2)

#### 2.1 Sound - Add Missing Methods

```r
# Add to Sound class:
to_formant_path_burg = function(...),  # NEW
to_spectrum = function(fast = TRUE),   # NEW
to_ltas = function(bandwidth = 100),   # NEW
to_cochleagram = function(...),        # NEW
combine_to_stereo = function(other_sound),  # NEW
concatenate = function(other_sound, overlap = 0)  # NEW
```

#### 2.2 Intensity - Add Conversion Methods

```r
# Add to Intensity class:
down_to_intensity_tier = function(),   # NEW - matches Parselmouth
to_matrix = function()                 # NEW
```

#### 2.3 Formant - Add Missing Query Methods

```r
# Add to Formant class:
get_bandwidth_at_time = function(formant_number, time),  # Already exists
list_formant_slope = function(formant_number, ...),      # NEW
track_formants = function(...)                            # NEW (if not in FormantPath)
```

#### 2.4 Spectrogram - Complete Implementation

**Current status**: Partially implemented  
**Add**:

```r
# Add to Spectrogram class:
to_spectrum_slice = function(time),
get_power_at = function(time, frequency),
paint = function(...),  # For future plotting
as_matrix = function()  # For visualization
```

### Phase 3: Advanced Objects (Priority 3)

#### 3.1 FormantGrid

For detailed formant manipulation beyond FormantTier.

#### 3.2 Cochleagram

Auditory filterbank representation.

#### 3.3 Excitation

Excitation pattern for auditory modeling.

## Implementation Guidelines

### 1. C++ Integration Pattern

Each object should follow this pattern:

```cpp
// src/praat_<objecttype>.cpp

#include <Rcpp.h>
#include "praat/fon/<ObjectType>.h"

// [[Rcpp::export(.<objecttype>_method_name)]]
SEXP <objecttype>_method_name(SEXP xptr, ...) {
  auto* obj = unwrapExternalPointer<<ObjectType>>(xptr, "<ObjectType>");
  // Call Praat C++ method
  // Return result
}
```

### 2. R6 Class Pattern

```r
<ObjectType> <- R6Class("<ObjectType>",
  inherit = PraatObject,
  
  public = list(
    # Constructor
    initialize = function(.xptr = NULL) {
      if (is.null(.xptr)) {
        stop("<ObjectType> must be created from another object")
      }
      private$ptr <- .xptr
    },
    
    # Query methods (get_*)
    # Transformation methods (to_*)
    # Modification methods (set_*, add_*, etc.)
    # Export methods (as_*, save)
  ),
  
  private = list(
    ptr = NULL
  )
)
```

### 3. Documentation Requirements

Each method must document:
- Correspondence to Praat menu command
- Parameters with defaults matching Praat
- Return type
- Example showing Praat script equivalent

Example:
```r
#' @description
#' Extract pitch contour from sound
#' 
#' Corresponds to Praat menu: "To Pitch..."
#' 
#' @param time_step Time step in seconds (0 = auto: 0.75 / pitch_floor)
#' @param pitch_floor Minimum pitch in Hz (default: 75)
#' @param pitch_ceiling Maximum pitch in Hz (default: 600)
#' 
#' @return Pitch object
#' 
#' @examples
#' \dontrun{
#' # Praat script:
#' # selectObject: "Sound example"
#' # To Pitch: 0.01, 75, 600
#' 
#' # R equivalent:
#' sound <- Sound$new("example.wav")
#' pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
#' }
to_pitch = function(time_step = 0, pitch_floor = 75, pitch_ceiling = 600) {
  # Implementation
}
```

## Testing Strategy

### 1. Comparison Tests

For each object/method, create tests comparing against known Praat output:

```r
test_that("Sound$to_pitch matches Praat output", {
  sound <- Sound$new(test_audio_path)
  pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
  
  # Compare against reference data from Praat
  expect_equal(pitch$get_mean(), expected_mean, tolerance = 0.01)
})
```

### 2. Parselmouth Parity Tests

Replicate Parselmouth examples from superassp:

```r
test_that("FormantPath matches Parselmouth behavior", {
  # Implement equivalent of praat_formantpath_burg.py
  sound <- Sound$new(test_audio_path)
  formant_path <- sound$to_formant_path_burg(...)
  formant <- formant_path$extract_formant()
  
  # Compare results
})
```

## Documentation Requirements

### 1. Update CLAUDE.md

Document design decisions:

```markdown
## Object-Oriented Design Decisions

### Praat Object Hierarchy
- All Praat objects inherit from PraatObject base class
- Memory managed via external pointers with finalizers
- Methods mirror Praat's C++ API using snake_case

### Naming Conventions
- Praat "To X" → `to_x()`
- Praat "Get Y" → `get_y()`
- Praat "Down to Z" → `down_to_z()`

### Extension Strategy
To add new Praat objects:
1. Create R6 class in R/<objecttype>-r6.R
2. Create C++ bindings in src/praat_<objecttype>.cpp
3. Add conversion methods to parent objects
4. Document with Praat script equivalents
5. Test against Praat output
```

### 2. Create Vignettes

- `vignettes/praat-to-r.Rmd` - Translation guide
- `vignettes/textgrid-annotation.Rmd` - TextGrid workflow
- `vignettes/formant-tracking.Rmd` - Formant analysis

## Migration from superassp Examples

Create `inst/examples/` with R translations:

- `inst/examples/formant_path_analysis.R` - From `praat_formantpath_burg.py`
- `inst/examples/intensity_analysis.R` - From `praat_intensity.py`
- `inst/examples/voice_analysis.R` - From voice_analysis features

## Success Criteria

1. ✅ All critical Praat objects implemented (Sound, Pitch, Formant, Intensity, TextGrid, Spectrum)
2. ✅ Method names match Praat commands consistently
3. ✅ Parselmouth examples can be translated to R
4. ✅ Comprehensive documentation with Praat equivalents
5. ✅ Test coverage >80% with Praat comparison tests

## Timeline

- **Phase 1** (TextGrid, FormantPath, Spectrum, Ltas): 2-3 days
- **Phase 2** (Enhance existing objects): 1-2 days
- **Phase 3** (Advanced objects): 1-2 days
- **Documentation & Examples**: 1 day

**Total**: ~1 week for complete implementation

## Next Steps

1. Implement TextGrid (highest priority)
2. Implement FormantPath 
3. Implement Spectrum and Ltas
4. Enhance existing objects with missing methods
5. Create translation examples from superassp
6. Write comprehensive documentation
7. Update version to 0.5.0 and commit
