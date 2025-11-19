# Speaker Package Gap Analysis
## Re-implementation Affordance Assessment for Praat Functionality

**Analysis Date**: 2025-11-18
**Praat Scripts Analyzed**: 124 repositories, 1,213 .praat files
**Speaker Package Version**: Analyzed from /Users/frkkan96/Documents/src/speaker/

---

## Executive Summary

The **speaker** R package provides a modern, R6-based object-oriented interface to core Praat functionality, covering approximately **60-70% of commonly-used Praat features**. However, analysis of 124 Praat script repositories reveals significant gaps in higher-level workflows, batch processing utilities, advanced prosodic analysis, and visualization capabilities.

### Re-implementation Affordance: **MODERATE to HIGH**

The speaker package has **strong foundational capabilities** but lacks the **workflow automation**, **batch processing infrastructure**, and **domain-specific analysis pipelines** that make Praat scripts valuable for research.

---

## Part 1: Speaker Package Capabilities (What EXISTS)

### ✅ Core Acoustic Analysis (WELL IMPLEMENTED)
- **Pitch/F0 extraction**: `Sound$to_pitch()` → `Pitch` object with statistics
- **Formant tracking**: `Sound$to_formant_burg()`, `Sound$to_formant_keepall()`
- **Intensity analysis**: `Sound$to_intensity()` → `Intensity` object
- **Harmonicity (HNR)**: `Sound$to_harmonicity_ac()`, `Sound$to_harmonicity_cc()`
- **Voice quality metrics**: Jitter, Shimmer via `PointProcess` class

### ✅ TextGrid Operations (COMPREHENSIVE)
- Read/write TextGrid files
- Add/remove/query tiers (interval and point tiers)
- Get/set labels, insert/remove boundaries and points
- Convert to data frames for R analysis

### ✅ Spectral Analysis (SOLID)
- Spectrogram: `Sound$to_spectrogram()`
- Spectrum (FFT): `Sound$to_spectrum()`
- LTAS: `Sound$to_ltas()`
- LPC coefficients: `Sound$to_lpc_burg()` and variants

### ✅ Signal Processing (GOOD)
- Filtering: `Sound$pre_emphasize()`, `Sound$de_emphasize()`
- Resampling: `Sound$resample()`
- Amplitude normalization: `Sound$scale_intensity()`, `Sound$scale_peak()`
- Concatenation and mixing: `Sound$concatenate()`, `Sound$mix()`

### ✅ PSOLA-based Manipulation (IMPLEMENTED)
- `Sound$to_manipulation()` → `Manipulation` object
- Extract/replace `PitchTier`, `DurationTier`
- Resynthesize with `get_resynthesis_overlap_add()`

### ✅ Audio I/O (FLEXIBLE)
- Read via `av` package (WAV, MP3, FLAC, etc.)
- Save in multiple formats
- Generate tones and noise

---

## Part 2: Gaps Identified from Praat Script Analysis

Based on analysis of 1,213 Praat scripts across 124 repositories, the following functionality patterns are **MISSING or UNDERDEVELOPED** in speaker:

### ❌ GAP 1: Batch Processing & Workflow Automation
**Praat Pattern**: Almost ALL scripts (>90%) implement batch processing loops over directories of sound files and TextGrids.

**Examples from Archive**:
- `feelins/Praat_Scripts`: Processes entire directories, applies transformations, exports results to CSV/TXT
- `PoLaR-Praat-plugin`: Directory-level operations for prosodic labeling
- `FastTrack`: Batch formant tracking with refinement loops

**Speaker Limitation**:
- No built-in batch processing utilities
- No directory traversal helpers
- No file pairing logic (Sound + TextGrid matching)
- Users must implement their own `lapply()`/`purrr::map()` workflows

**Re-implementation Affordance**: **HIGH** — R excels at batch processing. Speaker could add:
```r
Sound$batch_process(directory, pattern, func, export_func)
process_directory(path, sound_func, textgrid_func, output_format = "csv")
```

---

### ❌ GAP 2: Advanced Prosodic Analysis
**Praat Pattern**: Many scripts perform specialized intonation and prosody analysis beyond basic pitch extraction.

**Examples**:
- **PoLaR plugin** (ByronAhn/PoLaR-Praat-plugin): Turning point detection, pitch stylization, Momel integration, straight-line approximation
- **ProPer_Projekt** (finkelbert): Periodic energy analysis, prosodic profiling
- Pitch dynamics scripts: Slope calculation, rate-of-change, stylization

**Speaker Limitation**:
- Only basic `Pitch` object with mean/min/max
- No pitch stylization (Momel, PENTA, ToBI)
- No turning point detection
- No pitch slope/derivative calculations
- No prosodic tier generation algorithms

**Re-implementation Affordance**: **MODERATE** — Requires domain expertise but could build on existing `Pitch` and `PitchTier` classes:
```r
Pitch$detect_turning_points(threshold)
Pitch$stylize_momel()
Pitch$calculate_slope(interval_tier)
PitchTier$to_straight_line_approximation()
```

---

### ❌ GAP 3: TextGrid Automation & Annotation Utilities
**Praat Pattern**: Scripts automate TextGrid creation, validation, and complex label transformations.

**Examples**:
- **Automatic segmentation**: Voice activity detection, silence detection, boundary placement
- **Label validation**: Check for empty intervals, label format validation, tier consistency
- **Label transformation**: Find/replace patterns, merge intervals, split by regex
- **Cross-TextGrid operations**: Compare two TextGrids, merge annotations, consensus labeling

**Speaker Limitation**:
- Manual TextGrid manipulation only
- No segmentation algorithms
- No validation helpers
- No pattern-based label operations

**Re-implementation Affordance**: **HIGH** — String/regex operations are R's strength:
```r
TextGrid$validate_labels(tier, allowed_labels)
TextGrid$find_replace(tier, pattern, replacement)
TextGrid$auto_segment_silence(sound, threshold)
TextGrid$merge_intervals(tier, condition_func)
TextGrid$compare(other_textgrid, report = TRUE)
```

---

### ❌ GAP 4: Data Extraction & Export Pipelines
**Praat Pattern**: Scripts extract measurements at specific time points, aggregate over intervals, and export to tabular formats.

**Examples**:
- Extract formants/pitch at interval midpoints or multiple time-normalized points
- Aggregate statistics per label (mean F0 per phone, formant trajectories)
- Export to CSV/TXT with custom column structures
- Long-format vs. wide-format output options

**Speaker Limitation**:
- `as_data_frame()` exists for TextGrid but limited
- No formant/pitch trajectory extraction helpers
- No time-normalization utilities
- No aggregation by interval labels

**Re-implementation Affordance**: **HIGH** — This is where R shines:
```r
Formant$extract_trajectory(textgrid, tier, label, n_points = 10)
extract_measurements(sound, textgrid, tier, measures = c("pitch", "formants", "intensity"))
aggregate_by_label(measurements_df, textgrid, tier)
```

---

### ❌ GAP 5: Visualization & Plotting
**Praat Pattern**: Many scripts create publication-quality plots with Praat's Picture window (waveform + spectrogram + TextGrid + pitch track).

**Examples**:
- **PoLaR plugin**: Styled plots with prosodic annotations
- **PraatPictures**: Batch plot generation
- Custom spectrogram overlays with formant tracks

**Speaker Limitation**:
- **NO plotting capabilities** in the package
- Users must use separate R plotting (ggplot2, phonR, etc.)
- No integrated way to visualize `Sound` + `TextGrid` + `Pitch`

**Re-implementation Affordance**: **MODERATE** — R has powerful plotting, but integrating Praat-style multi-panel plots requires design:
```r
plot_sound_and_textgrid(sound, textgrid, pitch = NULL, formant = NULL)
plot_spectrogram(sound, overlay_formants = TRUE, overlay_pitch = TRUE)
Sound$plot() # with ggplot2-based implementation
```

---

### ❌ GAP 6: Voice Quality & EGG Analysis
**Praat Pattern**: Specialized voice quality scripts beyond basic jitter/shimmer.

**Examples**:
- Detailed voice reports with CPP, NHR, spectral tilt
- Electroglottogram (EGG) derivative analysis
- Open quotient measurement from EGG
- Vocal fold contact analysis

**Speaker Limitation**:
- Has `Electroglottogram` class but minimal methods
- Has jitter/shimmer via `PointProcess`
- Missing: CPP (Cepstral Peak Prominence), NHR, spectral tilt

**Re-implementation Affordance**: **MODERATE** — Core functionality exists; needs expansion:
```r
PointProcess$get_cpp()
Spectrum$get_spectral_tilt(f_low, f_high)
Harmonicity$get_nhr()
```

---

### ❌ GAP 7: Formant Refinement & Tracking Algorithms
**Praat Pattern**: Scripts implement iterative formant refinement and tracking across time.

**Examples**:
- **FastTrack** (santiagobarreda): Winner-take-all formant tracking with constraints
- Manual formant correction workflows
- Formant smoothing and outlier removal

**Speaker Limitation**:
- Basic formant extraction only (`to_formant_burg()`)
- No formant tracking across time with constraints
- No smoothing/refinement algorithms
- `Formant$track()` method exists but may be underdeveloped

**Re-implementation Affordance**: **LOW to MODERATE** — Requires signal processing expertise:
```r
Formant$refine_tracking(constraints = list(max_jump = 500))
Formant$smooth(window_size = 3)
Formant$remove_outliers(z_threshold = 3)
```

---

###  ❌ GAP 8: Audio Editing & Manipulation
**Praat Pattern**: Scripts perform surgical audio editing (cut, insert silence, normalize peaks, remove sections).

**Examples**:
- Insert silence at beginning/end
- Normalize peak amplitude across files
- Cut/trim based on TextGrid intervals
- Create stimuli from segments

**Speaker Limitation**:
- Basic operations exist (`scale_peak()`, `concatenate()`)
- Missing: Insert silence, extract intervals to new Sounds, trim

**Re-implementation Affordance**: **HIGH** — R can handle this:
```r
Sound$insert_silence(duration, position = "start")
Sound$extract_interval(textgrid, tier, interval_number)
Sound$trim(start_time, end_time)
```

---

### ❌ GAP 9: Multi-file Coordination
**Praat Pattern**: Scripts coordinate operations across multiple related files (Sound + TextGrid + PitchTier + Formant).

**Examples**:
- Load matching Sound/TextGrid pairs from directories
- Save multiple object types together
- Batch apply transformations maintaining file relationships

**Speaker Limitation**:
- Objects are independent
- No file pairing utilities
- No batch save coordinated objects

**Re-implementation Affordance**: **HIGH**:
```r
pair_files(sound_dir, textgrid_dir, by = "basename")
save_bundle(sound, textgrid, pitch, base_path)
load_bundle(base_path) # returns list of objects
```

---

### ❌ GAP 10: Scripting Infrastructure
**Praat Pattern**: Form-based user input, progress reporting, error handling, logging.

**Examples**:
- `form` blocks for user parameters
- `writeFileLine` for logging
- Progress bars for batch processing
- Error handling for missing files

**Speaker Limitation**:
- No equivalent to Praat's `form` system
- No built-in logging or progress reporting
- Error messages could be more informative

**Re-implementation Affordance**: **HIGH** — R has rich UI/logging ecosystem:
```r
# Use shiny for forms, cli for progress, logger for logging
speaker_config <- configure_analysis(interactive = TRUE)
with_progress({ batch_process(...) })
```

---

## Part 3: Re-implementation Priority & Roadmap

### 🔴 HIGH PRIORITY (Immediate Affordance)
1. **Batch Processing Utilities** — Essential for research workflows
2. **Data Extraction Pipelines** — R's core strength, fills major gap
3. **TextGrid Automation** — Regex/string ops are trivial in R
4. **Audio Editing Helpers** — Simple signal operations
5. **Multi-file Coordination** — File management in R is straightforward

### 🟡 MEDIUM PRIORITY (Requires Design)
6. **Visualization Integration** — Needs careful API design (ggplot2 vs base)
7. **Advanced Prosody** — Requires phonetics expertise but feasible
8. **Voice Quality Extensions** — Build on existing classes
9. **Formant Refinement** — Algorithmic complexity moderate

### 🟢 LOW PRIORITY (Specialized/Complex)
10. **Full Praat Scripting Emulation** — Likely unnecessary (use R idioms instead)
11. **Praat GUI Features** — Interactive R workflows differ from Praat's approach

---

## Part 4: Specific Function Recommendations

### Batch Processing Module
```r
# Core batch functions
process_directory(
  path,
  sound_pattern = "\\.wav$",
  textgrid_pattern = "\\.TextGrid$",
  func,
  export = c("csv", "rds", "none"),
  parallel = FALSE
)

pair_sound_textgrid(sound_dir, textgrid_dir, method = "basename")

batch_extract_features(
  pairs_df,
  features = c("pitch", "formants", "intensity"),
  export_path
)
```

### TextGrid Utilities
```r
TextGrid$auto_segment(
  sound,
  method = c("silence", "intensity", "spectral_change"),
  tier_name = "segments"
)

TextGrid$validate(
  checks = c("empty_intervals", "label_format", "tier_structure")
)

TextGrid$find_replace_labels(tier, pattern, replacement, regex = TRUE)

TextGrid$merge_consecutive_intervals(tier, same_label = TRUE)

compare_textgrids(tg1, tg2, tolerance = 0.01) # for agreement studies
```

### Data Extraction
```r
extract_interval_measurements(
  sound,
  textgrid,
  tier,
  measures = list(
    pitch = list(points = "midpoint", aggregation = "mean"),
    formants = list(points = c(0.2, 0.5, 0.8), formant_numbers = 1:3),
    intensity = list(points = "midpoint")
  )
)

Formant$get_trajectory(
  textgrid,
  tier,
  label_pattern,
  formant_number = 1,
  n_points = 10,
  normalize_time = TRUE
)
```

### Prosodic Analysis
```r
Pitch$stylize(method = c("momel", "penta", "linear_segments"))

Pitch$detect_turning_points(
  sensitivity = 2,  # semitones
  minimum_duration = 0.05
)

Pitch$calculate_slopes(textgrid, tier) # slopes per interval

PitchTier$to_levels_tier(thresholds = c(-1, 1)) # ToBI-style levels
```

### Visualization
```r
plot_praat_style(
  sound,
  textgrid = NULL,
  pitch = NULL,
  formant = NULL,
  spectrogram = TRUE,
  time_range = NULL
)

Sound$plot(type = c("waveform", "spectrogram", "both"))
Pitch$plot(overlay_textgrid = NULL)
Formant$plot(formant_numbers = 1:3)
```

---

## Part 5: Implementation Strategy

### Phase 1: Low-Hanging Fruit (1-2 weeks)
- Batch processing infrastructure
- TextGrid validation/find-replace utilities
- Audio editing helpers (insert silence, extract intervals)
- File pairing utilities

### Phase 2: Data Pipelines (2-3 weeks)
- Measurement extraction at time points
- Trajectory extraction with time normalization
- Aggregation by labels
- Export formatting

### Phase 3: Advanced Analysis (3-4 weeks)
- Pitch stylization (Momel integration)
- Turning point detection
- Formant refinement algorithms
- Voice quality extensions (CPP, spectral tilt)

### Phase 4: Visualization (2-3 weeks)
- ggplot2-based plotting methods for all classes
- Multi-panel Praat-style plots
- Interactive visualization (plotly integration?)

---

## Part 6: Specific Repository Examples to Study

### Exemplary for Batch Processing
1. **feelins/Praat_Scripts**: Comprehensive directory processing templates
2. **PoLaR plugin**: Multi-file coordination and directory operations
3. **kirbyj/praatsauce**: Full pipeline from audio to measurements

### Exemplary for Prosodic Analysis
1. **ByronAhn/PoLaR-Praat-plugin**: State-of-the-art intonation analysis
2. **finkelbert/ProPer_Projekt**: Periodic energy and prosody profiling

### Exemplary for Formant Analysis
1. **santiagobarreda/FastTrack**: Sophisticated formant tracking with constraints

### Exemplary for Data Extraction
1. **lennes/spect**: Spectral measurements along trajectories
2. **feelins/Praat_Scripts/09-get_duration_and_pitch**: Time-normalized pitch extraction

---

## Conclusion

**The speaker package has EXCELLENT core Praat functionality** but lacks the **workflow automation and high-level analysis pipelines** that researchers actually use in practice.

### Key Findings:
1. ✅ **60-70% of core Praat functions are well-implemented**
2. ❌ **Batch processing, data pipelines, and workflow automation are almost entirely missing**
3. ✅ **Re-implementation affordance is HIGH for most gaps** (R's strengths align well)
4. 🎯 **Priority 1**: Add batch processing infrastructure and data extraction helpers
5. 🎯 **Priority 2**: TextGrid automation and validation utilities
6. 🎯 **Priority 3**: Visualization and prosodic analysis extensions

### Recommendation:
Focus development on **"infrastructure" gaps** (batch processing, data pipelines) rather than low-level signal processing. The core acoustic analysis is strong; what's missing is the **glue code** that makes Praat scripts productive for research.

The 1,213 Praat scripts analyzed are predominantly **workflow automation scripts**, not novel acoustic algorithms. **Speaker can replicate this value by adding R-idiomatic batch processing and data wrangling helpers.**
