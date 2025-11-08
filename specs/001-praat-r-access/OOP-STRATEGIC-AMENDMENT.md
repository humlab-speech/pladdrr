# Object-Oriented Strategic Amendment

**Date:** 2025-11-08  
**Status:** Active Strategic Direction  
**Supersedes:** Initial functional/procedural approach

## Executive Summary

This amendment shifts the `speaker` package implementation from a function-based approach to a **comprehensive object-oriented architecture** that mirrors Praat's native C++ design. This change is based on:

1. **Analysis of Praat source code** revealing a rich OOP hierarchy with 30+ object types
2. **Success of Python's Parselmouth** which uses an object-oriented design
3. **User needs** for complete phonetic analysis workflows, not just isolated functions

## Problem Statement

### Original Approach (Procedural)

The initial specification focused on standalone functions:

```r
# Functional approach
pitch_data <- praat_extract_pitch(audio_file, min_pitch = 75, max_pitch = 600)
formant_data <- praat_extract_formant(audio_file, max_formant = 5500)
intensity_data <- praat_extract_intensity(audio_file)
```

**Limitations:**
- Doesn't reflect how Praat actually works (object-oriented)
- Requires reading/copying data repeatedly
- No persistent object state between operations
- Missing critical objects (TextGrid, Manipulation, Tier objects)
- Difficult to compose complex analysis pipelines
- Doesn't match Praat script mental model

### Amended Approach (Object-Oriented)

```r
# Object-oriented approach - mirrors Praat
sound <- Sound$new("audio.wav")

# Extract analysis objects
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 600)
formant <- sound$to_formant_burg(max_formant_hz = 5500)
intensity <- sound$to_intensity()

# Query methods
mean_f0 <- pitch$get_mean(unit = "hertz")
f1_values <- formant$get_value_at_time(formant_number = 1, time = 0.5)

# TextGrid annotation (CRITICAL - previously missing)
tg <- TextGrid$new("annotation.TextGrid")
word_intervals <- tg$as_data_frame(tiers = "words")

# Pitch manipulation (CRITICAL - previously missing)
manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(factor = 1.2)  # Raise pitch 20%
manip$replace_pitch_tier(pitch_tier)
modified_sound <- manip$get_resynthesis_overlap_add()
modified_sound$save("higher_pitch.wav")
```

## Praat Object Architecture Analysis

### Inheritance Hierarchy (from Praat source)

Based on analysis of `src/praat.github.io/fon/`:

```
Thing (base for all Praat objects)
├── Function (base for time-based objects)
│   ├── Sampled
│   │   └── Pitch (F0 contour)
│   ├── Vector (1D array over time/frequency)
│   │   ├── Sound (audio waveform)
│   │   ├── Intensity (loudness contour)
│   │   ├── Harmonicity (HNR contour)
│   │   ├── Ltas (long-term spectrum)
│   │   └── Excitation
│   ├── Matrix (2D array)
│   │   ├── Spectrogram (time-frequency)
│   │   ├── Spectrum (frequency domain)
│   │   └── Cochleagram
│   └── PointProcess (time point sequence)
├── Formant (formant tracks - special structure)
├── TextGrid (annotation tiers)
├── Manipulation (PSOLA modification object)
├── LPC (linear predictive coding)
└── [Tier objects]
    ├── PitchTier (modifiable pitch contour)
    ├── FormantGrid (modifiable formant tracks)
    ├── IntensityTier (modifiable intensity)
    └── DurationTier (time warping)
```

### Method Pattern Analysis

Praat objects follow consistent method patterns:

| Pattern | Purpose | Example Functions |
|---------|---------|------------------|
| `[Object]_create()` | Constructor | `Sound_create()`, `Pitch_create()` |
| `[Object]_readFromFile()` | I/O | `Sound_readFromSoundFile()`, `TextGrid_readFromFile()` |
| `[Object]_get*()` | Query properties | `Sound_getDuration()`, `Pitch_getMean()` |
| `[Object]_to_[Other]()` | Transform to different type | `Sound_to_Pitch()`, `Pitch_to_PitchTier()` |
| `[Object]_extract*()` | Extract subset (same type) | `Sound_extractPart()`, `TextGrid_extractPart()` |
| `[Object]_[action]()` | Modify | `Sound_scaleIntensity()`, `Pitch_smooth()` |
| `[Object]_save()` / `[Object]_writeToFile()` | Export | `Sound_saveAsWavFile()`, `TextGrid_writeToTextFile()` |

## Complete Object Catalog with Priorities

### Priority 1: Foundation Objects (WEEKS 1-4)

**Sound** (fon/Sound.h) ⭐ FOUNDATION
- Current: Partially implemented (~15/40 methods)
- Missing critical methods:
  - Filtering: `filter_pass_hann_band()`, `filter_stop_hann_band()`
  - Pre-emphasis: `pre_emphasize()`, `de_emphasize()`
  - Modification: `resample()`, `lengthen()`, `deepen_band_modulation()`
  - Combination: `concatenate()`, `convolve()`, `cross_correlate()`
  - Transforms: `to_spectrogram()`, `to_spectrum()`, `to_lpc()`, `to_manipulation()`
- **Action:** Implement remaining ~25 methods

**Pitch** (fon/Pitch.h) ⭐ CORE
- Current: Basic R6 implementation (~8/20 methods)
- Missing:
  - Modification: `smooth()`, `interpolate()`, `kill_octave_jumps()`
  - Statistics: `get_quantile()`, `count_voiced_frames()`
  - Transforms: `to_pitch_tier()`, `to_point_process()`, `to_sound()` (resynthesize)
- **Action:** Add remaining ~12 methods

**Formant** (fon/Formant.h) ⭐ CORE
- Current: S3 implementation (needs R6 conversion)
- Needs: ~15 methods total
  - Query: `get_value_at_time()`, `get_bandwidth_at_time()`, statistics
  - Tracking: `track()` with reference formants
  - Transforms: `down_to_formant_grid()`, `down_to_table()`
- **Action:** Convert to R6, implement all methods

**Intensity** (fon/Intensity.h) ⭐ CORE
- Current: S3 implementation (needs R6 conversion)
- Needs: ~12 methods total
  - Query: `get_value_at_time()`, statistics
  - Transforms: `down_to_intensity_tier()`
- **Action:** Convert to R6, implement all methods

**Harmonicity** (fon/Harmonicity.h) ⭐ CORE
- Current: S3 implementation (needs R6 conversion)
- Needs: ~10 methods total
  - Query: `get_value_at_time()`, statistics
- **Action:** Convert to R6, implement all methods

**PointProcess** (fon/PointProcess_def.h) ⭐
- Current: Basic R6 implementation
- Needs: Voice quality methods (with Sound)
  - Jitter: `get_jitter_local()`, `get_jitter_rap()`, `get_jitter_ppq5()`
  - Shimmer: `get_shimmer_local()`, `get_shimmer_apq3()`, `get_shimmer_apq5()`
- **Action:** Add voice quality methods

### Priority 2: Critical Missing Objects (WEEKS 5-7)

**TextGrid** (fon/TextGrid_def.h) ⭐⭐⭐ HIGHEST PRIORITY
- Current: NOT IMPLEMENTED
- **Why Critical:**
  - Used by 90%+ of phonetic research
  - Essential for forced alignment (MFA, P2FA, WebMAUS)
  - Required for segment-based analysis
  - Needed for time-aligned transcription
  - Integration with Sound for extraction by interval
- Needs: ~35 methods
  - Tier management: `add_tier()`, `remove_tier()`, `get_tier_names()`
  - Interval tier: `get_interval_at_time()`, `set_interval_text()`, `insert_boundary()`
  - Point tier: `insert_point()`, `remove_point()`, `get_point_time()`
  - I/O: Read/write text and binary formats
  - Export: `as_data_frame()` for R analysis
- **Action:** IMPLEMENT IMMEDIATELY after foundation objects

**Manipulation** (fon/Manipulation_def.h) ⭐⭐ HIGH PRIORITY
- Current: NOT IMPLEMENTED
- **Why Critical:**
  - Only way to do pitch/duration modification in Praat
  - PSOLA-based resynthesis
  - Essential for prosody research, speech synthesis
- Needs: ~10 methods
  - Extract: `extract_pitch_tier()`, `extract_duration_tier()`, `extract_pulses()`
  - Replace: `replace_pitch_tier()`, `replace_duration_tier()`
  - Resynthesize: `get_resynthesis_overlap_add()`
- **Action:** Implement after TextGrid

### Priority 3: Spectral Analysis (WEEKS 7-9)

**Spectrogram** (fon/Spectrogram.h)
- Time-frequency representation
- ~12 methods: query power, to_Spectrum at time, to_Ltas
- Visualization support

**Spectrum** (fon/Spectrum.h)
- Frequency domain (FFT)
- ~15 methods: query values, filtering, spectral moments
- Transforms: to_Sound (IFFT), to_Ltas

**LPC** (fon/LPC.h)
- Linear predictive coding
- ~8 methods
- Transforms: to_Formant, to_Spectrum

**Ltas** (fon/Ltas.h)
- Long-term average spectrum
- ~10 methods

### Priority 4: Tier Objects (WEEKS 9-10)

**PitchTier** (fon/PitchTier.h)
- Modifiable pitch contour
- ~10 methods: add/remove points, multiply frequencies, shift

**FormantGrid** (fon/FormantGrid.h)
- Modifiable formant tracks
- ~12 methods: tier management, value modification

**IntensityTier** (fon/IntensityTier.h)
- Modifiable intensity contour
- ~10 methods

**DurationTier** (fon/DurationTier.h)
- Time warping/duration modification
- ~8 methods

### Priority 5: Advanced Analysis (WEEKS 10-12)

**VoiceReport** (composite object)
- Comprehensive voice quality analysis
- Combines: Pitch, PointProcess, Harmonicity
- ~15 metrics: jitter variants, shimmer variants, HNR, etc.

**Cochleagram** (fon/Cochleagram.h)
- Auditory model representation
- ~10 methods

**Additional objects as needed based on user requirements**

## Implementation Roadmap

### Week 1-2: Complete Foundation Objects

**Goal:** Finish Sound, Pitch, convert Formant/Intensity/Harmonicity to R6

**Tasks:**
1. Sound expansion
   - Add filtering methods (pass/stop band filters)
   - Add modification methods (resample, scale, pre-emphasize)
   - Add combination methods (concatenate, mix)
   - Add transform methods (to_Spectrogram, to_Spectrum, to_LPC, to_Manipulation)
   - Test all methods with validation against Praat desktop

2. Pitch expansion
   - Add modification methods (smooth, interpolate, kill_octave_jumps)
   - Add transform methods (to_PitchTier, to_PointProcess, to_Sound)
   - Add statistics methods (quantile, count_voiced_frames)

3. Formant R6 conversion
   - Convert existing S3 code to R6 pattern
   - Add all query methods
   - Add tracker method
   - Add transform methods (to_FormantGrid, to_Table)

4. Intensity R6 conversion
   - Convert to R6
   - Add all query methods
   - Add transform to IntensityTier

5. Harmonicity R6 conversion
   - Convert to R6
   - Add all query methods

6. PointProcess expansion
   - Add voice quality methods (jitter, shimmer)
   - Requires integration with Sound object

**Deliverables:**
- 6 complete R6 classes with full method coverage
- Comprehensive tests for each object
- Documentation for all new methods
- Integration tests showing workflows

**Milestone:** ✅ Foundation objects complete

---

### Week 3-4: TextGrid Implementation ⭐⭐⭐

**Goal:** Full TextGrid support (CRITICAL MISSING FEATURE)

**Why This is Week 3-4 Priority:**
- TextGrid is used by 90%+ of phonetic researchers
- Essential for forced alignment workflows
- Needed for segment-based analysis
- Major differentiator from other R phonetic packages

**Implementation:**

1. **C++ Wrappers** (`src/textgrid_wrappers.cpp`)
   - Finalizer for TextGrid objects
   - Constructor from file (text and binary formats)
   - Constructor from scratch (create new)
   - Tier query methods (count, names, types)
   - Interval tier methods (~15 functions)
   - Point tier methods (~10 functions)
   - Tier management methods (add, remove, duplicate)
   - Export to R data.frame
   - Save methods (text and binary)

2. **R6 Class** (`R/textgrid-r6.R`)
   - TextGrid main class
   - Helper classes: IntervalTier, PointTier (optional, can be internal)
   - Print method showing tier structure
   - as_data_frame() for tidy data export

3. **Integration with Sound**
   - Extract sound segments based on intervals
   - Example workflow:
     ```r
     tg <- TextGrid$new("annotation.TextGrid")
     sound <- Sound$new("audio.wav")
     
     # Get all intervals from "words" tier
     words <- tg$as_data_frame(tiers = "words")
     
     # Extract each word as separate Sound
     for (i in 1:nrow(words)) {
       if (words$text[i] != "") {  # Skip empty intervals
         word_sound <- sound$extract_part(words$start[i], words$end[i])
         word_sound$save(paste0("word_", i, ".wav"))
       }
     }
     ```

4. **Testing**
   - Create test TextGrid files (Praat text format)
   - Test reading both text and binary formats
   - Test tier management
   - Test interval/point operations
   - Test export to data.frame
   - Test integration with Sound extraction

5. **Documentation**
   - Complete roxygen2 documentation
   - Vignette: "Working with TextGrid Annotations"
   - Examples from forced alignment workflows

**Deliverables:**
- `src/textgrid_wrappers.cpp` (~500 lines)
- `R/textgrid-r6.R` (~300 lines)
- `tests/testthat/test-textgrid.R` (~200 lines)
- `vignettes/textgrid-annotation.Rmd`
- `inst/extdata/sample.TextGrid` (example files)

**Milestone:** ✅ TextGrid fully functional

---

### Week 5-6: Manipulation Implementation ⭐⭐

**Goal:** Pitch and duration modification via PSOLA

**Implementation:**

1. **C++ Wrappers** (`src/manipulation_wrappers.cpp`)
   - Create Manipulation from Sound
   - Extract PitchTier, DurationTier, PointProcess
   - Replace PitchTier, DurationTier
   - Resynthesize (overlap-add)

2. **R6 Classes**
   - Manipulation main class
   - PitchTier class (modifiable pitch contour)
   - DurationTier class (time warping)

3. **Example Workflows**
   - Pitch shifting
   - Time stretching
   - Combined modifications

4. **Testing**
   - Test pitch modification accuracy
   - Test duration modification
   - Compare to Praat desktop output

**Deliverables:**
- Manipulation R6 class
- PitchTier, DurationTier R6 classes
- Tests and documentation
- Vignette: "Pitch and Duration Manipulation"

**Milestone:** ✅ Manipulation working

---

### Week 7-8: Spectral Analysis Objects

**Goal:** Spectrogram, Spectrum, LPC, Ltas

**Implementation:**
- 4 R6 classes following established pattern
- ~50 total methods across all objects
- Integration with Sound
- Visualization support

**Deliverables:**
- 4 complete R6 classes
- Tests and documentation
- Vignette: "Spectral Analysis in R"

**Milestone:** ✅ Spectral analysis complete

---

### Week 9-10: Tier Objects

**Goal:** IntensityTier, FormantGrid (PitchTier done in Manipulation phase)

**Implementation:**
- 2 R6 classes
- Point management methods
- Integration with Manipulation (future)

**Deliverables:**
- 2 R6 classes
- Tests and documentation

**Milestone:** ✅ All tier objects available

---

### Week 11-12: Examples, Validation, Polish

**Goal:** Production-ready package

**Tasks:**
1. Re-implement Python Parselmouth examples from superassp
   - Voice quality analysis
   - Pitch tracking
   - Formant tracking
   - Spectral analysis
   - 10+ complete example scripts in `inst/examples/`

2. Validation testing
   - Compare output to Praat desktop (numerical accuracy)
   - Performance benchmarking
   - Memory leak testing (valgrind)

3. Documentation polish
   - 10+ comprehensive vignettes
   - Complete reference documentation
   - README with all features
   - Migration guides (Praat script → R, Parselmouth → speaker)

4. CRAN preparation
   - R CMD check (zero errors/warnings)
   - Cross-platform testing
   - Package size optimization

**Deliverables:**
- `inst/examples/` with 10+ complete scripts
- Comprehensive test suite (>90% coverage)
- Complete documentation
- CRAN-ready package

**Milestone:** ✅ Ready for release

---

## Success Metrics

### Completeness
- [ ] 15+ Praat object types as R6 classes
- [ ] 200+ methods covering core Praat functionality
- [ ] TextGrid full support ⭐
- [ ] Manipulation full support ⭐
- [ ] All major analysis workflows supported

### Quality
- [ ] Zero memory leaks (valgrind clean)
- [ ] Test coverage >90% (R code)
- [ ] Numerical accuracy matches Praat desktop (<0.1% error)
- [ ] Builds on Windows, macOS, Linux

### Usability
- [ ] Consistent naming conventions (easy Praat script translation)
- [ ] 10+ comprehensive vignettes
- [ ] 50+ documented examples
- [ ] Clear migration guides

### Performance
- [ ] Within 10% speed of Praat desktop
- [ ] Efficient memory usage (XPtr, no unnecessary copying)

## Migration from Current State

### What Changes

**Keep:**
- R6 infrastructure and XPtr memory management ✅
- Sound, Pitch, PointProcess R6 classes ✅
- C++ build system with Praat source ✅
- Error handling patterns ✅

**Expand:**
- Sound: Add ~25 missing methods
- Pitch: Add ~12 missing methods
- PointProcess: Add voice quality methods

**Convert:**
- Formant: S3 → R6 with full methods
- Intensity: S3 → R6 with full methods
- Harmonicity: S3 → R6 with full methods

**New:**
- TextGrid (critical) ⭐⭐⭐
- Manipulation (high priority) ⭐⭐
- Spectrogram, Spectrum, LPC, Ltas
- PitchTier, FormantGrid, IntensityTier, DurationTier
- VoiceReport

### What Stays the Same

- C++ build process
- XPtr-based memory management
- Error handling (MelderError → Rcpp::stop)
- Testing framework
- Documentation approach

## Conclusion

This amended plan transforms `speaker` from a limited function-based tool into a **comprehensive, object-oriented phonetic analysis toolkit** that:

1. **Mirrors Praat's architecture** - 15+ objects, 200+ methods
2. **Eliminates Python dependency** - Pure R + C++
3. **Enables complete workflows** - From audio to publication-ready analysis
4. **Provides clear migration paths** - From Praat scripts and Parselmouth code
5. **Prioritizes critical features** - TextGrid and Manipulation first

**The result:** The most comprehensive phonetic analysis package for R, matching the capabilities of Praat desktop and Parselmouth while leveraging R's statistical ecosystem.

**Next action:** Begin Week 1 implementation (expand Sound, Pitch; convert Formant, Intensity, Harmonicity to R6).
