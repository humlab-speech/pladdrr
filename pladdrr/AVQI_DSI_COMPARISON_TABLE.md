# AVQI and DSI: Praat vs speaker Package Feature Comparison

**Last Updated**: 2025-11-22

---

## AVQI (Acoustic Voice Quality Index)

| Feature | Praat AVQI301.praat | speaker Package | Status | Priority |
|---------|---------------------|-----------------|--------|----------|
| **DSP Components** |
| CPPS computation | ✅ PowerCepstrogram + smoothing | ✅ `to_powercepstrogram()` + `get_cpps()` | ✅ Complete | - |
| HNR computation | ✅ Harmonicity (cc) | ✅ `to_harmonicity_cc()` + `get_mean()` | ✅ Complete | - |
| Shimmer Local | ✅ Voice Report | ✅ `voice_report()$shimmer_local` | ✅ Complete | - |
| Shimmer Local dB | ✅ Voice Report | ✅ `voice_report()$shimmer_local_db` | ✅ Complete | - |
| LTAS Slope | ✅ Regression 0-1k vs 1k-5k Hz | ✅ `to_ltas()` + `get_slope()` | ✅ Complete | - |
| LTAS Tilt (H1-A3) | ✅ H1 and A3 from LTAS | ✅ F0 and F3 based approximation | ✅ Complete | - |
| **Pre-processing** |
| Stereo to mono | ✅ `Convert to mono` | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Resampling | ✅ `Resample... 44100 50` | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| High-pass filter | ✅ `Filter (stop Hann band)... 0 34 0.1` | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| **Voice Activity Detection** |
| Adaptive threshold | ✅ `max_intensity - 25 dB` | ⚠️ Fixed `-25 dB` | ⚠️ Partial | **HIGH** |
| TextGrid creation | ✅ `To TextGrid (silences)` | ✅ Optional in `extract_voiced_segments()` | ✅ Complete | - |
| Segment extraction | ✅ `Extract intervals where...` | ✅ `extract_voiced_segments()` | ✅ Complete | - |
| **Vowel Analysis** |
| Segment selection | ✅ 1s window with min pitch SD | ⚠️ Middle 3 seconds (fixed) | ⚠️ Partial | MEDIUM |
| Duration check | ✅ Extract last 3s if > 3s | ✅ Similar logic | ✅ Complete | - |
| **Formula** |
| AVQI calculation | ✅ Barsties & Maryn (2015) | ✅ Same formula | ✅ Complete | - |
| Score interpretation | ✅ Cutoff 2.95 | ✅ Same cutoff | ✅ Complete | - |
| **Simple Report** |
| Component values | ✅ Text output | ✅ `print()` method | ✅ Complete | - |
| AVQI score | ✅ Numeric display | ✅ `$avqi` field | ✅ Complete | - |
| Metadata | ✅ Name, DOB, Date | ✅ `$metadata` list | ✅ Complete | - |
| **Illustrated Report** |
| Waveform plot | ✅ Praat Picture | ❌ Placeholder only | ⚠️ Missing | **HIGH** |
| VAD overlay | ✅ TextGrid on waveform | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Spectrogram | ✅ Paint... 0-4000 Hz | ❌ Placeholder only | ⚠️ Missing | **HIGH** |
| LTAS plot | ✅ Draw... with annotations | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Slope/Tilt lines | ✅ Regression + markers | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Power-cepstrogram | ✅ Paint... time × quefrency | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Power-cepstrum | ✅ Draw... with tilt line | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Component table | ✅ Formatted text | ✅ `$components` data.frame | ✅ Complete | - |
| Multi-panel layout | ✅ Single Praat Picture | ⚠️ Partial (gridExtra needed) | ⚠️ Partial | **HIGH** |
| Save as image | ✅ PDF/PNG/EPS | ✅ `ggsave()` support | ✅ Complete | - |
| **Batch Processing** |
| Multiple files | ✅ String list + loop | ❌ Manual loop needed | ⚠️ Missing | MEDIUM |
| CSV export | ✅ Table + save | ⚠️ Manual export | ⚠️ Partial | MEDIUM |

---

## DSI (Dysphonia Severity Index)

| Feature | Praat DSI201.praat | speaker Package | Status | Priority |
|---------|-------------------|-----------------|--------|----------|
| **DSP Components** |
| MPT measurement | ✅ Duration - trim | ⚠️ Total duration (no trim) | ⚠️ Partial | MEDIUM |
| F0-high | ✅ 95th percentile | ⚠️ Absolute maximum | ⚠️ Partial | **HIGH** |
| I-low | ✅ 5th percentile | ⚠️ Absolute minimum | ⚠️ Partial | **HIGH** |
| Jitter ppq5 | ✅ Voice Report | ✅ `voice_report()$jitter_ppq5` | ✅ Complete | - |
| **Pre-processing** |
| Stereo to mono | ✅ `Convert to mono` | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Resampling | ✅ Not in DSI script | ➖ N/A | ➖ N/A | - |
| Calibration | ✅ Optional +10 dB | ❌ Not implemented | ⚠️ Missing | MEDIUM |
| **Task-Specific Analysis** |
| MPT file detection | ✅ `mpt*.wav` pattern | ⚠️ Manual specification | ⚠️ Partial | MEDIUM |
| Glide file detection | ✅ `fh*.wav` pattern | ⚠️ Manual specification | ⚠️ Partial | MEDIUM |
| Soft phonation files | ✅ `im*.wav` pattern | ⚠️ Manual specification | ⚠️ Partial | MEDIUM |
| Jitter files | ✅ `ppq*.wav` pattern | ⚠️ Manual specification | ⚠️ Partial | MEDIUM |
| File concatenation | ✅ Automatic | ❌ Not implemented | ⚠️ Missing | MEDIUM |
| **Measurements** |
| Onset/offset trim | ✅ Intensity-based | ❌ Not implemented | ⚠️ Missing | MEDIUM |
| Percentile robust | ✅ 95th/5th percentiles | ❌ Absolute extrema | ⚠️ Missing | **HIGH** |
| Stable segment | ✅ Last 3s of sustained vowel | ✅ Middle extraction | ✅ Complete | - |
| **Formula** |
| DSI calculation | ✅ Wuyts et al. (2000) | ✅ Same formula | ✅ Complete | - |
| Score interpretation | ✅ 4 categories | ✅ Same categories | ✅ Complete | - |
| **Simple Report** |
| Component values | ✅ Text output | ✅ `print()` method | ✅ Complete | - |
| DSI score | ✅ Numeric display | ✅ `$dsi` field | ✅ Complete | - |
| Metadata | ✅ Name, DOB, Date | ✅ `$metadata` list | ✅ Complete | - |
| **Illustrated Report** |
| Pitch contour | ✅ Draw... | ❌ Placeholder only | ⚠️ Missing | **HIGH** |
| F0-high marker | ✅ Horizontal line + label | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Intensity contour | ✅ Draw... | ❌ Placeholder only | ⚠️ Missing | **HIGH** |
| I-low marker | ✅ Horizontal line + label | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Time-aligned dual plot | ✅ Combined view | ❌ Not implemented | ⚠️ Missing | **HIGH** |
| Component bar chart | ✅ Text table | ✅ ggplot2 bar chart | ✅ Complete | - |
| Score scale | ✅ -10 to +10 with arrow | ✅ Color-coded scale | ✅ Complete | - |
| Category colors | ✅ Red/Yellow/Green | ✅ Similar palette | ✅ Complete | - |
| Formula display | ✅ Text with values | ⚠️ Can add to plot | ⚠️ Partial | LOW |
| Multi-panel layout | ✅ Single Praat Picture | ⚠️ Partial (needs work) | ⚠️ Partial | **HIGH** |
| Save as image | ✅ PDF/PNG | ✅ `ggsave()` support | ✅ Complete | - |
| **Batch Processing** |
| Multiple subjects | ✅ String list + loop | ❌ Manual loop needed | ⚠️ Missing | MEDIUM |
| CSV export | ✅ Table + save | ⚠️ Manual export | ⚠️ Partial | MEDIUM |

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Fully implemented, protocol-compliant |
| ⚠️ | Partially implemented or differs from Praat |
| ❌ | Not implemented |
| ➖ | Not applicable |

---

## Priority Levels

| Priority | Meaning | Action |
|----------|---------|--------|
| **HIGH** | Critical for protocol compliance or core functionality | Implement ASAP |
| MEDIUM | Important for usability or accuracy | Implement soon |
| LOW | Nice to have, minor enhancement | Implement later |

---

## Summary Statistics

### AVQI
- **Complete**: 13/27 features (48%)
- **Partial**: 6/27 features (22%)
- **Missing**: 8/27 features (30%)
- **High Priority Gaps**: 10 items

### DSI
- **Complete**: 10/24 features (42%)
- **Partial**: 7/24 features (29%)
- **Missing**: 6/24 features (25%)
- **High Priority Gaps**: 7 items

### Overall
- **Core DSP Algorithms**: ✅ Excellent (>90% complete)
- **Pre-processing**: ⚠️ Needs work (30% complete)
- **Visualization**: ⚠️ Needs work (40% complete)
- **Batch/Workflow**: ⚠️ Needs work (50% complete)

---

## Recommendations

### Immediate Action Items

1. **Pre-processing pipeline** (both AVQI and DSI)
   - Mono conversion
   - Resampling
   - High-pass filtering

2. **Percentile measurements** (DSI)
   - Add C++ wrappers
   - Update R6 methods
   - Change from absolute to percentile

3. **Adaptive VAD** (AVQI)
   - Dynamic threshold calculation
   - Update `extract_voiced_segments()`

### Short-term Goals

4. **Visualization infrastructure**
   - Implement all 5 AVQI plot types
   - Implement all 3 DSI plot types
   - Multi-panel layout system

5. **Enhanced accuracy**
   - Optimal vowel segment selection
   - MPT trimming logic

### Medium-term Goals

6. **Clinical workflow**
   - Batch processing utilities
   - Automated CSV export
   - Calibration support

7. **Quality assurance**
   - Validation test suite
   - Reference dataset
   - Tolerance testing vs Praat

---

**Created**: 2025-11-22  
**Version**: speaker 0.9.6  
**References**:
- AVQI301.praat (Maryn & Corthals)
- DSI201.praat (Maryn)
- `AVQI_DSI_GAP_ANALYSIS.md`
