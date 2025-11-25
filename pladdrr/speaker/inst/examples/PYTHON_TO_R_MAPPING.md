# Python Parselmouth to R speaker Mapping

## Overview

This document maps Python implementations using Parselmouth (from superassp) to equivalent R implementations using the speaker package.

## Summary of Python Implementations

Total Python files analyzed: 12 files, ~3,395 lines of code

### Core Analysis Functions (Already Implemented in speaker ✅)

1. **praat_pitch.py** (311 lines)
   - Multiple pitch tracking methods (cc, ac, SPINET, SHS)
   - R equivalent: `extract_pitch()` ✅
   - Status: **IMPLEMENTED** with autocorrelation method

2. **praat_formant_burg.py** (78 lines)
   - Formant tracking with Burg's algorithm
   - Optional formant tracking (smoothing)
   - Formant intensity calculation
   - R equivalent: `extract_formants()` ✅
   - Status: **IMPLEMENTED** with Burg's LPC

3. **praat_intensity.py** (75 lines)
   - Intensity contour extraction
   - R equivalent: `extract_intensity()` ✅
   - Status: **IMPLEMENTED**

### Advanced Composite Measures (Need Implementation 🔨)

4. **praat_voice_report_memory.py** (305 lines)
   - Comprehensive voice quality analysis
   - Measures: Jitter, Shimmer, HNR, NHR
   - Pitch statistics
   - Voice breaks analysis
   - R equivalent: **NEW FUNCTION NEEDED** `voice_report()`

5. **praat_spectral_moments.py** (116 lines)
   - Center of gravity, SD, Skewness, Kurtosis
   - Time-varying spectral shape analysis
   - R equivalent: **NEW FUNCTION NEEDED** `spectral_moments()`

6. **praat_formantpath_burg.py** (176 lines)
   - Ceiling optimization for formant tracking
   - Tests multiple ceiling values
   - R equivalent: **ENHANCEMENT NEEDED** `optimize_formant_ceiling()`

### Clinical Voice Indices (Complex - Future Phase 🔮)

7. **praat_avqi_memory.py** (324 lines)
   - Acoustic Voice Quality Index
   - Combines multiple acoustic measures
   - Requires: HNR, shimmer, spectral slope, tilt, CPP
   - R equivalent: **FUTURE** `avqi()`

8. **praat_dsi_memory.py** (319 lines)
   - Dysphonia Severity Index
   - Clinical voice assessment tool
   - R equivalent: **FUTURE** `dsi()`

9. **praat_praatsauce_memory.py** (416 lines)
   - Voice source measures (VoiceSauce implementation)
   - Spectral measures, harmonics, etc.
   - R equivalent: **FUTURE** `voice_sauce()`

10. **praat_sauce_memory.py** (434 lines)
    - Extended VoiceSauce measures
    - R equivalent: **FUTURE** `sauce_measures()`

11. **praat_voice_tremor_memory.py** (772 lines)
    - Voice tremor analysis
    - Frequency and amplitude modulation
    - R equivalent: **FUTURE** `voice_tremor()`

## Implementation Priority

### Phase 2.5: Immediate Extensions (This Session) 🎯

Priority functions that complete the basic phonetic analysis toolkit:

1. **voice_report()** - Essential voice quality measures
   - Jitter (local, rap, ppq5, ddp)
   - Shimmer (local, apq3, apq5, apq11, dda)
   - HNR (Harmonics-to-Noise Ratio)
   - NHR (Noise-to-Harmonics Ratio)
   - Voice breaks
   - Estimated effort: 2 hours

2. **spectral_moments()** - Spectral shape analysis
   - Center of gravity
   - Standard deviation
   - Skewness
   - Kurtosis
   - Estimated effort: 1 hour

3. **optimize_formant_ceiling()** - Better formant tracking
   - Test multiple ceiling values
   - Find optimal parameters
   - Estimated effort: 1 hour

**Total for Phase 2.5**: ~4 hours → Brings package to 85% complete

### Phase 3: Clinical Indices (Future Session) 🔮

Advanced clinical assessment tools:

4. **avqi()** - Acoustic Voice Quality Index
5. **dsi()** - Dysphonia Severity Index
6. **voice_sauce()** - VoiceSauce measures
7. **voice_tremor()** - Tremor analysis

**Total for Phase 3**: ~8-12 hours → Brings package to 100%

## Detailed Mapping

### 1. Pitch Extraction

**Python (praat_pitch.py)**:
```python
import parselmouth as pm

sound = pm.Sound("audio.wav")
pitch_cc = pm.praat.call(sound, "To Pitch (cc)", 
    time_step, min_f0, max_candidates, very_accurate,
    silence_threshold, voicing_threshold, 
    octave_cost, octave_jump_cost, 
    voiced_voiceless_cost, max_f0)
```

**R (speaker)** ✅:
```r
library(speaker)

sound <- read_sound("audio.wav")
pitch <- extract_pitch(sound,
  time_step = 0.005,
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_candidates = 15,
  very_accurate = TRUE,
  silence_threshold = 0.03,
  voicing_threshold = 0.45,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14
)
```

**Status**: ✅ Implemented (autocorrelation method)

### 2. Formant Extraction

**Python (praat_formant_burg.py)**:
```python
sound = pm.Sound("audio.wav")
formants = sound.to_formant_burg(
    time_step=0.005,
    max_number_of_formants=5,
    maximum_formant=5500,
    window_length=0.025,
    pre_emphasis_from=50
)
```

**R (speaker)** ✅:
```r
sound <- read_sound("audio.wav")
formants <- extract_formants(sound,
  time_step = 0.005,
  max_formant = 5500,
  n_formants = 5,
  window_length = 0.025,
  pre_emphasis_from = 50
)
```

**Status**: ✅ Implemented (Burg's algorithm)

### 3. Intensity Extraction

**Python (praat_intensity.py)**:
```python
sound = pm.Sound("audio.wav")
intensity = pm.praat.call(sound, "To Intensity",
    minimum_pitch, time_step, subtract_mean)
```

**R (speaker)** ✅:
```r
sound <- read_sound("audio.wav")
intensity <- extract_intensity(sound,
  minimum_pitch = 100,
  time_step = 0.0,
  subtract_mean = TRUE
)
```

**Status**: ✅ Implemented

### 4. Voice Report (NEW - Priority 1) 🔨

**Python (praat_voice_report_memory.py)**:
```python
result = praat_voice_report_memory(
    audio_np, sample_rate,
    min_f0=75, max_f0=600
)
# Returns dict with jitter, shimmer, HNR, etc.
```

**R (speaker)** - TO IMPLEMENT:
```r
sound <- read_sound("audio.wav")
report <- voice_report(sound,
  pitch_floor = 75,
  pitch_ceiling = 600,
  from_time = 0,
  to_time = 0
)
# Returns data.frame with all measures
```

**Status**: 🔨 TO IMPLEMENT

### 5. Spectral Moments (NEW - Priority 2) 🔨

**Python (praat_spectral_moments.py)**:
```python
moments = praat_spectral_moments(
    sound,
    windowLength=0.005,
    time_step=0.005,
    power=2.0
)
```

**R (speaker)** - TO IMPLEMENT:
```r
sound <- read_sound("audio.wav")
moments <- spectral_moments(sound,
  window_length = 0.005,
  time_step = 0.005,
  power = 2.0
)
# Returns data.frame: time, cog, sd, skewness, kurtosis
```

**Status**: 🔨 TO IMPLEMENT

### 6. Formant Ceiling Optimization (NEW - Priority 3) 🔨

**Python (praat_formantpath_burg.py)**:
```python
# Tests multiple ceiling values
formants = praat_formantpath_burg(
    sound,
    ceiling_range=[4500, 5000, 5500, 6000],
    stress_pattern=[2, 1, 3]
)
```

**R (speaker)** - TO IMPLEMENT:
```r
sound <- read_sound("audio.wav")
optimized <- optimize_formant_ceiling(sound,
  ceiling_range = c(4500, 5000, 5500, 6000),
  gender = "female"
)
# Returns best ceiling and formants
```

**Status**: 🔨 TO IMPLEMENT

## Implementation Strategy

### Step 1: Voice Report (Most Important)

The voice_report() function provides essential clinical measures. Implementation approach:

1. Use existing `extract_pitch()` to get pitch object
2. Implement jitter calculations (requires point process)
3. Implement shimmer calculations (requires pulses)
4. Implement HNR/NHR (requires harmonicity object)
5. Combine into comprehensive report

**New Functions Needed**:
- `extract_point_process()` - Get pitch marks
- `get_jitter_*()` - Various jitter measures
- `get_shimmer_*()` - Various shimmer measures  
- `extract_harmonicity()` - HNR analysis
- `voice_report()` - Wrapper combining all measures

### Step 2: Spectral Moments

Spectral shape analysis. Implementation approach:

1. Create spectrogram from sound
2. For each time frame, extract spectrum
3. Calculate moments (weighted statistics)
4. Return time series

**New Functions Needed**:
- `extract_spectrogram()` - Create spectrogram object
- `extract_spectrum()` - Get spectrum slice
- `get_spectral_moments()` - Calculate moments
- `spectral_moments()` - Main wrapper

### Step 3: Formant Optimization

Find best formant ceiling. Implementation approach:

1. Try multiple ceiling values
2. Track formants with each ceiling
3. Score based on continuity/smoothness
4. Return best parameters

**New Functions Needed**:
- `optimize_formant_ceiling()` - Main function
- Helper scoring functions

## File Organization

```
inst/examples/
├── PYTHON_TO_R_MAPPING.md           # This file
├── 01_basic_analysis.R              # Pitch, formants, intensity
├── 02_voice_quality.R               # Voice report example
├── 03_spectral_analysis.R           # Spectral moments
├── 04_formant_optimization.R        # Ceiling optimization
├── 05_complete_workflow.R           # Full analysis pipeline
└── README.md                        # Quick start guide
```

## Testing Strategy

For each new function:

1. **Unit tests** - Test individual components
2. **Integration tests** - Test with real audio
3. **Validation tests** - Compare with Python/Praat output
4. **Edge case tests** - Handle errors gracefully

## Expected Completion Timeline

- **Phase 2.5** (This session): 4 hours
  - voice_report(): 2 hours
  - spectral_moments(): 1 hour
  - optimize_formant_ceiling(): 1 hour
  - Examples and tests: Included
  - **Result**: 85% complete

- **Phase 3** (Future session): 8-12 hours
  - Clinical indices (AVQI, DSI, etc.)
  - Voice tremor analysis
  - Advanced spectral measures
  - **Result**: 100% complete

## Benefits of R Implementation

1. **No Python dependency** - Pure R solution
2. **Better integration** - Works with R data structures
3. **Memory efficient** - No data serialization
4. **Type safe** - R's type system
5. **Easier debugging** - All in one language
6. **Package ecosystem** - Use R's tools
7. **Performance** - C++ backend via Rcpp

## Notes

- All Python implementations use Parselmouth's `pm.praat.call()` which calls Praat functions
- Our R implementation replicates Praat algorithms directly in C++/R
- Some functions (like voice report) require multiple Praat objects working together
- We focus on the most commonly used measures first

---

**Document Status**: Complete  
**Last Updated**: 2025-01-08  
**Next Action**: Implement Phase 2.5 functions
