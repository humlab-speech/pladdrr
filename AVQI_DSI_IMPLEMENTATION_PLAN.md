# AVQI and DSI Implementation Plan

**Date**: 2025-11-22  
**Package Version**: 0.9.6  
**Target Version**: 1.0.0  
**Implementation Time**: ~2-3 weeks  
**Status**: Ready to implement

---

## Implementation Phases

### Phase 1: Core DSP Missing Functions (Week 1: Days 1-3)

#### 1.1 Ltas$compute_trend_line() - Day 1
- C++ wrapper to `Ltas_computeTrendLine()`
- Modifies LTAS in-place with linear regression fit
- Required for AVQI tilt measurement

#### 1.2 Sound$filter_stop_hann_band() - Day 1-2
- C++ wrapper to `Sound_filterStopHannBand()`  
- Band-stop filter with Hann window smoothing
- Required for AVQI 0-34 Hz high-pass filtering

#### 1.3 PointProcess$to_textgrid_vuv() - Day 2-3
- C++ wrapper to `PointProcess_to_TextGrid_vuv()`
- Creates Voiced/Unvoiced TextGrid for segmentation
- Required for DSI minimum intensity in voiced segments

---

### Phase 2: Plotting Functions (Week 1-2: Days 4-7)

#### 2.1 autoplot.PowerCepstrogram() - Day 4
- ggplot2 heatmap: time × quefrency → amplitude (dB)
- Similar to spectrogram but with quefrency axis
- Required for AVQI illustrated report

#### 2.2 autoplot.PowerCepstrum() - Day 5
- ggplot2 line plot: quefrency → amplitude (dB)
- Optional tilt line overlay (regression)
- Required for AVQI illustrated report

#### 2.3 plot_avqi_scale() - Day 6
- Custom ggplot2 color scale (green 0-2.43, red 2.43-10)
- Arrow indicator for AVQI value
- Required for both AVQI reports

#### 2.4 plot_dsi_scale() - Day 7
- Custom ggplot2 color scale (red -10-1.6, green 1.6-5)
- Arrow indicator for DSI value
- Required for DSI report

---

### Phase 3: High-Level Analysis (Week 2: Days 8-10)

#### 3.1 compute_avqi() - Days 8-9
Pipeline orchestration:
1. Load and concatenate continuous speech files
2. Load and concatenate sustained vowel files
3. High-pass filter both (stop 0-34 Hz)
4. Detect voiced segments in continuous speech
5. Extract and concatenate voiced segments
6. Append last 3 seconds of sustained vowel
7. Compute 6 measurements:
   - CPPS (smoothed cepstral peak prominence)
   - HNR (harmonics-to-noise ratio)
   - Shimmer local (%)
   - Shimmer local dB
   - LTAS slope (0-1000 Hz vs 1000-10000 Hz)
   - LTAS tilt (trend line slope)
8. Calculate AVQI = (4.152 - 0.177×CPPS - 0.006×HNR - 0.037×Shim + 0.941×ShimDB + 0.01×Slope + 0.093×Tilt) × 2.8902

Returns: list(avqi, cpps, hnr, shimmer_local, shimmer_local_db, ltas_slope, ltas_tilt, combined_sound)

#### 3.2 compute_dsi() - Day 10
Pipeline orchestration:
1. MPT (maximum phonation time) = max duration of mpt*.wav files
2. I-low (softest intensity) = min intensity of concatenated im*.wav files (calibrated)
3. F0-high (highest F0) = max F0 of concatenated fh*.wav files  
4. Jitter ppq5 = from voice report of last 3s of ppq*.wav files
5. Calculate DSI = 1.127 + 0.164×MPT - 0.038×I_low + 0.0053×F0_high - 5.30×Jitter_ppq5

Returns: list(dsi, mpt, i_low, f0_high, jitter_ppq5)

---

### Phase 4: Report Generation (Week 2-3: Days 11-14)

#### 4.1 generate_avqi_report() - Days 11-12
Creates either:
- **Simple report**: Table + AVQI scale
- **Full report**: Table + AVQI scale + 4 plots:
  - Oscillogram  
  - Narrow-band spectrogram with LTAS overlay
  - Power-cepstrogram
  - Power-cepstrum with tilt line

Returns: patchwork/cowplot combined plot or list of plots

#### 4.2 generate_dsi_report() - Day 13
Creates:
- Table with 4 measurements
- DSI color scale with arrow

Returns: combined ggplot2 object

#### 4.3 save_*_report() - Day 14
- `save_avqi_report(report, filename)` → PDF/PNG/CSV
- `save_dsi_report(report, filename)` → PDF/PNG/CSV

---

## Example Usage (Post-Implementation)

### AVQI Workflow
```r
library(speaker)

# Compute AVQI from files
result <- compute_avqi(
  cs_files = c("continuous_speech1.wav", "continuous_speech2.wav"),
  sv_files = c("sustained_vowel1.wav", "sustained_vowel2.wav"),
  pitch_floor = 75,
  pitch_ceiling = 600
)

# Examine results
result$avqi          # 3.45
result$cpps          # 12.3
result$hnr           # 15.2
result$shimmer_local # 4.5
result$shimmer_local_db # 0.45
result$ltas_slope    # -12.5
result$ltas_tilt     # -15.8

# Generate full illustrated report
report <- generate_avqi_report(
  avqi_result = result,
  simple = FALSE,
  patient_info = list(
    name = "John Doe",
    dob = "1980-01-01", 
    assessment_date = Sys.Date()
  )
)

# Save to PDF
save_avqi_report(report, "patient_avqi_report.pdf")
```

### DSI Workflow
```r
# Compute DSI from files
result <- compute_dsi(
  mpt_files = c("max_phonation1.wav", "max_phonation2.wav"),
  im_files = c("soft_phonation.wav"),
  fh_files = c("high_pitch.wav"),
  ppq_files = c("sustained_vowel.wav"),
  calibration_factor = 10
)

# Examine results  
result$dsi          # 2.34
result$mpt          # 15.2 seconds
result$i_low        # 45.3 dB
result$f0_high      # 523.5 Hz
result$jitter_ppq5  # 0.85%

# Generate report
report <- generate_dsi_report(
  dsi_result = result,
  patient_info = list(name = "John Doe")
)

# Save to PDF
save_dsi_report(report, "patient_dsi_report.pdf")
```

---

## Testing & Validation

### Unit Tests
- Each C++ wrapper function
- Each R6 method
- Each plotting function
- Each high-level analysis function

### Integration Tests
- Full AVQI pipeline vs Praat output (tolerance ±0.5)
- Full DSI pipeline vs Praat output (tolerance ±0.5)

### Test Data
Use superassp test files:
- `tests/signalfiles/AVQI/input/`
- `tests/signalfiles/DSI/input/`

---

## Files to Create/Modify

### C++ Wrappers
- `src/ltas_wrappers.cpp` - Add `praat_ltas_compute_trend_line()`
- `src/sound_wrappers.cpp` - Add `praat_sound_filter_stop_hann_band()`
- `src/pointprocess_wrappers.cpp` - Add `praat_pointprocess_to_textgrid_vuv()`

### R6 Methods
- `R/ltas-r6.R` - Add `compute_trend_line()`
- `R/sound-r6.R` - Add `filter_stop_hann_band()`
- `R/pointprocess-r6.R` - Add `to_textgrid_vuv()`

### Plotting
- `R/autoplot-powercepstrogram.R` - New file
- `R/autoplot-powercepstrum.R` - New file
- `R/plot-scales.R` - New file (AVQI/DSI scales)

### High-Level Analysis
- `R/compute-avqi.R` - New file
- `R/compute-dsi.R` - New file

### Report Generation
- `R/generate-reports.R` - New file
- `R/save-reports.R` - New file

### Documentation
- `man/compute_avqi.Rd`
- `man/compute_dsi.Rd`
- `man/generate_avqi_report.Rd`
- `man/generate_dsi_report.Rd`
- `vignettes/avqi-analysis.Rmd`
- `vignettes/dsi-analysis.Rmd`

---

## Success Criteria

- [  ] All 3 DSP functions implemented and tested
- [  ] All 4 plotting functions work correctly
- [  ] `compute_avqi()` produces results within ±0.5 of Praat AVQI301.praat
- [  ] `compute_dsi()` produces results within ±0.5 of Praat DSI201.praat
- [  ] Full and simple reports generate correctly
- [  ] All tests pass (>95% coverage)
- [  ] Documentation complete
- [  ] R CMD check --as-cran passes with 0 errors, 0 warnings

---

## Version Milestones

- Phase 1 complete: **0.9.6 → 0.9.7** (DSP functions)
- Phase 2 complete: **0.9.7 → 0.9.8** (Plotting)
- Phase 3 complete: **0.9.8 → 0.9.9** (Analysis functions)
- Phase 4 complete: **0.9.9 → 1.0.0** 🎉 (Report generation)

---

## Ready to Begin Implementation

**Next Action**: Proceed with Phase 1, Task 1.1 (Ltas trend line)

See `AVQI_DSI_IMPLEMENTATION_ANALYSIS.md` for detailed gap analysis.
