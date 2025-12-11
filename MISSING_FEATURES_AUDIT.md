# Package Audit: Missing Features from Previous Version

## Issue #1: Missing Gaussian1 Window Support ❌ NOT FIXED

**Current Status**: Only 5 window shapes supported in `Sound$extract_part()`
- rectangular (0)
- hamming (1) 
- bartlett (2)
- welch (3)
- hanning (4)

**Missing from Praat**: 
- triangular (1) ← WRONG MAPPING!
- parabolic (2) ← WRONG MAPPING!
- Gaussian1 through Gaussian5 (5-9)
- Kaiser1, Kaiser2 (10-11)

**Praat Enum** (from `Sound_enums.h`):
```
0  = RECTANGULAR
1  = TRIANGULAR
2  = PARABOLIC  
3  = HANNING
4  = HAMMING
5  = GAUSSIAN_1
6  = GAUSSIAN_2
7  = GAUSSIAN_3
8  = GAUSSIAN_4
9  = GAUSSIAN_5
10 = KAISER_1
11 = KAISER_2
```

**Current pladdrr mapping** (WRONG):
```r
"rectangular" = 0  ✓
"hamming" = 1      ✗ Should be 4
"bartlett" = 2     ✗ Should be... (Bartlett not in Praat enum!)
"welch" = 3        ✗ (Welch not in Praat enum!)
"hanning" = 4      ✗ Should be 3
```

**FIX NEEDED**: Correct enum mapping + add all Praat window types

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

## Issue #3: Sound + Pitch → PointProcess (peaks) ⚠️ PARTIALLY FIXED

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

### ❌ Pitch$to_point_process_peaks() - MISSING
Two-object command using existing Pitch:
```r
# SHOULD EXIST BUT DOESN'T:
pitch <- sound$to_pitch()
pp <- pitch$to_point_process_peaks(sound, 
                                    include_maxima = TRUE,
                                    include_minima = FALSE)
```
Should use: `Sound_Pitch_to_PointProcess_peaks(sound, pitch, maxima, minima)`

**FIX NEEDED**: Add wrapper + R6 method for `Sound_Pitch_to_PointProcess_peaks()`

---

## Summary

| Issue | Status | Action Required |
|-------|--------|-----------------|
| 1. Gaussian1 windows | ❌ BROKEN | Fix enum mapping + add all window types |
| 2. Interpolation parameter | ✅ FIXED | None |
| 3. Sound+Pitch→PP(peaks) | ⚠️ PARTIAL | Add `Pitch$to_point_process_peaks(sound, ...)` method |

## Priority

**HIGH**: Issue #1 (window shapes) - Current implementation has WRONG enum values, may produce incorrect results
**MEDIUM**: Issue #3 - Workaround exists via `to_point_process_periodic_peaks()`
