# Revised OOP Implementation Roadmap for speaker Package
**Date**: 2025-11-10  
**Status**: MASTER PLAN - REVISED APPROACH  
**Paradigm**: Object-Oriented Praat in R (No Python Dependency)

## Executive Summary

This revised roadmap refocuses the `speaker` package to **expose Praat's native object-oriented architecture** rather than implementing specific procedures. The approach is inspired by Python's Parselmouth but implemented directly in R using R6 classes wrapping Praat's C++ source code.

### Key Insight

**Praat IS object-oriented** - its C++ source code is built around a rich hierarchy of objects (`Thing`, `Sampled`, `Function`, etc.) with hundreds of methods. The original spec focused on procedures, missing this fundamental design.

### What This Means

Instead of:
```r
# Procedural approach (OLD)
pitch_data <- praat_extract_pitch(audio_file)
formant_data <- praat_extract_formant(audio_file)
```

We provide:
```r
# Object-oriented approach (NEW - matches Praat's design)
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant_hz = 5500)

# Method chaining
f0_mean <- pitch$get_mean(unit = "hertz")
f1_value <- formant$get_value_at_time(formant_number = 1, time = 0.5)

# Critical objects missing from original plan
textgrid <- TextGrid$new("annotation.TextGrid")
label <- textgrid$get_label_at_time("words", 0.5)

manipulation <- sound$to_manipulation()
pitch_tier <- manipulation$extract_pitch_tier()
pitch_tier$multiply_frequencies(1.2)  # Raise pitch 20%
```

## Current Status Assessment

### What Exists (Partially Implemented)

Based on analysis with Gemini:

1. **R6 Base Classes**: `Sound`, `Pitch`, `Formant`, `Intensity`, `Harmonicity`, `PointProcess`
2. **C++ Wrappers**: Partial implementation in `src/*_wrappers.cpp`
3. **Some Methods**: Query and export methods exist but incomplete

### Critical Gaps

1. **TextGrid** - DISABLED (`R/textgrid-r6.R.disabled`) - **CRITICAL FOR LINGUISTICS**
2. **Manipulation** - NOT IMPLEMENTED - **CRITICAL FOR PSOLA**
3. **Tier Objects** - NOT IMPLEMENTED (`PitchTier`, `FormantTier`, `DurationTier`)
4. **Spectral Objects** - NOT IMPLEMENTED (`Spectrum`, `Spectrogram`, `Ltas`)
5. **Incomplete Methods** - Many transformation and modification methods missing
6. **Legacy Code** - Old S3 functions still present, creating confusion

## Complete Praat Object Hierarchy (From Source Code Analysis)

### Priority 1: Foundation Objects (IMPLEMENT FIRST)

```
Thing (base: sys/Thing.h)
├── Sound (fon/Sound.h) ⭐ PARTIALLY DONE
├── Pitch (fon/Pitch.h) ⭐ PARTIALLY DONE  
├── Formant (fon/Formant.h) ⭐ PARTIALLY DONE
├── Intensity (fon/Intensity.h) ⭐ PARTIALLY DONE
├── Harmonicity (fon/Harmonicity.h) ⭐ PARTIALLY DONE
└── PointProcess (fon/PointProcess_def.h) ⭐ PARTIALLY DONE
```

### Priority 2: Critical Missing Objects (IMPLEMENT NEXT)

```
TextGrid (fon/TextGrid_def.h) ⭐⭐⭐ CRITICAL - DISABLED
├── IntervalTier
└── TextTier (PointTier)

Manipulation (fon/Manipulation_def.h) ⭐⭐⭐ CRITICAL - NOT IMPLEMENTED
├── Contains: Sound, PointProcess, PitchTier, DurationTier
└── Enables: PSOLA pitch/duration modification
```

### Priority 3: Spectral Analysis Objects

```
Spectrum (fon/Spectrum.h)
Spectrogram (fon/Spectrogram.h)
Ltas (fon/Ltas.h)
Cochleagram (fon/Cochleagram.h)
Excitation (fon/Excitation.h)
```

### Priority 4: Tier Objects (Fine Control)

```
PitchTier (fon/PitchTier.h)
FormantTier (fon/FormantTier.h)
FormantGrid (fon/FormantGrid.h)
IntensityTier (fon/IntensityTier.h)
DurationTier (fon/DurationTier.h)
AmplitudeTier (fon/AmplitudeTier.h)
```

## Naming Convention Standard

**Goal**: R users should be able to easily translate Praat code

### Method Categories

| Praat Pattern | R6 Pattern | Purpose | Example |
|---------------|------------|---------|---------|
| `Get X` | `get_x()` | Query scalar/vector | `get_duration()` |
| `To X` | `to_x()` | Transform to new object type | `to_pitch()` |
| `Extract X` | `extract_x()` | Extract portion, same type | `extract_part()` |
| `Scale X`, `Filter X` | verb method | Modify in-place | `scale_intensity()` |
| `Down to Matrix` | `as_x()` | Export to R type | `as_matrix()` |
| `Save as WAV` | `save()` | File I/O | `save("out.wav")` |
| `Read from file` | `$new(path)` | Constructor | `Sound$new("in.wav")` |

### Consistency Rules

1. **snake_case** for all methods (R convention)
2. **Verbs without underscores** stay lowercase: `get`, `to`, `extract`, `scale`, `filter`
3. **Multi-word parameters** use underscores: `pitch_floor`, `max_formant_hz`
4. **Units explicit** in parameters: `_hz`, `_db`, `_seconds` when ambiguous
5. **Return self** from modification methods for chaining: `invisible(self)`

## Implementation Roadmap

### Phase 1: Foundation Completion (Weeks 1-2)

**Goal**: Complete the partially implemented foundation objects

#### 1.1 Sound Object - COMPLETE IT

**Current Status**: Exists (`R/sound-r6.R`) but incomplete  
**Missing Methods**:
- `to_manipulation()` - CRITICAL for PSOLA
- `to_spectrum()`
- `to_spectrogram()`
- `to_textgrid()`
- `scale_peak()` - modification method
- `pre_emphasize()` - modification method
- `extract_channel()` - for stereo handling
- `extract_part()` - time windowing

**Action Items**:
1. Review existing `R/sound-r6.R`
2. Add missing transformation methods (`to_*`)
3. Add missing modification methods (in-place operations)
4. Add missing extraction methods
5. Implement corresponding C++ wrappers in `src/sound_wrappers.cpp`
6. Add comprehensive tests
7. Update documentation

#### 1.2 Pitch Object - COMPLETE IT

**Current Status**: Exists (`R/pitch-r6.R`) but incomplete  
**Missing Methods**:
- `to_pitch_tier()` - for manipulation
- `smooth()` - smoothing algorithm
- `interpolate()` - fill unvoiced regions
- Statistical methods (if missing): `get_quantile()`, `get_standard_deviation()`

#### 1.3 Formant Object - COMPLETE IT

**Current Status**: Exists (`R/formant-r6.R`) but incomplete  
**Missing Methods**:
- `to_formant_tier()`
- `track_formants()` - formant path tracking
- Better query methods for formant values

#### 1.4 Intensity, Harmonicity, PointProcess - COMPLETE THEM

**Review each object** for missing methods based on Praat source code.

#### 1.5 Remove Legacy Code

**Action**: Delete or clearly deprecate S3-style functions
- `R/pitch.R` - old S3 methods
- `R/formant.R` - old S3 methods  
- `R/intensity.R` - old S3 methods
- `R/harmonicity.R` - old S3 methods
- `R/s3-methods.R` - S3 generic methods

**Strategy**: 
- Move to `R/deprecated/` folder
- Add deprecation warnings if keeping temporarily
- Update NAMESPACE to remove S3 exports
- Focus documentation on R6 classes only

### Phase 2: TextGrid Implementation (Weeks 3-4) ⭐⭐⭐ CRITICAL

**Why Critical**: 
- Essential for linguistic annotation
- Required for forced alignment workflows
- Integration with phonetic corpora
- Most requested feature for R phoneticians

**Goal**: Enable full TextGrid functionality

#### 2.1 Re-enable and Complete TextGrid

**Current Status**: Disabled file exists (`R/textgrid-r6.R.disabled`)

**Required Methods**:

**Tier Management**:
```r
textgrid$get_number_of_tiers()
textgrid$get_tier_names()
textgrid$add_interval_tier(name)
textgrid$add_point_tier(name)
textgrid$remove_tier(tier)
```

**Interval Tier Methods**:
```r
textgrid$get_number_of_intervals(tier)
textgrid$get_interval_at_time(tier, time)
textgrid$get_interval_start_time(tier, interval_number)
textgrid$get_interval_end_time(tier, interval_number)
textgrid$get_interval_text(tier, interval_number)
textgrid$set_interval_text(tier, interval_number, text)
textgrid$insert_boundary(tier, time)
textgrid$remove_boundary(tier, time)
textgrid$get_label_at_time(tier, time)
```

**Point Tier Methods**:
```r
textgrid$get_number_of_points(tier)
textgrid$get_point_time(tier, point_number)
textgrid$get_point_text(tier, point_number)
textgrid$insert_point(tier, time, text)
textgrid$remove_point(tier, point_number)
```

**Export Methods**:
```r
textgrid$as_data_frame(tiers = NULL)  # tidy format
textgrid$save(path, format = "text")  # text or binary
```

#### 2.2 C++ Implementation

**File**: `src/textgrid_wrappers.cpp`

**Key Functions** (~30-35 functions):
- TextGrid creation/reading
- Tier queries and manipulation
- Interval operations
- Point operations
- Export to R data structures

**Integration with Praat Source**:
- Link to `src/praat/fon/TextGrid.cpp`
- Use existing Praat TextGrid classes
- Handle both text and binary formats

#### 2.3 Testing

**Test Coverage**:
- Read/write TextGrid files (both formats)
- Create TextGrids programmatically
- Tier manipulation
- Interval/point operations
- Edge cases (empty tiers, boundary conditions)
- Integration with Sound objects

### Phase 3: Manipulation Object (Weeks 5-6) ⭐⭐⭐ CRITICAL

**Why Critical**: 
- Enables PSOLA-based pitch/duration modification
- Core functionality for speech synthesis research
- Required for voice transformation experiments

**Goal**: Complete Manipulation object for speech modification

#### 3.1 Manipulation Class

**File**: `R/manipulation-r6.R` (NEW)

**Methods Required**:

**Creation**:
```r
# From Sound
manipulation <- sound$to_manipulation(
  time_step = 0.01,
  pitch_floor = 75,
  pitch_ceiling = 600
)

# Or direct
manipulation <- Manipulation$new(.xptr = ptr)
```

**Component Extraction**:
```r
manipulation$extract_sound()
manipulation$extract_pitch()
manipulation$extract_pitch_tier()
manipulation$extract_duration_tier()
manipulation$extract_point_process()
```

**Component Replacement**:
```r
manipulation$replace_pitch_tier(pitch_tier)
manipulation$replace_duration_tier(duration_tier)
manipulation$replace_point_process(point_process)
```

**Synthesis**:
```r
# Resynthesize with modifications
modified_sound <- manipulation$get_resynthesis_overlap_add()
```

**Complete Workflow Example**:
```r
# Load sound
sound <- Sound$new("voice.wav")

# Create manipulation
manip <- sound$to_manipulation()

# Extract pitch tier
pitch_tier <- manip$extract_pitch_tier()

# Modify pitch (raise by 20%)
pitch_tier$multiply_frequencies(1.2)

# Replace in manipulation
manip$replace_pitch_tier(pitch_tier)

# Synthesize modified sound
modified <- manip$get_resynthesis_overlap_add()
modified$save("higher_pitch.wav")
```

#### 3.2 Tier Objects (Required for Manipulation)

Must implement before Manipulation works:

**PitchTier** (`R/pitchtier-r6.R`):
```r
PitchTier <- R6Class("PitchTier",
  inherit = PraatObject,
  public = list(
    add_point = function(time, frequency),
    get_value_at_time = function(time),
    multiply_frequencies = function(factor),
    shift_frequencies = function(shift),
    as_data_frame = function()
  )
)
```

**DurationTier** (`R/durationtier-r6.R`):
```r
DurationTier <- R6Class("DurationTier",
  inherit = PraatObject,
  public = list(
    add_point = function(time, relative_duration),
    get_value_at_time = function(time),
    as_data_frame = function()
  )
)
```

#### 3.3 C++ Implementation

**Files**:
- `src/manipulation_wrappers.cpp`
- `src/pitchtier_wrappers.cpp`
- `src/durationtier_wrappers.cpp`

**Link to Praat Source**:
- `src/praat/fon/Manipulation.cpp`
- `src/praat/fon/PitchTier.cpp`

### Phase 4: Spectral Objects (Week 7)

**Goal**: Enable spectral analysis capabilities

#### 4.1 Spectrum Object

**File**: `R/spectrum-r6.R` (NEW)

**Methods**:
```r
Spectrum <- R6Class("Spectrum",
  inherit = PraatObject,
  public = list(
    # Query
    get_bin_width = function(),
    get_lowest_frequency = function(),
    get_highest_frequency = function(),
    get_value_at_frequency = function(frequency, unit = "dB"),
    get_centre_of_gravity = function(power = 2),
    get_standard_deviation = function(power = 2),
    get_skewness = function(power = 2),
    get_kurtosis = function(power = 2),
    
    # Transform
    to_ltas = function(),
    to_spectrogram = function(),
    
    # Export
    as_matrix = function(),
    as_data_frame = function()
  )
)
```

#### 4.2 Spectrogram Object

**File**: `R/spectrogram-r6.R` (NEW)

**Methods**:
```r
Spectrogram <- R6Class("Spectrogram",
  inherit = PraatObject,
  public = list(
    # Query
    get_power_at = function(time, frequency),
    get_time_from_frame = function(frame),
    get_frequency_from_bin = function(bin),
    
    # Transform
    to_spectrum_slice = function(time),
    to_ltas = function(),
    
    # Export
    as_matrix = function(),
    as_data_frame = function()
  )
)
```

#### 4.3 Ltas Object

**File**: `R/ltas-r6.R` (NEW)

**Methods**:
```r
Ltas <- R6Class("Ltas",
  inherit = PraatObject,
  public = list(
    # Query
    get_bin_width = function(),
    get_value_at_frequency = function(frequency),
    get_minimum = function(),
    get_maximum = function(),
    
    # Export
    as_data_frame = function()
  )
)
```

### Phase 5: Additional Tier Objects (Week 8)

Complete the tier object ecosystem:

- **FormantTier** (`R/formant-tier.R`)
- **FormantGrid** (`R/formant-grid.R`)
- **IntensityTier** (`R/intensity-tier.R`)
- **AmplitudeTier** (`R/amplitude-tier.R`)

### Phase 6: Parselmouth Example Re-implementation (Weeks 9-10)

**Goal**: Demonstrate equivalence and provide migration path

**Source**: `/Users/frkkan96/Documents/src/superassp/inst/python/*.py`

**Target**: `inst/examples/` in speaker package

#### 6.1 Priority Examples to Re-implement

1. **`praat_pitch.py`** → **`inst/examples/pitch_tracking.R`**
   - Multiple pitch algorithms (ac, cc)
   - Demonstrates `Sound$to_pitch()` and `Pitch` methods

2. **`praat_formant_burg.py`** → **`inst/examples/formant_tracking.R`**
   - Formant tracking with Burg algorithm
   - Demonstrates `Sound$to_formant_burg()` and `Formant` methods

3. **`praat_voice_report_memory.py`** → **`inst/examples/voice_quality.R`**
   - Comprehensive voice quality metrics
   - Jitter, shimmer, HNR calculations
   - Demonstrates `Sound`, `Pitch`, `PointProcess` integration

4. **`praat_intensity.py`** → **`inst/examples/intensity_analysis.R`**
   - Intensity tracking
   - Demonstrates `Sound$to_intensity()` and `Intensity` methods

5. **`praat_spectral_moments.py`** → **`inst/examples/spectral_analysis.R`**
   - Spectral moments (COG, SD, skewness, kurtosis)
   - Demonstrates `Sound$to_spectrum()` and `Spectrum` methods

6. **`praat_avqi_memory.py`** → **`inst/examples/avqi.R`**
   - Acoustic Voice Quality Index
   - Complex multi-object workflow

7. **`praat_dsi_memory.py`** → **`inst/examples/dsi.R`**
   - Dysphonia Severity Index
   - Multi-metric calculation

8. **`praat_sauce_memory.py`** → **`inst/examples/sauce.R`**
   - SAUCE (Speech Acoustics Using Common Experiments)
   - Comprehensive phonetic measurements

#### 6.2 Example Template

Each example should include:

```r
# inst/examples/pitch_tracking.R

#' Pitch Tracking Example
#' 
#' This example demonstrates pitch tracking using the speaker package,
#' re-implementing functionality from the Parselmouth Python code in
#' /Users/frkkan96/Documents/src/superassp/inst/python/praat_pitch.py

# ==============================================================================
# ORIGINAL PYTHON CODE (for reference)
# ==============================================================================
# import parselmouth as pm
# snd = pm.Sound("audio.wav")
# pitch_ac = snd.to_pitch_ac(
#     time_step=0.005,
#     pitch_floor=75.0,
#     pitch_ceiling=600.0,
#     very_accurate=True
# )
# f0_mean = pitch_ac.get_mean()

# ==============================================================================
# EQUIVALENT R CODE (speaker package)
# ==============================================================================
library(speaker)

# Load sound
sound <- Sound$new("audio.wav")

# Extract pitch using autocorrelation
pitch <- sound$to_pitch_ac(
  time_step = 0.005,
  pitch_floor = 75.0,
  pitch_ceiling = 600.0,
  very_accurate = TRUE
)

# Get statistics
f0_mean <- pitch$get_mean(unit = "hertz")
f0_sd <- pitch$get_standard_deviation(unit = "hertz")
f0_min <- pitch$get_minimum(unit = "hertz")
f0_max <- pitch$get_maximum(unit = "hertz")

# Export to data frame
pitch_df <- pitch$as_data_frame()

# Print results
cat("Pitch Statistics:\n")
cat(sprintf("  Mean F0: %.2f Hz\n", f0_mean))
cat(sprintf("  SD F0: %.2f Hz\n", f0_sd))
cat(sprintf("  Min F0: %.2f Hz\n", f0_min))
cat(sprintf("  Max F0: %.2f Hz\n", f0_max))
```

### Phase 7: Documentation (Week 11)

#### 7.1 Vignettes

**Create comprehensive vignettes** in `vignettes/`:

1. **`getting-started.Rmd`**
   - Installation
   - Basic workflow: Sound → Pitch → export
   - Introduction to R6 OOP approach

2. **`working-with-sound.Rmd`**
   - Loading audio files
   - Sound properties and queries
   - Manipulation and modification
   - Generating synthetic sounds

3. **`pitch-analysis.Rmd`**
   - Different pitch algorithms (ac, cc)
   - Pitch statistics and contours
   - Pitch smoothing and interpolation
   - Export and visualization

4. **`formant-tracking.Rmd`**
   - Formant extraction (Burg algorithm)
   - Formant values at specific times
   - Formant tracking over time
   - Formant statistics

5. **`textgrid-annotation.Rmd`**
   - Creating TextGrids programmatically
   - Reading existing TextGrids
   - Manipulating tiers and intervals
   - Integration with forced alignment

6. **`voice-quality.Rmd`**
   - Jitter calculation
   - Shimmer calculation
   - Harmonics-to-Noise Ratio
   - Complete voice report

7. **`speech-manipulation.Rmd`**
   - PSOLA-based pitch modification
   - Duration modification
   - Complete manipulation workflow
   - Voice transformation examples

8. **`spectral-analysis.Rmd`**
   - Spectrum analysis
   - Spectrograms
   - Long-term average spectrum
   - Spectral moments (COG, SD, etc.)

9. **`from-praat-to-r.Rmd`**
   - Translation guide for Praat users
   - Naming convention mappings
   - Common workflow examples
   - Praat script → R translation examples

10. **`from-parselmouth-to-speaker.Rmd`**
    - Migration guide for Python/Parselmouth users
    - API comparison
    - Code translation examples

#### 7.2 Reference Documentation

**Ensure complete Rd files** for:
- All R6 classes
- All public methods
- All parameters with descriptions
- Return value descriptions
- Examples for each method
- Links between related methods/classes

#### 7.3 Package-Level Documentation

**Update `R/speaker-package.R`**:
- Complete package description
- Overview of OOP approach
- Quick start example
- Links to vignettes
- Citation information

### Phase 8: Testing & Validation (Week 12)

#### 8.1 Unit Tests

**Structure**: `tests/testthat/test-<object>.R` for each object

**Coverage Goals**:
- R code: >95%
- C++ code: >85%

**Test Categories**:

1. **Object Creation Tests**
   - From file
   - From data
   - With XPtr
   - Error handling for invalid inputs

2. **Method Tests**
   - All query methods
   - All transformation methods
   - All modification methods
   - All export methods

3. **Integration Tests**
   - Complete workflows
   - Object interaction
   - Method chaining

4. **Memory Tests**
   - XPtr lifecycle
   - Finalizers working correctly
   - No memory leaks (valgrind)

5. **Edge Case Tests**
   - Empty objects
   - Invalid parameters
   - Boundary conditions
   - Different audio formats

#### 8.2 Validation Tests

**Goal**: Ensure results match Praat desktop application

**Method**:
1. Generate test results in Praat
2. Run same analysis in speaker
3. Compare outputs (within tolerance)

**Test Datasets**:
- Various sample rates
- Mono/stereo
- Different durations
- Various voice types (male, female, pathological)

#### 8.3 Performance Benchmarks

**Compare performance**:
- speaker vs Praat desktop
- speaker vs Parselmouth
- Different object operations

**Acceptance Criteria**:
- Performance within 10% of Praat desktop
- No major regressions vs Parselmouth

### Phase 9: CRAN Preparation (Week 13)

#### 9.1 CRAN Requirements

- [ ] Pass `R CMD check --as-cran` with no errors, warnings, or notes
- [ ] All examples run successfully
- [ ] All tests pass on multiple platforms
- [ ] Documentation complete
- [ ] NEWS.md updated
- [ ] DESCRIPTION accurate
- [ ] LICENSE correct
- [ ] README.md informative

#### 9.2 Platform Testing

**Test on**:
- macOS (Intel and Apple Silicon)
- Windows (latest R)
- Linux (Ubuntu, Fedora)

#### 9.3 Version Update

- Update to version 0.2.0 (major functionality addition)
- Document breaking changes (S3 → R6 migration)
- Provide migration guide

## Success Criteria

### Technical Completeness

- ✅ **12+ Praat objects** implemented as R6 classes
- ✅ **200+ methods** covering Praat functionality
- ✅ **TextGrid full support** (read, write, manipulate)
- ✅ **Manipulation/PSOLA** working for speech modification
- ✅ **Zero memory leaks** (valgrind clean)
- ✅ **Test coverage >90%** (R), >80% (C++)
- ✅ **Cross-platform** (Windows, macOS, Linux)

### Usability

- ✅ **Intuitive OOP API** matching Praat's design
- ✅ **Consistent naming** conventions for easy Praat-to-R translation
- ✅ **50+ documented examples**
- ✅ **10+ comprehensive vignettes**
- ✅ **Migration guides** (Praat scripts, Parselmouth)

### Research Value

- ✅ **All superassp Python examples** re-implemented
- ✅ **Voice quality metrics** (jitter, shimmer, HNR, AVQI, DSI)
- ✅ **Spectral analysis** (moments, COG, spectrograms)
- ✅ **Linguistic annotation** (TextGrid integration)
- ✅ **Speech synthesis** (PSOLA modification)

## Implementation Notes

### AV Package Integration

**Decision** (from CLAUDE.md context): Use the `av` package fork from https://github.com/humlab-speech/av for media loading.

**Implications**:
- Sound file I/O may leverage av for format support
- Document av as suggested dependency
- Ensure compatibility with Praat's audio handling

### Interpreter Decision

**Decision**: Omit Praat script interpreter for now

**Implications**:
- **Cannot** execute unconverted Praat scripts directly
- **Future extension**: Mark interpreter as future feature
- **Current approach**: Provide R6 API + translation guides
- **Plotting**: Picture/plotting functionality postponed (requires interpreter)

**Documented in**: CLAUDE.md as future extensions

### C++ Standard

**Requirement**: C++11 minimum for Rcpp compatibility with R 4.0+

**Praat compatibility**: Praat source uses modern C++, ensure compatibility layer

### Future Extensions

Document these for future implementation:

1. **Praat Script Interpreter**
   - Execute unconverted Praat scripts
   - Dynamic script loading
   - Integration with R workflows

2. **Picture/Plotting Graphics**
   - Praat's native drawing commands
   - Integration with R graphics devices
   - Spectrogram plotting, pitch contours, etc.

3. **Additional Objects**
   - More advanced analysis objects
   - Machine learning-related objects
   - Experimental features from Praat development

## Timeline Summary

| Week | Phase | Deliverable |
|------|-------|-------------|
| 1-2 | Foundation Completion | Sound, Pitch, Formant, Intensity, Harmonicity, PointProcess COMPLETE |
| 1-2 | Legacy Cleanup | Remove/deprecate S3 code |
| 3-4 | TextGrid | Full TextGrid implementation |
| 5-6 | Manipulation | Manipulation + PitchTier + DurationTier |
| 7 | Spectral | Spectrum, Spectrogram, Ltas |
| 8 | Tiers | FormantTier, IntensityTier, AmplitudeTier, FormantGrid |
| 9-10 | Examples | Re-implement all superassp Python examples |
| 11 | Documentation | 10 vignettes + complete reference docs |
| 12 | Testing | Comprehensive tests + validation |
| 13 | CRAN Prep | Package polish + cross-platform testing |

**Total**: 13 weeks to production-ready, CRAN-submittable package

## Conclusion

This revised roadmap transforms speaker from a partial, procedure-based implementation into a **comprehensive, object-oriented Praat interface for R** that:

1. **Mirrors Praat's native C++ OOP design**
2. **Provides Python/Parselmouth equivalent functionality** (without Python dependency)
3. **Exposes 12+ objects with 200+ methods**
4. **Enables natural Praat-to-R code translation**
5. **Includes complete documentation and migration guides**

The result will be **the definitive phonetic analysis toolkit for R**, filling a critical gap in the R ecosystem for linguists and speech scientists.
