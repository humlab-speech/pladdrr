# Session Summary: Pitch Intensity & Tremor Fix (2025-12-11 Continued)

## Accomplishments ✅

### 1. Pitch Frame Intensity & Strength Implemented
**Commits:**
- d1d132d: Added pitch strength extraction (get_strength_at_time, get_mean_strength)
- 50094cf: Added pitch intensity extraction (get_intensity_at_time, get_mean_intensity)

**New API:**
```r
# Pitch strength (periodicity/cyclicality)
pitch$get_strength_at_time(time, unit, interpolate)
pitch$get_mean_strength(from_time, to_time, unit)

# Pitch frame intensity (acoustic magnitude)
pitch$get_intensity_at_time(time)
pitch$get_mean_intensity(from_time, to_time)

# Export both
pitch$as_data_frame(include_intensity=TRUE, include_strength=TRUE)
```

### 2. Understanding of Pitch_Frame Structure
**Praat C++ Structure** (Pitch_def.h):
```cpp
Pitch_Frame {
    double intensity;        // Acoustic magnitude of frame
    integer nCandidates;     
    Pitch_Candidate[nCandidates] {
        double frequency;    // F0 candidate
        double strength;     // Periodicity/cyclicality (0-1)
    }
}
```

**Field Semantics:**
- `intensity`: Acoustic magnitude (how loud the frame is)
- `strength`: Periodicity measure (how periodic/cyclic the pitch is)

### 3. tremor.R Initial Review
**Current implementation:**
- FCoM uses pitch `strength` (max of all voiced frames)
- ACoM uses Intensity object values (range/mean)
- FTrC/ATrC use autocorrelation (correct approach)

## Issues Discovered 🔍

### FCoM Value Mismatch
**Problem:** FCoM calculated as 0.9963, but external analysis shows ~0.599

**Possible causes:**
1. **Different formula**: Perhaps FCoM should be calculated from detrended F0 values, not pitch strength
2. **Normalization**: May need additional normalization step
3. **Reference mismatch**: External analysis might use different parameters

**Test results:**
```r
# Using pitch strength (current implementation)
max(voiced_strength) = 0.9963  # Got this
# Expected from external analysis: 0.599
```

**Hypothesis:** FCoM might need to be calculated as:
- Coefficient of variation of F0 contour?
- Relative strength measure?
- Different normalization?

### FTrC/ATrC Implementation
**Current status:** Uses autocorrelation method (appears correct)
**Need to verify:** Compare against external analysis values

## Next Steps (IMMEDIATE) 🎯

### 1. Investigate FCoM Formula
**Actions:**
- Review Brückl (2012) paper definition of "Frequency Contour Magnitude"
- Check if it's calculated from F0 values or from pitch strength
- Compare with Praat tremor plugin implementation
- Test alternative formulas:
  - Coefficient of variation: `sd(f0) / mean(f0)`
  - Relative range: `(max(f0) - min(f0)) / mean(f0)`
  - Normalized strength: `(max(strength) - min(strength)) / mean(strength)`

### 2. Run Complete Tremor Analysis
**Test with sv1.wav:**
```r
result <- analyze_tremor("inst/signalfiles/AVQI/input/sv1.wav")
```

**Compare all metrics:**
- FCoM (current: 0.9963, expected: ~0.599)
- FTrC (expected: ~0.353)
- ACoM (expected: ~0.442)
- ATrC (expected: varies)

### 3. Fix FCoM Calculation
Once correct formula is identified, update line ~206 in R/tremor.R

### 4. Test & Commit
After successful testing:
```bash
git add R/tremor.R
git commit -m "Fix FCoM calculation in tremor analysis"
```

## Key Files

**Modified:**
- `R/tremor.R` - Reviewed FCoM/ACoM calculations (needs FCoM fix)
- `src/pitch_wrappers.cpp` - Added intensity getters (complete)
- `R/pitch-r6.R` - Added intensity methods (complete)

**Test location:**
- Audio: `inst/signalfiles/AVQI/input/sv1.wav`
- Expected values from external analysis

## Technical Notes

### Pitch Frame Fields Usage
**intensity** (Pitch_Frame->intensity):
- Direct field access (no Praat API)
- Acoustic magnitude of frame (0-1 normalized)
- Used for: ACoM calculation (amplitude tremor)

**strength** (Pitch_Candidate->strength):
- Praat API: `Pitch_getStrength(pitch, frame)`
- Periodicity/cyclicality measure (0-1)
- Used for: FCoM calculation (frequency tremor)? ← VERIFY THIS

### Debug Output
Build verbose but successful (~3 min)
Can ignore debug prints for now (will remove later)

## References
- SESSION_SUMMARY_2025-12-11_PITCH_STRENGTH.md - Initial implementation
- PITCH_INTENSITY_QUICK_REF.md - API reference
- Brückl (2012) - Tremor measurement protocol
