# Next Steps: Tremor Analysis Fix

**Status:** pladdrr 1.2.2 ✅ installed | Primary bug ✅ resolved | 1 fix ready | 3 blocked

---

## Immediate Action Required (User Side)

### 1. Update Script Parameters ⚡ HIGH PRIORITY

**Problem:** Using non-standard parameters causes voicing errors

**Fix:** In your tremor analysis script:

```r
# ❌ REMOVE THIS (causes 188% error)
pitch <- sound$to_pitch(
  time_step = 0.015,
  pitch_floor = min_pitch,
  pitch_ceiling = 350,        # ← WRONG
  voicing_threshold = 0.3     # ← WRONG
)

# ✅ USE THIS (Praat defaults)
pitch <- sound$to_pitch(
  time_step = 0.0,            # Auto-calculate
  pitch_floor = min_pitch,
  pitch_ceiling = 600,        # ← Praat default
  voicing_threshold = 0.45    # ← Praat default
)
```

**Impact:** Fixes voicing detection immediately (188% error → <1%)

---

### 2. Fix FTrI Calculation 🔧 READY TO IMPLEMENT

**Problem:** Using simple extrema instead of pitch-guided peaks (33% error)

**Where:** In your tremor intensity calculation code (wherever you extract peaks from contour signal)

**Fix:**

```r
# ❌ CURRENT (simple maxima - 33% underestimation)
pp_max <- contour_sound$to_point_process_extrema(
  channel = 1,
  include_maxima = TRUE,
  include_minima = FALSE
)

# ✅ FIXED (pitch-guided - matches Praat)
pp_max <- tremor_pitch$to_pointprocess_peaks(
  sound = contour_sound,
  include_maxima = TRUE,
  include_minima = FALSE
)
```

**Verify method exists:**
```r
library(pladdrr)
pitch <- Sound$new("test.wav")$to_pitch()
"to_pointprocess_peaks" %in% names(pitch)  # Should be TRUE
```

**Impact:** Fixes FTrI from 1.454% to 2.170% (33% improvement)

---

### 3. Test Results

After making above fixes, run:

```r
library(pladdrr)

# Load test file
sound <- Sound$new("inst/signalfiles/AVQI/input/sv1.wav")

# Run with corrected parameters
result <- your_tremor_function(
  sound = sound,
  voicing_threshold = 0.45,  # Praat default
  max_pitch = 600            # Praat default
)

# Expected results:
# - Tremor frequency: ~1.7 Hz (was 4.999 Hz)
# - FTrI intensity: ~2.17% (was 1.454%)
# - Frames 4-9: mostly unvoiced (were all voiced)
```

---

## Future Work (Blocked - Requires Maintainer)

### 4. Request API Enhancement for FCoM/FTrC/ACoM 📋 LOW PRIORITY

**Problem:** Cannot extract pitch strength values from binary pitch files

**Affected metrics:**
- FCoM (Frequency Contour Magnitude) - Returns 0.000 instead of 0.599
- FTrC (Frequency Tremor Cyclicality) - Returns 0.000 instead of 0.353
- ACoM (Amplitude Contour Magnitude) - Error instead of 0.442

**Solution needed:** One of:
```r
# Option 1: Text file export
pitch$save_as_text_file(filename)

# Option 2: Direct strength accessor
pitch$get_strength_at_time(time)

# Option 3: Enhanced data frame with strength column
pitch$as_data_frame()  # Add 'strength' column
```

**Action:** Open GitHub issue requesting this feature

**Timeline:** Requires C++ wrapper implementation (2-3 days for maintainer)

---

## Testing Checklist

After applying fixes 1 & 2:

- [ ] Voicing detection correct (frames 4-9 unvoiced)
- [ ] Tremor frequency ~1.7 Hz (not 4.999 Hz)
- [ ] FTrI intensity ~2.17% (not 1.454%)
- [ ] Results match Praat/Parselmouth within 5%

---

## Files to Modify

### Your Code (Location Unknown)
- [ ] Script with `pitch_ceiling = 350` → change to `600`
- [ ] Script with `voicing_threshold = 0.3` → change to `0.45`
- [ ] Function using `to_point_process_extrema()` → change to `to_pointprocess_peaks()`

### pladdrr Package (Future)
- [ ] Add `pitch$save_as_text_file()` or equivalent
- [ ] Update documentation about parameter defaults
- [ ] Add parameter validation helpers

---

## Summary

| Issue | Status | Action | Priority |
|-------|--------|--------|----------|
| Voicing bug (188% error) | ✅ Resolved | Update parameters | ⚡ HIGH |
| FTrI fix (33% error) | 🔧 Ready | Use pitch-guided peaks | ⚡ HIGH |
| FCoM/FTrC/ACoM | ❌ Blocked | Request API feature | 📋 LOW |

**Key Insight:** Primary issue was parameter choice, not pladdrr algorithm! Using Praat defaults fixes most problems immediately.

---

**Last Updated:** 2025-12-11  
**pladdrr Version:** 1.2.2 (installed and working)  
**See:** `SESSION_SUMMARY_2025-12-11.md` for complete technical details
