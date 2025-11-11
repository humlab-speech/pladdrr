# Object-Oriented Architecture Amendment
## Realigning speaker with Praat's OOP Design

**Created**: 2025-11-11  
**Status**: MASTER ARCHITECTURAL AMENDMENT  
**Purpose**: Redesign speaker package to fully mirror Praat's object-oriented architecture

---

## Executive Summary

### The Core Problem

The current implementation focuses on **isolated procedures** rather than **persistent objects**. While we have R6 classes, the design doesn't fully leverage Praat's rich object-oriented architecture where objects transform into other objects and methods operate on persistent state.

### The Solution

**Treat Praat objects as first-class citizens in R**, not just temporary data structures. Every Praat C++ object should have a corresponding R6 class with:
1. **Persistent state** via external pointers
2. **Transform methods** that return NEW objects (`to_*()`)
3. **Query methods** that extract values (`get_*()`)
4. **Modification methods** that alter state (`set_*()`, `filter_*()`)
5. **Export methods** that convert to R types (`as_*()`)

### Comparison: Procedural vs Object-Oriented

#### ❌ Current Procedural Approach
```r
# Each call reads file, processes, returns data
pitch_data <- extract_pitch("file.wav", min_pitch = 75)
formant_data <- extract_formant("file.wav", max_formant = 5500)
# No object persistence, repeated I/O, limited functionality
```

#### ✅ Object-Oriented Approach (Praat-like)
```r
# Create persistent Sound object
sound <- Sound$new("file.wav")

# Transform to analysis objects
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant = 5500)
intensity <- sound$to_intensity()

# Query methods on objects
mean_f0 <- pitch$get_mean(unit = "hertz")
f1 <- formant$get_value_at_time(formant_number = 1, time = 0.5)

# Manipulation workflow (CRITICAL missing feature)
manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(factor = 1.2)
manip$replace_pitch_tier(pitch_tier)
modified_sound <- manip$get_resynthesis_overlap_add()
modified_sound$save("output.wav")
```

---

## Praat's Object-Oriented Architecture

### How Praat Actually Works

Praat is built on a **rich C++ object hierarchy** starting from the base class `Thing`:

```
Thing (base class with name, class info)
├── Daata (data objects)
│   ├── Function (functions of time/frequency)
│   │   ├── Sampled (sampled at regular intervals)
│   │   │   ├── Sound (audio waveform)
│   │   │   ├── Pitch (F0 contour)
│   │   │   ├── Formant (formant tracks)
│   │   │   ├── Intensity (loudness contour)
│   │   │   ├── Harmonicity (HNR contour)
│   │   │   ├── Spectrogram (time-frequency)
│   │   │   ├── Spectrum (frequency domain)
│   │   │   ├── LPC (LPC coefficients)
│   │   │   ├── LTAS (long-term average spectrum)
│   │   │   └── PointProcess (time points)
│   │   ├── PitchTier (modifiable pitch)
│   │   ├── FormantGrid (modifiable formants)
│   │   ├── IntensityTier (modifiable intensity)
│   │   ├── DurationTier (duration modification)
│   │   └── TextGrid (annotation tiers)
│   ├── Manipulation (PSOLA modification)
│   ├── Matrix (2D data)
│   ├── Table (data frames)
│   └── Collection (object containers)
```

### Key Architectural Principles

1. **Objects transform into other objects**
   - `Sound → to_Pitch() → Pitch`
   - `Sound → to_Formant_burg() → Formant`
   - `Pitch → to_PitchTier() → PitchTier`

2. **Objects query their own state**
   - `pitch.get_mean()` not `get_pitch_mean(pitch)`
   - `formant.get_value_at_time(1, 0.5)` not `get_formant(formant, 1, 0.5)`

3. **Objects maintain persistent state**
   - Sound keeps audio samples in memory
   - Pitch keeps F0 candidates
   - TextGrid keeps tier structure

4. **Objects can be modified**
   - `pitch_tier.multiply_frequencies(1.2)`
   - `textgrid.insert_boundary("words", 1.5)`
   - `sound.scale_intensity(-3.0)`

5. **Objects can be serialized**
   - `sound.save("output.wav")`
   - `textgrid.save("annotation.TextGrid")`
   - `pitch.as_data_frame()`

---

## How Parselmouth Does It (Python)

Parselmouth (the Python wrapper) successfully mirrors this architecture:

```python
import parselmouth

# Persistent objects via pybind11
sound = parselmouth.Sound("file.wav")

# Transform methods return new objects
pitch = sound.to_pitch(pitch_floor=75, pitch_ceiling=600)
formant = sound.to_formant_burg(max_number_of_formants=5)

# Query methods on objects
mean_f0 = pitch.get_mean(unit="Hertz")
f1_value = formant.get_value_at_time(formant_number=1, time=0.5)

# praat.call() for methods not wrapped directly
jitter = parselmouth.praat.call([sound, point_process], 
                                 "Get jitter (local)", 
                                 0, 0, 0.0001, 0.02, 1.3)

# Manipulation workflow
manipulation = parselmouth.call(sound, "To Manipulation", 0.01, 75, 600)
pitch_tier = parselmouth.call(manipulation, "Extract pitch tier")
parselmouth.call(pitch_tier, "Multiply frequencies", 0, 0, 1.2)
parselmouth.call(manipulation, "Replace pitch tier", pitch_tier)
modified = parselmouth.call(manipulation, "Get resynthesis (overlap-add)")
```

**Key Features**:
- Direct method calls on objects (`.to_pitch()`, `.get_mean()`)
- Fallback to `praat.call()` for unwrapped methods
- External pointers keep C++ objects alive
- Memory management via pybind11 smart pointers

---

## Our R Implementation Strategy

### R6 + External Pointers Pattern

We'll use **R6 classes** with **external pointers (XPtr)** to persistent C++ Praat objects:

```r
# R6 class wraps C++ object
Sound <- R6::R6Class("Sound",
  private = list(
    ptr = NULL  # XPtr to structSound* in C++
  ),
  
  public = list(
    initialize = function(path = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        private$ptr <- .xptr
      } else if (!is.null(path)) {
        private$ptr <- .sound_read(path)  # C++ wrapper
      }
    },
    
    # Query methods
    get_duration = function() {
      .sound_get_duration(private$ptr)
    },
    
    # Transform methods return NEW objects
    to_pitch = function(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600) {
      pitch_ptr <- .sound_to_pitch(private$ptr, time_step, pitch_floor, pitch_ceiling)
      Pitch$new(.xptr = pitch_ptr)  # Wrap in R6 object
    },
    
    # Export methods
    as_matrix = function() {
      .sound_as_matrix(private$ptr)
    },
    
    save = function(path) {
      .sound_save(private$ptr, path)
      invisible(self)
    }
  )
)
```

### C++ Wrapper Pattern

```cpp
// External pointer finalizer
void sound_finalizer(structSound* sound) {
    if (sound != nullptr) {
        forget(sound);  // Praat's memory management
    }
}

// Read sound from file
// [[Rcpp::export(.sound_read)]]
Rcpp::XPtr<structSound> sound_read(std::string path) {
    try {
        autoSound sound = Sound_readFromSoundFile(
            Melder_peek8to32(path.c_str())
        );
        structSound* ptr = sound.releaseToAmbiguousOwner();
        return Rcpp::XPtr<structSound>(ptr, true, sound_finalizer);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to read sound: " + path);
    }
}

// Transform: Sound -> Pitch
// [[Rcpp::export(.sound_to_pitch)]]
Rcpp::XPtr<structPitch> sound_to_pitch(
    Rcpp::XPtr<structSound> sound_xptr,
    double time_step,
    double pitch_floor,
    double pitch_ceiling
) {
    if (!sound_xptr) Rcpp::stop("Invalid Sound pointer");
    
    try {
        autoPitch pitch = Sound_to_Pitch(
            sound_xptr.get(),
            time_step,
            pitch_floor,
            pitch_ceiling
        );
        structPitch* ptr = pitch.releaseToAmbiguousOwner();
        return Rcpp::XPtr<structPitch>(ptr, true, pitch_finalizer);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to extract pitch");
    }
}
```

---

## Complete Object Implementation Plan

### Priority 1: Core Objects (Weeks 1-6) - FOUNDATION

These objects form the foundation of ALL phonetic analysis workflows:

#### 1. Sound ⭐⭐⭐ COMPLETE (v0.4.0)
- **Status**: ✅ Implemented (~50 methods)
- File I/O, generation, queries, transformations
- Transform methods: to_pitch, to_formant_burg, to_intensity, to_harmonicity_cc, to_spectrogram, to_spectrum, to_manipulation, to_point_process

#### 2. Pitch ⭐⭐⭐ COMPLETE (v0.4.0)
- **Status**: ✅ Implemented (~30 methods)
- Query methods: get_value_at_time, get_mean, statistics
- Transform methods: to_pitch_tier, to_point_process

#### 3. Formant ⭐⭐⭐ COMPLETE (v0.4.0)
- **Status**: ✅ Implemented (~20 methods)
- Formant tracking queries
- Statistical methods

#### 4. Intensity ⭐⭐⭐ COMPLETE (v0.4.0)
- **Status**: ✅ Implemented (~15 methods)
- Intensity contour queries
- Transform to IntensityTier

#### 5. Harmonicity ⭐⭐⭐ COMPLETE (v0.4.0)
- **Status**: ✅ Implemented (~15 methods)
- HNR queries and statistics

#### 6. TextGrid ⭐⭐⭐ CRITICAL - PARTIAL
- **Status**: 🚧 Structure defined, needs full implementation
- **Priority**: HIGHEST - 90% of phonetic research uses TextGrids
- **Why critical**: Forced alignment, annotation, segmentation
- **Methods needed** (~35 total):
  - Tier queries: `get_number_of_tiers()`, `get_tier_names()`
  - Interval tier: `get_number_of_intervals()`, `get_interval_text()`, `insert_boundary()`, `remove_boundary()`
  - Point tier: `get_number_of_points()`, `insert_point()`, `remove_point()`
  - Tier management: `add_interval_tier()`, `add_point_tier()`, `remove_tier()`
  - Export: `as_data_frame()`, `save()`

### Priority 2: Manipulation & Voice Quality (Weeks 7-10)

These enable advanced workflows like pitch modification and clinical voice assessment:

#### 7. PointProcess ⭐⭐ HIGH PRIORITY
- **Status**: ❌ NOT IMPLEMENTED
- **Why needed**: Voice quality metrics (jitter, shimmer)
- **Methods** (~20):
  - `get_number_of_points()`, `get_time_from_index()`
  - **Voice quality with Sound**: `get_jitter_local()`, `get_jitter_rap()`, `get_shimmer_local()`, `get_shimmer_apq3()`
  - Point manipulation: `add_point()`, `remove_point()`

#### 8. Manipulation ⭐⭐⭐ CRITICAL MISSING FEATURE
- **Status**: ❌ NOT IMPLEMENTED
- **Why critical**: PSOLA pitch/duration modification, speech synthesis
- **Methods** (~12):
  - `extract_pitch_tier()` → PitchTier
  - `extract_duration_tier()` → DurationTier
  - `extract_original_sound()` → Sound
  - `replace_pitch_tier(tier)`
  - `replace_duration_tier(tier)`
  - `get_resynthesis_overlap_add()` → Sound (PSOLA)
- **Example workflow**:
  ```r
  sound <- Sound$new("voice.wav")
  manip <- sound$to_manipulation()
  pitch_tier <- manip$extract_pitch_tier()
  pitch_tier$multiply_frequencies(factor = 1.5)  # Raise pitch 50%
  manip$replace_pitch_tier(pitch_tier)
  modified <- manip$get_resynthesis_overlap_add()
  modified$save("voice_high.wav")
  ```

#### 9. PitchTier ⭐⭐ (for Manipulation)
- **Status**: ❌ NOT IMPLEMENTED
- **Methods** (~12):
  - `get_value_at_time()`, `add_point()`, `remove_point()`
  - `multiply_frequencies()`, `shift_frequencies()`, `stylize()`

#### 10. DurationTier ⭐ (for Manipulation)
- **Status**: ❌ NOT IMPLEMENTED
- **Methods** (~10):
  - `get_value_at_time()`, `add_point()`, `multiply_durations()`

#### 11. IntensityTier ⭐ (for Manipulation)
- **Status**: ❌ NOT IMPLEMENTED
- **Methods** (~10):
  - `get_value_at_time()`, `add_point()`, `multiply_intensities()`

### Priority 3: Spectral Analysis (Weeks 11-13)

Complete spectral analysis capabilities:

#### 12. Spectrogram ⭐⭐
- **Status**: ✅ IMPLEMENTED (v0.4.0)
- Time-frequency representation
- Methods: query power, to_spectrum, to_ltas

#### 13. Spectrum ⭐⭐
- **Status**: ✅ IMPLEMENTED (v0.4.0)
- FFT representation
- Methods: query values, filtering, statistics

#### 14. LTAS ⭐
- **Status**: ✅ IMPLEMENTED (v0.4.0)
- Long-term average spectrum
- Methods: query, statistics

#### 15. LPC ⭐
- **Status**: ❌ Stubbed (lpc_stub.cpp exists)
- Linear predictive coding
- Methods (~10): `to_formant()`, `to_spectrum()`, coefficient queries

### Priority 4: Advanced Objects (Weeks 14-16)

Objects for advanced analysis:

#### 16. FormantPath ⭐
- Multi-candidate formant tracking (modern approach)
- Methods: candidate queries, optimal path selection

#### 17. FormantGrid ⭐
- Modifiable formant contours
- Methods: tier management, value modification

#### 18. Matrix
- 2D numerical data (base for many objects)
- Methods: query, statistics, formula operations

#### 19. Table
- Praat's data frame equivalent
- Methods: column/row operations, statistics, formula

---

## Naming Conventions for Praat → R Translation

**Consistency enables easy code migration from Praat scripts**

| Praat Pattern | R6 Pattern | Example Praat | Example R |
|---------------|------------|---------------|-----------|
| `Get [property]` | `get_[property]()` | `Get duration` | `sound$get_duration()` |
| `Get [property] at time...` | `get_[property]_at_time(t)` | `Get value at time... 0.5` | `pitch$get_value_at_time(0.5)` |
| `Get mean [property]` | `get_mean()` or `get_mean_[property]()` | `Get mean... 0 0 Hertz` | `pitch$get_mean(unit="hertz")` |
| `To [Object]` | `to_[object]()` | `To Pitch...` | `sound$to_pitch()` |
| `To [Object] ([method])` | `to_[object]_[method]()` | `To Formant (burg)...` | `sound$to_formant_burg()` |
| `Extract [subset]` | `extract_[subset]()` | `Extract part... 0 1` | `sound$extract_part(0, 1)` |
| `Scale [property]` | `scale_[property]()` | `Scale intensity... 70` | `sound$scale_intensity(70)` |
| `Down to [type]` | `as_[type]()` | `Down to Table...` | `formant$as_data_frame()` |
| `Save as [format]` | `save(path)` | `Save as WAV file...` | `sound$save("out.wav")` |
| `Insert boundary...` | `insert_boundary()` | `Insert boundary... 1 0.5` | `textgrid$insert_boundary(1, 0.5)` |
| `Set interval text...` | `set_interval_text()` | `Set interval text... 1 2 "hello"` | `textgrid$set_interval_text(1, 2, "hello")` |

### Method Categories

1. **Query methods** (`get_*`): Return values without modifying object
2. **Transform methods** (`to_*`): Create new objects of different type
3. **Extract methods** (`extract_*`): Create new objects of same type
4. **Modify methods** (verbs): Alter object state in place
5. **Export methods** (`as_*`): Convert to R native types
6. **I/O methods**: `save()`, `$new(path)` for reading

---

## Implementation Phases - REVISED

### Phase 1: Complete TextGrid Implementation (Week 1-2) ⭐⭐⭐

**CRITICAL**: TextGrid is essential for 90% of research workflows

**Tasks**:
1. ✅ Enable textgrid_wrappers.cpp (currently disabled)
2. ❌ Implement all 35+ TextGrid methods
3. ❌ Complete interval tier operations (insert/remove boundaries, set text)
4. ❌ Complete point tier operations (insert/remove points)
5. ❌ Tier management (add/remove tiers)
6. ❌ Integration tests with forced alignment data
7. ❌ Vignette: "Working with TextGrids in R"

**Deliverables**:
- `src/textgrid_wrappers.cpp` - Complete implementation
- `R/textgrid-r6.R` - Full R6 class
- `tests/testthat/test-textgrid.R` - Comprehensive tests
- `vignettes/textgrid-annotation.Rmd` - Tutorial
- `man/TextGrid.Rd` - Documentation

**Success criteria**: Can load TextGrid, edit intervals, save, and extract sound segments based on labels

---

### Phase 2: Voice Quality Objects (Weeks 3-5) ⭐⭐

**Goal**: Enable clinical voice assessment

#### Week 3: PointProcess
- Implement all methods including voice quality metrics
- Integration with Sound for jitter/shimmer
- Add Sound methods: `to_point_process_periodic_cc()`, `to_point_process_extrema()`

#### Week 4-5: Manipulation + Tier Objects
- PitchTier, DurationTier, IntensityTier
- Manipulation object (PSOLA)
- Complete pitch modification workflow

**Deliverables**:
- 4 R6 classes (PointProcess, Manipulation, PitchTier, DurationTier)
- C++ wrappers for all methods
- Tests demonstrating jitter/shimmer calculations
- Tests demonstrating pitch modification
- Vignettes: "Voice Quality Analysis", "Pitch Manipulation"

**Success criteria**: Can calculate jitter/shimmer AND modify pitch via PSOLA

---

### Phase 3: Advanced Objects (Weeks 6-8)

#### Week 6: LPC
- Implement LPC object (currently stubbed)
- Integration with Formant and Spectrum

#### Weeks 7-8: Advanced Formant & Data Objects
- FormantPath (modern formant tracking)
- FormantGrid (modifiable formants)
- Matrix (2D data)
- Table (data frames)

**Deliverables**:
- 5 R6 classes
- All tests and documentation

---

### Phase 4: Examples & Migration Guides (Weeks 9-10)

**Goal**: Demonstrate Python → R migration

#### Re-implement superassp Python Examples

Translate key Parselmouth examples from superassp/inst/python/:

1. **`examples/voice_quality_report.R`** (from praat_voice_report_memory.py)
2. **`examples/pitch_analysis.R`** (from praat_pitch.py)
3. **`examples/formant_tracking.R`** (from praat_formant_burg.py)
4. **`examples/formant_path.R`** (from praat_formantpath_burg.py)
5. **`examples/spectral_analysis.R`** (from praat_spectral_moments.py)
6. **`examples/avqi_calculation.R`** (from praat_avqi_memory.py)
7. **`examples/dsi_calculation.R`** (from praat_dsi_memory.py)

**Format for each example**:
```r
#' [Title]
#'
#' Re-implementation of [python_file.py] using speaker package
#'
#' Python (Parselmouth):
#' ```python
#' [original Python code snippet]
#' ```
#'
#' R (speaker):
#' ```r
#' [equivalent R code]
#' ```
#'
#' Key differences:
#' - [difference 1]
#' - [difference 2]

library(speaker)

# [implementation]
```

**Deliverables**:
- `inst/examples/*.R` - All example scripts
- `inst/examples/README.md` - Overview
- `inst/examples/MIGRATION_GUIDE.md` - Parselmouth → speaker mapping

---

### Phase 5: Documentation & Testing (Weeks 11-12)

**Goal**: Production-ready package

#### Documentation
- 10+ comprehensive vignettes
- Complete Rd files for all classes
- Package website (pkgdown)
- Migration guides (Praat scripts, Parselmouth)

#### Testing
- Unit tests for all methods (>95% coverage)
- Integration tests (complete workflows)
- Memory leak tests (valgrind)
- Performance benchmarks (vs Praat, Parselmouth)
- Platform tests (macOS/Linux/Windows)

#### CRAN Preparation
- R CMD check --as-cran (zero errors/warnings)
- Reduce package size
- CITATION file
- NEWS.md updates
- Submission materials

---

## Success Criteria

### Technical Excellence
- [ ] 19+ Praat objects as R6 classes
- [ ] 400+ methods covering comprehensive Praat functionality
- [ ] Zero memory leaks (valgrind clean)
- [ ] Test coverage >95% (R), >85% (C++)
- [ ] Performance within 10% of Praat desktop
- [ ] Clean builds on macOS (Intel + ARM), Linux, Windows

### Usability
- [ ] Intuitive OOP API matching Praat's design
- [ ] Consistent naming (easy Praat script translation)
- [ ] 100+ documented examples
- [ ] 10+ comprehensive vignettes
- [ ] Clear migration guides

### Completeness
- [ ] ✅ Sound, Pitch, Formant, Intensity, Harmonicity, Spectrogram, Spectrum, LTAS
- [ ] TextGrid FULL support (read, write, edit)
- [ ] Voice quality (jitter, shimmer, HNR via PointProcess)
- [ ] Pitch manipulation (PSOLA via Manipulation)
- [ ] LPC, FormantPath, FormantGrid, Matrix, Table
- [ ] All major workflows supported
- [ ] Ready for CRAN submission

---

## Architecture Decisions (for CLAUDE.md)

### Memory Management Strategy
- **R6 objects** wrap **external pointers (XPtr)** to C++ Praat objects
- XPtr finalizers call `forget()` for automatic cleanup
- No manual memory management in R code
- Pattern proven by Rcpp, RcppEigen, etc.

### Object Creation Patterns
1. **From file**: `Sound$new("file.wav")` calls `.sound_read()` C++ wrapper
2. **From transformation**: `sound$to_pitch()` calls `.sound_to_pitch()`, wraps result in `Pitch$new(.xptr = ptr)`
3. **From generation**: `Sound$create_tone()` static factory method

### Method Naming
- **Consistency is CRITICAL** for Praat script translation
- Follow table above for all new methods
- Use snake_case (R convention)
- Preserve Praat's semantic categories (get, to, extract, etc.)

### C++ Wrapper Naming
- Internal functions: `.object_method_name()`
- Always start with dot (prevents namespace pollution)
- Maps directly to R6 method: `object$method_name()` → `.object_method_name()`

### Error Handling
- Wrap Praat C++ in try/catch
- Convert MelderError to R errors via `Rcpp::stop()`
- Clear Praat error state with `Melder_clearError()`
- Provide helpful error messages

### Testing Strategy
- Unit test each method individually
- Integration tests for workflows
- Memory leak detection (valgrind, ASAN)
- Cross-platform validation
- Performance benchmarks

---

## Next Immediate Steps

1. ✅ Review and approve this amendment
2. **START PHASE 1**: Complete TextGrid implementation
3. Update version to 0.4.1-dev
4. Create GitHub issues for each object
5. Set up project tracking (milestones)
6. Begin weekly progress summaries

---

## Timeline Summary

| Weeks | Phase | Deliverable |
|-------|-------|-------------|
| 1-2 | TextGrid | Full annotation support ⭐⭐⭐ |
| 3-5 | Voice Quality | PointProcess, Manipulation, Tier objects ⭐⭐ |
| 6-8 | Advanced | LPC, FormantPath, FormantGrid, Matrix, Table |
| 9-10 | Examples | Parselmouth migration, example scripts |
| 11-12 | Finalization | Documentation, testing, CRAN prep |

**Total**: 12 weeks to comprehensive OOP implementation  
**Goal**: CRAN-ready package mirroring complete Praat architecture

---

## Conclusion

This amendment transforms speaker from a good foundation into **the definitive R interface to Praat**, mirroring Praat's object-oriented architecture and eliminating Python dependencies.

### What We Build
1. **Complete OOP interface** - 19+ objects, 400+ methods
2. **Praat-like workflows** - Direct translation from Praat scripts
3. **Python-free phonetics** - Replace Parselmouth with native R
4. **Research-grade quality** - Tested, documented, validated
5. **Future-proof design** - Extensible for new Praat features

**Let's build the phonetics toolkit R deserves!** 🎉🎤📊
