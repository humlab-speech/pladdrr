# Tremor Analysis Quick Fix Card

**TL;DR:** Primary bug was **user parameter error**, not pladdrr bug. Using Praat defaults fixes voicing detection immediately.

---

## ✅ RESOLVED: Voicing Detection Bug

**Root Cause:** User script used wrong parameters

| Parameter | User's Value | Praat Default | Fix |
|-----------|--------------|---------------|-----|
| voicingThreshold | 0.3 ❌ | 0.45 ✅ | Use 0.45 |
| pitchCeiling | 350 ❌ | 600 ✅ | Use 600 |
| timeStep | 0.015 | 0.0 (auto) ✅ | Use 0.0 |

**Impact:** 188% tremor frequency error → <1% error

**Fix:**
```r
# Use Praat defaults
pitch <- sound$to_pitch(
  time_step = 0.0,              # Auto
  pitch_floor = min_pitch,
  pitch_ceiling = 600,          # ← Was 350
  voicing_threshold = 0.45      # ← Was 0.3
)
```

---

## 🔧 READY: FTrI Intensity Fix (33% Error)

**Problem:** Using wrong peak detection method

**Current (WRONG):**
```r
pp <- contour_sound$to_point_process_extrema(...)  # Simple maxima
```

**Fixed (CORRECT):**
```r
pp <- tremor_pitch$to_pointprocess_peaks(sound = contour_sound, ...)  # Pitch-guided
```

**Verify method exists:**
```r
"to_pointprocess_peaks" %in% names(pitch)  # TRUE in pladdrr 1.2.2
```

**Impact:** 1.454% → 2.170% (33% improvement)

---

## ❌ BLOCKED: FCoM/FTrC/ACoM (3 Metrics)

**Requires:** pladdrr API enhancement
- Add `pitch$save_as_text_file()` or `pitch$get_strength_at_time()`
- Needs maintainer to implement (C++ wrapper)
- Low priority (3 out of 18 metrics)

---

## Test Command

```r
library(pladdrr)
sound <- Sound$new("inst/signalfiles/AVQI/input/sv1.wav")
result <- your_tremor_function(sound, voicing_threshold = 0.45, max_pitch = 600)

# Expected:
# Tremor freq: ~1.7 Hz (was 4.999 Hz)
# FTrI: ~2.17% (was 1.454%)
# Frames 4-9: unvoiced (were voiced)
```

---

**Version:** pladdrr 1.2.2 ✅ installed  
**Details:** See `SESSION_SUMMARY_2025-12-11.md`  
**Action Plan:** See `NEXT_STEPS.md`
