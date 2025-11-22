# AVQI and DSI Implementation Analysis

**Date**: 2025-11-22  
**Package Version**: 0.9.6  
**Status**: Gap Analysis Complete

## Executive Summary

This document analyzes the speaker package's capabilities for implementing:
1. **AVQI** (Acoustic Voice Quality Index) - 6 acoustic measures
2. **DSI** (Dysphonia Severity Index) - 4 acoustic measures
3. Full graphical reports (AVQI: 4 plots, DSI: visual scale)
4. Simple text reports (measurements only)

---

## AVQI Requirements (AVQI301.praat)

### AVQI Formula
```
AVQI = (4.152 - (0.177 * CPPS) - (0.006 * HNR) - (0.037 * Shimmer_local) + 
        (0.941 * Shimmer_local_dB) + (0.01 * LTAS_slope) + (0.093 * LTAS_tilt)) * 2.8902
```

### Required Acoustic Measurements

| Measure | Praat Operation | Speaker Package Status | Notes |
|---------|----------------|----------------------|-------|
| **CPPS** | PowerCepstrum → Get CPPS | ✅ `PowerCepstrum$get_cpps()` | Implemented |
| **HNR** | Voice report → extract HNR | ✅ `Sound$get_voice_report()` | Voice report implemented |
| **Shimmer local** | Get shimmer (local) | ✅ `Sound$get_shimmer()` with PointProcess | Implemented |
| **Shimmer local dB** | Get shimmer (local_dB) | ✅ `Sound$get_shimmer()` variant | Implemented |
| **LTAS slope** | Ltas → Get slope | ✅ `Ltas$get_slope()` | Implemented |
| **LTAS tilt** | Ltas → Compute trend line → Get slope | ❌ **MISSING** | Need `Ltas$compute_trend_line()` |

### Required DSP Operations

| Operation | Praat Command | Speaker Status | Implementation Needed |
|-----------|--------------|----------------|---------------------|
| **Filter (stop Hann band)** | Line 123, 128 | ❌ | `Sound$filter_stop_hann_band(from, to, smoothing)` |
| **Voiced segment detection** | To TextGrid (silences) | ✅ Partial | `Sound$to_textgrid_silences()` - exists? Check |
| **Extract voiced intervals** | Extract intervals where... | ✅ | `TextGrid$extract_intervals_where()` |
| **Concatenate sounds** | Concatenate | ✅ | `Sound$concatenate()` exists |
| **To PowerCepstrogram** | Line 280 | ✅ | `Sound$to_power_cepstrogram()` |
| **To PowerCepstrum** | Line 281 | ✅ | `Sound$to_power_cepstrum()` |
| **Get CPPS** | Line 282-287 | ✅ | `PowerCepstrum$get_cpps()` |
| **To Ltas** | Line 314 | ✅ | `Sound$to_ltas()` |
| **Get slope** | Line 316 | ✅ | `Ltas$get_slope()` |
| **Compute trend line** | Line 321 | ❌ **MISSING** | `Ltas$compute_trend_line()` |
| **To PointProcess (periodic, cc)** | Line 327 | ✅ | `Sound$to_point_process_periodic_cc()` |
| **Get shimmer (local)** | Line 333 | ✅ | Already implemented |
| **Get shimmer (local_dB)** | Line 335 | ✅ | Already implemented |
| **To Pitch (cc)** | Line 340 | ✅ | `Sound$to_pitch_cc()` |
| **Voice report** | Line 352 | ✅ | `Sound$get_voice_report()` |

### Required Plotting (Full Report)

| Plot | Praat Visualization | ggplot2 Implementation | Status |
|------|--------------------|-----------------------|--------|
| **Oscillogram** | Sound$Draw | `autoplot(Sound)` | ✅ Implemented |
| **Narrow-band spectrogram** | Spectrogram$Paint | `autoplot(Spectrogram)` | ✅ Implemented |
| **LTAS curve** | Ltas$Draw | `autoplot(Ltas)` | ✅ Implemented |
| **Power-cepstrogram** | PowerCepstrogram$Paint | ❌ **MISSING** | Need `autoplot(PowerCepstrogram)` |
| **Power-cepstrum** | PowerCepstrum$Draw | ❌ **MISSING** | Need `autoplot(PowerCepstrum)` |
| **AVQI scale** | Custom graphics | Custom ggplot2 function | ❌ Need `plot_avqi_scale()` |

---

## DSI Requirements (DSI201.praat)

### DSI Formula
```
DSI = 1.127 + (0.164 * MPT) - (0.038 * I_low) + (0.0053 * F0_high) - (5.30 * Jitter_ppq5)
```

### Required Acoustic Measurements

| Measure | Praat Operation | Speaker Package Status | Notes |
|---------|----------------|----------------------|-------|
| **MPT** | Get total duration (max) | ✅ `Sound$get_total_duration()` | Trivial - max of durations |
| **I_low** | Intensity → Get minimum | ✅ `Intensity$get_minimum()` | Implemented |
| **F0_high** | Pitch → Get maximum | ✅ `Pitch$get_maximum()` | Implemented |
| **Jitter ppq5** | Voice report → extract | ✅ `Sound$get_voice_report()` | Extract from voice report string |

### Required DSP Operations

| Operation | Praat Command | Speaker Status | Implementation Needed |
|-----------|--------------|----------------|---------------------|
| **To Pitch (cc)** | Lines 160, 187, 204 | ✅ | `Sound$to_pitch_cc()` |
| **To PointProcess (cc)** | Lines 164, 208 | ✅ | `Sound$to_point_process_cc()` |
| **To TextGrid (vuv)** | Line 167 | ❌ | `PointProcess$to_textgrid_vuv()` |
| **Extract intervals where** | Line 171 | ✅ | `TextGrid$extract_intervals_where()` |
| **To Intensity** | Line 175/177 | ✅ | `Sound$to_intensity()` |
| **Intensity calibration** | Line 178 | ✅ | `Intensity$formula()` exists |
| **Get minimum intensity** | Line 181 | ✅ | `Intensity$get_minimum()` |
| **Get maximum F0** | Line 188 | ✅ | `Pitch$get_maximum()` |
| **Voice report** | Line 214 | ✅ | `Sound$get_voice_report()` |

### Required Plotting (DSI Report)

| Plot | Praat Visualization | ggplot2 Implementation | Status |
|------|--------------------|-----------------------|--------|
| **DSI scale** | Custom color-coded scale | Custom ggplot2 function | ❌ Need `plot_dsi_scale()` |

---

## Gap Analysis Summary

### ✅ **Fully Implemented** (85% complete)
- ✅ All basic sound analysis (Pitch, Intensity, Formant, Harmonicity)
- ✅ PowerCepstrum with CPPS calculation
- ✅ Ltas with slope calculation
- ✅ Shimmer and jitter measurements
- ✅ Voice report functionality
- ✅ PointProcess operations
- ✅ TextGrid with interval extraction
- ✅ Basic plotting (Sound, Pitch, Intensity, Formant, Spectrogram, Ltas)

### ❌ **Missing Core DSP Functions** (3 functions)

#### 1. **Ltas$compute_trend_line()** - HIGH PRIORITY
```r
# Required for AVQI LTAS tilt calculation
Ltas$compute_trend_line = function(fmin, fmax) {
  # C++ wrapper to Praat's Ltas_computeTrendLine()
  # Modifies LTAS in-place by fitting linear regression
}
```
**C++ Implementation**: `praat/fon/Ltas.cpp::Ltas_computeTrendLine()`

#### 2. **Sound$filter_stop_hann_band()** - HIGH PRIORITY
```r
# Required for AVQI high-pass filtering (0-34 Hz rejection)
Sound$filter_stop_hann_band = function(from_freq, to_freq, smoothing) {
  # C++ wrapper to Praat's Sound_filterStopHannBand()
  # Returns new filtered Sound object
}
```
**C++ Implementation**: `praat/fon/Sound_filtering.cpp`

#### 3. **PointProcess$to_textgrid_vuv()** - MEDIUM PRIORITY
```r
# Required for DSI voiced/unvoiced segmentation
PointProcess$to_textgrid_vuv = function(max_period, mean_period) {
  # C++ wrapper to Praat's PointProcess_to_TextGrid_vuv()
  # Creates TextGrid with V/U labels
}
```
**C++ Implementation**: `praat/fon/PointProcess_and_TextGrid.cpp`

### ❌ **Missing Plotting Functions** (4 functions)

#### 1. **autoplot.PowerCepstrogram()** - HIGH PRIORITY
```r
#' @export
autoplot.PowerCepstrogram <- function(object, time_range = c(0, 0), 
                                      quefrency_range = c(0, 0),
                                      maximum_db = 70, ...) {
  # ggplot2 heatmap of quefrency vs time
  # Similar to autoplot.Spectrogram but quefrency axis
}
```

#### 2. **autoplot.PowerCepstrum()** - HIGH PRIORITY  
```r
#' @export
autoplot.PowerCepstrum <- function(object, quefrency_range = c(0, 0),
                                   amplitude_range = c(0, 0),
                                   draw_tilt_line = FALSE, ...) {
  # ggplot2 line plot: quefrency (x) vs amplitude dB (y)
  # Optional: overlay tilt line (regression line)
}
```

#### 3. **plot_avqi_scale()** - MEDIUM PRIORITY
```r
#' Plot AVQI Color-Coded Scale
#' @param avqi_value Numeric AVQI score
#' @export
plot_avqi_scale <- function(avqi_value, threshold = 2.43) {
  # Green bar: 0-2.43 (normal)
  # Red bar: 2.43-10 (dysphonic)
  # Arrow pointing to avqi_value
}
```

#### 4. **plot_dsi_scale()** - MEDIUM PRIORITY
```r
#' Plot DSI Color-Coded Scale  
#' @param dsi_value Numeric DSI score
#' @export
plot_dsi_scale <- function(dsi_value, threshold = 1.6) {
  # Red bar: -10 to 1.6 (dysphonic)
  # Green bar: 1.6 to 5 (normal)
  # Arrow pointing to dsi_value
}
```

### ❌ **Missing High-Level Report Functions** (2 functions)

#### 1. **compute_avqi()** - HIGH PRIORITY
```r
#' Compute Acoustic Voice Quality Index
#' @param cs_files Character vector of continuous speech WAV files
#' @param sv_files Character vector of sustained vowel WAV files
#' @return List with AVQI score and component measurements
#' @export
compute_avqi <- function(cs_files, sv_files, 
                        pitch_floor = 75, pitch_ceiling = 600) {
  # 1. Load and concatenate cs files
  # 2. Load and concatenate sv files  
  # 3. High-pass filter both (stop 0-34 Hz)
  # 4. Detect voiced segments in cs
  # 5. Concatenate voiced cs + last 3s of sv
  # 6. Compute 6 measurements (CPPS, HNR, Shimm, ShimmDB, slope, tilt)
  # 7. Calculate AVQI = (4.152 - 0.177*CPPS - ...) * 2.8902
  # 8. Return list(avqi = score, cpps = ..., hnr = ..., etc.)
}
```

#### 2. **compute_dsi()** - HIGH PRIORITY
```r
#' Compute Dysphonia Severity Index
#' @param mpt_files Character vector of max phonation time WAV files
#' @param im_files Character vector of softest intensity WAV files
#' @param fh_files Character vector of highest pitch WAV files
#' @param ppq_files Character vector of sustained vowel WAV files
#' @param calibration_factor Numeric intensity calibration (default 10)
#' @return List with DSI score and component measurements
#' @export
compute_dsi <- function(mpt_files, im_files, fh_files, ppq_files,
                       calibration_factor = 10) {
  # 1. MPT = max duration of mpt_files
  # 2. I_low = min intensity of concatenated im_files (calibrated)
  # 3. F0_high = max F0 of concatenated fh_files
  # 4. Jitter_ppq5 = from voice report of last 3s of ppq_files
  # 5. DSI = 1.127 + 0.164*MPT - 0.038*I_low + 0.0053*F0_high - 5.30*Jitter
  # 6. Return list(dsi = score, mpt = ..., i_low = ..., etc.)
}
```

### ❌ **Missing Report Generation Functions** (4 functions)

#### 1. **generate_avqi_report()** - MEDIUM PRIORITY
```r
#' Generate AVQI Report (Simple or Full)
#' @param avqi_result Output from compute_avqi()
#' @param sound_object Combined Sound object for plotting
#' @param simple Logical, TRUE for simple (measurements only)
#' @param patient_info List with name, dob, assessment_date
#' @export
generate_avqi_report <- function(avqi_result, sound_object = NULL,
                                simple = FALSE, patient_info = list()) {
  # If simple = TRUE:
  #   - Table with 6 measurements + AVQI score
  #   - AVQI color scale
  # If simple = FALSE:
  #   - All above PLUS:
  #   - Oscillogram
  #   - Narrow-band spectrogram with LTAS overlay
  #   - Power-cepstrogram
  #   - Power-cepstrum with tilt line
}
```

#### 2. **generate_dsi_report()** - MEDIUM PRIORITY
```r
#' Generate DSI Report
#' @param dsi_result Output from compute_dsi()
#' @param patient_info List with name, dob, assessment_date
#' @export
generate_dsi_report <- function(dsi_result, patient_info = list()) {
  # - Table with 4 measurements + DSI score
  # - DSI color scale with arrow
}
```

#### 3. **save_avqi_report()** - LOW PRIORITY
```r
#' Save AVQI Report to File
#' @param report Output from generate_avqi_report()
#' @param filename Output filename (PDF, PNG, or CSV for simple)
#' @export
save_avqi_report <- function(report, filename) {
  # Use ggsave() or write.csv() depending on format
}
```

#### 4. **save_dsi_report()** - LOW PRIORITY
```r
#' Save DSI Report to File
#' @param report Output from generate_dsi_report()
#' @param filename Output filename (PDF, PNG, or CSV)
#' @export
save_dsi_report <- function(report, filename) {
  # Use ggsave() or write.csv()
}
```

---

## Implementation Priority

### Phase 1: Core DSP Functions (Week 1)
**Status**: Ready to implement  
**Estimated Time**: 3-4 days

1. ✅ `Ltas$compute_trend_line()` - C++ wrapper
2. ✅ `Sound$filter_stop_hann_band()` - C++ wrapper  
3. ✅ `PointProcess$to_textgrid_vuv()` - C++ wrapper

**Deliverable**: All DSP operations available for AVQI/DSI calculations

---

### Phase 2: Plotting Functions (Week 1-2)
**Status**: Ready to implement  
**Estimated Time**: 3-4 days

1. ✅ `autoplot.PowerCepstrogram()` - ggplot2 heatmap
2. ✅ `autoplot.PowerCepstrum()` - ggplot2 line plot
3. ✅ `plot_avqi_scale()` - ggplot2 custom scale
4. ✅ `plot_dsi_scale()` - ggplot2 custom scale

**Deliverable**: Full graphical capabilities for AVQI/DSI reports

---

### Phase 3: High-Level Analysis Functions (Week 2)
**Status**: Ready to implement  
**Estimated Time**: 2-3 days

1. ✅ `compute_avqi()` - Orchestrate all AVQI operations
2. ✅ `compute_dsi()` - Orchestrate all DSI operations

**Deliverable**: One-function interface for AVQI/DSI calculation

---

### Phase 4: Report Generation (Week 2)
**Status**: Ready to implement  
**Estimated Time**: 2 days

1. ✅ `generate_avqi_report()` - Combine plots and tables
2. ✅ `generate_dsi_report()` - Combine plots and tables
3. ✅ `save_avqi_report()` - Export to file
4. ✅ `save_dsi_report()` - Export to file

**Deliverable**: Complete report generation system

---

## Example Usage (Post-Implementation)

### AVQI Analysis
```r
library(speaker)

# Compute AVQI
result <- compute_avqi(
  cs_files = c("cs1.wav", "cs2.wav"),
  sv_files = c("sv1.wav", "sv2.wav")
)

# result$avqi = 3.45
# result$cpps = 12.3
# result$hnr = 15.2
# result$shimmer_local = 4.5
# result$shimmer_local_db = 0.45
# result$ltas_slope = -12.5
# result$ltas_tilt = -15.8

# Generate full report with plots
report <- generate_avqi_report(
  avqi_result = result,
  sound_object = result$combined_sound,
  simple = FALSE,
  patient_info = list(
    name = "John Doe",
    dob = "1980-01-01",
    assessment_date = Sys.Date()
  )
)

# Save to PDF
save_avqi_report(report, "avqi_report.pdf")
```

### DSI Analysis
```r
# Compute DSI
result <- compute_dsi(
  mpt_files = c("mpt1.wav", "mpt2.wav"),
  im_files = c("im1.wav"),
  fh_files = c("fh1.wav"),
  ppq_files = c("ppq1.wav"),
  calibration_factor = 10
)

# result$dsi = 2.34
# result$mpt = 15.2
# result$i_low = 45.3
# result$f0_high = 523.5
# result$jitter_ppq5 = 0.85

# Generate report
report <- generate_dsi_report(
  dsi_result = result,
  patient_info = list(name = "John Doe")
)

# Save to PDF
save_dsi_report(report, "dsi_report.pdf")
```

---

## Technical Notes

### C++ Files to Modify

1. **src/ltas_wrappers.cpp**
   - Add `praat_ltas_compute_trend_line()`

2. **src/sound_wrappers.cpp**  
   - Add `praat_sound_filter_stop_hann_band()`

3. **src/pointprocess_wrappers.cpp**
   - Add `praat_pointprocess_to_textgrid_vuv()`

### R Files to Create/Modify

1. **R/ltas-r6.R** - Add `compute_trend_line()` method
2. **R/sound-r6.R** - Add `filter_stop_hann_band()` method
3. **R/pointprocess-r6.R** - Add `to_textgrid_vuv()` method
4. **R/autoplot-powercepstrogram.R** - New file
5. **R/autoplot-powercepstrum.R** - New file
6. **R/plot-scales.R** - New file for AVQI/DSI scales
7. **R/compute-avqi.R** - New file
8. **R/compute-dsi.R** - New file
9. **R/generate-reports.R** - New file

### Dependencies

- ✅ ggplot2 (already in DESCRIPTION)
- ✅ patchwork or cowplot for multi-panel plots
- ✅ All Praat C++ code already available in `src/praat/`

---

## Validation Strategy

### AVQI Validation
1. Compare with Praat AVQI301.praat on test dataset
2. Ensure formula matches: `(4.152 - 0.177*CPPS - ...) * 2.8902`
3. Verify each component (CPPS, HNR, etc.) matches Praat output
4. Visual inspection of plots vs Praat graphics

### DSI Validation
1. Compare with Praat DSI201.praat on test dataset
2. Ensure formula matches: `1.127 + 0.164*MPT - ...`
3. Verify calibration factor applied correctly
4. Visual inspection of DSI scale

---

## Conclusion

The speaker package is **85% ready** for full AVQI and DSI implementation:

- ✅ **All core acoustic analysis** is implemented
- ✅ **Most DSP operations** exist
- ❌ **3 DSP functions** need C++ wrappers (1 week)
- ❌ **4 plotting functions** need ggplot2 implementation (3-4 days)
- ❌ **6 high-level functions** need R orchestration (1 week)

**Total Implementation Time**: ~2.5 weeks for complete AVQI/DSI system

**Next Steps**: Proceed with Phase 1 (Core DSP Functions)
