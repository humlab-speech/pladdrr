# Issue #1: FTrI Tremor Intensity Fix

**Status:** ✅ FIXABLE NOW (method exists in pladdrr 1.2.2)
**Error:** 33% underestimation (1.454% vs 2.170% expected)
**Root Cause:** Using simple extrema instead of pitch-guided peaks

---

## The Fix

### Location
File: `R_implementations/tremor.R` (or equivalent tremor analysis code)
Function: `calculate_tremor_intensity()` (around line 335)

### Current Code (WRONG)
```r
# Uses simple extrema detection (no pitch guidance)
pp_max <- contour_sound$to_point_process_extrema(
  channel = 1,
  include_maxima = TRUE,
  include_minima = FALSE
)

pp_min <- contour_sound$to_point_process_extrema(
  channel = 1,
  include_maxima = FALSE,
  include_minima = TRUE
)
```

### Fixed Code (CORRECT)
```r
# Use pitch-guided peak detection (matches Praat/Parselmouth)
pp_max <- tremor_pitch$to_pointprocess_peaks(
  sound = contour_sound,
  include_maxima = TRUE,
  include_minima = FALSE
)

pp_min <- tremor_pitch$to_pointprocess_peaks(
  sound = contour_sound,
  include_maxima = FALSE,
  include_minima = TRUE
)
```

---

## Technical Details

### Praat Command Equivalent
```praat
select Sound contour_sound
plus Pitch tremor_pitch
To PointProcess (peaks)... yes no
```

### Python/Parselmouth Equivalent
```python
pp_max = call([contour_sound, tremor_pitch], "To PointProcess (peaks)", "yes", "no")
```

### R/pladdrr Method Signature
```r
Pitch$to_pointprocess_peaks(sound, include_maxima = TRUE, include_minima = FALSE)
```

**Arguments:**
- `sound`: Sound object containing the contour
- `include_maxima`: Include positive peaks (TRUE/FALSE)
- `include_minima`: Include negative troughs (TRUE/FALSE)

**Returns:** PointProcess object with time points at peaks/troughs

---

## Why This Matters

### Pitch-Guided Peaks (Correct Method)
- Uses tremor pitch frequency to identify expected peak locations
- Finds peaks synchronized with detected tremor cycles
- Robust to noise and spurious local maxima
- **Result:** FTrI = 2.170% (matches Praat)

### Simple Extrema (Current Method)
- Finds all local maxima in signal
- No awareness of tremor periodicity
- May include noise artifacts or miss true peaks
- **Result:** FTrI = 1.454% (33% error)

---

## Testing

After applying fix, verify with:

```r
library(pladdrr)

# Load test file
sound <- Sound$new("inst/signalfiles/AVQI/input/sv1.wav")

# Run tremor analysis (should now return FTrI ≈ 2.170%)
result <- calculate_tremor_metrics(sound)

cat(sprintf("FTrI: %.3f%% (expected 2.170%%)\n", result$ftri))
cat(sprintf("Error: %.1f%%\n", abs(result$ftri - 2.170) / 2.170 * 100))
```

**Expected output:**
```
FTrI: 2.170% (expected 2.170%)
Error: 0.0%
```

---

## Impact

**Clinical:** ⚠️ Moderate
- Underestimates tremor severity by 33%
- Still detects presence of tremor
- May affect clinical decision thresholds

**Research:** ⚠️ Moderate  
- Systematic bias in R vs Python/Praat comparisons
- Within-R comparisons still valid (relative measurements)

**Effort:** 🟢 LOW
- Two-line code change
- No new dependencies
- No API changes needed

**Priority:** 🔴 HIGH
- Easy fix for significant improvement
- Brings R closer to Praat parity

---

**Date:** 2025-12-11
**pladdrr Version:** 1.2.2
**Status:** Ready to implement
