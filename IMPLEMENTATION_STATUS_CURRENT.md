# Speaker Package Implementation Status

**Date:** 2025-11-09  
**Version:** 0.2.1 (development)  
**Branch:** 001-praat-r-access

## Executive Summary

The speaker package is transitioning from a function-based approach to a comprehensive object-oriented interface to Praat's C++ codebase. This mirrors the successful design of Python's Parselmouth library while leveraging R6 classes and Rcpp for efficient memory management.

## Architecture Decision: Object-Oriented Approach

**Key Insight:** Praat is fundamentally object-oriented (Thing → Function → Sampled hierarchy), so the package should expose objects with methods rather than standalone functions.

**Benefits:**
- Matches Praat's native design
- Enables method chaining and natural workflows
- Efficient memory management via XPtr
- Easy transcoding from Praat scripts to R
- Proven pattern (Parselmouth's success)

## Implementation Progress

### ✅ Completed (Phase 1-2)

#### Infrastructure
- [x] R6-based `PraatObject` base class
- [x] XPtr memory management with custom finalizers
- [x] Error handling bridge (MelderError → Rcpp exceptions)
- [x] Build system for Praat source integration (C++17)
- [x] Package structure (R6 classes, C++ wrappers, tests, docs)

#### Core Objects (Partial Implementation)
- [x] **Sound** - Basic functionality (~25/50 methods)
  - File I/O, queries (duration, sample rate, etc.)
  - Core transformations: to_pitch(), to_formant_burg(), to_intensity(), to_harmonicity_cc()
  - Missing: spectral transforms, filtering, resampling, manipulation
- [x] **Pitch** - R6 class (~20/30 methods)
  - Query methods (get_mean, get_minimum, get_maximum, get_value_at_time)
  - Statistical methods
  - Missing: smoothing, interpolation, to_pitch_tier()
- [x] **PointProcess** - R6 class (~15/20 methods)
  - Point queries, voice quality with Sound
  - Jitter/shimmer calculations
  - Missing: some advanced voice metrics
- [x] **Formant** - S3 implementation (needs R6 conversion)
  - Basic queries implemented
  - Missing: tracker, formant_grid integration
- [x] **Intensity** - S3 implementation (needs R6 conversion)
  - Basic queries implemented
  - Missing: intensity_tier integration
- [x] **Harmonicity** - S3 implementation (needs R6 conversion)
  - Basic HNR queries implemented

#### Media Loading
- [x] AV package integration decision documented
- [x] Added `av` to DESCRIPTION
- [x] Dual loading strategy designed (av for diverse formats, Praat for WAV)
- [ ] Implementation pending (blocked by build issues)

#### Examples
- [x] Basic analysis workflow (`inst/examples/01_basic_analysis.R`)
- [x] Voice quality example (`inst/examples/02_voice_quality.R`)
- [x] Spectral analysis example (`inst/examples/03_spectral_analysis.R`)
- [x] Complete workflow (`inst/examples/05_complete_workflow.R`)
- [x] Python to R mapping guide (`inst/examples/PYTHON_TO_R_MAPPING.md`)

### 🚧 In Progress (Phase 2-3)

#### Build System Issues
**BLOCKER:** Praat source compilation encountering undefined symbols:
- `classLongSound` - Long audio file class
- `classLPC` - Linear predictive coding class  
- `theCurrentPraatApplication` - GUI application context
- `theCurrentPraatObjects` - GUI object list
- `theMelder_error_threadId` - Threading infrastructure

**Attempted Solutions:**
- Created stub files for LongSound, LPC, Praat application symbols
- Moved GUI-related sources to excluded_sources/
- Still hitting deep Melder threading symbols

**Recommended Approach:**
- Option B (modular build) - Symlink only needed .cpp files to src/
- Document minimum required Praat source set
- Clean separation of Praat vs wrapper code

#### Object Conversions
- [ ] Convert Formant from S3 to R6
- [ ] Convert Intensity from S3 to R6
- [ ] Convert Harmonicity from S3 to R6
- [ ] Expand Sound class with remaining methods
- [ ] Expand Pitch class with remaining methods

### ❌ Not Started (Phase 3-5)

#### Critical Missing Objects (Phase 3)
- [ ] **TextGrid** ⭐⭐⭐ HIGHEST PRIORITY
  - Essential for linguistic annotation
  - Tier management (IntervalTier, PointTier)
  - Interval/point operations
  - Integration with Sound for segmentation
  - Estimated: ~35 methods

- [ ] **Manipulation** ⭐⭐ HIGH PRIORITY
  - PSOLA-based pitch/duration modification
  - Extract/replace PitchTier, DurationTier
  - Resynthesis methods
  - Essential for prosody research
  - Estimated: ~12 methods

#### Spectral Objects (Phase 3-4)
- [ ] **Spectrum** (~18 methods)
  - FFT frequency-domain representation
  - Power queries, filtering
  - to_sound() inverse transform

- [ ] **Spectrogram** (~15 methods)
  - Time-frequency representation
  - Power at time/frequency queries
  - Slice extraction

- [ ] **LPC** (~10 methods)
  - Linear predictive coding
  - to_formant(), to_spectrum() conversions

- [ ] **Ltas** (~12 methods)
  - Long-term average spectrum
  - Slope calculations

- [ ] **MelFilter, MFCC** (~15 methods combined)
  - Perceptual frequency scales
  - Cepstral coefficients

#### Tier Objects (Phase 4)
- [ ] **PitchTier** (~12 methods) - Modifiable F0 contour
- [ ] **DurationTier** (~10 methods) - Time warping
- [ ] **IntensityTier** (~10 methods) - Modifiable intensity
- [ ] **FormantGrid** (~15 methods) - Modifiable formant tracks

#### Advanced Objects (Phase 5)
- [ ] **FormantPath** (~10 methods) - Modern formant tracking
- [ ] **Matrix** (~20 methods) - 2D numerical data
- [ ] **Table** (~50 methods) - Praat's data frame
- [ ] **Collection** (~8 methods) - Multi-object container
- [ ] **VoiceReport** - Comprehensive voice quality
- [ ] **Excitation, Cochleagram** - Auditory models

#### Examples (Phase 6)
**Re-implement Python examples from `/Users/frkkan96/Documents/src/superassp/inst/python/`:**
- [ ] praat_pitch.py → R
- [ ] praat_formant_burg.py → R
- [ ] praat_formantpath_burg.py → R
- [ ] praat_intensity.py → R
- [ ] praat_spectral_moments.py → R
- [ ] praat_voice_report_memory.py → R
- [ ] praat_avqi_memory.py → R
- [ ] praat_dsi_memory.py → R
- [ ] praat_praatsauce_memory.py → R
- [ ] praat_sauce_memory.py → R
- [ ] praat_voice_tremor_memory.py → R

## Method Naming Conventions

Consistent naming enables easy Praat → R transcoding:

| Praat Pattern | R6 Pattern | Example |
|---------------|------------|---------|
| `Get [property]` | `get_[property]()` | `get_duration()` |
| `To [Object]...` | `to_[object]()` | `to_pitch()` |
| `Extract [part]` | `extract_[part]()` | `extract_channel()` |
| `Down to [Type]` | `as_[type]()` | `as_data_frame()` |
| `Save as...` | `save(path)` | `save("out.wav")` |

## Object Count Summary

| Status | Count | Objects |
|--------|-------|---------|
| ✅ Implemented (partial) | 6 | Sound, Pitch, Formant, Intensity, Harmonicity, PointProcess |
| 🚧 In progress | 1 | Build system fixes |
| ❌ Not started | 17 | TextGrid, Manipulation, Spectrum, Spectrogram, LPC, Ltas, MelFilter, MFCC, PitchTier, DurationTier, IntensityTier, FormantGrid, FormantPath, Matrix, Table, Collection, VoiceReport |
| **TOTAL** | **24** | Complete Praat OOP interface |

## Method Count Estimate

| Object | Implemented | Remaining | Total |
|--------|-------------|-----------|-------|
| Sound | ~25 | ~25 | ~50 |
| Pitch | ~20 | ~10 | ~30 |
| Formant | ~10 | ~10 | ~20 |
| Intensity | ~8 | ~7 | ~15 |
| Harmonicity | ~8 | ~7 | ~15 |
| PointProcess | ~15 | ~5 | ~20 |
| TextGrid | 0 | ~35 | ~35 |
| Manipulation | 0 | ~12 | ~12 |
| Spectrum | 0 | ~18 | ~18 |
| Spectrogram | 0 | ~15 | ~15 |
| LPC | 0 | ~10 | ~10 |
| Ltas | 0 | ~12 | ~12 |
| Others | 0 | ~150 | ~150 |
| **TOTAL** | **~86** | **~316** | **~402** |

**Progress: ~21% methods implemented**

## Immediate Priorities

### 1. Resolve Build Issues ⚠️
**CRITICAL BLOCKER** - Cannot proceed until Praat source compiles cleanly
- Implement modular build approach (Option B)
- Document minimum required Praat .cpp files
- Create comprehensive symbol stubs or minimal Melder threading support
- Validate on macOS, Linux, Windows

### 2. Complete Foundation Objects
Once builds work:
- Expand Sound class with remaining ~25 methods
- Convert Formant, Intensity, Harmonicity to R6
- Add missing Pitch methods

### 3. Implement TextGrid ⭐⭐⭐
**HIGHEST USER PRIORITY** - Essential for 90%+ of phonetic research
- Most requested missing feature
- Required for forced alignment integration
- Blocking many real-world workflows

### 4. Implement Manipulation
**HIGH PRIORITY** - Key differentiator from other packages
- PSOLA-based pitch modification
- Duration manipulation
- Essential for prosody research

### 5. Add Spectral Objects
- Spectrum, Spectrogram, LPC
- Enable full spectral analysis workflows

### 6. Re-implement superassp Examples
- Demonstrate migration from Python Parselmouth
- Validate API completeness
- Create tutorial materials

## Timeline Estimate

Assuming build issues resolved within 1 week:

| Week | Focus | Deliverable |
|------|-------|-------------|
| 1 | Build fixes | Clean compilation on all platforms |
| 2 | Foundation objects | R6 conversions complete, Sound/Pitch expanded |
| 3 | TextGrid | Full implementation with tests |
| 4 | Manipulation | PSOLA modification working |
| 5-6 | Spectral objects | Spectrum, Spectrogram, LPC, Ltas, MFCC |
| 7 | Tier objects | PitchTier, DurationTier, IntensityTier, FormantGrid |
| 8-9 | Advanced objects | FormantPath, Matrix, Table, Collection |
| 10 | Examples | Re-implement all 11 superassp Python scripts |
| 11 | Documentation | Comprehensive vignettes, reference docs |
| 12 | Testing | Validation, benchmarks, CRAN prep |

**Total: 12 weeks to complete OOP implementation**

## Success Criteria

### Technical
- [ ] 24 Praat objects as R6 classes
- [ ] ~400+ methods covering comprehensive Praat functionality
- [ ] Zero memory leaks (valgrind clean)
- [ ] Test coverage >95% (R), >85% (C++)
- [ ] Performance within 10% of Praat desktop
- [ ] Builds on Windows, macOS (Intel/ARM), Linux
- [ ] R CMD check: 0 errors, 0 warnings, 0 notes

### Usability
- [ ] Intuitive OOP API matching Praat design
- [ ] Consistent naming (get_*, to_*, as_*)
- [ ] 100+ examples
- [ ] 10 vignettes
- [ ] Migration guides (Praat scripts, Parselmouth)
- [ ] pkgdown website

### Completeness
- [ ] All 11 superassp Python examples in R
- [ ] TextGrid full support
- [ ] Voice quality analysis (jitter, shimmer, HNR, AVQI, DSI)
- [ ] Pitch/duration manipulation (PSOLA)
- [ ] Spectral analysis (all major objects)
- [ ] Ready for CRAN

## Key Documentation

**Planning:**
- `specs/001-praat-r-access/COMPREHENSIVE-OOP-PLAN.md` - Master plan
- `specs/001-praat-r-access/COMPREHENSIVE-OOP-AMENDMENT.md` - Expanded scope
- `CLAUDE.md` - Architectural decisions and integration strategy

**Status:**
- This file - Current implementation status
- `AV_INTEGRATION_STATUS.md` - Media loading details and build issues
- Git commit history

## Next Steps

1. **Fix build system** (CRITICAL)
   - Implement modular build approach
   - Document minimal Praat source requirements
   - Test on all platforms

2. **Complete foundation objects**
   - Expand Sound, Pitch classes
   - Convert S3 to R6 for Formant, Intensity, Harmonicity

3. **Implement TextGrid**
   - Highest user priority
   - ~35 methods for full functionality

4. **Continue with roadmap**
   - Follow 12-week timeline
   - Weekly commits with progress summaries

---

**Last Updated:** 2025-11-09  
**Status:** In active development, currently blocked on build system issues
