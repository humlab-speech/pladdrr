# AVQI & DSI Implementation Plan for speaker Package
## Voice Quality Indices Implementation Roadmap

**Date**: 2025-11-20  
**Package Version**: 0.4.0  
**Target**: Complete AVQI and DSI implementation with ggplot2 visualization

---

## Executive Summary

This document outlines the implementation plan for two critical voice quality assessment tools:
1. **AVQI (Acoustic Voice Quality Index) v3.01** - Multi-parameter dysphonia severity assessment
2. **DSI (Dysphonia Severity Index) v2.01** - Clinical voice disorder index

Both scripts from superassp repository will be re-implemented using:
- `speaker` package R6 object-oriented architecture
- `ggplot2` for all visualizations (replacing Praat graphics)
- Native R reporting capabilities (data.frames, knitr/rmarkdown)

---

## Part 1: Praat Operations Inventory

### AVQI Script Operations Analysis

#### File I/O Operations
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `Read from file` | filename | ✅ | `Sound$new(path)` |
| `Create Strings as file list` | name, pattern | ❌ | Use `list.files()` |
| `Get number of strings` | - | ❌ | Use `length()` |
| `Get string: n` | index | ❌ | Use `[i]` indexing |
| `Get total duration` | - | ✅ | `sound$get_total_duration()` |
| `Get sampling frequency` | - | ✅ | `sound$get_sampling_frequency()` |
| `Get sampling period` | - | ✅ | `sound$get_sampling_period()` |

#### Sound Processing Operations
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `Concatenate` | - | ✅ | `Sound$concatenate(sounds)` |
| `Filter (stop Hann band)` | from, to, smoothing | ❌ | **MISSING** - Need bandstop filter |
| `Extract part` | start, end, window, rel_width, preserve | ✅ | `sound$extract_part()` |
| `Copy` | new_name | ✅ | `sound$clone()` |
| `Rename` | new_name | ✅ | R object assignment |
| `Create Sound` | name, start, end, sr, formula | ✅ | `Sound$create()` |

#### Voice Activity Detection
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `To TextGrid (silences)` | min_pitch, time_step, sil_thresh, min_sil, min_sound, sil_label, sound_label | ❌ | **MISSING** - Voice activity detection |
| `Extract intervals where` | tier, preserve_times, condition, text | ❌ | **NEED**: TextGrid interval extraction |
| `Get power in air` | - | ❌ | **MISSING** - RMS power calculation |
| `Get nearest zero crossing` | time | ❌ | **MISSING** - Zero-crossing detection |

#### Pitch Analysis
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `To Pitch` | time_step, pitch_floor, pitch_ceiling | ✅ | `sound$to_pitch()` |
| `To Pitch (cc)` | time_step, pitch_floor, ... | ✅ | `sound$to_pitch_cc()` |
| `Get mean` | from, to, unit | ✅ | `pitch$get_mean()` |
| `Get maximum` | from, to, unit, interpolation | ✅ | `pitch$get_maximum()` |
| `Get minimum` | from, to, unit, interpolation | ✅ | `pitch$get_minimum()` |
| `Get quantile` | from, to, quantile, unit | ✅ | `pitch$get_quantile()` |

#### Formant Analysis
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `To Formant (burg)` | time_step, max_n_formants, max_formant, window_length, pre_emphasis | ✅ | `sound$to_formant_burg()` |
| `List formant values at time` | time, ... | ✅ | `formant$get_value_at_time()` |

#### Intensity Analysis
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `To Intensity` | min_pitch, time_step, subtract_mean | ✅ | `sound$to_intensity()` |
| `Get minimum` | from, to, interpolation | ✅ | `intensity$get_minimum()` |
| `Get maximum` | from, to, interpolation | ✅ | `intensity$get_maximum()` |
| `Formula` | expression | ❌ | **NEED**: Matrix/Vector formula interface |

#### Harmonicity Analysis
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `To Harmonicity (cc)` | time_step, pitch_floor, sil_thresh, periods_per_window | ✅ | `sound$to_harmonicity_cc()` |
| `Get mean` | from, to | ✅ | `harmonicity$get_mean()` |

#### Spectral Analysis (LTAS)
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `To Ltas` | bandwidth | ✅ | `sound$to_ltas()` |
| `Get slope` | f1_min, f1_max, f2_min, f2_max, energy/dB | ✅ | `ltas$get_slope()` |
| `Get value at frequency` | freq, interpolation | ✅ | `ltas$get_value_at_frequency()` |

#### Cepstral Analysis (CPPS - KEY MISSING FEATURE)
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `To PowerCepstrum` | pitch_floor, time_step, max_freq, pre_emphasis | ⚠️ | `sound$to_powercepstrum()` - **EXISTS BUT MAY NEED TESTING** |
| `Get CPPS` | subtract_tilt, time_averaging, quefrency_averaging, peak_search_floor, peak_search_ceiling, interpolation, qstep | ❌ | **CRITICAL MISSING**: Smoothed Cepstral Peak Prominence |
| `Smooth` | time_range, quefrency_range | ❌ | **MISSING**: PowerCepstrum smoothing |
| `To PowerCepstrogram` | pitch_floor, time_step, max_freq, pre_emphasis | ❌ | **MISSING**: Time-varying cepstrum |

#### Point Process (Jitter/Shimmer)
| Praat Command | Parameters | Status | speaker Method |
|--------------|------------|--------|----------------|
| `To PointProcess (cc)` | - | ✅ | Sound+Pitch → `sound$to_point_process_cc()` |
| `To PointProcess (peaks)` | channel, include_maxima, include_minima | ✅ | `sound$to_point_process_peaks()` |
| `To TextGrid (vuv)` | max_period, mean_period | ❌ | **MISSING**: Voiced/unvoiced TextGrid |
| `Voice report` | from, to, floor, ceiling, max_period_factor, max_ampl_factor, silence_thresh, voicing_thresh | ❌ | **CRITICAL MISSING**: Voice report with jitter/shimmer |

**Voice Report extracts:**
- Jitter (local)
- Jitter (local, absolute)
- Jitter (rap)
- Jitter (ppq5) - **REQUIRED FOR DSI**
- Jitter (ddp)
- Shimmer (local)
- Shimmer (local, dB) - **REQUIRED FOR AVQI**
- Shimmer (apq3)
- Shimmer (apq5)
- Shimmer (apq11)
- Shimmer (dda)
- Mean autocorrelation
- Mean noise-to-harmonics ratio
- Mean harmonics-to-noise ratio

### DSI Script Operations Analysis

#### DSI-Specific Operations
| Operation | Purpose | Status | Implementation |
|-----------|---------|--------|----------------|
| Maximum Phonation Time (MPT) | Longest vowel duration | ✅ | `sound$get_total_duration()` |
| Highest F0 (f0-high) | Maximum pitch | ✅ | `pitch$get_maximum()` |
| Softest Intensity (I-low) | Minimum intensity from voiced segments | ✅ | `intensity$get_minimum()` |
| Jitter ppq5 | Period perturbation quotient | ❌ | **MISSING**: Voice report |
| DSI Formula | `1.127 + 0.164*mpt - 0.038*il + 0.0053*fh - 5.30*ppq` | ✅ | R calculation |

---

## Part 2: Missing Functionality Assessment

### CRITICAL MISSING (Blocks Implementation)

#### 1. Voice Report with Jitter/Shimmer ❌ **HIGHEST PRIORITY**
**Location**: `src/pointprocess_wrappers.cpp`, `R/pointprocess-r6.R`

**Required Methods**:
```r
# C++ wrapper needed
voice_report <- sound$voice_report(
  pitch,                    # Pitch object
  point_process,            # PointProcess object  
  time_range = c(0, 0),     # Time range
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_period_factor = 1.3,
  max_amplitude_factor = 1.6,
  silence_threshold = 0.03,
  voicing_threshold = 0.45
)

# Returns named list:
# $jitter_local, $jitter_local_absolute, $jitter_rap, $jitter_ppq5, $jitter_ddp
# $shimmer_local, $shimmer_local_db, $shimmer_apq3, $shimmer_apq5, $shimmer_apq11, $shimmer_dda
# $mean_autocorrelation, $mean_noise_to_harmonics_ratio, $mean_harmonics_to_noise_ratio
# $mean_pitch, $num_pulses, $num_periods, $fraction_unvoiced_frames
```

**Praat C++ Source**: `fon/Sound_to_PointProcess.cpp::Sound_Point Process_Pitch_voiceReport()`

#### 2. PowerCepstrum CPPS (Smoothed Cepstral Peak Prominence) ❌ **HIGH PRIORITY**
**Location**: `src/powercepstrum_wrappers.cpp`, `R/powercepstrum-r6.R`

**Required Methods**:
```r
# CPPS calculation
cpps <- power_cepstrum$get_cpps(
  subtract_tilt = TRUE,
  time_averaging_window = 0.001,      # 1 ms
  quefrency_averaging_window = 0.0005, # 0.5 ms
  peak_search_floor = 60,              # Hz (1/quefrency_ceiling)
  peak_search_ceiling = 333.3,         # Hz (1/quefrency_floor)
  interpolation = "parabolic",
  quefrency_step = 0.0001
)

# PowerCepstrogram for time-varying CPPS
cepstrogram <- sound$to_power_cepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,
  pre_emphasis_from = 50
)

cpps_mean <- cepstrogram$get_cpps(
  subtract_tilt = TRUE,
  time_averaging_window = 0.001,
  quefrency_averaging_window = 0.0005,
  peak_search_floor = 60,
  peak_search_ceiling = 333.3,
  interpolation = "parabolic",
  quefrency_step = 0.0001,
  tolerance = 0.05,
  from_time = 0,
  to_time = 0
)
```

**Praat C++ Source**:
- `fon/PowerCepstrum.cpp::PowerCepstrum_getCPPS()`
- `fon/PowerCepstrogram.cpp::PowerCepstrogram_getCPPS()`

#### 3. Voice Activity Detection (VAD) ❌ **HIGH PRIORITY**
**Location**: New file `src/vad_wrappers.cpp`, `R/vad.R`

**Required Methods**:
```r
# TextGrid-based silence detection
textgrid_vad <- sound$to_textgrid_silences(
  min_pitch = 100,
  time_step = 0.01,
  silence_threshold = -25,        # dB
  min_silent_interval = 0.1,      # s
  min_sounding_interval = 0.1,    # s
  silent_interval_label = "silence",
  sounding_interval_label = "sounding"
)

# Extract voiced segments
voiced_intervals <- textgrid_vad$get_intervals_where(
  tier = 1,
  condition = "is equal to",
  text = "sounding"
)

# Extract and concatenate voiced parts
voiced_sounds <- lapply(voiced_intervals, function(interval) {
  sound$extract_part(interval$xmin, interval$xmax, "rectangular", 1.0, FALSE)
})
voiced_concatenated <- Sound$concatenate(voiced_sounds)
```

**Praat C++ Source**: `fon/Sound_to_TextGrid.cpp::Sound_to_TextGrid_detectSilences()`

#### 4. Bandstop Filter ❌ **MEDIUM PRIORITY**
**Location**: `src/sound_wrappers.cpp`

**Required Method**:
```r
# High-pass filter (stopband from 0 to cutoff)
filtered <- sound$filter_stop_hann_band(
  from_frequency = 0,
  to_frequency = 34,
  smoothing = 0.1
)
```

**Praat C++ Source**: `fon/Sound_filtering.cpp::Sound_filterStopBand()`

### IMPORTANT MISSING (Needed for Full Feature Parity)

#### 5. Sound Power/Energy Calculations ❌
```r
# RMS power in air
power <- sound$get_power_in_air()

# Power in specific time range
power_segment <- sound$get_power_in_air(from_time, to_time)
```

#### 6. Zero-Crossing Detection ❌
```r
# Find nearest zero crossing
zero_time <- sound$get_nearest_zero_crossing(time, channel = 1)
```

#### 7. Formula Interface for Intensity/Matrix ❌
```r
# Apply formula to Intensity values
intensity$formula("1*self+10")  # Calibration adjustment

# Matrix formula operations
matrix$formula("self * 2")
```

#### 8. PointProcess to TextGrid (Voiced/Unvoiced) ❌
```r
# Create TextGrid from point process with V/U marking
textgrid_vuv <- point_process$to_textgrid_vuv(
  maximum_period = 0.02,
  mean_period = 0.01
)
```

---

## Part 3: ggplot2 Visualization Requirements

### AVQI Visualizations

Both scripts produce graphical output that needs ggplot2 equivalents:

#### 1. **Waveform (Oscillogram)**
**Praat**: `Draw... 0 0 0 0 yes curve`

**ggplot2 Implementation**:
```r
plot_waveform <- function(sound, from_time = 0, to_time = 0) {
  # Extract samples
  if (to_time == 0) to_time <- sound$get_total_duration()
  
  n_samples <- min(10000, sound$nx)  # Downsample for plotting
  times <- seq(from_time, to_time, length.out = n_samples)
  values <- sound$get_values_at_times(times, channel = 1)
  
  df <- data.frame(time = times, amplitude = values)
  
  ggplot(df, aes(x = time, y = amplitude)) +
    geom_line(linewidth = 0.3) +
    labs(x = "Time (s)", y = "Amplitude", title = "Waveform") +
    theme_minimal()
}
```

#### 2. **Narrowband Spectrogram with LTAS Overlay**
**Praat**: `Paint... 0 0 0 0 100 yes 50 6 0 yes` + LTAS curve

**ggplot2 Implementation**:
```r
plot_spectrogram_with_ltas <- function(sound) {
  # Create spectrogram
  spectrogram <- sound$to_spectrogram(
    window_length = 0.03,  # Narrowband: 30 ms
    max_frequency = 5000,
    time_step = 0.002,
    frequency_step = 20,
    window_shape = "Gaussian"
  )
  
  # Extract matrix for plotting
  spec_matrix <- spectrogram$as_matrix()
  
  # Create LTAS
  ltas <- sound$to_ltas(bandwidth = 100)
  ltas_df <- data.frame(
    frequency = ltas$get_frequencies(),
    power = ltas$get_values()
  )
  
  # Spectrogram heatmap
  p1 <- ggplot(spec_matrix_long, aes(x = time, y = frequency, fill = power)) +
    geom_raster() +
    scale_fill_viridis_c(option = "magma") +
    labs(x = "Time (s)", y = "Frequency (Hz)") +
    theme_minimal()
  
  # LTAS overlay (on separate axis)
  p2 <- ggplot(ltas_df, aes(x = frequency, y = power)) +
    geom_line() +
    coord_flip() +
    theme_minimal()
  
  # Combine with patchwork
  library(patchwork)
  p1 + p2 + plot_layout(widths = c(3, 1))
}
```

#### 3. **Power Cepstrogram with Power Cepstrum**
**Praat**: PowerCepstrogram painted image + PowerCepstrum line plot

**ggplot2 Implementation**:
```r
plot_cepstrogram_with_cepstrum <- function(sound) {
  # Create power cepstrogram (MISSING - needs implementation)
  cepstrogram <- sound$to_power_cepstrogram(
    pitch_floor = 60,
    time_step = 0.002,
    max_frequency = 5000,
    pre_emphasis_from = 50
  )
  
  # Average cepstrum
  cepstrum <- cepstrogram$to_power_cepstrum_slice(time = 0)  # Mean over time
  
  # Similar layout to spectrogram
  # ... (analogous to above)
}
```

### DSI Visualizations

#### 4. **DSI Score Bar with Color Coding**
**Praat**: Colored rectangles + arrow indicator

**ggplot2 Implementation**:
```r
plot_dsi_score <- function(dsi_value) {
  df <- data.frame(
    region = c("Severe Dysphonia", "Normal"),
    xmin = c(-5, 1.6),
    xmax = c(1.6, 5),
    ymin = 0,
    ymax = 1,
    color = c("red", "green")
  )
  
  ggplot(df) +
    geom_rect(aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = color),
              alpha = 0.3) +
    geom_segment(aes(x = dsi_value, xend = dsi_value, y = 0, yend = 1),
                 arrow = arrow(length = unit(0.3, "cm")),
                 linewidth = 1.5) +
    scale_fill_identity() +
    labs(x = "DSI Score", y = "", title = "Dysphonia Severity Index") +
    theme_minimal() +
    theme(axis.text.y = element_blank(),
          axis.ticks.y = element_blank())
}
```

#### 5. **Pitch Contour**
**Praat**: `Speckle... 0 0 0 0 yes`

**ggplot2 Implementation**:
```r
plot_pitch <- function(pitch, sound = NULL) {
  times <- pitch$get_frame_times()
  values <- sapply(times, function(t) pitch$get_value_at_time(t, "hertz", "linear"))
  
  df <- data.frame(time = times, f0 = values)
  df <- df[!is.na(df$f0), ]  # Remove unvoiced frames
  
  p <- ggplot(df, aes(x = time, y = f0)) +
    geom_point(size = 0.5, alpha = 0.6) +
    labs(x = "Time (s)", y = "Fundamental frequency (Hz)", title = "Pitch Contour") +
    theme_minimal()
  
  # Optional: overlay waveform
  if (!is.null(sound)) {
    # Add waveform in background (secondary axis)
  }
  
  p
}
```

#### 6. **Intensity Contour**
**Praat**: `Draw... 0 0 0 0 yes`

**ggplot2 Implementation**:
```r
plot_intensity <- function(intensity) {
  times <- intensity$get_frame_times()
  values <- sapply(times, function(t) intensity$get_value_at_time(t, "nearest"))
  
  df <- data.frame(time = times, intensity_db = values)
  
  ggplot(df, aes(x = time, y = intensity_db)) +
    geom_line(linewidth = 0.7) +
    labs(x = "Time (s)", y = "Intensity (dB)", title = "Intensity Contour") +
    theme_minimal()
}
```

---

## Part 4: Report Generation Architecture

### AVQI Report Output

**Praat Output**: Info window text + PDF with graphics

**R Implementation Strategy**:

#### Option A: Data Frame Output (Simple)
```r
avqi_result <- list(
  metadata = data.frame(
    patient_name = "Fredrik Nylén",
    date_of_birth = "1975-12-31",
    assessment_date = "2021-12-31",
    avqi_version = "v03.01"
  ),
  acoustics = data.frame(
    measure = c("CPPS", "Shimmer Local", "Shimmer Local dB", 
                "LTAS Slope", "LTAS Tilt", "HNR"),
    value = c(cpps, shimmer_local, shimmer_local_db,
              ltas_slope, ltas_tilt, hnr),
    unit = c("dB", "%", "dB", "dB/kHz", "dB", "dB")
  ),
  avqi_score = avqi_value,
  durations = data.frame(
    segment = c("Sustained Vowel", "Continuous Speech", "Total"),
    duration_s = c(sv_duration, cs_duration, total_duration)
  )
)

class(avqi_result) <- c("avqi", "list")

# S3 print method
print.avqi <- function(x, ...) {
  cat("=== ACOUSTIC VOICE QUALITY INDEX (AVQI) v03.01 ===\n\n")
  cat("Patient:", x$metadata$patient_name, "\n")
  cat("DOB:", x$metadata$date_of_birth, "\n")
  cat("Assessment:", x$metadata$assessment_date, "\n\n")
  cat("--- Acoustic Measures ---\n")
  print(x$acoustics, row.names = FALSE)
  cat("\n*** AVQI SCORE:", round(x$avqi_score, 2), "***\n\n")
}
```

#### Option B: R Markdown Report (Professional)
```r
# Template: inst/rmarkdown/templates/avqi_report/template.yaml

generate_avqi_report <- function(avqi_result, output_file = "avqi_report.html",
                                  format = c("html", "pdf", "docx")) {
  format <- match.arg(format)
  
  # Render R Markdown template with avqi_result data
  rmarkdown::render(
    input = system.file("rmarkdown/templates/avqi_report/skeleton.Rmd", 
                       package = "speaker"),
    output_format = switch(format,
      html = rmarkdown::html_document(),
      pdf = rmarkdown::pdf_document(),
      docx = rmarkdown::word_document()
    ),
    output_file = output_file,
    params = list(avqi_data = avqi_result)
  )
}
```

**R Markdown Template** (`inst/rmarkdown/templates/avqi_report/skeleton.Rmd`):
````markdown
---
title: "Acoustic Voice Quality Index (AVQI) Report"
date: "`r Sys.Date()`"
params:
  avqi_data: NULL
output: html_document
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = FALSE, message = FALSE, warning = FALSE)
library(ggplot2)
library(knitr)
library(speaker)
```

## Patient Information

```{r metadata}
kable(params$avqi_data$metadata)
```

## AVQI Score

**AVQI: `r round(params$avqi_data$avqi_score, 2)`**

Interpretation:
- AVQI < 2.95: Normal voice quality
- AVQI ≥ 2.95: Dysphonic voice quality

## Acoustic Measures

```{r acoustics}
kable(params$avqi_data$acoustics, digits = 2)
```

## Visualizations

### Waveform

```{r waveform}
# Plot generated from stored plot object or regenerated from sound
params$avqi_data$plots$waveform
```

### Spectrogram with LTAS

```{r spectrogram}
params$avqi_data$plots$spectrogram_ltas
```

### Power Cepstrogram

```{r cepstrogram}
params$avqi_data$plots$cepstrogram
```

## Recording Details

```{r durations}
kable(params$avqi_data$durations)
```
````

### DSI Report Output

Similar structure to AVQI:

```r
dsi_result <- list(
  metadata = data.frame(
    patient_name = "Fredrik Karlsson",
    date_of_birth = "1975-12-31",
    assessment_date = "2021-12-31"
  ),
  measurements = data.frame(
    measure = c("Maximum Phonation Time (MPT)",
                "Highest F0",
                "Softest Intensity (I-low)",
                "Jitter (ppq5)"),
    value = c(mpt, foh, imin, jitter_ppq5),
    unit = c("s", "Hz", "dB", "%")
  ),
  dsi_score = dsi_value,
  interpretation = ifelse(dsi_value < 1.6, 
                         "Dysphonic voice", 
                         "Normal voice")
)

class(dsi_result) <- c("dsi", "list")
```

---

## Part 5: Implementation Phases

### Phase 1: Critical Missing Functionality (Week 1-2)

**Priority**: Implement blockers for AVQI/DSI

1. **Voice Report Implementation** (5 days)
   - File: `src/pointprocess_wrappers.cpp`
   - Wrap `Sound_PointProcess_Pitch_voiceReport()`
   - Return all jitter/shimmer metrics
   - Test against Praat output

2. **CPPS Implementation** (4 days)
   - File: `src/powercepstrum_wrappers.cpp`
   - Implement `PowerCepstrum$get_cpps()`
   - Implement `PowerCepstrogram` class
   - Implement `PowerCepstrogram$get_cpps()`
   - Validate against Praat CPPS values

3. **Voice Activity Detection** (3 days)
   - File: `src/vad_wrappers.cpp`, `R/vad.R`
   - Wrap `Sound_to_TextGrid_detectSilences()`
   - Implement `TextGrid$extract_intervals_where()`
   - Test concatenation of voiced segments

**Deliverable**: All CRITICAL missing functions implemented and tested

### Phase 2: AVQI Implementation (Week 3)

**Files**: `R/avqi.R`, `R/plot-avqi.R`

1. **Core AVQI Function** (3 days)
```r
compute_avqi <- function(
  cs_files,                 # Continuous speech files
  sv_files,                 # Sustained vowel files
  patient_name = "",
  date_of_birth = "",
  assessment_date = Sys.Date(),
  generate_plots = TRUE
) {
  # 1. Load and concatenate files
  # 2. High-pass filter
  # 3. Extract voiced segments from CS
  # 4. Concatenate SV and voiced CS
  # 5. Compute 6 acoustic measures:
  #    - CPPS (Smoothed Cepstral Peak Prominence)
  #    - Shimmer Local
  #    - Shimmer Local dB
  #    - LTAS Slope
  #    - LTAS Tilt (H1-A3)
  #    - HNR (Harmonics-to-Noise Ratio)
  # 6. Calculate AVQI score
  # 7. Generate plots if requested
  # 8. Return avqi object
}
```

2. **AVQI Plotting Functions** (2 days)
```r
plot.avqi <- function(x, which = c("all", "waveform", "spectrogram", "cepstrogram"), ...) {
  # ggplot2 implementations
}

autoplot.avqi <- function(object, ...) {
  # ggplot2 implementation using patchwork for multi-panel
}
```

3. **Testing & Validation** (2 days)
   - Compare with superassp AVQI reference values
   - Ensure numerical accuracy
   - Document differences from Praat (if any)

**Deliverable**: Complete AVQI implementation with visualization

### Phase 3: DSI Implementation (Week 4)

**Files**: `R/dsi.R`, `R/plot-dsi.R`

1. **Core DSI Function** (2 days)
```r
compute_dsi <- function(
  mpt_files,                # Maximum phonation time recordings
  im_files,                 # Soft phonation recordings  
  fh_files,                 # High pitch recordings
  ppq_files,                # Sustained vowel for jitter
  patient_name = "",
  date_of_birth = "",
  assessment_date = Sys.Date(),
  calibration = 0,
  apply_calibration = FALSE,
  generate_plots = TRUE
) {
  # 1. Determine MPT (maximum duration)
  # 2. Compute I-low (softest voiced intensity)
  # 3. Compute F0-high (maximum pitch)
  # 4. Compute Jitter ppq5
  # 5. Calculate DSI: 1.127 + 0.164*mpt - 0.038*il + 0.0053*fh - 5.30*ppq
  # 6. Generate plots
  # 7. Return dsi object
}
```

2. **DSI Plotting Functions** (2 days)
```r
plot.dsi <- function(x, which = c("all", "score", "pitch", "intensity"), ...) {
  # ggplot2 implementations
}

autoplot.dsi <- function(object, ...) {
  # Comprehensive multi-panel report
}
```

3. **Testing & Validation** (1 day)

**Deliverable**: Complete DSI implementation with visualization

### Phase 4: Documentation & Examples (Week 5)

1. **Vignettes** (3 days)
   - `vignettes/avqi.Rmd`: Complete AVQI tutorial
   - `vignettes/dsi.Rmd`: Complete DSI tutorial
   - `vignettes/voice-quality-indices.Rmd`: Overview of both

2. **Function Documentation** (2 days)
   - Roxygen2 documentation for all functions
   - Examples using included test data

3. **Test Data** (1 day)
   - Include minimal test recordings in `inst/extdata/`
   - Create unit tests with expected values

4. **Migration Guide** (1 day)
   - `inst/doc/praat-to-speaker-avqi-dsi.md`
   - Line-by-line comparison with Praat scripts

**Deliverable**: Production-ready AVQI/DSI functionality

---

## Part 6: Testing Strategy

### Unit Tests

**File**: `tests/testthat/test-avqi.R`
```r
test_that("AVQI computes correctly", {
  # Use known reference files
  cs_file <- system.file("extdata/test_cs.wav", package = "speaker")
  sv_file <- system.file("extdata/test_sv.wav", package = "speaker")
  
  result <- compute_avqi(cs_files = cs_file, sv_files = sv_file,
                        generate_plots = FALSE)
  
  # Compare with known reference value
  expect_equal(result$avqi_score, 3.47, tolerance = 0.1)
  expect_equal(result$acoustics$value[1], 15.2, tolerance = 0.5)  # CPPS
})
```

**File**: `tests/testthat/test-dsi.R`
```r
test_that("DSI computes correctly", {
  # Use known reference files
  mpt <- system.file("extdata/test_mpt.wav", package = "speaker")
  im <- system.file("extdata/test_im.wav", package = "speaker")
  fh <- system.file("extdata/test_fh.wav", package = "speaker")
  ppq <- system.file("extdata/test_ppq.wav", package = "speaker")
  
  result <- compute_dsi(mpt_files = mpt, im_files = im,
                       fh_files = fh, ppq_files = ppq,
                       generate_plots = FALSE)
  
  expect_equal(result$dsi_score, 2.15, tolerance = 0.1)
})
```

### Integration Tests

Compare outputs with superassp package using identical input files.

---

## Part 7: Package Dependencies

Add to `DESCRIPTION`:

```
Imports:
    ggplot2 (>= 3.4.0),
    patchwork (>= 1.1.0),
    scales,
    viridisLite
Suggests:
    knitr,
    rmarkdown,
    testthat (>= 3.0.0)
VignetteBuilder: knitr
```

---

## Part 8: File Structure

```
speaker/
├── R/
│   ├── avqi.R                    # AVQI computation
│   ├── dsi.R                     # DSI computation
│   ├── plot-avqi.R               # AVQI ggplot2 plots
│   ├── plot-dsi.R                # DSI ggplot2 plots
│   ├── vad.R                     # Voice activity detection (R interface)
│   └── voice-quality.R           # Shared utilities
├── src/
│   ├── vad_wrappers.cpp          # VAD C++ wrappers
│   ├── pointprocess_wrappers.cpp # Add voice_report
│   └── powercepstrum_wrappers.cpp# Add CPPS methods
├── inst/
│   ├── extdata/
│   │   ├── test_cs.wav           # Test continuous speech
│   │   ├── test_sv.wav           # Test sustained vowel
│   │   ├── test_mpt.wav          # Test max phonation
│   │   └── ...
│   └── rmarkdown/
│       └── templates/
│           ├── avqi_report/      # AVQI R Markdown template
│           └── dsi_report/       # DSI R Markdown template
├── vignettes/
│   ├── avqi.Rmd
│   ├── dsi.Rmd
│   └── voice-quality-indices.Rmd
└── tests/
    └── testthat/
        ├── test-avqi.R
        ├── test-dsi.R
        └── test-voice-report.R
```

---

## Part 9: Example Usage

### AVQI Example

```r
library(speaker)

# Compute AVQI from files
avqi_result <- compute_avqi(
  cs_files = c("recording1_cs.wav", "recording2_cs.wav"),
  sv_files = c("recording1_sv.wav", "recording2_sv.wav"),
  patient_name = "John Doe",
  date_of_birth = "1980-05-15",
  assessment_date = "2025-01-15",
  generate_plots = TRUE
)

# View results
print(avqi_result)

# Plot visualizations
plot(avqi_result, which = "all")

# Generate HTML report
generate_avqi_report(avqi_result, output_file = "john_doe_avqi.html")

# Export to CSV
write.csv(avqi_result$acoustics, "avqi_measures.csv", row.names = FALSE)
```

### DSI Example

```r
library(speaker)

# Compute DSI from files
dsi_result <- compute_dsi(
  mpt_files = "mpt_recording.wav",
  im_files = c("soft1.wav", "soft2.wav"),
  fh_files = c("high1.wav", "high2.wav"),
  ppq_files = "sustained_vowel.wav",
  patient_name = "Jane Smith",
  calibration = 10,
  apply_calibration = TRUE
)

# View results
print(dsi_result)

# Plot DSI score
plot(dsi_result, which = "score")

# Generate report
generate_dsi_report(dsi_result, output_file = "jane_smith_dsi.pdf", format = "pdf")
```

---

## Part 10: Success Criteria

- [ ] All CRITICAL missing functions implemented and tested
- [ ] AVQI computes within 5% of Praat reference values
- [ ] DSI computes within 5% of Praat reference values
- [ ] All ggplot2 visualizations implemented
- [ ] R Markdown report templates functional
- [ ] Complete documentation with examples
- [ ] Unit tests achieve >90% coverage
- [ ] Integration tests pass with superassp reference data
- [ ] Package builds without warnings on R CMD check
- [ ] Vignettes render successfully

---

## References

1. Maryn, Y., Corthals, P., Van Cauwenberge, P., Roy, N., & De Bodt, M. (2010). Toward improved ecological validity in the acoustic measurement of overall voice quality: Combining continuous speech and sustained vowels. *Journal of Voice*, 24(5), 540-555.

2. Barsties, B., & Maryn, Y. (2015). The improvement of internal consistency of the Acoustic Voice Quality Index. *American Journal of Otolaryngology*, 36(5), 647-656.

3. Wuyts, F. L., De Bodt, M. S., Molenberghs, G., Remacle, M., Heylen, L., Millet, B., ... & Heyning, P. H. (2000). The dysphonia severity index: an objective measure of vocal quality based on a multiparameter approach. *Journal of Speech, Language, and Hearing Research*, 43(3), 796-809.

---

**Document Status**: DRAFT - Ready for implementation  
**Next Step**: Phase 1 - Implement critical missing functionality  
**Estimated Completion**: 5 weeks from start
