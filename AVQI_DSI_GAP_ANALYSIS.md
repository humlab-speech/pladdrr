# AVQI and DSI Gap Analysis - speaker Package
**Date**: 2025-11-22  
**Analysis**: Comparison of Praat AVQI301 and DSI201 scripts vs speaker package implementation

## Executive Summary

The `speaker` package has successfully implemented the **core acoustic algorithms** for both AVQI and DSI computation. However, there are significant gaps in:

1. **Pre-processing pipelines** (mono conversion, resampling, filtering)
2. **Voice Activity Detection** (VAD) robustness and adaptivity
3. **Analysis segment selection** for optimal measurement
4. **Visualization and reporting** features matching Praat's illustrated versions

This document outlines what needs to be added to achieve full protocol compliance and feature parity.

---

## 1. MISSING DSP CAPABILITIES

### AVQI (AVQI301.praat vs R/avqi.R)

#### 1.1 Pre-processing Pipeline

**Praat Script:**
```praat
# Explicit pre-processing steps:
1. Convert to mono (if stereo)
2. Resample to 44100 Hz
3. Filter (stop Hann band) 0-34 Hz, 0.1 smoothing
```

**speaker Package:**
- ❌ No explicit mono conversion
- ❌ No resampling to standardized rate
- ❌ High-pass filtering not implemented

**Required Implementation:**
```r
# Add to .compute_avqi_vowel and .compute_avqi_speech:
sound <- sound$convert_to_mono()  # If stereo
sound <- sound$resample(44100, 50)  # 44.1 kHz, precision 50
sound <- sound$filter_stop_hann_band(0, 34, 0.1)  # Remove DC offset
```

**Priority**: **HIGH** - Required for protocol compliance

---

#### 1.2 Voice Activity Detection (Continuous Speech)

**Praat Script:**
```praat
# Adaptive VAD based on signal's own statistics:
1. Create Intensity object (60 Hz time step)
2. Get maximum intensity
3. Set dynamic threshold: max_intensity - 25 dB
4. To TextGrid (silences) using threshold
5. Extract only "sounding" intervals
6. Concatenate voiced segments
```

**speaker Package:**
```r
# Current implementation:
voiced_sound <- extract_voiced_segments(
  sound,
  silence_threshold = -25,  # FIXED threshold
  ...
)
```

**Problem**: Uses **fixed -25 dB threshold** instead of **adaptive threshold** based on signal's peak intensity.

**Required Enhancement:**
```r
# Adaptive VAD:
intensity <- sound$to_intensity(minimum_pitch = 50, time_step = 0.0)
max_intensity <- intensity$get_maximum(0, 0)
adaptive_threshold <- max_intensity - 25  # Dynamic threshold

voiced_sound <- extract_voiced_segments(
  sound,
  silence_threshold = adaptive_threshold,  # Adaptive!
  ...
)
```

**Priority**: **HIGH** - Critical for continuous speech accuracy

---

#### 1.3 Optimal Vowel Segment Selection

**Praat Script:**
```praat
# Find most stable 1-second segment:
To Pitch (cc)... 0.01 75 600
select Sound sv
plus Pitch sv
noprogress To PointProcess (cc)
select Pitch sv
Get standard deviation: 0, 0

# Iterate through 1s windows, find minimum pitch SD
# Extract that specific 1s segment for analysis
```

**speaker Package:**
```r
# Current implementation:
# Simply extract middle 3 seconds
mid_start <- (duration - 3.0) / 2
sound_analysis <- sound$extract_part(mid_start, mid_end)
```

**Problem**: Doesn't identify the **most stable** segment; may include onset/offset artifacts.

**Required Enhancement:**
```r
.find_most_stable_segment <- function(sound, window_size = 1.0, f0_floor = 75, f0_ceiling = 600) {
  duration <- sound$get_duration()
  pitch <- sound$to_pitch(0.01, f0_floor, f0_ceiling)
  
  # Find 1s window with minimum pitch SD
  best_start <- 0
  min_sd <- Inf
  
  for (start in seq(0, duration - window_size, by = 0.1)) {
    end <- start + window_size
    sd <- pitch$get_standard_deviation(start, end)
    if (!is.na(sd) && sd < min_sd) {
      min_sd <- sd
      best_start <- start
    }
  }
  
  sound$extract_part(best_start, best_start + window_size)
}
```

**Priority**: **MEDIUM** - Improves measurement accuracy

---

### DSI (DSI201.praat vs R/dsi.R)

#### 1.4 Maximum Phonation Time (MPT) - Trimming Logic

**Praat Script:**
```praat
# MPT: Total duration with onset/offset trimming
duration = Get total duration
mpt = duration - 0.05 - 0.05  # Trim 50ms from each end
```

**speaker Package:**
```r
# Current implementation:
mpt <- sound$get_duration()  # No trimming
```

**Problem**: Includes silence/noise at onset and offset.

**Required Enhancement:**
```r
# Auto-trim based on intensity:
.compute_mpt_with_trimming <- function(sound) {
  intensity <- sound$to_intensity(minimum_pitch = 50, time_step = 0.001)
  
  # Find voice onset/offset
  threshold <- intensity$get_maximum(0, 0) - 30
  
  duration <- sound$get_duration()
  onset_time <- 0
  offset_time <- duration
  
  # Scan forward for onset
  for (t in seq(0, duration, by = 0.01)) {
    if (intensity$get_value_at_time(t, "nearest") > threshold) {
      onset_time <- t
      break
    }
  }
  
  # Scan backward for offset
  for (t in seq(duration, 0, by = -0.01)) {
    if (intensity$get_value_at_time(t, "nearest") > threshold) {
      offset_time <- t
      break
    }
  }
  
  offset_time - onset_time
}
```

**Priority**: **MEDIUM** - Clinical accuracy

---

#### 1.5 Percentile-Based F0-high and I-low

**Praat Script:**
```praat
# F0-high: Use 95th percentile (not absolute max)
To Pitch (cc)... 0 70 1300
maximumF0 = Get quantile: 0, 0, 0.95, "Hertz"

# I-low: Use 5th percentile (not absolute min)
minimumIntensity = Get quantile: 0, 0, 0.05
```

**speaker Package:**
```r
# Current implementation:
f0_high <- pitch$get_maximum(0, 0, "hertz", TRUE)  # Absolute max
i_low <- intensity$get_minimum(0, 0)  # Absolute min
```

**Problem**: **Absolute extrema** are sensitive to outliers and measurement errors.

**Required Enhancement:**
```r
# Need to add quantile methods to Pitch and Intensity R6 classes:
f0_high <- pitch$get_quantile(0, 0, 0.95, "hertz")  # 95th percentile
i_low <- intensity$get_quantile(0, 0, 0.05)  # 5th percentile
```

**Priority**: **HIGH** - Measurement robustness

**C++ Wrapper Needed:**
```cpp
// src/pitch_wrappers.cpp
// [[Rcpp::export]]
double praat_pitch_get_quantile(SEXP xptr, double from_time, double to_time, 
                                 double quantile, std::string unit) {
  Rcpp::XPtr<Pitch> pitch(xptr);
  // Call Pitch_getQuantile() from Praat
}

// src/intensity_wrappers.cpp
// [[Rcpp::export]]
double praat_intensity_get_quantile(SEXP xptr, double from_time, double to_time, 
                                    double quantile) {
  Rcpp::XPtr<Intensity> intensity(xptr);
  // Call Intensity_getQuantile() from Praat
}
```

---

## 2. MISSING REPORT/VISUALIZATION FEATURES

### AVQI Illustrated Report

**Praat Output Components:**
1. ✅ Patient metadata (name, DOB, assessment date)
2. ✅ AVQI score with interpretation
3. ✅ Six component measures tabulated
4. ❌ Waveform with VAD overlay (TextGrid)
5. ❌ Spectrogram (0-4000 Hz)
6. ❌ LTAS with slope/tilt annotations
7. ❌ Power-cepstrogram
8. ❌ Power-cepstrum with tilt line and CPPS peak

**speaker Current Implementation:**
- ✅ `plot_avqi()` - Component bar chart
- ❌ Waveform plot (placeholder only)
- ❌ Spectrogram plot (not implemented)
- ❌ LTAS plot (not implemented)
- ❌ Cepstrogram plot (not implemented)

**Required Additions:**

```r
# R/avqi_dsi_plots.R - New functions needed:

plot_avqi_waveform <- function(sound, vad_textgrid = NULL) {
  # Extract waveform data from Sound object
  # Overlay VAD TextGrid intervals as shaded regions
  # ggplot2 implementation
}

plot_avqi_spectrogram <- function(sound, max_freq = 4000) {
  # Create spectrogram using sound$to_spectrogram()
  # Use ggplot2::geom_raster() for heatmap
  # Add frequency axis 0-4000 Hz
}

plot_avqi_ltas <- function(sound, ltas, slope_value, tilt_value) {
  # Plot LTAS curve
  # Add regression line for slope (0-1000 Hz vs 1000-5000 Hz)
  # Mark H1 and A3 points for tilt
  # Annotate with calculated values
}

plot_avqi_cepstrogram <- function(sound, pitch_floor = 75) {
  # Create PowerCepstrogram
  # Plot as heatmap with quefrency (0.003-0.017 s) vs time
  # Highlight cepstral peak trajectory
}

plot_avqi_cepstrum <- function(sound, time_point = NULL) {
  # Extract PowerCepstrum at specific time
  # Plot amplitude vs quefrency
  # Draw tilt line
  # Mark CPPS peak
}
```

**Priority**: **HIGH** - Clinical reporting standard

---

### DSI Illustrated Report

**Praat Output Components:**
1. ✅ Patient metadata
2. ✅ DSI score with color-coded interpretation scale
3. ✅ Four component measures tabulated
4. ❌ Pitch contour with F0-high marked
5. ❌ Intensity contour with I-low marked
6. ❌ Combined pitch + intensity time-aligned plot

**speaker Current Implementation:**
- ✅ `plot_dsi()` - Component bar chart
- ✅ `plot_dsi()` - Score interpretation scale
- ❌ Contour plots (placeholder only)

**Required Additions:**

```r
# R/avqi_dsi_plots.R

plot_dsi_contours <- function(sound, pitch, intensity, f0_high, i_low) {
  # Extract pitch contour data
  pitch_data <- data.frame(
    time = pitch$get_frame_times(),
    f0 = sapply(pitch$get_frame_times(), function(t) pitch$get_value_at_time(t))
  )
  
  # Extract intensity contour data
  intensity_data <- data.frame(
    time = intensity$get_frame_times(),
    db = sapply(intensity$get_frame_times(), function(t) intensity$get_value_at_time(t))
  )
  
  # Create dual-axis plot
  p1 <- ggplot(pitch_data, aes(x = time, y = f0)) +
    geom_line(color = "blue") +
    geom_hline(yintercept = f0_high, linetype = "dashed", color = "red") +
    annotate("text", x = max(pitch_data$time) * 0.9, y = f0_high, 
             label = sprintf("F0-high: %.1f Hz", f0_high), vjust = -0.5) +
    labs(y = "F0 (Hz)", title = "Pitch and Intensity Contours")
  
  p2 <- ggplot(intensity_data, aes(x = time, y = db)) +
    geom_line(color = "darkgreen") +
    geom_hline(yintercept = i_low, linetype = "dashed", color = "red") +
    annotate("text", x = max(intensity_data$time) * 0.9, y = i_low,
             label = sprintf("I-low: %.1f dB", i_low), vjust = 1.5) +
    labs(x = "Time (s)", y = "Intensity (dB SPL)")
  
  # Combine using patchwork or cowplot
  p1 / p2
}
```

**Priority**: **HIGH** - Essential for clinical interpretation

---

## 3. IMPLEMENTATION ROADMAP

### Phase 1: Critical DSP Functions (Week 1-2)

**Objective**: Ensure protocol compliance and measurement accuracy

1. **Pre-processing Pipeline**
   - [ ] Add `Sound$convert_to_mono()` method
   - [ ] Add `Sound$resample()` method  
   - [ ] Add `Sound$filter_stop_hann_band()` method
   - [ ] Update AVQI/DSI to use pre-processing

2. **Adaptive VAD for AVQI**
   - [ ] Implement adaptive threshold VAD
   - [ ] Update `extract_voiced_segments()` to accept dynamic threshold
   - [ ] Validate against Praat AVQI script

3. **Percentile Methods for DSI**
   - [ ] Add `Pitch$get_quantile()` C++ wrapper
   - [ ] Add `Intensity$get_quantile()` C++ wrapper
   - [ ] Update DSI to use 95th/5th percentiles
   - [ ] Add R6 methods to Pitch and Intensity classes

**Deliverable**: Updated `compute_avqi()` and `compute_dsi()` with full protocol compliance

---

### Phase 2: Enhanced Segment Selection (Week 3)

**Objective**: Improve measurement precision

1. **AVQI Vowel Analysis**
   - [ ] Implement `.find_most_stable_segment()` function
   - [ ] Add pitch SD scanning logic
   - [ ] Update `.compute_avqi_vowel()` to use optimal segment
   - [ ] Add verbose output showing selected segment

2. **DSI MPT Measurement**
   - [ ] Implement `.compute_mpt_with_trimming()` function
   - [ ] Add intensity-based onset/offset detection
   - [ ] Update `compute_dsi()` to use trimmed MPT
   - [ ] Add option for manual vs automatic trimming

**Deliverable**: More robust and accurate measurements

---

### Phase 3: Report Visualization (Week 4-5)

**Objective**: Match Praat's illustrated report functionality

#### 3.1 AVQI Visualizations

1. **Waveform with VAD**
   - [ ] Extract amplitude data from Sound object
   - [ ] Create `plot_avqi_waveform()` with ggplot2
   - [ ] Add TextGrid overlay for voiced segments
   - [ ] Add time markers and annotations

2. **Spectrogram**
   - [ ] Use `sound$to_spectrogram()` for data
   - [ ] Create `plot_avqi_spectrogram()` with geom_raster
   - [ ] Add frequency range 0-4000 Hz
   - [ ] Add color scale (dB) with legend

3. **LTAS with Annotations**
   - [ ] Create `plot_avqi_ltas()` function
   - [ ] Plot LTAS curve
   - [ ] Add slope regression line
   - [ ] Mark H1 (F0) and A3 (F3) points
   - [ ] Annotate slope and tilt values

4. **Cepstrum Plots**
   - [ ] Create `plot_avqi_cepstrogram()` for time-quefrency heatmap
   - [ ] Create `plot_avqi_cepstrum()` for single-frame spectrum
   - [ ] Add tilt line and CPPS peak marker
   - [ ] Quefrency range: 0.003-0.017 s (60-330 Hz)

5. **Integrated Report**
   - [ ] Update `create_avqi_report_plot()` to combine all panels
   - [ ] Use `patchwork` or `cowplot` for multi-panel layout
   - [ ] Match Praat layout: waveform, spectrogram, LTAS, cepstrum
   - [ ] Add metadata header and footer

#### 3.2 DSI Visualizations

1. **Pitch Contour with F0-high**
   - [ ] Extract pitch frame data
   - [ ] Create `plot_dsi_pitch_contour()` 
   - [ ] Add horizontal line at F0-high with annotation

2. **Intensity Contour with I-low**
   - [ ] Extract intensity frame data
   - [ ] Create `plot_dsi_intensity_contour()`
   - [ ] Add horizontal line at I-low with annotation

3. **Combined Contours**
   - [ ] Update `plot_dsi_contours()` with real implementation
   - [ ] Dual-axis plot: F0 (top) + Intensity (bottom)
   - [ ] Time-aligned with vertical grid
   - [ ] Mark measurement points clearly

4. **Integrated Report**
   - [ ] Update `create_dsi_report_plot()` to include:
     - Component bar chart
     - Combined contour plot
     - Score interpretation scale
   - [ ] Export as multi-panel figure

**Deliverable**: Publication-ready report plots matching Praat output

---

### Phase 4: Additional Enhancements (Week 6)

1. **Batch Processing Support**
   - [ ] Add directory-based batch AVQI/DSI computation
   - [ ] CSV export with all components
   - [ ] Automated report generation for multiple subjects

2. **Clinical Features**
   - [ ] Add calibration support for intensity (DSI requirement)
   - [ ] Add metadata fields (patient info, date, assessor)
   - [ ] Generate clinical report PDFs with plots + tables

3. **Validation and Testing**
   - [ ] Compare with Praat outputs (tolerance testing)
   - [ ] Add test suite with reference audio files
   - [ ] Document expected differences (if any)

---

## 4. NEW R6 METHODS NEEDED

### Sound Class Extensions

```r
# R/sound-r6-new.R
Sound$set("public", "convert_to_mono", function() {
  # Call praat_sound_convert_to_mono()
})

Sound$set("public", "resample", function(sampling_frequency, precision = 50) {
  # Call praat_sound_resample()
})

Sound$set("public", "filter_stop_hann_band", function(from_freq, to_freq, smoothing) {
  # Call praat_sound_filter_stop_hann_band()
})
```

### Pitch Class Extensions

```r
# R/pitch-r6.R
Pitch$set("public", "get_quantile", function(from_time, to_time, quantile, unit = "hertz") {
  # Call praat_pitch_get_quantile()
})

Pitch$set("public", "get_standard_deviation", function(from_time, to_time) {
  # Call praat_pitch_get_standard_deviation()
})

Pitch$set("public", "get_frame_times", function() {
  # Return vector of all frame times for plotting
})
```

### Intensity Class Extensions

```r
# R/intensity-r6.R
Intensity$set("public", "get_quantile", function(from_time, to_time, quantile) {
  # Call praat_intensity_get_quantile()
})

Intensity$set("public", "get_frame_times", function() {
  # Return vector of all frame times for plotting
})
```

### Spectrogram Class (if not fully implemented)

```r
# R/spectrogram-r6.R
Spectrogram$set("public", "as_matrix", function(freq_min = 0, freq_max = 4000) {
  # Return time × frequency matrix for ggplot2 heatmap
})
```

### PowerCepstrogram Class Extensions

```r
# R/powercepstrum-r6.R
PowerCepstrogram$set("public", "as_matrix", function() {
  # Return time × quefrency matrix for plotting
})

PowerCepstrogram$set("public", "extract_slice", function(time) {
  # Extract single PowerCepstrum at specific time
})
```

---

## 5. NEW C++ WRAPPERS NEEDED

### src/sound_wrappers.cpp

```cpp
// [[Rcpp::export]]
SEXP praat_sound_convert_to_mono(SEXP xptr) {
  Rcpp::XPtr<Sound> sound(xptr);
  autoSound mono = Sound_convertToMono(sound);
  return Rcpp::XPtr<Sound>(mono.releaseToAmbiguousOwner());
}

// [[Rcpp::export]]
SEXP praat_sound_resample(SEXP xptr, double sampling_frequency, int precision) {
  Rcpp::XPtr<Sound> sound(xptr);
  autoSound resampled = Sound_resample(sound, sampling_frequency, precision);
  return Rcpp::XPtr<Sound>(resampled.releaseToAmbiguousOwner());
}

// [[Rcpp::export]]
SEXP praat_sound_filter_stop_hann_band(SEXP xptr, double from_freq, 
                                       double to_freq, double smoothing) {
  Rcpp::XPtr<Sound> sound(xptr);
  autoSound filtered = Sound_filterStopHannBand(sound, from_freq, to_freq, smoothing);
  return Rcpp::XPtr<Sound>(filtered.releaseToAmbiguousOwner());
}
```

### src/pitch_wrappers.cpp

```cpp
// [[Rcpp::export]]
double praat_pitch_get_quantile(SEXP xptr, double from_time, double to_time,
                                double quantile, std::string unit) {
  Rcpp::XPtr<Pitch> pitch(xptr);
  int unit_code = (unit == "hertz") ? kPitch_unit::HERTZ : kPitch_unit::SEMITONES_1;
  return Pitch_getQuantile(pitch, from_time, to_time, quantile, unit_code);
}

// [[Rcpp::export]]
double praat_pitch_get_standard_deviation(SEXP xptr, double from_time, double to_time) {
  Rcpp::XPtr<Pitch> pitch(xptr);
  return Pitch_getStandardDeviation(pitch, from_time, to_time, kPitch_unit::HERTZ);
}

// [[Rcpp::export]]
Rcpp::NumericVector praat_pitch_get_frame_times(SEXP xptr) {
  Rcpp::XPtr<Pitch> pitch(xptr);
  long n_frames = pitch->nx;
  Rcpp::NumericVector times(n_frames);
  for (long i = 1; i <= n_frames; i++) {
    times[i-1] = Sampled_indexToX(pitch, i);
  }
  return times;
}
```

### src/intensity_wrappers.cpp

```cpp
// [[Rcpp::export]]
double praat_intensity_get_quantile(SEXP xptr, double from_time, double to_time,
                                    double quantile) {
  Rcpp::XPtr<Intensity> intensity(xptr);
  return Intensity_getQuantile(intensity, from_time, to_time, quantile);
}

// [[Rcpp::export]]
Rcpp::NumericVector praat_intensity_get_frame_times(SEXP xptr) {
  Rcpp::XPtr<Intensity> intensity(xptr);
  long n_frames = intensity->nx;
  Rcpp::NumericVector times(n_frames);
  for (long i = 1; i <= n_frames; i++) {
    times[i-1] = Sampled_indexToX(intensity, i);
  }
  return times;
}
```

---

## 6. SUCCESS CRITERIA

### Technical Validation

1. **Measurement Accuracy**
   - ✓ AVQI scores within ±0.10 of Praat script (on reference dataset)
   - ✓ DSI scores within ±0.15 of Praat script
   - ✓ All six AVQI components within acceptable tolerances
   - ✓ All four DSI components within acceptable tolerances

2. **Protocol Compliance**
   - ✓ Pre-processing matches AVQI301/DSI201 specifications
   - ✓ VAD uses adaptive thresholding
   - ✓ Segment selection follows optimal stability criteria
   - ✓ Percentile-based measurements for robustness

3. **Visualization Completeness**
   - ✓ All Praat "illustrated version" plots replicated
   - ✓ ggplot2-based, publication-quality figures
   - ✓ Annotations and legends match clinical standards
   - ✓ Export to PNG, PDF, SVG with high DPI

### Documentation

1. **User Documentation**
   - ✓ Complete vignettes for AVQI and DSI workflows
   - ✓ Recording protocol instructions
   - ✓ Interpretation guidelines
   - ✓ Example analyses with real audio

2. **Developer Documentation**
   - ✓ C++ wrapper documentation
   - ✓ R6 method documentation
   - ✓ Plot customization guide

---

## 7. ESTIMATED EFFORT

| Phase | Tasks | Effort (Days) | Priority |
|-------|-------|---------------|----------|
| 1. Critical DSP | Pre-processing, Adaptive VAD, Percentiles | 8-10 | HIGH |
| 2. Segment Selection | Optimal vowel, MPT trimming | 3-4 | MEDIUM |
| 3. AVQI Visualization | 5 plot types, integrated report | 6-8 | HIGH |
| 4. DSI Visualization | 3 plot types, integrated report | 4-5 | HIGH |
| 5. Enhancements | Batch, calibration, validation | 5-6 | MEDIUM |
| **TOTAL** | | **26-33 days** | |

**Target**: 5-6 weeks full-time development

---

## 8. CONCLUSION

The `speaker` package has **excellent foundations** for AVQI and DSI computation. The core algorithms are correctly implemented. To achieve **full clinical and research readiness**, we need to:

1. **Add missing pre-processing steps** for protocol compliance
2. **Enhance measurement robustness** with adaptive VAD and percentiles
3. **Implement comprehensive visualizations** matching Praat's illustrated reports
4. **Validate against reference data** to ensure accuracy

**Recommendation**: Prioritize **Phase 1** (Critical DSP) and **Phase 3** (Visualizations) for immediate impact. These are the most visible gaps for clinical users migrating from Praat.

---

**Analysis completed**: 2025-11-22  
**Gemini CLI used for comprehensive codebase scanning**  
**Next step**: Begin Phase 1 implementation
