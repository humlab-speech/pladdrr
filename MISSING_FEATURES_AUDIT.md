# Package Audit: Missing Features from Previous Version

## Issue #1: Gaussian1 Window Support ✅ FIXED in v1.2.2

**Status**: ALL window shapes now supported correctly in `Sound$extract_part()`

**Fixed on**: 2025-12-11 (commit 67e4b65)

**Current Implementation** (CORRECT):
```r
"rectangular" = 0   # kSound_windowShape::RECTANGULAR
"triangular"  = 1   # kSound_windowShape::TRIANGULAR
"parabolic"   = 2   # kSound_windowShape::PARABOLIC
"hanning"     = 3   # kSound_windowShape::HANNING
"hamming"     = 4   # kSound_windowShape::HAMMING
"Gaussian1"   = 5   # kSound_windowShape::GAUSSIAN_1
"Gaussian2"   = 6   # kSound_windowShape::GAUSSIAN_2
"Gaussian3"   = 7   # kSound_windowShape::GAUSSIAN_3
"Gaussian4"   = 8   # kSound_windowShape::GAUSSIAN_4
"Gaussian5"   = 9   # kSound_windowShape::GAUSSIAN_5
"Kaiser1"     = 10  # kSound_windowShape::KAISER_1
"Kaiser2"     = 11  # kSound_windowShape::KAISER_2
```

**Verified**: All 12 window shapes tested and working ✓

**File**: `R/sound-r6-new.R` lines 944-958

---

## Issue #2: get_value_at_time() Interpolation ✅ ALREADY FIXED

**Status**: WORKING CORRECTLY

**Evidence**:
```r
# R layer (pitch-r6.R)
get_value_at_time = function(time, unit = "hertz", interpolate = TRUE) {
  .pitch_get_value_at_time(private$ptr, time, unit_code, interpolate)
}
```

```cpp
// C++ layer (pitch_wrappers.cpp)
double pitch_get_value_at_time(
    XPtr<structPitch> pitch,
    double time,
    int unit,
    bool interpolate  // ✓ Parameter exists
) {
    double value = Pitch_getValueAtTime(
        pitch.get(),
        time,
        static_cast<kPitch_unit>(unit),
        interpolate  // ✓ Passed to Praat
    );
}
```

✅ **NO ACTION NEEDED**

---

## Issue #3: Sound + Pitch → PointProcess (peaks) ✅ FIXED in v1.2.2

**Status**: Method exists and works correctly

**Fixed on**: 2025-12-11 (commit 67e4b65)

**Available Methods**:

### ✅ Sound$to_point_process_periodic_peaks() - WORKS
Single-object command that internally creates Pitch:
```r
pp <- sound$to_point_process_periodic_peaks(
  pitch_floor = 75,
  pitch_ceiling = 600,
  include_maxima = TRUE,
  include_minima = FALSE
)
```
Uses: `Sound_to_PointProcess_periodic_peaks(sound, ...)`

### ✅ Pitch$to_point_process_cc() - WORKS  
Uses existing Pitch + Sound pair:
```r
pitch <- sound$to_pitch()
pp <- pitch$to_point_process_cc(sound)  # Two-object command
```
Uses: `Sound_Pitch_to_PointProcess_cc(sound, pitch)`

### ✅ Pitch$to_pointprocess_peaks() - WORKS
Two-object command using existing Pitch:
```r
pitch <- sound$to_pitch()
pp <- pitch$to_pointprocess_peaks(sound, 
                                   include_maxima = TRUE,
                                   include_minima = FALSE)
```
Uses: `Sound_Pitch_to_PointProcess_peaks(sound, pitch, maxima, minima)`

**File**: `R/pitch-r6.R` lines 389-404

---

## Summary

| Issue | Status | Action Required |
|-------|--------|-----------------|
| 1. Gaussian1 windows | ✅ FIXED | None - all 12 window types working |
| 2. Interpolation parameter | ✅ FIXED | None |
| 3. Sound+Pitch→PP(peaks) | ✅ FIXED | None |

## Status Update

**All issues resolved in v1.2.2 (2025-12-11)**

This audit document is now historical. All identified missing features have been implemented and tested.

**Last Updated**: 2025-12-14
**Package Version**: 1.2.5
