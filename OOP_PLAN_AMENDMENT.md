# Object-Oriented Implementation Plan Amendment

**Date**: 2025-11-08  
**Status**: Plan Revised and Expanded

## Problem Identified

The initial implementation approach focused on specific acoustic procedures (pitch extraction, formant analysis, etc.) rather than exposing Praat's underlying **object-oriented architecture**. This meant:

1. **Limited coverage**: Only a few specific analyses were accessible
2. **Not idiomatic**: Didn't match how Praat actually works
3. **Python dependency**: Couldn't fully replace Python Parselmouth
4. **Hard to extend**: Each new feature required custom wrappers

## Key Insight from Parselmouth

After analyzing the Python Parselmouth library and how it's used in `/Users/frkkan96/Documents/src/superassp/inst/python/`, the successful pattern is clear:

### Parselmouth's Winning Strategy:
```python
# Wrap Praat OBJECTS, not procedures
sound = parselmouth.Sound("audio.wav")
pitch = sound.to_pitch()  # Object method, not standalone function
mean_f0 = pitch.get_mean()  # Query method on object

# Generic call for anything
result = parselmouth.praat.call(object, "Command", args...)
```

### Our Previous Approach (Procedural):
```r
# Standalone functions
sound <- read_sound("audio.wav")
pitch <- extract_pitch(sound)  # Function, not method
mean_f0 <- get_mean_pitch(pitch)
```

### Our New Approach (Object-Oriented):
```r
# R6 objects mirroring Praat
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch()  # Method on Sound object
mean_f0 <- pitch$get_mean()  # Method on Pitch object

# Eventually: Generic call
result <- praat_call(object, "Command", args...)
```

## Revised Plan: Complete Praat Object Hierarchy

Instead of implementing isolated procedures, we're now implementing **all major Praat object types**:

### Phase 1: Core Objects (IN PROGRESS)
- ✅ Sound (mostly complete)
- ✅ Pitch (mostly complete)
- ⚠️ Formant (needs completion - missing query methods)
- ⚠️ Intensity (needs completion - missing query methods)
- ❌ Harmonicity (NEW - needed for voice quality)

### Phase 2: Spectral Objects (PLANNED)
- ❌ Spectrum (frequency domain analysis)
- ❌ Spectrogram (time-frequency representation)
- ❌ LTAS (long-term average spectrum)

### Phase 3: Annotation Objects (CRITICAL - PLANNED)
- ❌ **TextGrid** (HIGH PRIORITY - essential for phonetic research)
  - IntervalTier support
  - PointTier support
  - Annotation queries and modifications
  
### Phase 4: Advanced Analysis (PLANNED)
- ❌ PointProcess (events, jitter/shimmer)
- ❌ Manipulation (PSOLA pitch/duration modification)
- ❌ LPC (linear predictive coding)
- ❌ FormantPath (optimal formant tracking with ceiling optimization)

### Phase 5: Generic Interface (PLANNED)
- ❌ `praat_call()` function (call ANY Praat command)

## What This Enables

### 1. Direct Praat Script Translation

**Praat Script:**
```praat
sound = Read from file: "audio.wav"
pitch = To Pitch: 0, 75, 600
mean_pitch = Get mean: 0, 0, "Hertz"
```

**R Translation:**
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(time_step = 0, pitch_floor = 75, pitch_ceiling = 600)
mean_pitch <- pitch$get_mean(from_time = 0, to_time = 0, unit = "Hertz")
```

### 2. Complete Praat Functionality

Any analysis possible in Praat will be possible in R:
- TextGrid annotations
- PSOLA modifications
- Spectral analysis
- Voice quality metrics
- Complex pipelines

### 3. Zero Python Dependency

No need for `reticulate` or `parselmouth` - direct C++ bindings to Praat.

### 4. Consistent, Predictable API

**Naming conventions** (already established):
- `get_[property]()` - query methods
- `to_[type]()` - transformation methods
- `extract_[subset]()` - subset extraction
- `as_[format]()` - export methods

## Implementation Priorities

### IMMEDIATE (Next 2 weeks):
1. **TextGrid** - Blocking phonetic research workflows
2. **Harmonicity** - Needed for voice quality analysis
3. **Complete Formant** - Add missing query methods
4. **Complete Intensity** - Add missing query methods

### SHORT-TERM (Weeks 3-4):
5. Spectrum + Spectrogram
6. PointProcess (jitter/shimmer)
7. FormantPath (optimal tracking)

### MEDIUM-TERM (Weeks 5-6):
8. Manipulation (PSOLA)
9. LPC analysis
10. Generic `praat_call()` interface

## Benefits of This Approach

1. **Comprehensive**: Access to ALL Praat functionality, not just specific analyses
2. **Maintainable**: Consistent patterns across all object types
3. **Extensible**: New Praat features can be added systematically
4. **Familiar**: Matches Praat's semantics and Parselmouth's proven design
5. **Efficient**: Zero-copy operations via external pointers
6. **Future-proof**: Generic call interface handles edge cases

## Technical Architecture

### R Layer (R6 Classes)
```
PraatObject (base)
├── Sound
├── Pitch
├── Formant
├── Intensity
├── Harmonicity
├── TextGrid
├── Spectrum
├── Spectrogram
├── PointProcess
├── Manipulation
└── LPC
```

### C++ Layer (Praat Wrappers)
```
sound_wrappers.cpp          ← Sound* operations
pitch_wrappers.cpp          ← Pitch* operations
formant_wrappers.cpp        ← Formant* operations
intensity_wrappers.cpp      ← NEW
harmonicity_wrappers.cpp    ← NEW
textgrid_wrappers.cpp       ← NEW
spectrum_wrappers.cpp       ← NEW
spectrogram_wrappers.cpp    ← NEW
pointprocess_wrappers.cpp   ← NEW
manipulation_wrappers.cpp   ← NEW
lpc_wrappers.cpp           ← NEW
```

## Success Metrics

✅ Can translate any Praat script to R directly  
✅ All major Praat object types accessible  
✅ Zero dependency on Python/Parselmouth  
✅ Performance matches or exceeds Python implementation  
✅ API is consistent and predictable  
✅ Comprehensive documentation with translation examples  

## Next Actions

1. ✅ Review Parselmouth architecture and usage patterns
2. ✅ Create comprehensive OOP implementation plan
3. ⏭️ Implement TextGrid class (CRITICAL)
4. ⏭️ Implement Harmonicity class
5. ⏭️ Complete Formant and Intensity classes
6. ⏭️ Create examples replicating superassp Python code in pure R
7. ⏭️ Continue with spectral objects
8. ⏭️ Implement generic praat_call() interface

## References

- **Detailed Plan**: `specs/001-praat-r-access/COMPLETE-OOP-IMPLEMENTATION-PLAN.md`
- **Naming Conventions**: `specs/001-praat-r-access/NAMING-CONVENTIONS.md`
- **Parselmouth Examples**: `/Users/frkkan96/Documents/src/superassp/inst/python/`
- **Praat Source**: `src/praat/` (submodule)

---

**Summary**: We're shifting from implementing specific procedures to exposing Praat's complete object-oriented architecture, enabling R users to access the full power of Praat directly, with an API that allows easy translation from Praat scripts.
