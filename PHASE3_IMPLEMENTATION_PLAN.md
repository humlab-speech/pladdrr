# Phase 3: Complete OOP Implementation Plan
**Date**: 2025-11-10  
**Package Version**: 0.2.1 → 0.3.0 (target)  
**Focus**: Documentation, Examples, and Missing Core Objects

## Overview

This plan completes the **speaker** package implementation with a focus on:
1. **Making existing features discoverable** through documentation and examples
2. **Implementing critical missing objects** (TextGrid, Manipulation, Spectral)
3. **Providing migration paths** from Parselmouth/Praat scripts
4. **Achieving production-ready status** for CRAN submission

## Phase 3A: Documentation & Examples (Week 1-2)

### Goal
Make the existing 6 core objects (Sound, Pitch, Formant, Intensity, Harmonicity, PointProcess) accessible to users through comprehensive documentation and real-world examples.

### Task 3A.1: Create inst/examples/ Directory

**Objective**: Re-implement Parselmouth examples from `/Users/frkkan96/Documents/src/superassp/inst/python/` in pure R.

**Structure**:
```
inst/
└── examples/
    ├── README.md                           # Overview and index
    ├── 01_voice_report.R                   # Voice quality analysis
    ├── 02_pitch_tracking.R                 # F0 extraction and stats
    ├── 03_formant_tracking.R               # Formant analysis
    ├── 04_intensity_analysis.R             # Intensity contours
    ├── 05_spectral_moments.R               # Spectral statistics
    ├── 06_jitter_shimmer.R                 # Voice quality metrics
    ├── 07_harmonicity.R                    # HNR analysis
    ├── 08_sound_manipulation.R             # Audio processing
    ├── 09_batch_processing.R               # Multiple files
    ├── 10_export_data.R                    # Data export workflows
    ├── PARSELMOUTH_TO_SPEAKER.md           # Migration guide
    └── data/                                # Example audio files
        ├── sample_voice.wav
        ├── sample_vowel.wav
        └── sample_speech.wav
```

**Example Template** (01_voice_report.R):
```r
#' Voice Quality Report Example
#' 
#' Re-implementation of praat_voice_report_memory.py from superassp
#' 
#' This example demonstrates:
#' - Loading audio with av package
#' - Extracting pitch, harmonicity, and point process
#' - Computing voice quality metrics (jitter, shimmer, HNR)
#' - Exporting results to data frame
#' 
#' Original Python implementation:
#' /Users/frkkan96/Documents/src/superassp/inst/python/praat_voice_report_memory.py

library(speaker)
library(av)

# === Load Audio ===
# Option 1: From file
sound <- Sound$new("inst/examples/data/sample_voice.wav")

# Option 2: From memory (numpy-style)
audio_data <- av::read_audio_bin("sample.wav")
sound <- Sound$from_values(audio_data$data, audio_data$rate)

# === Extract Pitch ===
pitch <- sound$to_pitch(
  time_step = 0.0,          # Auto (0.75 / pitch_floor)
  pitch_floor = 75,
  pitch_ceiling = 600
)

# Pitch statistics
pitch_stats <- list(
  mean_pitch = pitch$get_mean(unit = "hertz"),
  median_pitch = pitch$get_median(unit = "hertz"),
  sd_pitch = pitch$get_standard_deviation(),
  min_pitch = pitch$get_minimum(unit = "hertz"),
  max_pitch = pitch$get_maximum(unit = "hertz")
)

# === Extract Point Process (Glottal Pulses) ===
pp <- sound$to_point_process_periodic_cc(
  pitch_floor = 75,
  pitch_ceiling = 600
)

num_pulses <- pp$get_number_of_points()
num_periods <- num_pulses - 1

# === Voice Quality: Jitter ===
jitter_stats <- list(
  jitter_local = pp$get_jitter_local(sound),
  jitter_local_abs = pp$get_jitter_local_absolute(sound),
  jitter_rap = pp$get_jitter_rap(sound),
  jitter_ppq5 = pp$get_jitter_ppq5(sound),
  jitter_ddp = pp$get_jitter_ddp(sound)
)

# === Voice Quality: Shimmer ===
shimmer_stats <- list(
  shimmer_local = pp$get_shimmer_local(sound),
  shimmer_local_db = pp$get_shimmer_local_db(sound),
  shimmer_apq3 = pp$get_shimmer_apq3(sound),
  shimmer_apq5 = pp$get_shimmer_apq5(sound),
  shimmer_apq11 = pp$get_shimmer_apq11(sound),
  shimmer_dda = pp$get_shimmer_dda(sound)
)

# === Harmonicity (HNR) ===
harmonicity <- sound$to_harmonicity_cc(
  time_step = 0.01,
  min_pitch = 75,
  silence_threshold = 0.1,
  periods_per_window = 1.0
)

hnr_stats <- list(
  mean_hnr = harmonicity$get_mean(),
  sd_hnr = harmonicity$get_standard_deviation()
)

# === Compile Voice Report ===
voice_report <- c(
  pitch_stats,
  list(
    num_pulses = num_pulses,
    num_periods = num_periods
  ),
  jitter_stats,
  shimmer_stats,
  hnr_stats
)

# === Display Results ===
cat("=== PRAAT VOICE REPORT ===\n\n")
cat("Pitch Statistics:\n")
cat(sprintf("  Mean pitch: %.2f Hz\n", voice_report$mean_pitch))
cat(sprintf("  Median pitch: %.2f Hz\n", voice_report$median_pitch))
cat(sprintf("  SD pitch: %.2f Hz\n", voice_report$sd_pitch))
cat(sprintf("  Min pitch: %.2f Hz\n", voice_report$min_pitch))
cat(sprintf("  Max pitch: %.2f Hz\n", voice_report$max_pitch))

cat("\nPulse Statistics:\n")
cat(sprintf("  Number of pulses: %d\n", voice_report$num_pulses))
cat(sprintf("  Number of periods: %d\n", voice_report$num_periods))

cat("\nJitter:\n")
cat(sprintf("  Local: %.3f%%\n", voice_report$jitter_local * 100))
cat(sprintf("  RAP: %.3f%%\n", voice_report$jitter_rap * 100))
cat(sprintf("  PPQ5: %.3f%%\n", voice_report$jitter_ppq5 * 100))

cat("\nShimmer:\n")
cat(sprintf("  Local: %.3f%%\n", voice_report$shimmer_local * 100))
cat(sprintf("  Local (dB): %.3f dB\n", voice_report$shimmer_local_db))
cat(sprintf("  APQ3: %.3f%%\n", voice_report$shimmer_apq3 * 100))
cat(sprintf("  APQ5: %.3f%%\n", voice_report$shimmer_apq5 * 100))
cat(sprintf("  APQ11: %.3f%%\n", voice_report$shimmer_apq11 * 100))

cat("\nHarmonicity:\n")
cat(sprintf("  Mean HNR: %.2f dB\n", voice_report$mean_hnr))

# === Export to DataFrame ===
voice_report_df <- as.data.frame(voice_report)
write.csv(voice_report_df, "voice_report.csv", row.names = FALSE)

cat("\nReport exported to: voice_report.csv\n")
```

**Deliverables**:
- ✅ 10 example R scripts
- ✅ README.md with index and usage
- ✅ PARSELMOUTH_TO_SPEAKER.md comparison guide
- ✅ Example audio files in inst/examples/data/

**Estimated Time**: 3-4 days

### Task 3A.2: Create Vignettes

**Objective**: Provide comprehensive tutorials for package users.

**Vignettes to Create**:

1. **`quickstart.Rmd`** - Getting started with speaker
   - Installation
   - Basic workflow (Sound → Pitch → Formant)
   - Exporting results
   - Integration with tidyverse

2. **`voice-quality.Rmd`** - Voice quality analysis
   - Pitch extraction
   - Jitter/shimmer/HNR
   - Voice report generation
   - Clinical applications

3. **`formant-analysis.Rmd`** - Vowel space analysis
   - Formant tracking
   - F1-F2 vowel plots
   - Formant statistics
   - Trajectory analysis

4. **`batch-processing.Rmd`** - Processing multiple files
   - File iteration
   - Parallel processing
   - Data aggregation
   - Export to CSV/database

5. **`praat-to-speaker.Rmd`** - Migration guide from Praat scripts
   - Syntax comparison
   - Common workflows translated
   - Method name mappings

**Deliverables**:
- ✅ 5 comprehensive vignettes
- ✅ All vignettes knit without errors
- ✅ Included in package build

**Estimated Time**: 4-5 days

### Task 3A.3: Update Documentation

**Objective**: Ensure all functions are documented with examples.

**Tasks**:
- ✅ Review all R6 class Roxygen documentation
- ✅ Add @examples to every public method
- ✅ Update README.md with comprehensive examples
- ✅ Create CITATION file
- ✅ Update NEWS.md with v0.3.0 changes

**Deliverables**:
- ✅ Complete Roxygen documentation (all objects, all methods)
- ✅ Updated README.md
- ✅ CITATION file
- ✅ NEWS.md updated

**Estimated Time**: 2-3 days

**Total Phase 3A Duration**: 10-12 days

---

## Phase 3B: TextGrid Implementation (Week 3-4)

### Goal
Implement full TextGrid support to enable annotation-based workflows.

### Background

TextGrid is **the most critical missing feature**:
- 90%+ of phonetic research uses TextGrid
- Essential for forced alignment (MFA, P2FA, WebMAUS)
- Required for segment-based analysis
- Enables time-aligned transcription

**Current Status**:
- ✅ R6 class written (`R/textgrid-r6.R.disabled`)
- ✅ C++ wrappers partially written
- ❌ Disabled due to Praat dependency issues (file I/O, threading)

### Task 3B.1: Resolve Praat Dependencies

**Objective**: Stub out remaining Praat subsystems needed for TextGrid.

**Dependencies to Stub**:
1. **File I/O** (MelderFile, TextFile)
   - Create minimal file reading/writing stubs
   - Delegate to R file I/O where possible

2. **Threading** (MelderThread)
   - Stub out thread-safe functions
   - Single-threaded operation acceptable

3. **Data** (Data, Collection, Ordered)
   - Implement minimal container stubs
   - Support TextGrid tier management

**Deliverables**:
- ✅ `src/file_stubs.cpp` - File I/O stubs
- ✅ `src/thread_stubs.cpp` - Threading stubs
- ✅ `src/collection_stubs.cpp` - Data structure stubs
- ✅ Package builds successfully

**Estimated Time**: 2-3 days

### Task 3B.2: Complete TextGrid R6 Class

**Objective**: Full-featured TextGrid with tier management.

**R6 Methods** (~35 methods):

**Creation**:
```r
TextGrid$new(path)                    # Read from file
TextGrid$create(xmin, xmax, tier_names, point_tiers)  # Create empty
```

**Tier Query**:
```r
get_number_of_tiers()
get_tier_names()
get_tier_type(tier)                   # "IntervalTier" or "TextTier"
```

**Interval Tier Methods**:
```r
get_number_of_intervals(tier)
get_interval_start_time(tier, n)
get_interval_end_time(tier, n)
get_interval_text(tier, n)
get_interval_at_time(tier, t)
get_label_at_time(tier, t)
set_interval_text(tier, n, text)
insert_boundary(tier, t)
remove_boundary(tier, t)
```

**Point Tier Methods**:
```r
get_number_of_points(tier)
get_point_time(tier, n)
get_point_text(tier, n)
insert_point(tier, t, text)
remove_point(tier, n)
```

**Tier Management**:
```r
add_interval_tier(name)
add_point_tier(name)
remove_tier(tier)
duplicate_tier(n, name)
```

**Export**:
```r
as_data_frame(tiers = NULL)           # Long format data.frame
save(path, format = "text")           # Write TextGrid file
```

**Deliverables**:
- ✅ Complete `R/textgrid-r6.R`
- ✅ All methods documented with @examples
- ✅ Integration with Sound object (extract parts based on intervals)

**Estimated Time**: 2-3 days

### Task 3B.3: C++ TextGrid Wrappers

**Objective**: Complete C++ wrapper functions for TextGrid.

**Key Wrappers**:
```cpp
// Creation
Rcpp::XPtr<TextGrid> textgrid_read(std::string path)
Rcpp::XPtr<TextGrid> textgrid_create(double xmin, double xmax, ...)

// Query
int textgrid_get_number_of_tiers(XPtr<TextGrid> tg)
Rcpp::CharacterVector textgrid_get_tier_names(XPtr<TextGrid> tg)

// Interval tier
int textgrid_get_number_of_intervals(XPtr<TextGrid> tg, std::string tier)
double textgrid_get_interval_start(XPtr<TextGrid> tg, std::string tier, int n)
std::string textgrid_get_interval_text(XPtr<TextGrid> tg, std::string tier, int n)

// Point tier
int textgrid_get_number_of_points(XPtr<TextGrid> tg, std::string tier)
double textgrid_get_point_time(XPtr<TextGrid> tg, std::string tier, int n)

// Export
Rcpp::DataFrame textgrid_as_data_frame(XPtr<TextGrid> tg, Rcpp::Nullable<CharacterVector> tiers)
void textgrid_save(XPtr<TextGrid> tg, std::string path)
```

**Deliverables**:
- ✅ `src/textgrid_wrappers.cpp` (~1000 lines)
- ✅ All wrappers with error handling (try/catch MelderError)
- ✅ Compiles without errors

**Estimated Time**: 3-4 days

### Task 3B.4: Testing & Documentation

**Objective**: Ensure TextGrid works correctly with real files.

**Tests**:
```r
# tests/testthat/test-textgrid.R

test_that("TextGrid reads files", {
  tg <- TextGrid$new("inst/extdata/sample.TextGrid")
  expect_s3_class(tg, "TextGrid")
  expect_true(tg$get_number_of_tiers() > 0)
})

test_that("TextGrid interval query works", {
  tg <- TextGrid$new("inst/extdata/sample.TextGrid")
  n <- tg$get_number_of_intervals("words")
  expect_gt(n, 0)
  
  text <- tg$get_interval_text("words", 1)
  expect_type(text, "character")
})

test_that("TextGrid export to data.frame works", {
  tg <- TextGrid$new("inst/extdata/sample.TextGrid")
  df <- tg$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_true("tier" %in% names(df))
  expect_true("start" %in% names(df))
  expect_true("end" %in% names(df))
  expect_true("text" %in% names(df))
})

test_that("TextGrid integrates with Sound", {
  tg <- TextGrid$new("inst/extdata/sample.TextGrid")
  sound <- Sound$new("inst/extdata/sample.wav")
  
  # Extract first interval from "words" tier
  start <- tg$get_interval_start_time("words", 1)
  end <- tg$get_interval_end_time("words", 1)
  
  segment <- sound$extract_part(start, end)
  expect_s3_class(segment, "Sound")
  expect_equal(segment$get_duration(), end - start, tolerance = 0.001)
})
```

**Documentation**:
- ✅ Complete Roxygen documentation for all methods
- ✅ Vignette: `vignettes/textgrid-annotation.Rmd`
- ✅ Example: `inst/examples/11_textgrid_segmentation.R`

**Deliverables**:
- ✅ 20+ unit tests
- ✅ Integration tests with Sound
- ✅ Vignette with real-world examples
- ✅ Example TextGrid files in inst/extdata/

**Estimated Time**: 2-3 days

**Total Phase 3B Duration**: 9-13 days

---

## Phase 3C: Manipulation & Tier Objects (Week 5)

### Goal
Enable PSOLA-based pitch/duration modification.

### Task 3C.1: PitchTier Implementation

**R6 Methods** (~10 methods):
```r
PitchTier$new(xmin, xmax)
add_point(time, frequency)
remove_point(n)
get_number_of_points()
get_point_time(n)
get_point_value(n)
get_value_at_time(t)
multiply_frequencies(start, end, factor)
shift_frequencies(start, end, shift)
as_data_frame()
save(path)
```

**Deliverables**:
- ✅ `R/pitchtier-r6.R`
- ✅ `src/pitchtier_wrappers.cpp`
- ✅ Tests and documentation

**Estimated Time**: 1-2 days

### Task 3C.2: DurationTier Implementation

**R6 Methods** (~8 methods):
```r
DurationTier$new(xmin, xmax)
add_point(time, relative_duration)
remove_point(n)
get_number_of_points()
get_value_at_time(t)
as_data_frame()
save(path)
```

**Deliverables**:
- ✅ `R/durationtier-r6.R`
- ✅ `src/durationtier_wrappers.cpp`
- ✅ Tests and documentation

**Estimated Time**: 1 day

### Task 3C.3: Manipulation Implementation

**R6 Methods** (~12 methods):
```r
# Creation (from Sound)
sound$to_manipulation(time_step, min_pitch, max_pitch)

# Extract components
extract_pitch_tier()          → PitchTier
extract_duration_tier()       → DurationTier
extract_original_sound()      → Sound
extract_pulses()              → PointProcess

# Replace components
replace_pitch_tier(tier)
replace_duration_tier(tier)

# Resynthesis
get_resynthesis_overlap_add()  → Sound (PSOLA)
get_resynthesis_lpc()          → Sound (LPC)

# Query
get_start_time()
get_end_time()
```

**Deliverables**:
- ✅ `R/manipulation-r6.R`
- ✅ `src/manipulation_wrappers.cpp`
- ✅ Tests and documentation
- ✅ Vignette: `vignettes/pitch-manipulation.Rmd`

**Estimated Time**: 2-3 days

**Total Phase 3C Duration**: 4-6 days

---

## Phase 3D: Complete Spectral Suite (Week 6)

### Goal
Full spectral analysis capabilities.

### Task 3D.1: Complete Spectrum Object

**Additional Methods Needed** (~5 methods):
```r
get_centre_of_gravity(power = 2)
get_central_moment(moment, power = 2)
get_standard_deviation()
get_skewness()
get_kurtosis()
```

**Estimated Time**: 1 day

### Task 3D.2: Spectrogram Implementation

**R6 Methods** (~12 methods):
```r
# Creation (from Sound)
sound$to_spectrogram(window_length, max_frequency, time_step, freq_step, window_shape)

# Query
get_power_at(time, frequency)
get_time_from_frame(n)
get_frequency_from_bin(n)
get_number_of_frames()
get_number_of_bins()

# Transform
to_spectrum(time)             → Spectrum
to_ltas(bandwidth)            → Ltas

# Export
as_matrix()                   → time × frequency matrix
save(path)
```

**Deliverables**:
- ✅ `R/spectrogram-r6.R`
- ✅ `src/spectrogram_wrappers.cpp`
- ✅ Tests and documentation

**Estimated Time**: 2-3 days

### Task 3D.3: LPC Implementation

**R6 Methods** (~8 methods):
```r
# Creation (from Sound)
sound$to_lpc_burg(prediction_order, window_length, time_step, pre_emphasis)

# Query
get_number_of_coefficients()
get_coefficient(frame, coeff)

# Transform
to_formant(num_formants)      → Formant
to_spectrum(time, rate)       → Spectrum

# Export
as_data_frame()
save(path)
```

**Deliverables**:
- ✅ `R/lpc-r6.R`
- ✅ `src/lpc_wrappers.cpp`
- ✅ Tests and documentation

**Estimated Time**: 2 days

### Task 3D.4: MFCC Implementation

**R6 Methods** (~10 methods):
```r
# Creation (from Sound)
sound$to_mfcc(num_coefficients, window_length, time_step, first_filter, 
              distance_filter, max_frequency)

# Query
get_coefficient(frame, coeff)
get_number_of_frames()
get_number_of_coefficients()

# Export
as_matrix()                   → frames × coefficients
as_data_frame()
save(path)
```

**Deliverables**:
- ✅ `R/mfcc-r6.R`
- ✅ `src/mfcc_wrappers.cpp`
- ✅ Tests and documentation

**Estimated Time**: 2 days

**Total Phase 3D Duration**: 7-8 days

---

## Phase 4: Testing & CRAN Preparation (Week 7-8)

### Task 4.1: Comprehensive Testing

**Unit Tests**:
- ✅ Expand coverage to >90% (R code), >85% (C++ code)
- ✅ Edge cases for all methods
- ✅ Memory leak tests (valgrind)

**Integration Tests**:
- ✅ Complete workflows (Sound → analysis → export)
- ✅ TextGrid + Sound integration
- ✅ Manipulation pipelines
- ✅ Batch processing scenarios

**Platform Tests**:
- ✅ macOS (x86_64, arm64)
- ✅ Linux (Ubuntu, Fedora)
- ✅ Windows (x86_64)

**Validation Tests**:
- ✅ Compare output to Praat desktop (same input → same output)
- ✅ Compare to Parselmouth (verify parity)
- ✅ Benchmark performance (within 10% of Praat)

**Estimated Time**: 5-7 days

### Task 4.2: CRAN Preparation

**Tasks**:
- ✅ R CMD check (zero errors, warnings, notes)
- ✅ Fix any CRAN policy violations
- ✅ Optimize package size (<5 MB source)
- ✅ Check documentation completeness
- ✅ Update CITATION, README, NEWS
- ✅ Prepare submission comments

**Estimated Time**: 3-4 days

**Total Phase 4 Duration**: 8-11 days

---

## Timeline Summary

| Phase | Focus | Duration | Calendar |
|-------|-------|----------|----------|
| 3A | Documentation & Examples | 10-12 days | Week 1-2 |
| 3B | TextGrid Implementation | 9-13 days | Week 3-4 |
| 3C | Manipulation & Tiers | 4-6 days | Week 5 |
| 3D | Complete Spectral Suite | 7-8 days | Week 6 |
| 4 | Testing & CRAN Prep | 8-11 days | Week 7-8 |
| **Total** | **Complete Implementation** | **38-50 days** | **6-8 weeks** |

## Success Criteria

### Technical Excellence
- [ ] 12+ Praat objects as R6 classes
- [ ] 350+ methods covering full Praat functionality
- [ ] Zero memory leaks (valgrind clean)
- [ ] Test coverage >90% (R), >85% (C++)
- [ ] Performance within 10% of Praat desktop
- [ ] Builds on Windows, macOS, Linux

### Usability
- [ ] 10+ documented examples
- [ ] 7+ comprehensive vignettes
- [ ] Clear migration guides (Praat, Parselmouth)
- [ ] Consistent naming conventions
- [ ] Integration with tidyverse/ggplot2

### Completeness
- [ ] All 10+ example scripts from superassp re-implemented
- [ ] TextGrid full support (read, write, manipulate)
- [ ] Voice quality analysis (jitter, shimmer, HNR)
- [ ] Pitch manipulation (PSOLA via Manipulation)
- [ ] Spectral analysis (Spectrogram, Spectrum, LPC, MFCC)
- [ ] All major Praat workflows supported

### Production Ready
- [ ] R CMD check passes (zero errors/warnings)
- [ ] CRAN-compliant documentation
- [ ] Cross-platform build verified
- [ ] Benchmark results documented
- [ ] Ready for v0.3.0 release

## Next Immediate Actions

1. ✅ **Create inst/examples/ directory**
2. ✅ **Implement voice_report.R** (first example)
3. ✅ **Write quickstart.Rmd** (first vignette)
4. ✅ **Update README.md** with examples
5. ✅ **Commit Phase 3A.1 progress**

## Conclusion

This plan will transform the **speaker** package from a solid foundation (v0.2.1) into a **complete, production-ready phonetic analysis toolkit** (v0.3.0) that:

1. **Matches Parselmouth feature parity** (without Python dependency)
2. **Enables full Praat workflows in R** (annotation, analysis, modification)
3. **Provides excellent documentation** (vignettes, examples, migration guides)
4. **Achieves CRAN-ready status** (tested, validated, polished)

**Let's complete the implementation!** 🚀
