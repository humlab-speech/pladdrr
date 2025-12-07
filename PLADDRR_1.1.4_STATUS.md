# pladdrr 1.1.4 Status Report & Critical Bug

**Date:** 2025-12-07
**pladdrr Version:** 1.1.4
**Status:** ⚠️ **MAJOR PROGRESS BUT CRITICAL BUG** - Two-object support added, but pitch detection broken

## Executive Summary

pladdrr 1.1.4 makes the **crucial breakthrough** by adding `Pitch$to_pointprocess_cc(sound)` - the two-object command support that was the main architectural blocker. However, a **critical bug in pitch detection** prevents all voiced sound analysis from working.

## ✅ Major Win: Two-Object Command Added!

### The Breakthrough

pladdrr 1.1.4 adds the method we've been waiting for:

```r
pitch <- sound$to_pitch_cc(...)
pp <- pitch$to_pointprocess_cc(sound = sound)  # ← NEW in 1.1.4!
```

**This is exactly what was needed!** Python's equivalent:
```python
pp = call([sound, pitch], "To PointProcess (cc)")
```

### Verification

```r
> "to_pointprocess_cc" %in% ls(pitch)
[1] TRUE

> str(pitch$to_pointprocess_cc)
function (sound)
```

**Status:** ✅ Method exists with correct signature

## ❌ Critical Bug: Pitch Detection Returns 0 Voiced Frames

### The Problem

**ALL pitch detection methods return 0 voiced frames for ALL sounds:**

```r
library(pladdrr)

# Test 1: Pure 440Hz tone
tone <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 44100)
pitch <- tone$to_pitch()
pitch$count_voiced_frames()
# [1] 0  ← SHOULD BE ~270

# Test 2: Real sustained vowel
sound <- Sound$new("sustained_vowel.wav")
pitch <- sound$to_pitch()
pitch$count_voiced_frames()
# [1] 0  ← Python detects 770 voiced frames

# Test 3: With all parameters
pitch <- sound$to_pitch_cc(
  time_step = 0, pitch_floor = 70, max_candidates = 15,
  very_accurate = FALSE, silence_threshold = 0.03,
  voicing_threshold = 0.8, octave_cost = 0.01,
  octave_jump_cost = 0.35, voiced_unvoiced_cost = 0.14,
  pitch_ceiling = 600
)
pitch$count_voiced_frames()
# [1] 0  ← Python detects 770 voiced frames
```

### Symptoms

1. `pitch$count_voiced_frames()` always returns 0
2. `pitch$get_value_at_time(time, "Hertz")` always returns NaN
3. `pitch$get_maximum(0, 0, "Hertz")` returns NaN
4. Pitch object has correct number of frames but all contain NaN values

### Impact

This bug **completely blocks** all voiced sound analysis:

- **DSI:** Cannot create VUV TextGrid → Cannot extract voiced segments → **FAILS**
- **AVQI:** Cannot detect sounding segments → **FAILS**
- **Any voice quality analysis:** Cannot detect voicing → **FAILS**

## Test Results

### Python (Baseline - Works)

```bash
$ python3 -c "
import parselmouth
from parselmouth.praat import call

sound = parselmouth.Sound('signalfiles/AVQI/input/sv1.wav')
pitch = call(sound, 'To Pitch (cc)', 0, 70, 15, 'no', 0.03, 0.8, 0.01, 0.35, 0.14, 600)
print(f'Voiced frames: {call(pitch, \"Count voiced frames\")}')
pp = call([sound, pitch], 'To PointProcess (cc)')
print(f'Points: {call(pp, \"Get number of points\")}')
"
```

**Output:**
```
Voiced frames: 770
Points: 402
```

### pladdrr 1.1.4 (Broken)

```bash
$ Rscript -e "
library(pladdrr)
sound <- Sound\$new('signalfiles/AVQI/input/sv1.wav')
pitch <- sound\$to_pitch_cc(0, 70, 15, FALSE, 0.03, 0.8, 0.01, 0.35, 0.14, 600)
cat('Voiced frames:', pitch\$count_voiced_frames(), '\n')
pp <- pitch\$to_pointprocess_cc(sound = sound)
cat('Points:', pp\$get_number_of_points(), '\n')
"
```

**Output:**
```
Voiced frames: 0
Points: 0
```

### 3-Way Validation Tests

```bash
$ python -m pytest tests/test_3way_validation.py -v
```

**Results:**
- **DSI:** ❌ FAILED - "No voiced intervals found in sound"
- **AVQI:** ❌ FAILED - "No sounding intervals found"
- **Tremor:** ❌ FAILED - Returns all zeros

All fail due to pitch detection bug.

## Comparison: What Changed in 1.1.4

| Feature | 1.1.3 | 1.1.4 | Status |
|---------|-------|-------|--------|
| `Pitch$to_pointprocess_cc(sound)` | ❌ Missing | ✅ **Added** | ✅ FIXED |
| Pitch detection (to_pitch, to_pitch_cc) | ✅ Worked | ❌ **Broken** | ❌ **REGRESSION** |
| `count_voiced_frames()` | ✅ Worked | ❌ Returns 0 | ❌ **REGRESSION** |
| `get_value_at_time()` | ✅ Worked | ❌ Returns NaN | ❌ **REGRESSION** |
| `to_textgrid_silences` parameters | ⚠️ 2 params | ⚠️ 2 params | ⚠️ Still limited |

## Technical Details

### Version Information

```r
> packageDescription("pladdrr")$Version
[1] "1.1.4"

> praat_version()
[1] "pladdrr v0.9.11 (Praat C library integration)"
```

**Package version:** 1.1.4
**Built:** 2025-12-07 05:59:04 UTC
**Praat library:** v0.9.11

### Pitch Object Inspection

```r
sound <- Sound$create_tone(440, 1.0, 44100)
pitch <- sound$to_pitch()

pitch$get_number_of_frames()
# [1] 43997  ← Has frames

pitch$count_voiced_frames()
# [1] 0  ← But all unvoiced

pitch$get_value_at_time(0.5, "Hertz")
# [1] NaN  ← All values are NaN
```

The Pitch object is created with the correct number of frames, but every frame contains NaN for the F0 value.

## Root Cause Hypothesis

This appears to be a **regression** introduced in 1.1.4. Possible causes:

1. **C library integration issue** - The C function for pitch detection may not be called correctly
2. **Parameter passing bug** - Parameters may not be passed to Praat C library correctly
3. **Memory/pointer issue** - Pitch values might not be copied back from C to R correctly
4. **Initialization issue** - Pitch object might not be initialized properly

The fact that:
- Pitch object has correct number of frames
- But all F0 values are NaN
- And `count_voiced_frames()` returns 0

Suggests the issue is in **retrieving/setting the F0 values** after Praat computes them, not in the computation itself.

## What Works in 1.1.4

Despite the pitch detection bug, these features work:

✅ **Sound operations:**
- Loading WAV files
- Creating tones
- `get_duration()`, basic Sound methods
- `Sound$from_values()` (creates Sound from vector)

✅ **Non-pitch-dependent operations:**
- Intensity analysis (doesn't require pitch)
- Spectral analysis
- Sound concatenation
- extract_intervals_where (but needs working TextGrids)

✅ **Architecture:**
- Two-object command pattern now supported
- `Pitch$to_pointprocess_cc(sound)` exists and accepts Sound parameter

## What's Blocked

❌ **Everything requiring pitch detection:**
- DSI (needs voiced segment extraction)
- AVQI (needs voicing/silence detection)
- Tremor (needs F0 contour)
- Jitter/shimmer (needs periodic analysis)
- HNR (needs voicing detection)
- Any voice quality measure

## Recommendations

### For pladdrr Maintainers (URGENT)

**Priority 1: Fix pitch detection regression**

The bug is in one of these areas:
1. `Sound$to_pitch()` C binding
2. `Sound$to_pitch_cc()` C binding
3. `Sound$to_pitch_ac()` C binding
4. `Pitch$count_voiced_frames()` method
5. `Pitch$get_value_at_time()` / `Pitch$get_value_in_frame()` methods

**Test case to verify fix:**
```r
library(pladdrr)

# Should detect ~270 voiced frames:
tone <- Sound$create_tone(frequency = 440, duration = 1.0, sampling_rate = 44100)
pitch <- tone$to_pitch()

stopifnot(pitch$count_voiced_frames() > 0)
stopifnot(!is.nan(pitch$get_maximum(0, 0, "Hertz")))
stopifnot(abs(pitch$get_maximum(0, 0, "Hertz") - 440) < 10)

cat("✅ Pitch detection works!\n")
```

**Once fixed,** DSI and AVQI implementations should work immediately without code changes.

### For R Users

**Current workarounds:**

1. **Use pladdrr 1.1.3** - Pitch detection worked, but lacks `to_pointprocess_cc(sound)`
2. **Use Python/Parselmouth** - Fully functional
3. **Use reticulate** - Call Python from R
4. **Wait for pladdrr 1.1.5** - Bug fix release

### For This Project

**Status:**
- ✅ Python implementations: Complete, validated, production-ready
- ⏸️ R implementations: Architecturally ready (1.1.4 has needed methods), but blocked by pitch detection bug
- ⏳ Waiting for: pladdrr 1.1.5 with pitch detection bug fix

**When fixed:**
- No R code changes needed
- Run 3-way validation immediately
- Document final results

## Timeline

**pladdrr progress:**
- 1.1.0 → 1.1.1: Added TextGrid methods
- 1.1.1 → 1.1.2: Fixed extract_intervals_where segfault ✅
- 1.1.2 → 1.1.3: Added PointProcess$to_textgrid_vuv ✅
- 1.1.3 → 1.1.4: Added Pitch$to_pointprocess_cc ✅ BUT introduced pitch detection regression ❌
- 1.1.4 → 1.1.5 needed: **Fix pitch detection bug**

We're **one bug fix away** from fully functional R implementations.

## Conclusion

pladdrr 1.1.4 represents **critical architectural progress** - the two-object command support is now in place. However, a pitch detection bug prevents any voice analysis from working.

**The good news:** All the hard architectural work is done. The method we needed exists.

**The bad news:** A regression in pitch detection blocks everything.

**Next step:** pladdrr maintainers need to fix the pitch detection bug, then R implementations will work immediately.

---

**Test files:**
- `test_pladdrr_1.1.4_critical.R` - Demonstrates the bug
- `test_dsi_r.R` - Shows DSI failure
- `tests/test_3way_validation.py` - Complete test suite (all fail)

**Bug severity:** **CRITICAL** - Blocks all voice quality analysis

**Bug type:** **Regression** - Pitch detection worked in 1.1.3

**Estimated fix complexity:** **Medium** - Likely a single C binding or pointer issue
