# Object-Oriented Paradigm Shift - Summary

**Date**: 2025-11-11  
**Status**: ACTIVE AMENDMENT - Fundamental Architecture Change

## What Changed

The speaker package is shifting from a **procedural, function-based approach** to a **comprehensive object-oriented system** that mirrors Praat's native C++ architecture.

## Why

### Original Approach (WRONG)
```r
# Procedural - ignores Praat's OOP design
pitch_data <- praat_extract_pitch(audio_file, min_pitch = 75)
formant_data <- praat_extract_formant(audio_file, max_formant = 5500)
```

**Problems**:
- Ignores Praat's ~30+ object types with inheritance
- Forces repeated data copying
- No object persistence or method chaining
- Missing critical features (TextGrid, Manipulation)

### New Approach (CORRECT)
```r
# Object-oriented - mirrors Praat's design
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant_hz = 5500)

mean_f0 <- pitch$get_mean(unit = "hertz")
f1_mean <- formant$get_mean(formant_number = 1)

# Now possible: TextGrid annotation
tg <- TextGrid$new("annotation.TextGrid")
intervals <- tg$as_data_frame(tiers = "words")

# Now possible: Pitch manipulation
manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(1.2)  # Raise pitch 20%
modified <- manip$get_resynthesis_overlap_add()
```

## Key Decisions

### 1. R6 Classes for All Praat Objects

**Pattern**: R6 ↔ XPtr ↔ C++ Praat objects

```r
Sound <- R6Class("Sound",
  inherit = PraatObject,
  public = list(
    to_pitch = function(...),
    get_duration = function()
  ),
  private = list(ptr = NULL)  # XPtr to structSound*
)
```

### 2. Naming Convention

**Enables direct Praat → R translation**:

| Praat Command | R Method | Example |
|---------------|----------|---------|
| `Get duration` | `get_duration()` | `sound$get_duration()` |
| `To Pitch: 0, 75, 600` | `to_pitch(0, 75, 600)` | `sound$to_pitch(0, 75, 600)` |
| `Get mean: 0, 0, Hertz` | `get_mean(unit = "hertz")` | `pitch$get_mean()` |
| `Extract part: 0, 1` | `extract_part(0, 1)` | `sound$extract_part(0, 1)` |

**Rules**:
- `get_*()` - Query methods (read-only)
- `to_*()` - Transform to different object type
- `extract_*()` - Subset to same object type
- `scale_*()`, `filter_*()` - Modification methods
- `as_*()` - Export to R native types

### 3. Priority Objects

1. ⭐⭐⭐ **TextGrid** - Multi-tier annotation (90%+ of phonetic researchers)
2. ⭐⭐ **Manipulation** - PSOLA pitch/duration modification
3. ⭐⭐ **VoiceReport** - Comprehensive voice quality
4. ⭐ **Sound** - Foundation (40+ methods)
5. ⭐ **Pitch**, **Formant**, **Intensity** - Core analysis
6. **PointProcess**, Spectral objects, Tier objects

### 4. Media Loading

- **Native**: Praat file readers (WAV, AIFF)
- **Extended**: av package (humlab-speech/av fork) for MP3, MP4, FLAC, OGG

```r
# Native
sound <- Sound$new("audio.wav")

# Extended
sound <- Sound$new_from_av("podcast.mp3")
```

### 5. Future Extensions (NOT implementing now)

**Marked for post-CRAN**:
- Praat script interpreter (execute .praat files)
- Picture/Graphics (visualization exports)
- Additional objects on demand

## Implementation Status

### Current (v0.3.x - v0.4.x)
- ✅ Base infrastructure (PraatObject, XPtr, finalizers)
- ✅ Partial implementations of 15 objects
- ✅ ~60 methods implemented

### Next (v0.5.0 - v0.9.0)
- ⬜ Complete all core objects to 100% method coverage
- ⬜ TextGrid full implementation (35/35 methods) ⭐⭐⭐
- ⬜ VoiceReport comprehensive analysis
- ⬜ Re-implement superassp Python examples
- ⬜ 10 comprehensive vignettes
- ⬜ av package integration

### CRAN (v1.0.0)
- ⬜ 16+ objects, 300+ methods
- ⬜ 95%+ test coverage
- ⬜ Complete documentation
- ⬜ Cross-platform, zero memory leaks

## Files

**Main Amendment**: `specs/001-praat-r-access/OOP-PARADIGM-SHIFT-AMENDMENT.md`  
**Documentation**: Updated in `CLAUDE.md`

## Next Steps

1. ✅ Document OOP paradigm shift
2. ⬜ Complete Sound object (40/40 methods)
3. ⬜ Complete Pitch, Formant, Intensity objects
4. ⬜ Complete TextGrid object (CRITICAL)
5. ⬜ Implement VoiceReport
6. ⬜ Continue full implementation

---

**This is the comprehensive phonetic analysis toolkit R deserves!** 🎉
