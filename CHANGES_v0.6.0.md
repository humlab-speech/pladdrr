# Changes in speaker v0.6.0

**Release Date**: 2025-11-20  
**Focus**: AVQI/DSI Voice Quality Indices - Phase 1 Critical Functions

---

## Major New Features

### 1. Voice Report Functionality ⭐ CRITICAL

Comprehensive voice quality analysis with jitter, shimmer, and harmonicity measurements.

**New C++ Wrapper**:
- `.pointprocess_voice_report()` - Wraps Praat's `Sound_Pitch_PointProcess_voiceReport()`

**New R6 Method** (`PointProcess` class):
- `voice_report(sound, pitch, ...)` - Returns 26 voice quality measurements in a single call

**Returns**:
- **Jitter measures** (5): local, local_absolute, rap, ppq5, ddp
- **Shimmer measures** (6): local, local_db, apq3, apq5, apq11, dda
- **Harmonicity** (3): HNR, autocorrelation, NHR
- **Pitch statistics** (5): median, mean, stdev, min, max
- **Pulse statistics** (4): number of pulses, number of periods, mean period, stdev period
- **Voicing statistics** (3): fraction unvoiced, voice breaks count, voice breaks degree

**Usage**:
```r
sound <- Sound$new("voice.wav")
pitch <- sound$to_pitch_cc()
pp <- sound$to_point_process_cc(pitch)

report <- pp$voice_report(sound, pitch)

# Extract for DSI
jitter_ppq5 <- report$jitter_ppq5 * 100  # %

# Extract for AVQI
shimmer_local <- report$shimmer_local * 100  # %
shimmer_local_db <- report$shimmer_local_db   # dB
```

**Enables**: DSI (jitter ppq5) and AVQI (shimmer local, shimmer local dB) calculations

---

### 2. CPPS (Smoothed Cepstral Peak Prominence) ⭐ CRITICAL

Robust voice quality measure essential for AVQI calculation.

**New C++ Wrappers**:
- `.powercepstrogram_get_cpps()` - Wraps Praat's `PowerCepstrogram_getCPPS()`
- `.powercepstrum_get_peak_prominence_cpps()` - Wraps `PowerCepstrum_getPeakProminence()`

**New R6 Method** (`PowerCepstrogram` class):
- `get_cpps(...)` - Compute Smoothed Cepstral Peak Prominence

**Features**:
- Full parameter control for AVQI protocol compliance
- Default parameters match Barsties & Maryn (2015) AVQI standard
- Support for trend subtraction, smoothing, and peak interpolation
- Configurable pitch range and fitting methods

**Usage**:
```r
sound <- Sound$new("voice.wav")
cepstrogram <- sound$to_power_cepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,
  pre_emphasis_from = 50
)

# Get CPPS with AVQI-standard parameters (all defaults)
cpps <- cepstrogram$get_cpps()
cat("CPPS:", round(cpps, 2), "dB\n")
```

**Enables**: AVQI (cepstral peak prominence measurement)

---

## AVQI/DSI Implementation Status

### AVQI DSP Components: 100% Complete ✅

All six acoustic measures required for AVQI are now available:

| Measure | Implementation | Status |
|---------|----------------|--------|
| CPPS | `cepstrogram$get_cpps()` | ✅ v0.6.0 |
| HNR | `harmonicity$get_mean()` | ✅ Existing |
| Shimmer Local (%) | `report$shimmer_local * 100` | ✅ v0.6.0 |
| Shimmer Local (dB) | `report$shimmer_local_db` | ✅ v0.6.0 |
| LTAS Slope | `ltas$get_slope()` | ✅ Existing |
| LTAS Tilt | `ltas$get_value_at_frequency()` | ✅ Existing |

**AVQI Formula**:
```r
AVQI = 4.152 - 0.177*CPPS - 0.006*HNR - 0.037*ShimmerLocal + 
       0.941*ShimmerLocalDB + 0.01*Slope + 0.093*Tilt
```

### DSI DSP Components: 100% Complete ✅

All four measurements required for DSI are now available:

| Measure | Implementation | Status |
|---------|----------------|--------|
| MPT | `sound$get_total_duration()` | ✅ Existing |
| I-low | `intensity$get_minimum()` | ✅ Existing |
| F0-high | `pitch$get_maximum()` | ✅ Existing |
| Jitter ppq5 (%) | `report$jitter_ppq5 * 100` | ✅ v0.6.0 |

**DSI Formula**:
```r
DSI = 1.127 + 0.164*MPT - 0.038*Ilow + 0.0053*Fhigh - 5.30*JitterPPQ5
```

---

## Implementation Details

### Files Modified

**C++ Wrappers** (2 files):
- `src/pointprocess_wrappers.cpp` - Added voice_report wrapper (~120 lines)
- `src/powercepstrum_wrappers.cpp` - Added CPPS wrappers (~95 lines)

**R6 Classes** (2 files):
- `R/pointprocess-r6.R` - Added `voice_report()` method (~90 lines + docs)
- `R/powercepstrum-r6.R` - Added `get_cpps()` method (~115 lines + docs)

**Auto-generated** (2 files):
- `R/RcppExports.R` - Regenerated with new functions
- `src/RcppExports.cpp` - Regenerated with new functions

**Total new code**: ~420 lines (excluding auto-generated)

### Code Quality

- ✅ Comprehensive error handling with try-catch blocks
- ✅ Proper XPtr usage for memory safety
- ✅ Type-safe enum conversions
- ✅ Complete Roxygen2 documentation
- ✅ Usage examples with realistic code
- ✅ Parameter validation

---

## Documentation

### New Planning Documents (4 files, 56KB):

1. **AVQI_DSI_IMPLEMENTATION_PLAN.md** (28KB)
   - Complete 5-week implementation roadmap
   - All Praat operations catalogued
   - Missing functionality detailed
   - ggplot2 visualization specifications
   - Report generation architecture

2. **AVQI_DSI_QUICK_REFERENCE.md** (8KB)
   - Current implementation status
   - Priority order
   - Code templates (C++ and R)
   - Testing checklist
   - File organization

3. **PRAAT_TO_SPEAKER_AVQI_DSI.md** (20KB)
   - Line-by-line Praat script → speaker mapping
   - AVQI section-by-section translation
   - DSI section-by-section translation
   - Exact code equivalents

4. **AVQI_DSI_SUMMARY.md**
   - Executive overview
   - Quick reference

### Progress Reports:

5. **AVQI_DSI_PHASE1_PROGRESS.md**
   - Detailed implementation status
   - Component analysis
   - Next steps

6. **SESSION_STATUS_AVQI_DSI_2025-11-20.md**
   - Session summary
   - Achievements
   - Timeline tracking

---

## Remaining Work

### Phase 1 (Critical Functions)
- [x] Voice Report (jitter/shimmer) - ✅ v0.6.0
- [x] CPPS (cepstral prominence) - ✅ v0.6.0
- [ ] Voice Activity Detection - Next

### Phase 2-3 (Integration)
- [ ] High-level `compute_avqi()` function
- [ ] High-level `compute_dsi()` function
- [ ] ggplot2 visualizations
- [ ] R Markdown report templates

### Phase 4 (Documentation)
- [ ] AVQI vignette
- [ ] DSI vignette
- [ ] Example workflows
- [ ] Test data

**Estimated completion**: 4 weeks

---

## Technical Notes

### Enum Mappings

The CPPS implementation includes careful enum mapping between R strings and Praat C++ enums:

**Interpolation types**:
- "none" = 0
- "parabolic" = 1
- "cubic" = 2
- "sinc70" = 3
- "sinc700" = 4

**Trend line types**:
- "straight" = 1
- "exponential decay" = 2
- "parabolic" = 3

**Fit methods**:
- "least squares" = 1
- "robust" = 2
- "robust slow" = 3

### Default Parameters

CPPS defaults match AVQI protocol (Barsties & Maryn, 2015):
- `subtract_tilt = TRUE`
- `time_averaging_window = 0.001` (1 ms)
- `quefrency_averaging_window = 0.0005` (0.5 ms)
- `pitch_floor = 60` Hz
- `pitch_ceiling = 333.3` Hz
- `interpolation = "parabolic"`
- `trend_line_type = "straight"`
- `fit_method = "least squares"`

---

## References

1. Maryn, Y., Corthals, P., Van Cauwenberge, P., Roy, N., & De Bodt, M. (2010). Toward improved ecological validity in the acoustic measurement of overall voice quality: Combining continuous speech and sustained vowels. *Journal of Voice*, 24(5), 540-555.

2. Barsties, B., & Maryn, Y. (2015). The improvement of internal consistency of the Acoustic Voice Quality Index. *American Journal of Otolaryngology*, 36(5), 647-656.

3. Wuyts, F. L., De Bodt, M. S., Molenberghs, G., Remacle, M., Heylen, L., Millet, B., ... & Heyning, P. H. (2000). The dysphonia severity index: an objective measure of vocal quality based on a multiparameter approach. *Journal of Speech, Language, and Hearing Research*, 43(3), 796-809.

---

## Breaking Changes

None. All changes are additive.

---

## Bug Fixes

None in this release (focused on new features).

---

## Acknowledgments

This implementation follows the AVQI and DSI protocols as published in the scientific literature and as implemented in Praat by Paul Boersma, David Weenink, and Youri Maryn.

---

**Version 0.6.0 Status**: Phase 1 Critical Functions - 67% Complete  
**Next Release (0.7.0)**: Voice Activity Detection + High-level AVQI/DSI functions  
**Target (1.0.0)**: Complete AVQI/DSI with visualizations and documentation
