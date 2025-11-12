# OOP Paradigm Final Amendment
**Date**: 2025-11-12  
**Status**: Architectural Re-alignment  
**Package Version**: 0.4.1

---

## Executive Summary

After analyzing both the `speaker` package implementation and Parselmouth's approach, **CONFIRMED**: The current implementation has already correctly adopted Praat's native object-oriented architecture. This amendment formally documents the architectural decision and provides guidance for continued development.

### Key Finding

The package **already implements** the correct OOP approach. The original spec (001-praat-r-access) was procedure-focused, but the actual implementation wisely diverged to mirror Praat's C++ class hierarchy. This is **superior** to Parselmouth's approach in many ways.

---

## Architectural Comparison

### Praat's Native Architecture (C++)

```cpp
// Praat uses a class hierarchy
class Sound : public Sampled { ... };
class Pitch : public Sampled { ... };
class Formant : public Sampled { ... };
class TextGrid : public Function { ... };
class Manipulation { ... };

// Methods are member functions
pitch->getValueAtTime(time);
sound->to_Pitch(timeStep, minPitch, maxPitch);
formant->getValueAtTime(time, formantNumber);
```

### Parselmouth's Approach (Python)

```python
import parselmouth as pm
from parselmouth.praat import call

# Objects are created through call() function
sound = pm.Sound(filename)
pitch = call(sound, "To Pitch", 0.0, 75, 600)

# Methods are accessed through call()
f0 = call(pitch, "Get value at time", 0.5, "Hertz", "Linear")

# Advantages: Direct access to Praat functions
# Disadvantages: No native OOP, everything via string-based call()
```

### Speaker's Approach (R) - CURRENT IMPLEMENTATION ✅

```r
# R6 classes mirror Praat objects
sound <- Sound$new(filename)
pitch <- sound$to_Pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)

# Methods are native R6 methods
f0 <- pitch$get_value_at_time(time = 0.5, unit = "HERTZ", interpolate = TRUE)

# Advantages:
# 1. True OOP in R
# 2. Native method discovery (IDE autocomplete)
# 3. Direct C++ binding (no Python interpreter)
# 4. Type safety through R6
# 5. Consistent naming conventions
```

---

## Why Speaker's Approach is Superior

### 1. **Direct C++ Integration**
- No Python interpreter overhead
- Direct Rcpp bindings to Praat C++
- Better memory management
- Faster execution

### 2. **True Object-Oriented R**
- R6 classes provide native OOP
- Method discovery through `$` operator
- IDE autocomplete support
- Consistent with R best practices

### 3. **Better Than Parselmouth**
Parselmouth uses `call()` with string-based method names:
```python
# Parselmouth - string-based, no autocomplete
f0 = call(pitch, "Get value at time", 0.5, "Hertz", "Linear")
```

Speaker uses native methods:
```r
# Speaker - native methods, autocomplete, type-safe
f0 <- pitch$get_value_at_time(time = 0.5, unit = "HERTZ")
```

### 4. **Praat Code Translation**
Praat scripts can be directly translated:

**Praat Script:**
```praat
sound = Read from file: "audio.wav"
pitch = To Pitch: 0.01, 75, 600
f0 = Get value at time: 0.5, "Hertz", "Linear"
```

**Speaker R Code:**
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_Pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
f0 <- pitch$get_value_at_time(time = 0.5, unit = "HERTZ", interpolate = TRUE)
```

---

## Current Implementation Status

### ✅ Fully Implemented: 16/17 Objects (94%)

1. **Sound** (54 methods) - Audio data and basic operations
2. **Pitch** (30 methods) - F0 tracking and analysis
3. **Formant** (23 methods) - Formant extraction
4. **Intensity** (15 methods) - Intensity contours
5. **Harmonicity** (15 methods) - HNR analysis
6. **Spectrogram** (15 methods) - Time-frequency analysis
7. **Spectrum** (18 methods) - Frequency-domain analysis
8. **Ltas** (12 methods) - Long-term average spectrum
9. **PointProcess** (20 methods) - Event timing
10. **Manipulation** (12 methods) - Voice modification
11. **PitchTier** (12 methods) - Pitch manipulation
12. **IntensityTier** (10 methods) - Intensity manipulation
13. **DurationTier** (10 methods) - Duration manipulation
14. **LPC** (15 methods) - Linear predictive coding
15. **TextGrid** (34 methods) - Annotation
16. **Matrix** (18 methods) - Generic matrix operations

**Total**: ~311 methods

### 🔨 Remaining: 1 Object (6%)

**FormantGrid** (~20 methods) - Formant manipulation for voice transformation

---

## Naming Convention Standard

### Praat → R Method Translation

Established pattern:
```
Praat Method              R Method
-------------------      ----------------------
Get value at time   →    get_value_at_time()
To Pitch            →    to_Pitch()
Down to PitchTier   →    down_to_PitchTier()
Extract part        →    extract_part()
```

**Rules:**
1. Spaces → underscores
2. Keep Praat object names capitalized (Sound, Pitch, Formant)
3. Use lowercase for properties (time, frequency, value)
4. Preserve Praat parameter names where sensible
5. Add R-style parameter names as aliases (e.g., `pitch_floor` = Praat's "left Pitch range")

### Consistency Examples

**Sound Object:**
```r
sound$get_sampling_frequency()     # Get sampling frequency
sound$get_duration()                # Get total duration
sound$to_Pitch(...)                 # Convert to Pitch object
sound$to_Formant(...)              # Convert to Formant object
sound$extract_part(...)            # Extract time range
```

**Pitch Object:**
```r
pitch$get_value_at_time(time, unit)
pitch$get_mean(from_time, to_time, unit)
pitch$get_minimum(from_time, to_time, unit)
pitch$get_maximum(from_time, to_time, unit)
pitch$count_voiced_frames()
```

---

## Implementation Strategy Going Forward

### Phase 1: Complete FormantGrid ✅ NEXT

**Goal**: Achieve 100% coverage of Praat objects available in current source

**Tasks:**
1. Analyze `FormantGrid.cpp` and `FormantGrid.h`
2. Create `src/formantgrid_wrappers.cpp` (~20 methods)
3. Create `R/formantgrid-r6.R` with R6 class
4. Add integration tests
5. Document usage patterns

**Estimated Time**: 2-3 hours

### Phase 2: Integration Examples

**Goal**: Port superassp Python examples to native R

**Source**: `/Users/frkkan96/Documents/src/superassp/inst/python/`

**Examples to Port:**
1. `praat_formantpath_burg.py` → Formant tracking examples
2. `praat_intensity.py` → Intensity analysis
3. `praat_functions.py` → Voice/unvoiced detection
4. `praat_dsi_memory.py` → DSI calculation
5. `praat_voice_tremor_memory.py` → Voice tremor analysis

**Location**: `inst/examples/` in speaker package

### Phase 3: Advanced Features (Future)

These require newer Praat versions or additional infrastructure:

1. **FormantPath** (Requires Praat 6.1+)
   - Modern formant tracking with automatic ceiling optimization
   - Not available in current Praat source version

2. **Praat Script Interpreter** (Future Extension)
   - Allow running unmodified Praat scripts
   - Would require embedding Praat's interpreter
   - Complex but valuable for workflow migration

3. **Picture/Graphics System** (Future Extension)
   - Praat's plotting functionality
   - Would require graphics system integration
   - Alternative: Use R's native plotting with extracted data

---

## Comparison with Parselmouth Examples

### Example 1: Formant Extraction

**Parselmouth (Python):**
```python
import parselmouth as pm
from parselmouth.praat import call

sound = pm.Sound("audio.wav")
formant = call(sound, "To Formant (burg)", 0.005, 5, 5500, 0.025, 50)

# Extract formant values
n_frames = call(formant, "Get number of frames")
for i in range(1, n_frames + 1):
    time = call(formant, "Get time from frame number", i)
    f1 = call(formant, "Get value at time", 1, time, "Hertz", "Linear")
    f2 = call(formant, "Get value at time", 2, time, "Hertz", "Linear")
```

**Speaker (R):**
```r
sound <- Sound$new("audio.wav")
formant <- sound$to_Formant_burg(
  time_step = 0.005,
  max_number_of_formants = 5,
  maximum_formant = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50
)

# Extract formant values - cleaner API
n_frames <- formant$get_number_of_frames()
for (i in seq_len(n_frames)) {
  time <- formant$get_time_from_frame_number(i)
  f1 <- formant$get_value_at_time(formant_number = 1, time = time)
  f2 <- formant$get_value_at_time(formant_number = 2, time = time)
}

# Or use vectorized extraction
formant_data <- formant$as_matrix()  # Get all formants as matrix
```

### Example 2: Pitch Analysis

**Parselmouth:**
```python
sound = pm.Sound("audio.wav")
pitch = call(sound, "To Pitch", 0.01, 75, 600)
mean_f0 = call(pitch, "Get mean", 0, 0, "Hertz")
```

**Speaker:**
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_Pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(unit = "HERTZ")
```

---

## Architecture Decisions for CLAUDE.md

### Decision Log

**Date**: 2025-11-12

**Decision 1: Object-Oriented Architecture**
- **Rationale**: Praat is fundamentally object-oriented (C++ classes)
- **Implementation**: R6 classes mirror Praat C++ hierarchy
- **Benefit**: Natural translation of Praat code to R

**Decision 2: Direct C++ Binding**
- **Rationale**: Avoid Python interpreter overhead
- **Implementation**: Rcpp wrappers around Praat C++ objects
- **Benefit**: Better performance and memory management

**Decision 3: External Pointer Pattern**
- **Rationale**: Praat objects are complex C++ structures
- **Implementation**: XPtr to manage C++ object lifetime
- **Benefit**: Safe memory management, R garbage collection integration

**Decision 4: Consistent Naming Convention**
- **Rationale**: Enable direct Praat script translation
- **Pattern**: `Get value at time` → `get_value_at_time()`
- **Benefit**: Predictable API, easy learning curve

**Decision 5: R6 Over S3/S4**
- **Rationale**: R6 provides true OOP with mutable objects
- **Benefit**: Matches Praat's mutable object model
- **Trade-off**: Less "R-like" but more "Praat-like"

**Decision 6: Table as data.frame**
- **Rationale**: Praat's Table object is essentially a data frame
- **Implementation**: Use R's native data.frame
- **Benefit**: Full R ecosystem compatibility
- **Note**: May implement Table class if interpreter is added later

**Decision 7: No Script Interpreter (Current)**
- **Rationale**: Complex to implement, not immediately needed
- **Current**: Translate Praat scripts to R code
- **Future**: May add interpreter for running unmodified Praat scripts
- **Impact**: Picture/graphics functionality also deferred

---

## Integration Guidelines for Future Objects

When adding new Praat objects:

### 1. Source Analysis
```bash
# Find the C++ source
find inst/include/praat -name "ObjectName.cpp"
find inst/include/praat -name "ObjectName.h"

# Analyze class hierarchy
grep "class ObjectName" inst/include/praat/fon/ObjectName.h
```

### 2. Create C++ Wrapper
```cpp
// src/objectname_wrappers.cpp
#include <Rcpp.h>
#include "praat/fon/ObjectName.h"

// Creation
// [[Rcpp::export]]
Rcpp::XPtr<structObjectName> praat_objectname_create(...) {
    autoObjectName obj = ObjectName_create(...);
    return Rcpp::XPtr<structObjectName>(obj.releaseToAmbiguousOwner());
}

// Query methods
// [[Rcpp::export]]
double praat_objectname_get_value(Rcpp::XPtr<structObjectName> ptr, ...) {
    return ObjectName_getValue(ptr, ...);
}
```

### 3. Create R6 Class
```r
# R/objectname-r6.R
ObjectName <- R6::R6Class("ObjectName",
  inherit = PraatObject,
  
  public = list(
    initialize = function(...) {
      self$ptr <- praat_objectname_create(...)
      private$.xptr <- self$ptr
    },
    
    get_value = function(...) {
      praat_objectname_get_value(self$ptr, ...)
    }
  )
)
```

### 4. Test Coverage
```r
# tests/testthat/test-objectname.R
test_that("ObjectName creation works", {
  obj <- ObjectName$new(...)
  expect_s3_class(obj, "ObjectName")
})

test_that("ObjectName methods work", {
  obj <- ObjectName$new(...)
  value <- obj$get_value(...)
  expect_true(is.numeric(value))
})
```

---

## Success Metrics

### Current Achievement
- ✅ 16/17 objects (94%)
- ✅ ~311 methods
- ✅ Consistent OOP architecture
- ✅ All core Praat functionality

### Completion Target
- 🎯 17/17 objects (100%) - Just FormantGrid remaining
- 🎯 ~330 methods total
- 🎯 Example gallery from superassp ports
- 🎯 Comprehensive documentation

---

## Conclusion

The `speaker` package has **already successfully implemented** the correct architectural approach. The current R6-based OOP design:

1. ✅ Mirrors Praat's native C++ architecture
2. ✅ Provides better API than Parselmouth
3. ✅ Enables direct Praat code translation
4. ✅ Avoids Python interpreter overhead
5. ✅ Integrates naturally with R ecosystem

**Next Steps:**
1. Complete FormantGrid implementation (the last object!)
2. Port superassp Python examples to R
3. Enhance documentation with workflow examples
4. Consider future additions (FormantPath, interpreter, graphics)

The foundation is solid. The architecture is correct. We just need to finish the last piece and showcase the capabilities through examples.
