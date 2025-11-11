# Object-Oriented Architecture Reassessment - November 11, 2025

## Executive Summary

After reviewing the current implementation against the speckit plan and Praat's object-oriented architecture (as exemplified by Python's Parselmouth), this document provides an **amended implementation plan** that fully embraces Praat's OOP nature.

## Key Insight: The Paradigm Shift

### Original Approach (Procedural)
The initial specs focused on **isolated functions** that process audio files:
```r
# Functional approach - NOT aligned with Praat
pitch_data <- praat_extract_pitch(file, min_pitch = 75)
formant_data <- praat_extract_formant(file, max_formant = 5500)
```

**Problems**:
- Ignores Praat's inherent object-oriented design
- Forces repeated file I/O and copying
- Missing critical objects (TextGrid, Manipulation, etc.)
- Doesn't support method chaining or object persistence
- Not how Praat or Parselmouth actually work

### Amended Approach (Object-Oriented)
**Mirror Praat's C++ architecture** using R6 classes:
```r
# Object-oriented - Aligned with Praat
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant_hz = 5500)

# Method chaining
mean_f0 <- pitch$get_mean(unit = "hertz")
f1_values <- formant$as_data_frame()

# TextGrid annotation (CRITICAL missing from original plan)
tg <- TextGrid$new("annotation.TextGrid")
word_tier_data <- tg$as_data_frame(tier = "words")
```

## Current Implementation Status

### ✅ Already Implemented (Impressive Progress!)

The package has already made substantial progress toward the OOP paradigm:

1. **Sound** - Complete R6 class (`R/sound-r6-new.R`)
   - File I/O via av package
   - Query methods (duration, sampling frequency, RMS, energy, power)
   - Transformation methods (to_pitch, to_formant_burg, to_intensity, to_spectrogram, to_harmonicity)
   - Export methods (as_matrix, as_data_frame, save)
   - Modification methods (scale_intensity, filtering)

2. **Pitch** - Complete R6 class (`R/pitch-r6.R`)
   - Query methods (get_mean, get_minimum, get_maximum, get_value_at_time)
   - Statistical methods (get_standard_deviation, get_quantile)
   - Frame navigation
   - Export to data.frame
   - Down-sampling to PitchTier

3. **Formant** - Complete R6 class (`R/formant-r6.R`)
   - Query methods for formant values and bandwidths
   - Statistical aggregation (mean, min, max, SD, quantile)
   - Frame-by-frame access
   - Export to data.frame

4. **Intensity** - Complete R6 class (`R/intensity-r6.R`)
   - Query methods (get_value_at_time, get_mean, get_min/max)
   - Statistical methods
   - Export capabilities
   - Down-sampling to IntensityTier

5. **Harmonicity** - R6 class (partial - needs completion)
   - Basic query methods
   - Export functionality

6. **Spectrogram** - Complete R6 class (`R/spectrogram-r6.R`)
   - Time-frequency queries
   - Power extraction
   - Transformation to LTAS/Spectrum

7. **Spectrum** - Complete R6 class (`R/spectrum-r6.R`)
   - Spectral moment calculations (COG, SD, skewness, kurtosis)
   - Band energy/density queries
   - Filtering methods
   - Export capabilities

8. **TextGrid** - Complete R6 class (`R/textgrid-r6.R`) ⭐
   - Tier management (interval and point tiers)
   - Label queries and modifications
   - Interval/point navigation
   - Export to data.frame
   - **CRITICAL for phonetic research**

9. **Manipulation** - Complete R6 class (`R/manipulation-r6.R`)
   - PSOLA pitch/duration modification
   - Component extraction (PitchTier, DurationTier, pulses)
   - Resynthesis
   - **CRITICAL for prosody modification**

10. **PointProcess** - Complete R6 class (`R/pointprocess-r6.R`)
    - Glottal pulse detection
    - Jitter/shimmer calculations
    - Voice quality metrics
    - **CRITICAL for voice analysis**

11. **Supporting Tier Objects**:
    - **PitchTier** (`R/pitchtier-r6.R`) - For pitch manipulation
    - **IntensityTier** (`R/intensitytier-r6.R`) - For amplitude manipulation
    - **DurationTier** (`R/durationtier-r6.R`) - For tempo modification

12. **LTAS** - R6 class for long-term average spectrum

### C++ Infrastructure

Strong foundation already in place:
- `src/sound_wrappers.cpp` - Sound object operations
- `src/formant_wrappers.cpp` - Formant operations
- `src/intensity_wrappers.cpp` - Intensity operations
- `src/harmonicity_wrappers.cpp` - HNR calculations
- `src/textgrid_wrappers.cpp` - TextGrid I/O and queries
- `src/manipulation_wrappers.cpp` - PSOLA operations
- `src/pointprocess_wrappers.cpp` - Point process and voice quality
- `src/spectrogram_wrappers.cpp` - Time-frequency analysis
- External pointer management and memory safety
- Error handling bridge (Praat MelderError → R errors)

### ❌ Missing or Incomplete Components

Based on comparison with Parselmouth and Praat's capabilities:

1. **FormantPath** - Optimal formant ceiling tracking (NEW)
   - Critical for accurate formant analysis
   - Used in Parselmouth examples
   - Automatic ceiling selection

2. **LPC** - Linear Predictive Coding (Partial/Stub?)
   - Found `src/lpc_stub.cpp` - suggests incomplete
   - Needed for alternative formant estimation

3. **Generic praat_call() Interface** (Missing)
   - Like Parselmouth's `pm.praat.call(object, "Command", ...)`
   - Would enable calling ANY Praat command
   - Future-proofs against new Praat features

4. **Additional Sound Modification Methods** (Partially missing)
   - Resampling
   - Channel operations (mono/stereo conversion)
   - Sound combination (concatenate, mix)
   - Advanced filtering

5. **Voice Report** (Composite function - may be missing)
   - Comprehensive voice quality assessment
   - Combines pitch, jitter, shimmer, HNR

6. **Additional Tier Types** (May be missing)
   - FormantTier
   - AmplitudeTier
   - Other modification tiers

7. **Matrix/Table Objects** (Missing)
   - Praat has Matrix, Table objects for data
   - May not be critical if we use R's native data structures

## Assessment: Actual State vs Original Plan

### What Was Planned vs What Exists

The **original speckit plan** was procedural and limited in scope. However, the **actual implementation** has far exceeded this and is already substantially aligned with the proper OOP paradigm!

**The implementation team has already:**
1. ✅ Adopted R6 classes as the core architecture
2. ✅ Implemented external pointers for memory management
3. ✅ Created the full Sound → Analysis object pipeline
4. ✅ Implemented TextGrid (CRITICAL for linguistics)
5. ✅ Implemented Manipulation (CRITICAL for synthesis)
6. ✅ Implemented PointProcess (CRITICAL for voice quality)
7. ✅ Created supporting tier objects
8. ✅ Established naming conventions (get_*, to_*, as_*)

### What Still Needs Completion

Given the excellent foundation, the remaining work is **refinement and extension**:

1. **Complete Harmonicity** - Finish any incomplete methods
2. **Add FormantPath** - Optimal formant tracking
3. **Complete LPC** - Replace stub with full implementation
4. **Add Missing Sound Methods** - Resampling, combination, advanced modifications
5. **Create Composite Functions** - Voice reports, batch analysis helpers
6. **Documentation** - Comprehensive roxygen2 docs + vignettes
7. **Testing** - Extensive unit and integration tests
8. **Examples** - Replicate superassp Python workflows in pure R

## Amended Implementation Plan

### Phase 1: Complete Existing Objects (Week 1)

**Priority**: Finish incomplete implementations

Tasks:
1. **Harmonicity** - Verify/complete all query methods
2. **LPC** - Replace stub with full implementation OR document as future work
3. **Sound** - Add missing modification methods:
   - `resample(new_frequency, precision)`
   - `convert_to_mono()`
   - `convert_to_stereo()`
   - `concatenate(other_sound)`
   - `mix(other_sound)`
4. **Verify C++ wrappers** - Ensure all R6 methods have C++ backing
5. **Memory leak testing** - Run valgrind on all objects

**Deliverables**:
- All existing R6 classes fully functional
- No stub implementations
- Clean memory management
- Updated NAMESPACE exports

### Phase 2: Add Advanced Objects (Week 2)

**Priority**: Missing critical objects

Tasks:
1. **FormantPath** - Optimal formant ceiling analysis
   - R6 class: `R/formantpath-r6.R`
   - C++ wrapper: `src/formantpath_wrappers.cpp`
   - Methods: create from Sound, extract optimal formant, track formants
   
2. **Additional Tier Objects** (if needed):
   - FormantTier (if useful for formant manipulation)
   - AmplitudeTier (if distinct from IntensityTier)

3. **Voice Report Function**:
   - Composite analysis: `sound$voice_report(pitch_floor, pitch_ceiling)`
   - Returns list with pitch stats, jitter, shimmer, HNR
   - Wrapper around existing components

**Deliverables**:
- FormantPath R6 class + C++ + tests
- Voice report composite function
- Documentation for new objects

### Phase 3: Documentation & Testing (Week 3)

**Priority**: Make package production-ready

Tasks:
1. **Comprehensive roxygen2 docs** for ALL classes
   - Class descriptions
   - Method documentation with parameters and return values
   - Examples for each method
   - Links to Praat manual sections
   
2. **Vignettes**:
   - "Getting Started with speaker" - Basic workflow
   - "Acoustic Analysis Pipeline" - Sound → Pitch/Formant/Intensity
   - "TextGrid Annotation" - Working with linguistic annotations
   - "Voice Quality Assessment" - Jitter, shimmer, HNR
   - "Prosody Modification" - Using Manipulation objects
   - "Praat Script Translation Guide" - Converting Praat scripts to R

3. **Unit Tests**:
   - Test coverage > 80% for all R6 classes
   - Verify against known Praat results
   - Compare with Parselmouth outputs (where possible)
   - Memory leak tests

4. **Integration Tests**:
   - Full workflow tests
   - Replicate Praat manual examples
   - Edge case handling

**Deliverables**:
- `man/*.Rd` files for all classes
- `vignettes/*.Rmd` (6+ vignettes)
- `tests/testthat/*.R` with comprehensive coverage
- CRAN-ready documentation

### Phase 4: Examples & Parselmouth Parity (Week 4)

**Priority**: Demonstrate capabilities, enable migration

Tasks:
1. **Analyze superassp Python code** (`/Users/frkkan96/Documents/src/superassp/inst/python/`)
   - Identify all Parselmouth usage patterns
   - Categorize by functionality

2. **Create R equivalents**:
   - `inst/examples/` directory in package
   - One R script per Python file
   - Side-by-side comparison showing Python → R translation
   - Verify identical results

3. **Migration guide**:
   - Vignette: "Migrating from Parselmouth to speaker"
   - API comparison table
   - Common patterns

4. **Benchmark performance**:
   - Compare speed with Parselmouth
   - Identify any bottlenecks
   - Optimize if needed

**Deliverables**:
- `inst/examples/*.R` - R versions of Python analyses
- Migration guide vignette
- Performance comparison report
- Optimization if needed

### Phase 5: Optional Extensions (Future Work)

**Priority**: Nice-to-have features (document for future)

Potential additions:
1. **Generic praat_call() interface**:
   - Universal command executor
   - Map R args → Praat types
   - Return appropriate objects
   - Future-proof against Praat updates

2. **Additional Praat objects** (as needed):
   - Cochleagram
   - Excitation
   - MFCC
   - PowerCepstrum
   - Polygon (for formant tracking)

3. **Batch processing helpers**:
   - Process directories of files
   - Parallel processing support
   - Progress indicators

4. **Praat script interpreter** (AMBITIOUS):
   - Parse and execute Praat scripts directly
   - Would enable zero-modification script usage
   - Large undertaking - evaluate need vs effort

**Decision**: Document these as future extensions in CLAUDE.md but DO NOT implement now unless critical need emerges.

## Success Criteria

The package will be considered **complete** when:

1. ✅ All major Praat object types have R6 classes
2. ✅ All critical methods are implemented (query, transform, export)
3. ✅ TextGrid fully functional (annotation workflows)
4. ✅ Manipulation fully functional (prosody modification)
5. ✅ PointProcess fully functional (voice quality)
6. ✅ All R6 methods have C++ backing (no stubs)
7. ✅ Comprehensive documentation (roxygen2 + vignettes)
8. ✅ Test coverage > 80%
9. ✅ Zero memory leaks (valgrind clean)
10. ✅ Can replicate superassp Python workflows in pure R
11. ✅ Clear migration path from Parselmouth
12. ✅ CRAN-ready (passes R CMD check)

## Naming Conventions (Already Established)

The package has excellent, consistent naming:

| Pattern | Usage | Examples |
|---------|-------|----------|
| `get_*` | Query properties | `get_mean()`, `get_duration()`, `get_value_at_time()` |
| `to_*` | Transform to another object | `to_pitch()`, `to_formant_burg()`, `to_intensity()` |
| `as_*` | Export to R structure | `as_data_frame()`, `as_matrix()` |
| `extract_*` | Get subset/component | `extract_part()`, `extract_channel()`, `extract_pitch_tier()` |
| `*_at_time` | Time-specific queries | `get_value_at_time()`, `get_label_at_time()` |
| `*_at_index` | Index-specific queries | `get_value_at_index()`, `get_time_from_index()` |

**Maintain this consistency** in all new implementations.

## Architecture Decisions Documented

### Decision 1: R6 vs S3/S4
**Choice**: R6 classes with external pointers  
**Rationale**:
- Natural mapping to Praat's C++ objects
- Efficient memory management (no copying)
- Method syntax matches Praat/Parselmouth patterns
- Easier to maintain state (private fields)

### Decision 2: Media Loading
**Choice**: Use `av` package (humlab-speech fork) for file I/O  
**Rationale**:
- Supports all formats via FFmpeg (MP3, FLAC, OGG, AAC, etc.)
- Consistent with other humlab-speech packages
- No need to replicate Praat's file I/O code
- Well-maintained, cross-platform

### Decision 3: No Praat Script Interpreter (For Now)
**Choice**: No direct Praat script execution initially  
**Rationale**:
- Significant implementation effort
- Can translate scripts manually with good docs
- R6 API already mirrors Praat semantics
- Can add later if demand exists

**Consequence**: Users must translate Praat scripts to R, but with consistent naming this is straightforward.

### Decision 4: No Picture/Plotting in Phase 1
**Choice**: Omit Praat's Picture object/plotting initially  
**Rationale**:
- R has superior plotting (ggplot2, etc.)
- Praat's plotting is tied to GUI
- Export to data.frame enables R plotting
- Can add Praat-style plots as convenience wrappers later

**Consequence**: Users plot with R tools (recommended) or implement Praat-style plots as needed.

### Decision 5: Prioritize Core Phonetic Objects
**Choice**: Focus on Sound, Pitch, Formant, Intensity, TextGrid, Manipulation, PointProcess  
**Rationale**:
- Cover 95% of phonetic research needs
- These are most-used in Parselmouth
- Enable complete analysis pipelines
- Can add specialized objects later (MFCC, Cochleagram, etc.)

### Decision 6: Export to R Data Structures
**Choice**: Prefer `as_data_frame()` over Praat's native formats  
**Rationale**:
- Data frames are R's lingua franca
- Enables integration with tidyverse
- More flexible than Praat's Table object
- Can still save to Praat formats for interop

## Praat Object Coverage Plan

### Tier 1: IMPLEMENTED ✅
- Sound
- Pitch
- Formant
- Intensity
- Harmonicity (needs completion)
- Spectrogram
- Spectrum
- LTAS
- TextGrid ⭐
- Manipulation ⭐
- PointProcess ⭐
- PitchTier
- IntensityTier
- DurationTier

### Tier 2: TO ADD
- FormantPath (high priority)
- LPC (complete/replace stub)
- Voice Report (composite function)

### Tier 3: FUTURE EXTENSIONS (document, don't implement)
- Generic praat_call()
- Praat script interpreter
- Additional objects: Cochleagram, Excitation, MFCC, PowerCepstrum, Polygon
- Praat Picture/plotting wrappers
- Batch processing utilities
- Matrix/Table objects (or use R equivalents)

## Integration with superassp

The `/Users/frkkan96/Documents/src/superassp/inst/python/` directory contains Python code using Parselmouth. In Phase 4, we will:

1. Catalog all Python files
2. Identify Parselmouth usage patterns
3. Create equivalent R implementations using speaker
4. Place in `inst/examples/` with documentation
5. Create migration guide

This demonstrates **feature parity** and provides **concrete migration examples**.

## Timeline Summary

| Phase | Duration | Focus | Deliverable |
|-------|----------|-------|-------------|
| 1 | Week 1 | Complete existing objects | All R6 classes fully functional |
| 2 | Week 2 | Add advanced objects | FormantPath, Voice Report, missing features |
| 3 | Week 3 | Documentation & testing | Comprehensive docs, vignettes, tests |
| 4 | Week 4 | Examples & parity | superassp re-implementations, migration guide |

**Total: 4 weeks to production-ready package**

## Next Steps (Immediate)

1. ✅ Create this assessment document
2. Update CLAUDE.md with architectural decisions
3. Start Phase 1:
   - Review and complete Harmonicity
   - Address LPC stub
   - Add missing Sound modification methods
   - Run memory leak tests
4. Continue to Phase 2 and beyond without stopping

## Conclusion

The `speaker` package has already achieved substantial alignment with Praat's object-oriented architecture. The R6 classes, external pointer management, and method naming are excellent. The main remaining work is:

1. **Completing** incomplete implementations
2. **Adding** a few missing advanced objects (FormantPath, complete LPC)
3. **Documenting** comprehensively
4. **Testing** thoroughly
5. **Demonstrating** with examples

This is **refinement and polishing**, not fundamental restructuring. The architecture is sound and well-executed.
