# Speaker Package Examples

## Overview

This directory contains example R scripts demonstrating how to use the `speaker` package for phonetic analysis. These examples directly replace Python implementations using Parselmouth (from the superassp package).

## Files

### Documentation
- **PYTHON_TO_R_MAPPING.md** - Complete mapping of Python Parselmouth code to R speaker equivalents

### Example Scripts  
- **01_basic_analysis.R** - Pitch, formants, and intensity extraction (✅ Fully Implemented)
- **02_voice_quality.R** - Voice quality measures including jitter/shimmer/HNR
- **03_spectral_analysis.R** - Spectral moments and fricative analysis
- **04_spectral_moments.R** - Spectral moments for fricative analysis
- **05_complete_workflow.R** - End-to-end phonetic analysis pipeline
- **06_textgrid_analysis.R** - TextGrid manipulation and annotation workflows
- **07_comprehensive_phonetic_analysis.R** - Integrated TextGrid + acoustic analysis
- **08_textgrid_corpus_analysis.R** - Large-scale corpus processing with benchmark data
- **09_vowel_space_analysis.R** - Complete vowel acoustics pipeline (F1-F2 analysis)
- **textgrid_editing_demo.R** - TextGrid creation and editing demonstrations

## Quick Start

### Basic Phonetic Analysis (Currently Available ✅)

```r
library(speaker)
source("inst/examples/01_basic_analysis.R")

# Analyze a speech file
results <- complete_phonetic_analysis(
  "speech.wav",
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_formant = 5500,
  gender = "female"
)

# Results include:
# - Pitch statistics (mean, median, SD, min, max)
# - Formant values (F1-F5 time series and means)
# - Intensity statistics
```

### Vowel Space Analysis

```r
source("inst/examples/01_basic_analysis.R")

# Define vowel timepoints
vowel_times <- c(0.5, 1.0, 1.5, 2.0)
vowel_labels <- c("i", "e", "a", "o")

# Analyze and plot
vowel_data <- vowel_space_analysis(
  "speech.wav",
  vowel_times,
  vowel_labels,
  max_formant = 5500
)
```

### Voice Quality Profiling

```r
source("inst/examples/02_voice_quality.R")

# Basic voice quality metrics
quality <- basic_voice_quality(
  "speech.wav",
  pitch_floor = 75,
  pitch_ceiling = 600
)

# Visual dashboard
profile_data <- plot_voice_profile(
  "speech.wav",
  pitch_floor = 75,
  pitch_ceiling = 600
)
```

### Spectral Analysis

```r
source("inst/examples/03_spectral_analysis.R")

# Analyze fricative
fricative_analysis <- analyze_fricative(
  "speech.wav",
  fricative_start = 0.5,
  fricative_end = 0.65
)

# Compare sibilants
sibilant_comparison <- compare_sibilants(
  "speech.wav",
  s_start = 0.5, s_end = 0.65,
  sh_start = 1.2, sh_end = 1.35
)
```

## Implementation Status

### ✅ Fully Implemented (Phase 2 - Current)

These functions work right now:

| Function | Purpose | Python Equivalent |
|----------|---------|-------------------|
| `extract_pitch()` | F0 extraction | `pm.praat.call(sound, "To Pitch (ac)")` |
| `extract_formants()` | Formant tracking | `sound.to_formant_burg()` |
| `extract_intensity()` | Intensity contour | `pm.praat.call(sound, "To Intensity")` |
| `get_mean_pitch()` | Pitch statistics | `pitch.get_mean()` |
| `get_formant_at_time()` | Formant queries | `formant.get_value_at_time()` |
| `get_mean_intensity()` | Intensity stats | `intensity.get_mean()` |
| `as.data.frame()` | Export to DF | `pm.praat.call(obj, "To Table")` |

**Coverage**: ~35% of Parselmouth functionality (core phonetic analysis)

### 🔨 Planned for Phase 2.5 (Next Session)

Priority functions for comprehensive voice analysis:

| Function | Purpose | Python Equivalent | Effort |
|----------|---------|-------------------|--------|
| `voice_report()` | Jitter, shimmer, HNR | `praat_voice_report_memory()` | 2 hrs |
| `spectral_moments()` | Spectral shape | `praat_spectral_moments()` | 1 hr |
| `optimize_formant_ceiling()` | Parameter tuning | `praat_formantpath_burg()` | 1 hr |

**Coverage After Phase 2.5**: ~60% of Parselmouth functionality

### 🔮 Future Phase 3 (Advanced Clinical)

Specialized clinical assessment tools:

| Function | Purpose | Lines | Priority |
|----------|---------|-------|----------|
| `avqi()` | Acoustic Voice Quality Index | 324 | Medium |
| `dsi()` | Dysphonia Severity Index | 319 | Medium |
| `voice_sauce()` | Voice source measures | 416 | Low |
| `voice_tremor()` | Tremor analysis | 772 | Low |

**Coverage After Phase 3**: ~100% of common Parselmouth use cases

## Python to R Translation Guide

### Loading Audio

**Python (Parselmouth)**:
```python
import parselmouth as pm
sound = pm.Sound("audio.wav")
```

**R (speaker)**: ✅
```r
library(speaker)
sound <- read_sound("audio.wav")
```

### Pitch Extraction

**Python**:
```python
pitch = pm.praat.call(sound, "To Pitch (ac)", 
                      time_step, min_f0, max_candidates,
                      very_accurate, silence_threshold, 
                      voicing_threshold, octave_cost,
                      octave_jump_cost, voiced_voiceless_cost, 
                      max_f0)
mean_f0 = pm.praat.call(pitch, "Get mean", 0, 0, "Hertz")
```

**R**: ✅
```r
pitch <- extract_pitch(sound, 
                       time_step = time_step,
                       pitch_floor = min_f0,
                       pitch_ceiling = max_f0)
mean_f0 <- get_mean_pitch(pitch, unit = "Hertz")
```

### Formant Extraction

**Python**:
```python
formants = sound.to_formant_burg(
    time_step=0.005,
    max_number_of_formants=5,
    maximum_formant=5500,
    window_length=0.025,
    pre_emphasis_from=50
)
f1 = formants.get_value_at_time(1, 0.5)
```

**R**: ✅
```r
formants <- extract_formants(sound,
                             time_step = 0.005,
                             n_formants = 5,
                             max_formant = 5500,
                             window_length = 0.025,
                             pre_emphasis_from = 50)
f1 <- get_formant_at_time(formants, formant_number = 1, time = 0.5)
```

### Intensity Extraction

**Python**:
```python
intensity = pm.praat.call(sound, "To Intensity", 
                          minimum_pitch, time_step, subtract_mean)
mean_db = pm.praat.call(intensity, "Get mean", 0, 0, "energy")
```

**R**: ✅
```r
intensity <- extract_intensity(sound,
                               minimum_pitch = minimum_pitch,
                               time_step = time_step,
                               subtract_mean = subtract_mean)
mean_db <- get_mean_intensity(intensity)
```

### Data Export

**Python**:
```python
import io
table = pm.praat.call(pitch, "To Matrix")
df = pd.read_table(io.StringIO(pm.praat.call(table, "List", True)))
```

**R**: ✅
```r
df <- as.data.frame(pitch)
# Returns data.frame with time and frequency columns
```

## Key Advantages of R Implementation

1. **No Python Dependency** - Pure R/C++ solution
2. **Native R Integration** - Works seamlessly with R workflows
3. **Better Performance** - Direct C++ implementation (no Python bridge)
4. **Type Safety** - R's type system prevents common errors
5. **Easier Debugging** - All code in one language
6. **Package Ecosystem** - Use R's statistical and plotting tools
7. **Memory Efficiency** - No data serialization between R and Python

## Workarounds for Missing Functions

Until Phase 2.5 functions are implemented, you can use these approaches:

### Jitter/Shimmer (Manual Calculation)

```r
# Get pitch as data frame
pitch_df <- as.data.frame(pitch)

# Manual jitter calculation (simplified)
periods <- 1 / pitch_df$frequency[!is.na(pitch_df$frequency)]
period_diffs <- diff(periods)
jitter_local <- mean(abs(period_diffs) / periods[-length(periods)], na.rm = TRUE) * 100
```

### Spectral Analysis (Formant-Based Approximation)

```r
# Use formants as proxy for spectral characteristics
formant_df <- as.data.frame(formants)

# Approximate spectral center
spectral_center <- apply(formant_df, 1, function(row) {
  freqs <- c(row$F1, row$F2, row$F3, row$F4, row$F5)
  mean(freqs, na.rm = TRUE)
})
```

## Common Use Cases

### 1. Vowel Analysis

```r
source("inst/examples/01_basic_analysis.R")

# Extract vowel formants
sound <- read_sound("vowel.wav")
formants <- extract_formants(sound, max_formant = 5500)

# Get F1 and F2 at vowel midpoint
midpoint <- get_duration(sound) / 2
f1 <- get_formant_at_time(formants, 1, midpoint)
f2 <- get_formant_at_time(formants, 2, midpoint)

# Classify vowel based on F1-F2 space
```

### 2. Prosody Analysis

```r
# Extract pitch and intensity contours
pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 600)
intensity <- extract_intensity(sound, minimum_pitch = 100)

# Convert to data frames for analysis
pitch_df <- as.data.frame(pitch)
intensity_df <- as.data.frame(intensity)

# Analyze pitch range and movements
pitch_range <- max(pitch_df$frequency, na.rm = TRUE) - 
               min(pitch_df$frequency, na.rm = TRUE)
```

### 3. Speaker Comparison

```r
source("inst/examples/02_voice_quality.R")

files <- c("speaker1.wav", "speaker2.wav", "speaker3.wav")
labels <- c("Speaker A", "Speaker B", "Speaker C")

comparison <- compare_speakers(files, labels)
print(comparison)
```

### 4. Fricative Analysis

```r
source("inst/examples/03_spectral_analysis.R")

# Analyze /s/ fricative
s_analysis <- analyze_fricative("speech.wav", 
                                fricative_start = 0.5,
                                fricative_end = 0.65)

# Check spectral mean (should be ~8000 Hz for /s/)
print(s_analysis$spectral_mean_hz)
```

## Tips and Best Practices

1. **Choose appropriate parameters for speaker type**:
   - Male: `pitch_floor = 75`, `pitch_ceiling = 300`, `max_formant = 5000`
   - Female: `pitch_floor = 100`, `pitch_ceiling = 600`, `max_formant = 5500`
   - Child: `pitch_floor = 150`, `pitch_ceiling = 800`, `max_formant = 8000`

2. **Handle NA values properly**:
   - Pitch returns NA for unvoiced frames
   - Formants return NA when tracking fails
   - Use `na.rm = TRUE` in statistical functions

3. **Visualize before analyzing**:
   - Always plot your data first
   - Check for outliers and tracking errors
   - Verify parameter choices

4. **Use appropriate time windows**:
   - Vowels: Measure at steady state (middle third)
   - Fricatives: Use full segment duration
   - Pitch: Need voiced segments

## Getting Help

- **Function documentation**: `?extract_pitch`, `?extract_formants`, etc.
- **Vignette**: `vignette("getting-started", package = "speaker")`
- **Examples**: Source files in this directory
- **Mapping guide**: See `PYTHON_TO_R_MAPPING.md`

## Contributing Examples

If you create useful analysis scripts, consider contributing them:

1. Document your code clearly
2. Include example usage
3. Explain the phonetic rationale
4. Test with different audio types

## References

- **Praat**: Boersma, P., & Weenink, D. (2023). Praat: doing phonetics by computer.
- **Parselmouth**: Jadoul, Y., Thompson, B., & de Boer, B. (2018). Introducing Parselmouth: A Python interface to Praat.
- **speaker**: This package - Pure R implementation of Praat algorithms

## New Advanced Examples (v0.5.4+)

### Example 6: TextGrid Analysis (`06_textgrid_analysis.R`)

Demonstrates comprehensive TextGrid functionality for linguistic annotation:

- **Loading and inspection**: Read TextGrid files, query tier structure
- **Interval queries**: Extract labels, boundaries, and time-based lookups
- **Label statistics**: Distribution analysis, pattern matching
- **Duration statistics**: Calculate interval durations, coverage percentages
- **Data export**: Convert to R data frames for further analysis
- **TextGrid creation**: Build new TextGrids from scratch
- **Modification**: Add boundaries, set labels, manage tiers
- **File I/O**: Save modified TextGrids

**Use cases**: Annotation workflows, corpus preprocessing, forced alignment post-processing

### Example 7: Comprehensive Phonetic Analysis (`07_comprehensive_phonetic_analysis.R`)

Integrated workflow combining TextGrid annotation with acoustic analysis:

- **TextGrid-guided segmentation**: Extract audio segments based on annotations
- **Multi-tier analysis**: Process words, phones, or other linguistic units
- **Batch processing**: Iterate over annotated intervals automatically
- **Acoustic features**: Extract F0, formants, intensity, HNR for each segment
- **Vowel classification**: Separate vowels from consonants for targeted analysis
- **Statistical summaries**: Compute means, SDs by phone type
- **Data preparation**: Export ready for statistical modeling

**Use cases**: Phonetic corpus analysis, vowel quality studies, prosodic research

### Example 8: TextGrid Corpus Analysis (`08_textgrid_corpus_analysis.R`)

Efficient processing of large annotated corpora (uses benchmark data):

- **Large file handling**: Load and process multi-minute TextGrid files
- **Performance benchmarking**: Measure query operation speeds
- **Sampling strategies**: Handle very large datasets efficiently
- **Tier-level statistics**: Duration, coverage, label frequency by tier
- **Memory-conscious processing**: Process subsets for scalability
- **Temporal coverage**: Calculate proportion of labeled vs. unlabeled time
- **Quality control**: Identify annotation patterns and potential errors

**Use cases**: Corpus statistics, annotation quality assessment, preprocessing for ML pipelines

### Example 9: Vowel Space Analysis (`09_vowel_space_analysis.R`)

Complete pipeline for vowel acoustics research (F1-F2 analysis):

- **Multi-point measurement**: Extract formants at onset, midpoint, and offset
- **Formant normalization**: Lobanov (z-score) normalization implementation
- **Vowel space metrics**: Calculate vowel space area (triangulation)
- **Multiple tracking methods**: Compare Burg, Keep-all, and optimized tracking
- **Gender-appropriate settings**: Adjust formant ceiling by speaker type
- **Statistical analysis**: Compute vowel-specific means, SDs, and distributions
- **Visualization prep**: Export data ready for ggplot2 vowel plots
- **Trajectory analysis**: Track formant movement across vowel duration

**Use cases**: Sociolinguistic variation, L2 acquisition, dialect studies, clinical assessment

## Example Workflow Combinations

### Basic Phonetic Research
1. **06_textgrid_analysis.R** - Create/load annotations
2. **07_comprehensive_phonetic_analysis.R** - Extract features
3. **09_vowel_space_analysis.R** - Analyze vowel acoustics

### Large-Scale Corpus Processing
1. **08_textgrid_corpus_analysis.R** - Corpus statistics and QC
2. **07_comprehensive_phonetic_analysis.R** - Batch feature extraction
3. Export to CSV for statistical modeling in R/Python

### Voice Quality Assessment
1. **06_textgrid_analysis.R** - Identify voiced segments
2. **02_voice_quality.R** - Extract jitter, shimmer, HNR
3. Combine with formant data for comprehensive profile

---

**Last Updated**: 2025-11-19  
**Package Version**: 0.5.4  
**Implementation Status**: Comprehensive TextGrid + Sound manipulation complete
