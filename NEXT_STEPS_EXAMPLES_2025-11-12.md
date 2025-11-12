# Next Steps: Examples from superassp
**Date**: 2025-11-12  
**Package Version**: 0.4.1  
**Phase**: Week 1-2 of 4-week path to v1.0.0  
**Status**: Ready to begin example implementation

---

## Objective

Reimplement Python Parselmouth examples from the superassp package in native speaker R code to demonstrate:

1. ✅ Feature parity with Parselmouth
2. ✅ Advantages of speaker's direct OOP approach
3. ✅ Migration path from Python to R
4. ✅ Integration with R ecosystem (tidyverse, ggplot2)

---

## Source Files Identified

From `/Users/frkkan96/Documents/src/superassp/inst/python/`:

### Core Analyses
1. **`praat_formant_burg.py`** - Classic Burg formant extraction
2. **`praat_formantpath_burg.py`** - Modern FormantPath (optimal ceiling)
3. **`praat_pitch.py`** - Pitch extraction (multiple algorithms)
4. **`praat_intensity.py`** - Intensity/loudness analysis

### Voice Quality
5. **`praat_voice_report_memory.py`** - Comprehensive voice quality report
6. **`praat_dsi_memory.py`** - Dysphonia Severity Index
7. **`praat_avqi_memory.py`** - Acoustic Voice Quality Index

### Spectral Features
8. **`praat_spectral_moments.py`** - COG, spread, skewness, kurtosis
9. **`praat_sauce_memory.py`** - SAUCE (spectral/cepstral measures)
10. **`praat_praatsauce_memory.py`** - PraatSauce measurements

---

## Target Examples Structure

Create **`inst/examples/`** directory with:

### 1. Basic Analyses (`01_basic_analyses.R`)

**Content**:
```r
# Basic acoustic analyses using speaker package
# Demonstrates direct OOP approach vs Parselmouth

library(speaker)
library(ggplot2)

# Example 1: Pitch extraction
sound <- Sound$new(system.file("extdata", "audio.wav", package = "speaker"))
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)

# Query methods
mean_f0 <- pitch$get_mean(unit = "hertz")
sd_f0 <- pitch$get_standard_deviation(unit = "hertz")

# Convert to data frame for plotting
pitch_df <- pitch$as_data_frame()
ggplot(pitch_df, aes(x = time, y = frequency)) +
  geom_line() +
  labs(title = "Pitch Contour", x = "Time (s)", y = "F0 (Hz)")
```

**Python Comparison**: Side-by-side with `praat_pitch.py`

### 2. Formant Analysis (`02_formant_analysis.R`)

**Content**:
```r
# Formant extraction and vowel space analysis
# Reimplements praat_formant_burg.py

library(speaker)
library(dplyr)

# Extract formants
sound <- Sound$new("vowel.wav")
formant <- sound$to_formant_burg(
  time_step = 0.005,
  max_number_of_formants = 5,
  maximum_formant = 5500,
  window_length = 0.025,
  pre_emphasis_from = 50
)

# Get formant values over time
formant_df <- formant$as_data_frame()

# Vowel space plot
ggplot(formant_df, aes(x = F2, y = F1)) +
  geom_point(alpha = 0.3) +
  scale_x_reverse() +
  scale_y_reverse() +
  labs(title = "Vowel Space")
```

**Python Comparison**: Direct translation from Parselmouth approach

### 3. Voice Quality (`03_voice_quality.R`)

**Content**:
```r
# Voice quality metrics
# Reimplements praat_voice_report_memory.py

library(speaker)

sound <- Sound$new("voice.wav")

# Extract Pitch for jitter/shimmer
pitch <- sound$to_pitch()
point_process <- sound$to_point_process_cc(pitch)

# Jitter measurements
jitter_local <- point_process$get_jitter_local()
jitter_rap <- point_process$get_jitter_rap()
jitter_ppq5 <- point_process$get_jitter_ppq5()

# Shimmer measurements
shimmer_local <- point_process$get_shimmer_local()
shimmer_apq3 <- point_process$get_shimmer_apq3()
shimmer_apq5 <- point_process$get_shimmer_apq5()

# Harmonicity (HNR)
harmonicity <- sound$to_harmonicity_cc()
hnr_mean <- harmonicity$get_mean()

# Create voice quality report
voice_quality <- data.frame(
  jitter_local = jitter_local,
  jitter_rap = jitter_rap,
  jitter_ppq5 = jitter_ppq5,
  shimmer_local = shimmer_local,
  shimmer_apq3 = shimmer_apq3,
  shimmer_apq5 = shimmer_apq5,
  hnr = hnr_mean
)
```

**Python Comparison**: Show advantages of direct method access

### 4. Spectral Analysis (`04_spectral_analysis.R`)

**Content**:
```r
# Spectral moments and features
# Reimplements praat_spectral_moments.py

library(speaker)

sound <- Sound$new("fricative.wav")

# Extract spectrum
spectrum <- sound$to_spectrum()

# Spectral moments
cog <- spectrum$get_centre_of_gravity(power = 2)
spread <- spectrum$get_standard_deviation(power = 2)
skewness <- spectrum$get_skewness(power = 2)
kurtosis <- spectrum$get_kurtosis(power = 2)

# Band energy
band_energy <- spectrum$get_band_energy(
  from_frequency = 1000,
  to_frequency = 4000
)

spectral_features <- data.frame(
  COG = cog,
  spread = spread,
  skewness = skewness,
  kurtosis = kurtosis,
  band_energy = band_energy
)
```

### 5. Intensity Analysis (`05_intensity_analysis.R`)

**Content**:
```r
# Intensity/loudness analysis
# Reimplements praat_intensity.py

library(speaker)

sound <- Sound$new("speech.wav")

# Extract intensity
intensity <- sound$to_intensity(
  minimum_pitch = 100,
  time_step = 0.01,
  subtract_mean = TRUE
)

# Statistics
mean_intensity <- intensity$get_mean()
sd_intensity <- intensity$get_standard_deviation()
min_intensity <- intensity$get_minimum()
max_intensity <- intensity$get_maximum()

# Time of extrema
time_of_max <- intensity$get_time_of_maximum()
time_of_min <- intensity$get_time_of_minimum()

# Plot
intensity_df <- intensity$as_data_frame()
ggplot(intensity_df, aes(x = time, y = intensity)) +
  geom_line() +
  labs(title = "Intensity Contour", 
       x = "Time (s)", 
       y = "Intensity (dB)")
```

### 6. Manipulation (`06_pitch_manipulation.R`)

**Content**:
```r
# PSOLA pitch and duration modification
# Shows Manipulation object capabilities

library(speaker)

sound <- Sound$new("voice.wav")

# Create manipulation
manip <- sound$to_manipulation(
  time_step = 0.01,
  minimum_pitch = 75,
  maximum_pitch = 600
)

# Get pitch tier
pitch_tier <- manip$extract_pitch_tier()

# Modify pitch (multiply by 1.2 = 20% increase)
pitch_tier$multiply_frequencies(time_range = c(0, 0), factor = 1.2)

# Replace modified pitch tier
manip$replace_pitch_tier(pitch_tier)

# Resynthesize
modified_sound <- manip$get_resynthesis_overlap_add()

# Save result
modified_sound$save("voice_raised_pitch.wav")
```

### 7. Integration Pipeline (`07_complete_pipeline.R`)

**Content**:
```r
# Complete phonetic analysis pipeline
# Batch processing multiple files

library(speaker)
library(tidyverse)

# Process multiple files
files <- list.files("audio", pattern = "\\.wav$", full.names = TRUE)

results <- tibble(file = files) %>%
  mutate(
    # Load sound
    sound = map(file, ~Sound$new(.x)),
    
    # Basic properties
    duration = map_dbl(sound, ~.x$get_total_duration()),
    sampling_rate = map_dbl(sound, ~.x$get_sampling_frequency()),
    
    # Pitch analysis
    pitch = map(sound, ~.x$to_pitch()),
    mean_f0 = map_dbl(pitch, ~.x$get_mean(unit = "hertz")),
    sd_f0 = map_dbl(pitch, ~.x$get_standard_deviation(unit = "hertz")),
    
    # Formant analysis
    formant = map(sound, ~.x$to_formant_burg()),
    f1_mean = map_dbl(formant, ~.x$get_mean(formant_number = 1)),
    f2_mean = map_dbl(formant, ~.x$get_mean(formant_number = 2)),
    
    # Intensity
    intensity = map(sound, ~.x$to_intensity()),
    mean_intensity = map_dbl(intensity, ~.x$get_mean()),
    
    # Voice quality
    harmonicity = map(sound, ~.x$to_harmonicity_cc()),
    hnr = map_dbl(harmonicity, ~.x$get_mean())
  ) %>%
  select(-sound, -pitch, -formant, -intensity, -harmonicity)

# Export results
write_csv(results, "acoustic_analysis_results.csv")

# Visualize
ggplot(results, aes(x = f1_mean, y = f2_mean, label = basename(file))) +
  geom_point() +
  geom_text(vjust = -0.5) +
  scale_x_reverse() +
  scale_y_reverse() +
  labs(title = "Vowel Space", x = "F1 (Hz)", y = "F2 (Hz)")
```

### 8. README (`README.md`)

**Content**:
```markdown
# speaker Package Examples

This directory contains example scripts demonstrating the speaker package's
capabilities for acoustic phonetic analysis in R.

## Overview

The speaker package provides direct R6-based access to Praat's analysis
algorithms, offering advantages over Python's Parselmouth library:

- **Direct method calls**: No `praat.call()` indirection
- **Type-safe parameters**: RStudio autocomplete support
- **Native R integration**: Works seamlessly with tidyverse, ggplot2
- **Better performance**: Direct C++ binding, no Python interpreter

## Examples

1. **`01_basic_analyses.R`** - Pitch, formant, intensity basics
2. **`02_formant_analysis.R`** - Advanced formant tracking
3. **`03_voice_quality.R`** - Jitter, shimmer, HNR
4. **`04_spectral_analysis.R`** - Spectral moments, band energy
5. **`05_intensity_analysis.R`** - Loudness analysis
6. **`06_pitch_manipulation.R`** - PSOLA modification
7. **`07_complete_pipeline.R`** - Batch processing workflow

## Comparison with Parselmouth

### Parselmouth (Python)
```python
import parselmouth as pm

sound = pm.Sound("file.wav")
pitch = pm.praat.call(sound, "To Pitch", 0.01, 75, 600)
mean_f0 = pm.praat.call(pitch, "Get mean", 0, 0, "Hertz")
```

### speaker (R)
```r
library(speaker)

sound <- Sound$new("file.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
```

## Running Examples

```r
# Install speaker package
# install.packages("speaker")  # When on CRAN

# Run basic example
source(system.file("examples", "01_basic_analyses.R", package = "speaker"))

# Or source locally
source("inst/examples/01_basic_analyses.R")
```

## Python to R Migration

These examples demonstrate 1:1 translations from Parselmouth Python code
to speaker R code. See individual files for side-by-side comparisons.

## Integration with R Ecosystem

All examples use:
- **tidyverse** for data manipulation
- **ggplot2** for visualization
- **data.frame/tibble** for tabular data

This enables seamless integration with existing R workflows.

## Performance

speaker typically matches or exceeds Parselmouth performance due to:
- Direct C++ binding (no Python interpreter)
- Efficient memory management (external pointers)
- Zero-copy object transformations

See vignettes for detailed benchmarks.
```

---

## Implementation Plan

### Week 1 (Days 1-3)
- [x] **Day 1**: Plan confirmed, structure documented
- [ ] **Day 2**: Implement examples 1-3 (basic analyses, formants, voice quality)
- [ ] **Day 3**: Implement examples 4-5 (spectral, intensity)

### Week 2 (Days 4-7)
- [ ] **Day 4**: Implement examples 6-7 (manipulation, pipeline)
- [ ] **Day 5**: Write comprehensive README
- [ ] **Day 6**: Create comparison documents with Python code
- [ ] **Day 7**: Test all examples, validate output

---

## Success Criteria

### Functionality
- [ ] All 7-8 examples working without errors
- [ ] Output matches Praat/Parselmouth results
- [ ] All examples well-documented

### Quality
- [ ] Clear, readable R code
- [ ] Proper error handling
- [ ] Efficient implementations

### Documentation
- [ ] Side-by-side Python comparisons
- [ ] Clear migration guidance
- [ ] Integration with tidyverse demonstrated

### Demonstration
- [ ] Feature parity proven
- [ ] Advantages highlighted
- [ ] R idioms showcased

---

## Next Immediate Actions

1. Create `inst/examples/` directory
2. Start with `01_basic_analyses.R`
3. Analyze `praat_pitch.py` for Python comparison
4. Implement R equivalent
5. Proceed through remaining examples

---

**Status**: Ready to proceed with example implementation  
**Current Phase**: Week 1-2 of 4-week v1.0.0 roadmap  
**Next Step**: Create first example script
