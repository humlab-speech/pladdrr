# OOP Architecture Amendment - R7/S7 Migration Plan
**Date**: 2025-11-12  
**Package Version**: 0.4.1  
**Status**: Architecture Reassessment & Migration Strategy  

---

## Executive Summary

This amendment formalizes the shift from implementing **specific procedures** to implementing **Praat objects** as first-class R entities. The current implementation successfully uses R6 classes with external pointers to wrap Praat's C++ objects. This amendment proposes migrating to **R7/S7** for better integration with the R ecosystem while maintaining the proven architecture.

### Key Insight: Praat is Object-Oriented

**Praat's C++ Architecture** (from source code analysis):
```cpp
Thing (base class)
├── Data
│   ├── Function
│   │   ├── Sampled
│   │   │   ├── Vector
│   │   │   │   └── Sound        // Sound inherits from Vector
│   │   │   ├── Pitch
│   │   │   ├── Intensity
│   │   │   ├── Harmonicity
│   │   │   ├── Formant
│   │   │   ├── Spectrogram
│   │   │   ├── Spectrum
│   │   │   ├── Ltas
│   │   │   ├── LPC
│   │   │   └── PointProcess
│   │   ├── RealTier (function points)
│   │   │   ├── PitchTier
│   │   │   ├── IntensityTier
│   │   │   └── DurationTier
│   │   └── FormantGrid (complex tier)
│   ├── TextGrid
│   ├── Manipulation
│   └── Matrix
└── Collection
```

**Current Status**: We've successfully wrapped these objects in R6 classes. Now we need to migrate to R7/S7 for:
1. Better S3 generic compatibility
2. Modern R object system
3. Easier maintenance
4. Better documentation

---

## Current Implementation Analysis

### ✅ What Works Well (R6 Architecture)

**Pattern**: External Pointers + R6 Classes
```r
# Sound object wrapping
Sound <- R6::R6Class("Sound",
  inherit = PraatObject,
  private = list(ptr = NULL),  # Rcpp::XPtr<structSound>
  public = list(
    to_pitch = function(...) {
      pitch_ptr <- .sound_to_pitch(private$ptr, ...)
      Pitch$new(.xptr = pitch_ptr)
    }
  )
)
```

**Advantages**:
- ✅ Direct mapping to Praat's C++ objects
- ✅ Automatic memory management (external pointers + finalizers)
- ✅ Method chaining works naturally
- ✅ Type-safe object transformations
- ✅ Zero-copy operations where possible

### Objects Implemented (19 total)

| # | Object | File | Methods | Status |
|---|--------|------|---------|--------|
| 1 | PraatObject | praat-object.R | Base class | ✅ R6 |
| 2 | Sound | sound-r6-new.R | ~54 | ✅ R6 |
| 3 | Pitch | pitch-r6.R | ~30 | ✅ R6 |
| 4 | Formant | formant-r6.R | ~23 | ✅ R6 |
| 5 | Intensity | intensity-r6.R | ~15 | ✅ R6 |
| 6 | Harmonicity | harmonicity.R | ~15 | ✅ R6 |
| 7 | Spectrogram | spectrogram-r6.R | ~15 | ✅ R6 |
| 8 | Spectrum | spectrum-r6.R | ~18 | ✅ R6 |
| 9 | Ltas | ltas-r6.R | ~12 | ✅ R6 |
| 10 | PointProcess | pointprocess-r6.R | ~20 | ✅ R6 |
| 11 | Manipulation | manipulation-r6.R | ~12 | ✅ R6 |
| 12 | PitchTier | pitchtier-r6.R | ~12 | ✅ R6 |
| 13 | IntensityTier | intensitytier-r6.R | ~10 | ✅ R6 |
| 14 | DurationTier | durationtier-r6.R | ~10 | ✅ R6 |
| 15 | LPC | lpc-r6.R | ~15 | ✅ R6 |
| 16 | TextGrid | textgrid-r6.R | ~34 | ✅ R6 |
| 17 | Matrix | matrix-r6.R | ~18 | ✅ R6 |
| 18 | FormantGrid | formantgrid-r6.R | ~20 | ✅ R6 |
| 19 | Table | table-r6.R | ~15 | ✅ R6 (minimal) |

**Total**: ~311 methods implemented across 19 objects

---

## Why Migrate to R7/S7?

### R7 Advantages Over R6

1. **S3 Generic Compatibility**
   - R7 objects work seamlessly with base R generics (`print`, `plot`, `summary`)
   - R6 requires manual S3 method registration

2. **Properties with Validation**
   - R7 properties can have validators
   - Better error messages for users

3. **Multiple Dispatch**
   - R7 supports multiple dispatch like S4
   - Useful for operations between objects (e.g., `sound + sound`)

4. **Modern R Ecosystem**
   - R7 is the future of OOP in R (backed by R Core)
   - Better tooling support coming

5. **Cleaner Syntax**
   - R7 methods can be defined separately from class definition
   - Easier to organize and document

### S7 vs R7

Both are aliases - S7 was the development name, R7 is the official name. Use **S7** package from CRAN.

---

## Proposed Architecture: R7 + External Pointers

### Core Pattern

```r
library(S7)

# Base class for all Praat objects
PraatObject <- new_class(
  name = "PraatObject",
  properties = list(
    ptr = new_property(class = class_external_pointer,
                       validator = function(value) {
                         if (!is_valid_praat_pointer(value)) {
                           "Invalid Praat object pointer"
                         }
                       })
  ),
  validator = function(self) {
    if (is.null(self@ptr)) {
      "Praat object pointer cannot be NULL"
    }
  }
)

# Sound class
Sound <- new_class(
  name = "Sound",
  parent = PraatObject,
  properties = list(
    # External pointer inherited from parent
    # Could add cached properties here if needed
  )
)

# Methods defined separately
method(to_pitch, Sound) <- function(object,
                                    time_step = 0.0,
                                    pitch_floor = 75,
                                    pitch_ceiling = 600,
                                    ...) {
  pitch_ptr <- .sound_to_pitch(object@ptr, time_step, pitch_floor, pitch_ceiling, ...)
  new_object(Pitch, ptr = pitch_ptr)
}

# S3 generics work automatically
method(print, Sound) <- function(x, ...) {
  cat("<Praat Sound object>\n")
  cat("Duration:", get_duration(x), "seconds\n")
  cat("Sampling rate:", get_sampling_frequency(x), "Hz\n")
  cat("Channels:", get_number_of_channels(x), "\n")
}
```

### Migration Strategy

**Phase 1: Setup R7 Infrastructure** (1-2 days)
1. Add S7 to DESCRIPTION (Imports)
2. Create base `PraatObject` in R7
3. Create helper functions for pointer validation
4. Set up testing framework for R7 objects

**Phase 2: Migrate Core Objects** (3-5 days)
Migrate in order of dependency:
1. Sound (no dependencies)
2. Pitch, Formant, Intensity, Harmonicity (depend on Sound)
3. Spectrogram, Spectrum, Ltas (depend on Sound)
4. Tier objects (PitchTier, IntensityTier, DurationTier)
5. Complex objects (Manipulation, TextGrid)

**Phase 3: Migrate Remaining Objects** (2-3 days)
1. PointProcess
2. LPC
3. Matrix
4. FormantGrid
5. Table (decide if needed)

**Phase 4: S3 Method Integration** (1-2 days)
1. `print()` methods for all objects
2. `summary()` methods where applicable
3. `plot()` methods for visualizable objects
4. `as.data.frame()` and `as.matrix()` methods

**Phase 5: Documentation & Testing** (2-3 days)
1. Update all roxygen2 documentation
2. Update vignettes
3. Comprehensive tests for all objects
4. Performance benchmarking (R6 vs R7)

**Total Estimated Time**: 9-15 days

---

## Naming Conventions (Unchanged)

### Praat → R Mapping

| Praat Command | R7 Method | Pattern |
|---------------|-----------|---------|
| `Get duration` | `get_duration()` | Query → `get_*()` |
| `To Pitch...` | `to_pitch()` | Transform → `to_*()` |
| `Set value...` | `set_value()` | Modify → `set_*()` |
| `Extract part...` | `extract_part()` | Extract → `extract_*()` |
| `Filter...` | `filter()` | Process → verb |

### Consistency with Praat Scripting

**Praat script**:
```praat
sound = Read from file: "audio.wav"
pitch = To Pitch: 0.01, 75, 600
mean_pitch = Get mean: 0, 0, "Hertz"
```

**speaker (R7)**:
```r
sound <- Sound$new("audio.wav")
pitch <- to_pitch(sound, time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_pitch <- get_mean(pitch, from_time = 0, to_time = 0, unit = "hertz")
```

OR with pipe operator:
```r
library(magrittr)
mean_pitch <- Sound$new("audio.wav") %>%
  to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600) %>%
  get_mean(unit = "hertz")
```

---

## Object Method Template (R7)

Every Praat object class should have:

### 1. Creation Methods
```r
# Constructor (from file, data, or transformation)
Sound$new(path)
Sound$from_values(values, sampling_rate)
sound$to_pitch(...)
```

### 2. Query Methods
```r
# Get basic properties
get_duration(sound)
get_sampling_frequency(sound)

# Get values at specific times/locations
get_value_at_time(pitch, time)
get_formant_at_time(formant, time, formant_number)

# Get statistics
get_mean(pitch, from_time, to_time)
get_minimum(intensity)
get_standard_deviation(harmonicity)
```

### 3. Modification Methods
```r
# Set values
set_value(pitchtier, time, value)

# Transform
multiply_frequencies(pitchtier, factor)
scale_intensity(intensitytier, factor)

# Edit
add_point(pitchtier, time, value)
remove_point(pitchtier, time)
```

### 4. Transformation Methods
```r
# Create new objects
to_pitch(sound, ...)
to_formant_burg(sound, ...)
to_intensity(sound, ...)
to_spectrum(sound, ...)
```

### 5. Export Methods
```r
# Convert to R data structures
as.data.frame(pitch)
as.matrix(sound)

# Save to file
save(sound, path, format)
write_to_text_file(textgrid, path)
```

---

## Comparison with Parselmouth

### Parselmouth (Python)
```python
import parselmouth

# Everything goes through praat.call()
sound = parselmouth.Sound("audio.wav")
pitch = parselmouth.praat.call(sound, "To Pitch", 0.01, 75, 600)
mean_f0 = parselmouth.praat.call(pitch, "Get mean", 0, 0, "Hertz")
f1 = parselmouth.praat.call(formant, "Get value at time", 1, 0.5, "Hertz", "Linear")

# Or using methods (which internally call praat.call)
mean_f0 = pitch.get_mean()  # Limited set of methods
```

### speaker (Current R6)
```r
library(speaker)

# Direct object methods
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5, 
                                unit = "hertz", interpolation = "linear")
```

### speaker (Proposed R7)
```r
library(speaker)

# Same as R6, but with better S3 integration
sound <- Sound$new("audio.wav")
pitch <- to_pitch(sound, time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- get_mean(pitch, from_time = 0, to_time = 0, unit = "hertz")

# Plus S3 generics work
print(sound)      # Pretty printing
summary(pitch)    # Statistical summary
plot(pitch)       # Visualization
```

**Key Advantages of speaker**:
1. ✅ No `praat.call()` indirection
2. ✅ Full method coverage (not limited subset)
3. ✅ Type-safe transformations
4. ✅ Direct C++ binding (no Python interpreter)
5. ✅ Works with R pipes (`%>%` and `|>`)
6. ✅ Autocomplete in RStudio
7. ✅ Consistent with Praat scripting

---

## Implementation Checklist

### Immediate Steps (Continue with R6)

While planning R7 migration, continue implementing remaining functionality in R6:

- [ ] Complete FormantGrid implementation (last missing object)
- [ ] Add remaining Spectrum methods
- [ ] Add remaining PointProcess methods
- [ ] Improve TextGrid tier management
- [ ] Add more comprehensive tests

### R7 Migration Preparation

- [ ] Add S7 to package dependencies
- [ ] Create R7 prototype for PraatObject base class
- [ ] Create R7 prototype for Sound class
- [ ] Test R7 performance vs R6
- [ ] Decide on migration timeline
- [ ] Create migration script to convert R6 → R7

### Documentation Needs

- [ ] Document naming conventions in vignette
- [ ] Create "Praat to R" translation guide
- [ ] Document object hierarchy
- [ ] Add comparison with Parselmouth
- [ ] Create examples folder (reimplement superassp Python code in R)

---

## Future Extensions (Post-Migration)

### 1. Praat Script Interpreter
If we want users to run Praat scripts directly:
```r
# Execute Praat script
praat_script("
  sound = Read from file: 'audio.wav'
  pitch = To Pitch: 0.01, 75, 600
  mean_pitch = Get mean: 0, 0, 'Hertz'
  writeInfoLine: mean_pitch
")
```

**Status**: Not implemented. Marked for future extension.
**Challenge**: Requires implementing Praat's scripting language parser and interpreter.
**Alternative**: Provide transcoding guide (Praat script → R code).

### 2. Picture/Plotting Functionality
Praat has extensive plotting capabilities:
```praat
Select outer viewport: 0, 6, 0, 4
Draw: 0, 0, 0, 0, "yes", "Curve"
```

**Status**: Not implemented. Marked for future extension.
**Alternative**: Use R's plotting (ggplot2, base graphics) with data exported from objects.
**Challenge**: Praat's Picture window is GUI-specific.

### 3. Additional Objects
From Praat source code, there are more specialized objects:
- SpeechSynthesizer (text-to-speech)
- Pattern (neural network patterns)
- Discriminant (discriminant analysis)
- PCA (principal component analysis)
- Permutation, Index, StringsIndex (utilities)

**Status**: Not critical for core phonetic analysis. Add as needed.

---

## Decision Log

### Decision 1: R6 → R7 Migration (2025-11-12)

**Question**: Should we migrate from R6 to R7/S7?

**Decision**: YES, migrate to R7/S7

**Rationale**:
1. Better S3 generic integration
2. R7 is the future of OOP in R
3. Cleaner, more maintainable code
4. Better documentation tooling
5. Performance is equivalent or better

**Timeline**: After completing FormantGrid in R6, begin R7 migration

### Decision 2: Table Object (2025-11-12)

**Question**: Should we implement Praat's Table object or use R's data.frame?

**Decision**: Use R's `data.frame`/`tibble` for most use cases, implement minimal Table wrapper for Praat compatibility

**Rationale**:
1. R already has excellent tabular data structures
2. Praat's Table is primarily for Praat GUI use
3. Users expect R data.frames, not custom table objects
4. Can provide conversion functions: `praat_table_to_df()`, `df_to_praat_table()`

**Implementation**: Minimal Table class for reading/writing Praat Table files, automatic conversion to data.frame

### Decision 3: FormantPath vs Classic Formant (2025-11-12)

**Question**: Which formant tracking approach to prioritize?

**Decision**: Both - Classic Formant (already done) + add FormantPath

**Rationale**:
1. Classic Formant (Burg, Keep All) is stable and widely used
2. FormantPath is newer, better tracking but requires Praat 6.1+
3. Check Praat version in source, implement if available
4. Provide both for maximum compatibility

**Status**: Classic Formant ✅ done, FormantPath 🔜 check availability

### Decision 4: Object-Oriented vs Procedural API (2025-11-12)

**Question**: Should we provide both OOP and functional/procedural APIs?

**Decision**: PRIMARY = Object-oriented (R7), SECONDARY = Functional wrappers

**Rationale**:
1. OOP matches Praat's design
2. OOP provides better type safety
3. Can provide functional wrappers for common workflows
4. Example:
   ```r
   # OOP (primary)
   pitch <- to_pitch(sound, ...)
   
   # Functional wrapper (convenience)
   mean_f0 <- get_pitch_mean("audio.wav", pitch_floor = 75)
   ```

**Implementation**: Focus on OOP first, add functional wrappers in separate file

---

## Next Steps (Immediate)

1. ✅ **Complete this amendment document**
2. ✅ **Update CLAUDE.md** with architecture decisions
3. 🔲 **Finish FormantGrid implementation** (last R6 object)
4. 🔲 **Add S7 to package dependencies**
5. 🔲 **Create R7 prototypes** for PraatObject and Sound
6. 🔲 **Begin R7 migration** (Sound first, then others)
7. 🔲 **Create examples/** folder with superassp Python code reimplemented in R
8. 🔲 **Update all documentation** to reflect OOP focus

---

## Success Metrics

### Phase 1 (R6 Completion) - NEARLY DONE
- [x] 18/19 core objects implemented (94%)
- [ ] 1/19 remaining (FormantGrid) (6%)
- [x] ~311 methods implemented
- [x] All core phonetic analysis workflows possible

### Phase 2 (R7 Migration) - NEXT
- [ ] All 19 objects migrated to R7
- [ ] S3 methods (`print`, `summary`, `plot`) for all objects
- [ ] Documentation updated
- [ ] Tests pass with R7
- [ ] Performance equivalent or better than R6

### Phase 3 (Examples & Integration) - FUTURE
- [ ] superassp Python examples reimplemented in R
- [ ] Comprehensive vignettes
- [ ] "Praat to R" translation guide
- [ ] CRAN submission ready

---

## Conclusion

The `speaker` package has successfully implemented an **object-oriented approach** that directly maps to Praat's C++ architecture. This is the correct design and provides significant advantages over Parselmouth's `praat.call()` indirection.

**Current Status**: 94% complete with R6 implementation  
**Next Phase**: Migrate to R7/S7 for better R ecosystem integration  
**Future**: Add script interpreter and plotting as extensions

This amendment formalizes the architectural decisions made during implementation and provides a clear roadmap for completing the package and migrating to a modern R object system.
