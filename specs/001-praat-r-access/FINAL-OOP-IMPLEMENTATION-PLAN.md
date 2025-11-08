# Final Object-Oriented Praat R Package Implementation Plan

**Created**: 2025-11-08  
**Status**: Master Implementation Plan  
**Paradigm**: Complete Object-Oriented Architecture

## Executive Summary

This plan directs the complete implementation of the speaker package as a **comprehensive, object-oriented interface to Praat** that mirrors Praat's native C++ architecture and eliminates the need for Python/Parselmouth dependencies.

### Core Principle

**Expose Praat OBJECTS and their METHODS, not isolated procedures.**

Praat is fundamentally object-oriented with a rich hierarchy of ~30+ object types (Thing → Function → Sampled → Sound, Pitch, Formant, etc.). Our R package must reflect this structure using R6 classes backed by external pointers to persistent C++ Praat objects.

### Strategic Goals

1. **Mirror Praat's OOP Design**: R6 classes ↔ Praat C++ objects with full method coverage
2. **Eliminate Python Dependency**: Replace all Parselmouth workflows with native R
3. **Enable Complete Workflows**: Support full phonetic analysis pipelines in R
4. **Provide Migration Paths**: Clear translation from Praat scripts and Parselmouth code
5. **Prioritize Critical Objects**: Focus on most-used objects first (Sound, Pitch, Formant, TextGrid, etc.)

## Problem with Previous Approach

### Original Spec Limitations

The original specification focused on **isolated procedures**:
```r
# Functional/procedural style
pitch_data <- praat_extract_pitch(audio_file, min_pitch = 75, max_pitch = 600)
formant_data <- praat_extract_formant(audio_file, max_formant = 5500)
```

**Issues**:
- Ignores Praat's object-oriented architecture
- Forces repeated data copying between R and C++
- No object persistence for method chaining
- Missing critical functionality (TextGrid, Manipulation, etc.)
- Doesn't reflect how Praat actually works

### New Object-Oriented Approach

```r
# Object-oriented style - mirrors Praat
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant_hz = 5500)

# Method chaining
mean_f0 <- pitch$get_mean(unit = "hertz")
f1_mean <- formant$get_mean(formant_number = 1)

# TextGrid annotation (CRITICAL missing feature)
tg <- TextGrid$new("annotation.TextGrid")
word_tier <- tg$get_tier("words")
label <- tg$get_label_at_time("words", 0.5)

# Pitch manipulation (CRITICAL missing feature)
manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(factor = 1.2)
manip$replace_pitch_tier(pitch_tier)
modified <- manip$get_resynthesis_overlap_add()
modified$save("higher_pitch.wav")
```

## Complete Praat Object Hierarchy

Based on analysis of Praat source code (`src/praat.github.io/fon/`) and Parselmouth design:

### Priority 1: Foundation Objects (Weeks 1-5)

1. **Sound** (fon/Sound.h) ⭐ FOUNDATION
   - Audio waveform representation
   - Creation: from file, from values, generate
   - Methods: 40+ (query, transform, modify, extract, export)
   - Transforms to: Pitch, Formant, Intensity, Spectrogram, Spectrum, Harmonicity, etc.

2. **Pitch** (fon/Pitch.h) ⭐ CORE
   - F0 contour representation
   - Methods: 20+ (query statistics, manipulation, export)
   - Transforms to: PitchTier, PointProcess, Sound (resynthesize)

3. **Formant** (fon/Formant.h) ⭐ CORE
   - Formant trajectory representation
   - Methods: 15+ (query values, statistics, tracking, export)
   - Transforms to: FormantGrid, Table

4. **Intensity** (fon/Intensity.h) ⭐ CORE
   - Loudness contour representation
   - Methods: 12+ (query statistics, export)
   - Transforms to: IntensityTier

### Priority 2: Annotation & Manipulation (Weeks 5-7)

5. **TextGrid** (fon/TextGrid_def.h) ⭐⭐⭐ CRITICAL MISSING FEATURE
   - Multi-tier annotation system
   - IntervalTier and PointTier management
   - Methods: 35+ (tier management, interval/point operations, I/O)
   - **Essential for**: linguistic annotation, forced alignment, segmentation
   - **Used by**: 90%+ of phonetic research

6. **Manipulation** (fon/Manipulation_def.h) ⭐⭐ HIGH PRIORITY
   - PSOLA-based pitch/duration modification
   - Integrates: Sound, PointProcess, PitchTier, DurationTier
   - Methods: 10+ (extract components, modify, resynthesize)
   - **Essential for**: speech synthesis, prosody modification

7. **PointProcess** (fon/PointProcess_def.h) ⭐
   - Sequence of time points (glottal pulses, events)
   - Methods: 15+ (query, voice quality metrics with Sound)
   - **Essential for**: jitter, shimmer calculations

### Priority 3: Spectral Analysis (Weeks 7-8)

8. **Spectrogram** (fon/Spectrogram.h)
   - Time-frequency representation (STFT)
   - Methods: 12+ (query power, transformations)
   - Transforms to: Spectrum (at time), Ltas

9. **Spectrum** (fon/Spectrum.h)
   - FFT frequency domain representation
   - Methods: 15+ (query values, filtering, transformations)
   - Transforms to: Sound, Ltas, Excitation

10. **Harmonicity** (fon/Harmonicity.h)
    - HNR (Harmonics-to-Noise Ratio) contour
    - Methods: 10+ (query statistics, export)

11. **LPC** (fon/LPC.h)
    - Linear Predictive Coding coefficients
    - Methods: 8+ (query, transformations)
    - Transforms to: Formant, Spectrum

### Priority 4: Voice Quality & Advanced (Weeks 8-9)

12. **VoiceReport** (special combined object)
    - Comprehensive voice quality metrics
    - Methods: 15+ (jitter variants, shimmer variants, HNR, autocorrelation)
    - Integrates: Sound, Pitch, PointProcess, Harmonicity

13. **PitchTier** (fon/PitchTier.h)
    - Modifiable pitch contour
    - Methods: 10+ (add/remove points, multiply, shift)

14. **FormantTier** / **FormantGrid** (fon/FormantGrid.h)
    - Modifiable formant contours
    - Methods: 12+ (tier management, value modification)

15. **IntensityTier** (fon/IntensityTier.h)
    - Modifiable intensity contour
    - Methods: 10+ (point manipulation)

16. **DurationTier** (fon/DurationTier.h)
    - Duration modification control
    - Methods: 8+ (point manipulation, integration with Manipulation)

## Implementation Roadmap (12 Weeks)

### Week 1-2: Foundation Infrastructure

**Goal**: Establish robust R6/XPtr architecture

**Tasks**:
1. Finalize C++ build system with all Praat sources
2. Implement base `PraatObject` R6 class
3. Create comprehensive error handling (C++ MelderError → R errors)
4. Set up XPtr finalizer infrastructure
5. Memory leak testing framework (valgrind)
6. Basic unit test framework

**Deliverables**:
- `R/praat-object-base.R` - Base class for all Praat objects
- `src/praat_infrastructure.cpp` - XPtr utilities, error bridge
- `tests/testthat/test-memory.R` - Memory management tests
- Package builds cleanly on macOS, Linux, Windows

**Milestone**: Clean build with zero memory leaks ✅

---

### Week 2-3: Sound Object (Template for All Objects)

**Goal**: Complete Sound implementation as pattern for other objects

**R6 Methods** (~40 methods):

**Creation**:
- `Sound$new(path)` - Read from file
- `Sound$from_values(values, rate)` - From R vector
- `Sound$create_tone(duration, freq)` - Generate tone
- `Sound$create_silence(duration)` - Generate silence

**Query** (get_*):
- `get_duration()`, `get_sampling_frequency()`, `get_number_of_samples()`
- `get_value_at_time(t, channel)`, `get_value_at_sample(n, channel)`
- `get_energy()`, `get_power()`, `get_rms()`, `get_intensity_db()`

**Transform** (to_*):
- `to_pitch(...)` → Pitch
- `to_pitch_ac(...)` → Pitch (autocorrelation)
- `to_formant_burg(...)` → Formant
- `to_intensity(...)` → Intensity
- `to_spectrogram(...)` → Spectrogram
- `to_spectrum(...)` → Spectrum
- `to_harmonicity_cc(...)` → Harmonicity
- `to_manipulation(...)` → Manipulation
- `to_point_process_periodic_cc(...)` → PointProcess
- `to_textgrid(tier_name)` → TextGrid

**Modify**:
- `scale_intensity(db)`, `scale_peak(value)`
- `pre_emphasize(freq)`, `de_emphasize(freq)`
- `filter_pass_hann_band(from, to, width)`

**Extract**:
- `extract_channel(n)` → Sound
- `extract_part(start, end, window)` → Sound

**Export**:
- `as_matrix()` → R matrix
- `as_data_frame()` → R data.frame
- `save(path, format)` → write to file

**Deliverables**:
- `R/sound-r6.R` - Complete Sound R6 class
- `src/sound_wrappers.cpp` - All 40+ C++ wrappers
- `tests/testthat/test-sound.R` - Comprehensive tests
- `man/Sound.Rd` - Complete documentation
- `vignettes/sound-basics.Rmd` - Tutorial vignette

**Milestone**: Sound object fully functional ✅

---

### Week 4-5: Core Analysis Objects (Pitch, Formant, Intensity, Harmonicity)

**Goal**: Implement 4 core analysis objects

**Implementation Pattern** (repeat for each):
1. R6 class definition with all methods
2. C++ wrappers for each method
3. Unit tests (30+ per object)
4. Documentation (Rd + examples)

**Pitch** (~20 methods):
- Query: `get_value_at_time()`, `get_mean()`, `get_median()`, `get_quantile()`, `get_minimum()`, `get_maximum()`, `get_standard_deviation()`, `get_time_of_minimum()`, `get_time_of_maximum()`, `count_voiced_frames()`
- Modify: `interpolate()`, `smooth()`, `shift_frequencies()`, `scale_frequencies()`
- Transform: `to_pitch_tier()`, `to_point_process()`, `to_sound()`
- Export: `as_data_frame()`, `save()`

**Formant** (~15 methods):
- Query: `get_value_at_time(n, t)`, `get_bandwidth_at_time(n, t)`, `get_mean(n)`, `get_standard_deviation(n)`, `get_minimum(n)`, `get_maximum(n)`, `get_quantile(n, q)`
- Modify: `formula()`, `track(num_tracks, refs)`
- Transform: `down_to_formant_grid()`, `down_to_table()`
- Export: `as_data_frame()`, `save()`

**Intensity** (~12 methods):
- Query: `get_value_at_time()`, `get_mean()`, `get_minimum()`, `get_maximum()`, `get_standard_deviation()`, `get_quantile()`, `get_time_of_minimum()`, `get_time_of_maximum()`
- Transform: `down_to_intensity_tier()`
- Export: `as_data_frame()`, `save()`

**Harmonicity** (~10 methods):
- Query: `get_value_at_time()`, `get_mean()`, `get_minimum()`, `get_maximum()`, `get_standard_deviation()`
- Export: `as_data_frame()`, `save()`

**Deliverables**:
- 4 R6 classes (R/pitch-r6.R, formant-r6.R, intensity-r6.R, harmonicity-r6.R)
- 4 C++ wrapper files (src/*_wrappers.cpp)
- 4 test files (tests/testthat/test-*.R)
- 4 documentation files (man/*.Rd)
- Integration tests showing workflows

**Milestone**: Core analysis pipeline working end-to-end ✅

---

### Week 5-6: TextGrid Object ⭐⭐⭐ CRITICAL

**Goal**: Full TextGrid support (annotation, segmentation, forced alignment)

**Why Critical**:
- **90%+ of phonetic research** uses TextGrid for annotation
- Essential for forced alignment integration (MFA, P2FA, etc.)
- Required for segment-based analysis
- Enables time-aligned transcription
- Critical missing feature from current implementation

**R6 Methods** (~35 methods):

**Creation**:
- `TextGrid$new(path)` - Read from file
- `TextGrid$create(xmin, xmax, tier_names, point_tiers)`

**Tier Query**:
- `get_number_of_tiers()`, `get_tier_names()`, `get_tier_type(tier)`

**Interval Tier**:
- `get_number_of_intervals(tier)`, `get_interval_start_time(tier, n)`, `get_interval_end_time(tier, n)`, `get_interval_text(tier, n)`
- `get_interval_at_time(tier, t)`, `get_label_at_time(tier, t)`
- `set_interval_text(tier, n, text)`, `insert_boundary(tier, t)`, `remove_boundary(tier, t)`

**Point Tier**:
- `get_number_of_points(tier)`, `get_point_time(tier, n)`, `get_point_text(tier, n)`
- `insert_point(tier, t, text)`, `remove_point(tier, n)`

**Tier Management**:
- `add_interval_tier(name)`, `add_point_tier(name)`, `remove_tier(tier)`, `duplicate_tier(n, name)`

**Extraction**:
- `extract_part(start, end)` → TextGrid

**Export**:
- `as_data_frame(tiers)` → long format data.frame
- `save(path, format)` → text or binary TextGrid

**Integration with Sound**:
```r
# Extract sound segments based on TextGrid intervals
tg <- TextGrid$new("annotation.TextGrid")
sound <- Sound$new("audio.wav")

# Get all "word" tier intervals
words <- tg$as_data_frame(tiers = "words")
for (i in 1:nrow(words)) {
  segment <- sound$extract_part(words$start[i], words$end[i])
  segment$save(paste0("word_", i, ".wav"))
}
```

**Deliverables**:
- `R/textgrid-r6.R` - TextGrid, IntervalTier, PointTier classes
- `src/textgrid_wrappers.cpp` - All TextGrid C++ wrappers
- `tests/testthat/test-textgrid.R` - Comprehensive tests
- `man/TextGrid.Rd` - Complete documentation
- `vignettes/textgrid-annotation.Rmd` - Tutorial
- `inst/extdata/sample.TextGrid` - Example files

**Milestone**: Full TextGrid functionality working ✅

---

### Week 6-7: Spectral Objects (Spectrogram, Spectrum, LPC)

**Goal**: Complete spectral analysis capabilities

**Spectrogram** (~12 methods):
- `get_power_at(t, f)`, `get_time_from_frame(n)`, `get_frequency_from_bin(n)`
- `to_spectrum(t)` → Spectrum, `to_ltas(bandwidth)` → Ltas
- `as_matrix()` → time × frequency matrix

**Spectrum** (~15 methods):
- `get_power_at(f)`, `get_real_at(f)`, `get_imaginary_at(f)`
- `get_mean()`, `get_standard_deviation()`, `get_band_energy(f1, f2)`, `get_centre_of_gravity()`
- `filter(f1, f2)`, `passband_filter(f1, f2)`
- `to_sound()` → Sound, `to_ltas()` → Ltas

**LPC** (~8 methods):
- `get_number_of_coefficients()`
- `to_formant()` → Formant, `to_spectrum(t, rate)` → Spectrum

**Deliverables**:
- 3 R6 classes + C++ wrappers + tests + docs

**Milestone**: Complete spectral analysis pipeline ✅

---

### Week 7-8: Advanced Objects (PointProcess, Manipulation, VoiceReport)

**Goal**: Voice quality and pitch manipulation

**PointProcess** (~15 methods):
- `get_number_of_points()`, `get_time_from_index(i)`, `get_nearest_index(t)`
- Voice quality (with Sound): `get_jitter_local()`, `get_jitter_rap()`, `get_jitter_ppq5()`, `get_shimmer_local()`, `get_shimmer_apq3()`, `get_shimmer_apq5()`

**Manipulation** (~10 methods):
- `extract_pitch_tier()` → PitchTier
- `extract_duration_tier()` → DurationTier
- `extract_original_sound()` → Sound
- `extract_pulses()` → PointProcess
- `replace_pitch_tier(tier)`, `replace_duration_tier(tier)`
- `get_resynthesis_overlap_add()` → Sound (PSOLA)

**Example Workflow** (Pitch shifting):
```r
sound <- Sound$new("voice.wav")
manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(factor = 1.2)  # Raise pitch 20%
manip$replace_pitch_tier(pitch_tier)
modified <- manip$get_resynthesis_overlap_add()
modified$save("voice_higher.wav")
```

**VoiceReport** (~15 methods):
- `get_mean_pitch()`, `get_median_pitch()`
- `get_jitter_local()`, `get_jitter_rap()`, `get_jitter_ppq5()`
- `get_shimmer_local()`, `get_shimmer_apq3()`, `get_shimmer_apq5()`, `get_shimmer_apq11()`
- `get_mean_hnr()`, `get_mean_autocorrelation()`, `get_fraction_unvoiced()`, `get_number_of_voice_breaks()`
- `as_data_frame()` → single-row with all metrics

**Deliverables**:
- 3 R6 classes + C++ wrappers + tests + docs
- Voice quality vignette

**Milestone**: Voice quality and manipulation working ✅

---

### Week 8-9: Tier Objects (PitchTier, FormantTier, IntensityTier, DurationTier)

**Goal**: Modifiable tier objects for fine control

Each tier object (~10 methods):
- Point management: add, remove, modify
- Query: get value at time, get number of points
- Transformation: multiply, shift, scale
- Export: as_data_frame, save

**Deliverables**:
- 4 R6 classes + C++ wrappers + tests + docs

**Milestone**: Complete tier manipulation ✅

---

### Week 9-10: Re-implement superassp Python Examples

**Goal**: Demonstrate Parselmouth → speaker migration

**Python Files to Re-implement**:

| Python File | Lines | R Example | Priority |
|-------------|-------|-----------|----------|
| praat_voice_report_memory.py | 305 | voice_report.R | HIGH |
| praat_pitch.py | 311 | pitch_tracking.R | HIGH |
| praat_formant_burg.py | 78 | formant_tracking.R | HIGH |
| praat_formantpath_burg.py | 176 | formant_path.R | MEDIUM |
| praat_intensity.py | 75 | intensity_analysis.R | MEDIUM |
| praat_spectral_moments.py | 116 | spectral_moments.R | MEDIUM |
| praat_avqi_memory.py | 324 | avqi.R | LOW |
| praat_dsi_memory.py | 319 | dsi.R | LOW |
| praat_praatsauce_memory.py | 416 | praatsauce.R | LOW |
| praat_sauce_memory.py | 434 | sauce.R | LOW |
| praat_voice_tremor_memory.py | 772 | voice_tremor.R | LOW |

**Example Translation Format**:
```r
# inst/examples/voice_report.R

#' Voice Quality Report
#' 
#' Re-implementation of praat_voice_report_memory.py using speaker package
#' 
#' Original Python (Parselmouth):
#' ```python
#' import parselmouth
#' sound = parselmouth.Sound("voice.wav")
#' pitch = sound.to_pitch()
#' point_process = parselmouth.praat.call(sound, "To PointProcess (periodic, cc)", 75, 600)
#' jitter = parselmouth.praat.call([sound, point_process], "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)
#' ```
#' 
#' Equivalent R (speaker):

library(speaker)

sound <- Sound$new("voice.wav")

# Method 1: Comprehensive voice report
report <- sound$voice_report(
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6
)

cat("Jitter (local):", report$get_jitter_local(), "\n")
cat("Shimmer (local):", report$get_shimmer_local(), "\n")
cat("Mean HNR:", report$get_mean_hnr(), "\n")

# Method 2: Individual calculations
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)
jitter <- pp$get_jitter_local(sound, period_floor = 0.0001, period_ceiling = 0.02, max_period_factor = 1.3)
```

**Deliverables**:
- `inst/examples/*.R` - 11 complete example scripts
- `inst/examples/README.md` - Overview and usage guide
- `inst/examples/PYTHON_TO_R_MAPPING.md` - Comprehensive comparison

**Milestone**: All Python examples have R equivalents ✅

---

### Week 10-11: Documentation & Vignettes

**Goal**: Comprehensive documentation

**Vignettes** (7+):
1. **Getting Started with speaker** - Installation, basic workflow
2. **Working with Sound Objects** - Audio I/O, manipulation, generation
3. **Pitch Analysis** - F0 extraction, statistics, visualization
4. **Formant Tracking** - Vowel analysis, formant statistics
5. **TextGrid Annotation** - Creating, editing, exporting annotations
6. **Voice Quality Analysis** - Jitter, shimmer, HNR, complete voice report
7. **Pitch Manipulation** - PSOLA-based modification, prosody control
8. **Spectral Analysis** - Spectrogram, spectrum, LPC
9. **From Praat Scripts to R** - Translation guide with examples
10. **From Parselmouth to speaker** - Python → R migration guide

**Reference Documentation**:
- Complete Rd files for all 16+ R6 classes
- Method-level documentation with examples
- Cross-references between related objects
- Package overview (speaker-package.Rd)

**README**:
- Clear installation instructions
- Quick start examples
- Links to vignettes
- Comparison with Praat/Parselmouth
- Citation information

**Deliverables**:
- `vignettes/*.Rmd` - 10 comprehensive vignettes
- `man/*.Rd` - Complete reference documentation (100+ files)
- `README.md` - Updated with all features

**Milestone**: Documentation complete and clear ✅

---

### Week 11-12: Testing, Validation & CRAN Preparation

**Goal**: Production-ready package

**Testing**:
1. **Unit Tests** (>200 tests)
   - Each method tested individually
   - Edge cases (empty inputs, invalid parameters, boundary conditions)
   - Test coverage >95% (R code), >85% (C++ code)

2. **Integration Tests** (20+ workflows)
   - Complete analysis pipelines
   - Multi-object interactions
   - Real-world use cases

3. **Memory Tests**
   - valgrind on Linux
   - Address Sanitizer (ASAN)
   - Leak detection for all objects
   - Stress tests (1000+ object creations)

4. **Performance Benchmarks**
   - Compare to Praat desktop
   - Compare to Parselmouth
   - Target: within 10% of native Praat

5. **Validation Tests**
   - Compare output to Praat desktop (same input → same output)
   - Compare to Parselmouth (verify parity)
   - Use reference audio files with known values

6. **Platform Tests**
   - macOS (x86_64, arm64)
   - Linux (Ubuntu, Fedora)
   - Windows (x86_64)

**CRAN Preparation**:
- `R CMD check` with zero errors, warnings, notes
- Fix all CRAN policy violations
- Reduce package size if needed
- Add CITATION file
- Update NEWS.md
- Prepare CRAN submission comments

**Deliverables**:
- `tests/testthat/test-*.R` - 50+ test files
- `tests/benchmarks/*.R` - Performance benchmarks
- `tests/validation/*.R` - Validation against Praat
- `.github/workflows/R-CMD-check.yaml` - CI/CD setup
- CRAN submission materials

**Milestone**: Package ready for CRAN submission ✅

---

## Naming Convention Standard

**Consistency enables easy Praat → R translation**

### Method Naming Patterns

| Praat Pattern | R6 Pattern | Example |
|---------------|------------|---------|
| `Get [property]` | `get_[property]()` | `get_duration()` |
| `Get [property] at time` | `get_[property]_at_time(t)` | `get_value_at_time(t)` |
| `Get mean [property]` | `get_mean_[property]()` or `get_mean()` | `get_mean()` |
| `Get minimum [property]` | `get_minimum()` | `get_minimum()` |
| `To [Object]` | `to_[object]()` | `to_pitch()` |
| `To [Object] ([method])` | `to_[object]_[method]()` | `to_formant_burg()` |
| `Extract [subset]` | `extract_[subset]()` | `extract_part()` |
| `Scale [property]` | `scale_[property]()` | `scale_intensity()` |
| `Filter [type]` | `filter_[type]()` | `filter_pass_hann_band()` |
| `Down to [R type]` | `as_[type]()` | `as_data_frame()` |
| `Save as [format]` | `save(path, format)` | `save("out.wav")` |

### Consistency Rules

1. **Query methods**: `get_*()` → returns value(s)
2. **Transform methods**: `to_*()` → returns new object of different class
3. **Extract methods**: `extract_*()` → returns new object of same class
4. **Modify methods**: verb (e.g., `scale_*()`, `filter_*()`) → modifies in place or returns self
5. **Export methods**: `as_*()` → converts to R native type
6. **I/O methods**: `save(path)` writes, `$new(path)` reads

## Architecture Details

### Memory Model

```
R Layer                          C++ Layer
────────────────────────────────────────────────────
Sound R6 object          <───>  structSound* (Praat)
  private$ptr (XPtr)            - double** z (samples)
  public$get_duration()         - double xmin, xmax
  public$to_pitch()             - integer nx
                                - double dx
When R object GC'd → XPtr finalizer → forget(structSound*)
```

### XPtr Pattern (C++)

```cpp
// Finalizer
void sound_finalizer(structSound* sound) {
    if (sound != nullptr) {
        forget(sound);  // Praat's memory management
    }
}

// Creation
// [[Rcpp::export(.sound_read)]]
Rcpp::XPtr<structSound> sound_read(std::string path) {
    try {
        autoSound sound = Sound_readFromSoundFile(Melder_peek8to32(path.c_str()));
        structSound* ptr = sound.releaseToAmbiguousOwner();
        return Rcpp::XPtr<structSound>(ptr, true, sound_finalizer);
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop("Failed to read sound: " + path);
    }
}

// Query
// [[Rcpp::export(.sound_get_duration)]]
double sound_get_duration(Rcpp::XPtr<structSound> xptr) {
    if (!xptr) Rcpp::stop("Invalid Sound pointer");
    return xptr->xmax - xptr->xmin;
}

// Transform
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

### R6 Pattern (R)

```r
Sound <- R6Class("Sound",
  inherit = PraatObject,
  
  public = list(
    initialize = function(path = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        private$ptr <- .xptr
      } else if (!is.null(path)) {
        private$ptr <- .sound_read(path)
      } else {
        stop("Provide path or .xptr")
      }
    },
    
    get_duration = function() {
      .sound_get_duration(private$ptr)
    },
    
    to_pitch = function(time_step = 0.0, pitch_floor = 75, pitch_ceiling = 600) {
      pitch_ptr <- .sound_to_pitch(private$ptr, time_step, pitch_floor, pitch_ceiling)
      Pitch$new(.xptr = pitch_ptr)
    },
    
    print = function() {
      cat("<Praat Sound>\n")
      cat(sprintf("  Duration: %.3f s\n", self$get_duration()))
      cat(sprintf("  Sampling frequency: %.0f Hz\n", self$get_sampling_frequency()))
      invisible(self)
    }
  ),
  
  private = list(
    ptr = NULL
  )
)

# Static factory
Sound$from_values <- function(values, sampling_rate = 44100) {
  ptr <- .sound_from_values(values, sampling_rate)
  Sound$new(.xptr = ptr)
}
```

## Success Criteria

### Technical Excellence
- [ ] 16+ Praat objects as R6 classes
- [ ] 250+ methods covering full Praat functionality
- [ ] Zero memory leaks (valgrind clean)
- [ ] Test coverage >95% (R), >85% (C++)
- [ ] Performance within 10% of Praat desktop
- [ ] Builds on Windows, macOS, Linux

### Usability
- [ ] Intuitive OOP API matching Praat's design
- [ ] 60+ documented examples
- [ ] 10+ comprehensive vignettes
- [ ] Clear migration guides (Praat, Parselmouth)
- [ ] Consistent naming conventions

### Completeness
- [ ] All 11 superassp Python examples re-implemented
- [ ] TextGrid full support (read, write, manipulate)
- [ ] Voice quality analysis (jitter, shimmer, HNR, etc.)
- [ ] Pitch manipulation (PSOLA via Manipulation)
- [ ] Spectral analysis (Spectrogram, Spectrum, LPC)
- [ ] All major Praat workflows supported

## Timeline Summary

| Week | Phase | Deliverable |
|------|-------|-------------|
| 1-2 | Foundation | R6 infrastructure, base classes |
| 2-3 | Sound | Complete Sound object (template) |
| 4-5 | Analysis | Pitch, Formant, Intensity, Harmonicity |
| 5-6 | TextGrid | Full annotation support ⭐ |
| 6-7 | Spectral | Spectrogram, Spectrum, LPC |
| 7-8 | Advanced | PointProcess, Manipulation, VoiceReport |
| 8-9 | Tiers | PitchTier, FormantTier, IntensityTier, DurationTier |
| 9-10 | Examples | Re-implement 11 Python scripts |
| 10-11 | Documentation | 10 vignettes, complete reference |
| 11-12 | Testing | Validation, benchmarks, CRAN prep |

**Total Duration**: 12 weeks  
**Final Goal**: CRAN submission-ready package

## Next Immediate Actions

1. **Complete Praat source compilation** - Fix any remaining build issues
2. **Test Sound object end-to-end** - Verify all methods work
3. **Write Sound unit tests** - Establish testing pattern
4. **Create first vignette** - Document Sound usage
5. **Begin Pitch implementation** - Apply pattern from Sound
6. **Commit and document progress** - Keep momentum

## Conclusion

This plan transforms the speaker package into:

1. **A complete Praat interface for R** - 16+ objects, 250+ methods
2. **A Python-free phonetic analysis toolkit** - No Parselmouth dependency
3. **A production-ready research tool** - Comprehensive, tested, documented
4. **A bridge between Praat and R** - Easy migration, clear mapping
5. **The future of phonetic analysis in R** - Modern, object-oriented, performant

**Let's build the comprehensive phonetic analysis toolkit R deserves!** 🎉
