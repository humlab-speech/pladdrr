# Pitch Intensity & Strength API - Quick Reference

## Summary
Added direct access to Pitch_Frame intensity & candidate strength fields for tremor/voice quality analysis.

**Package:** pladdrr v1.2.2  
**Session:** 2025-12-11  

---

## New R6 Methods

### Get Intensity at Time Point
```r
pitch$get_intensity_at_time(time)
```
**Returns:** Numeric (0-1), frame intensity  
**Use:** FCoM/ACoM calculation, amplitude contour

### Get Mean Intensity Over Range
```r
pitch$get_mean_intensity(from_time = 0, to_time = 0)
```
**Params:** `from_time`, `to_time` (0 = start/end)  
**Returns:** Numeric (0-1), average intensity  
**Use:** Voice quality metrics

### Get Strength at Time Point
```r
pitch$get_strength_at_time(time, unit = "HERTZ", interpolate = FALSE)
```
**Returns:** Numeric (0-1), autocorrelation peak height  
**Use:** Pitch tracking confidence

### Get Mean Strength Over Range
```r
pitch$get_mean_strength(from_time = 0, to_time = 0, unit = "HERTZ")
```
**Returns:** Numeric (0-1), average strength  
**Use:** Overall voicing quality

### Export to Data Frame
```r
pitch$as_data_frame(include_intensity = TRUE, include_strength = TRUE)
```
**Returns:** data.frame with columns:
- `time` (s)
- `frequency` (Hz)
- `voiced` (logical)
- `intensity` (if enabled, 0-1)
- `strength` (if enabled, 0-1)

**Use:** Bulk extraction for analysis/plotting

---

## Implementation

### Why Direct Access?
Praat has **NO API function** for Pitch_Frame intensity. Only way: direct C struct field access.

### C++ Struct
```cpp
struct Pitch_Frame {
    double intensity;  // ← NEW: directly accessible via wrappers
    int nCandidates;
    struct {
        double frequency;
        double strength;  // ← Already accessible
    } candidates[];
};
```

### Files Modified
**C++:** `src/pitch_wrappers.cpp` (4 new functions)  
**R6:** `R/pitch-r6.R` (5 new methods)  
**Auto:** `R/RcppExports.R`, `src/RcppExports.cpp`

---

## Use Cases

### Tremor Analysis (Brückl Protocol)
```r
# Extract F0 contour from audio
pitch <- sound$to_pitch(...)
df <- pitch$as_data_frame(include_intensity = TRUE)

# Frequency Contour Magnitude
fcom <- max(df$intensity, na.rm = TRUE)
```

**Note:** For contour Pitch objects (created from F0/amplitude contours), use **ALL frames** not just voiced. Contours aren't periodic audio.

### Voice Quality Assessment
```r
# Average intensity (amplitude level)
amp_level <- pitch$get_mean_intensity(0, 0)

# Average strength (voicing confidence)
voicing_quality <- pitch$get_mean_strength(0, 0)
```

### Time-Series Plotting
```r
df <- pitch$as_data_frame(include_intensity = TRUE, include_strength = TRUE)

# Plot intensity over time
plot(df$time, df$intensity, type="l", 
     main="Frame Intensity", xlab="Time (s)", ylab="Intensity (0-1)")

# Plot strength over time
plot(df$time, df$strength, type="l",
     main="Pitch Strength", xlab="Time (s)", ylab="Strength (0-1)")
```

---

## Intensity vs Strength

| Property | What It Is | Range | Used For |
|----------|-----------|-------|----------|
| **Intensity** | Normalized local peak amplitude | 0-1 | Tremor (FCoM/ACoM), amplitude contours |
| **Strength** | Autocorrelation peak height | 0-1 | Pitch tracking confidence, voicing quality |

**Key insight:** Intensity = how loud, Strength = how periodic

---

## Current Status

### ✅ Working
- Pitch intensity/strength API complete
- Tremor analysis function (`analyze_tremor()`) implemented
- Export to NAMESPACE

### ⚠️ Outstanding Issues
1. **FCoM/ACoM values too low** (0.15 vs expected ~0.5-0.6)
   - May need different contour normalization
   - Need to verify against Brückl papers
   
2. **Debug logging pollution**
   - Praat source files have excessive fprintf output
   - Need to comment out debug statements

### 📝 Next Steps
1. Review Brückl (2012, 2015) papers for exact FCoM/ACoM protocol
2. Test with multiple audio files
3. Remove debug fprintf from Praat source
4. Add unit tests for tremor functions
5. Document in vignette

See `SESSION_SUMMARY_2025-12-11_TREMOR_METRICS.md` for complete session details.
