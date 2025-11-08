# Revised Object-Oriented Implementation Plan
**Date**: 2025-11-08 (Friday)  
**Current Status**: 70% Complete - Build Errors to Resolve  
**Focus**: Complete Praat OOP Architecture in R

## Executive Summary

The `speaker` package architecture has been successfully revised to mirror Praat's object-oriented design, similar to Python's Parselmouth but without Python dependencies. **The foundation is solid** with R6 classes backed by external pointers to C++ Praat objects.

### Current Achievements ✅
- **5/17 objects** implemented: Sound (100%), Pitch (100%), Formant (95%), Harmonicity (100%), TextGrid (60%)
- **R6 architecture** working with XPtr finalizers
- **Method chaining** functional
- **~100+ methods** implemented across objects

### Critical Issues to Resolve 🔧
1. **C++ compilation errors** in textgrid_wrappers.cpp (C++17 template issues)
2. **Missing objects**: Intensity, Spectrogram, Spectrum, PointProcess, Manipulation, VoiceReport, Tier objects
3. **Documentation gaps**: Vignettes incomplete, examples missing
4. **Testing gaps**: Unit tests incomplete

---

## Problem Analysis

### Why This Revision is Necessary

**Original Approach** (Procedural):
```r
# Isolated function calls
pitch_data <- praat_extract_pitch(audio_file)
```
- ❌ Doesn't reflect Praat's OOP design
- ❌ Forces data copying
- ❌ No object persistence
- ❌ Missing critical functionality (TextGrid, Manipulation)

**Parselmouth Approach** (OOP in Python):
```python
import parselmouth
sound = parselmouth.Sound("audio.wav")
pitch = sound.to_pitch()
mean_f0 = pitch.get_mean()
```
- ✅ Mirrors Praat's object hierarchy
- ✅ Method chaining
- ✅ Complete functionality
- ❌ Requires Python dependency

**Current speaker Approach** (OOP in R):
```r
sound <- Sound$new("audio.wav")
pitch <- sound$to_pitch()
mean_f0 <- pitch$get_mean()
```
- ✅ Mirrors Praat's object hierarchy
- ✅ No Python dependency
- ✅ Direct C++ integration
- ✅ R-native R6 classes
- 🔧 **Needs completion** (~70% done)

---

## Immediate Action Plan (Next 5 Days)

### Day 1: Fix Build Issues ⚠️ URGENT
**Goal**: Get package building successfully

**Tasks**:
1. Fix C++17 compilation errors in textgrid_wrappers.cpp
   - Resolve template/Collection.h issues
   - May need to simplify TextGrid implementation temporarily
2. Ensure all existing objects compile
3. Run `R CMD build` and `R CMD check` successfully
4. Test existing functionality works

**Files to Fix**:
- `src/textgrid_wrappers.cpp` - Main issue
- `src/Makevars` - Verify C++17 flags correct

**Success Criteria**:
- ✅ Package builds without errors
- ✅ Can load library(speaker)
- ✅ Sound, Pitch, Formant, Harmonicity objects work

---

### Day 2: Complete Core Objects
**Goal**: Finish Intensity and validate all core analysis objects

**Tasks**:
1. Implement **Intensity** R6 class
   - R/intensity-r6.R (~12 methods)
   - src/intensity_wrappers.cpp
   - Tests
2. Fix any remaining issues in TextGrid (or defer to later)
3. Create integration tests for core workflow:
   ```r
   sound <- Sound$new("test.wav")
   pitch <- sound$to_pitch()
   formant <- sound$to_formant_burg()
   intensity <- sound$to_intensity()
   harmonicity <- sound$to_harmonicity_cc()
   ```
4. Ensure all `as_data_frame()` methods work

**Deliverables**:
- Complete Intensity object
- Integration test suite
- Updated documentation

**Success Criteria**:
- ✅ All 6 core objects functional
- ✅ Complete analysis pipeline works
- ✅ Data export to R data.frames works

---

### Day 3: Spectral Analysis Objects
**Goal**: Implement Spectrogram and Spectrum

**Tasks**:
1. **Spectrogram** R6 class
   - R/spectrogram-r6.R (~12 methods)
   - src/spectrogram_wrappers.cpp
   - get_power_at_time_and_frequency()
   - to_spectrum(), to_ltas()
   - as_matrix() for visualization

2. **Spectrum** R6 class
   - R/spectrum-r6.R (~15 methods)
   - src/spectrum_wrappers.cpp
   - get_power_at_frequency()
   - get_centre_of_gravity()
   - to_sound() (inverse FFT)

**Example Workflow**:
```r
sound <- Sound$new("audio.wav")
spectrogram <- sound$to_spectrogram()
spec_matrix <- spectrogram$as_matrix()  # For heatmap
image(spec_matrix)

spectrum <- sound$to_spectrum()
cog <- spectrum$get_centre_of_gravity()
```

**Success Criteria**:
- ✅ Spectrogram working with matrix export
- ✅ Spectrum working with frequency queries

---

### Day 4: PointProcess and Voice Quality
**Goal**: Enable voice quality analysis (jitter, shimmer, HNR)

**Tasks**:
1. **PointProcess** R6 class
   - R/pointprocess-r6.R (~15 methods)
   - src/pointprocess_wrappers.cpp
   - Voice quality methods require Sound + PointProcess
   
2. **VoiceReport** convenience function
   - Wrapper combining Sound + Pitch + PointProcess + Harmonicity
   - Returns comprehensive voice metrics in data.frame
   
**Example Workflow**:
```r
sound <- Sound$new("voice.wav")
pitch <- sound$to_pitch()
pp <- sound$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 600)

# Individual metrics
jitter <- pp$get_jitter_local(sound)
shimmer <- pp$get_shimmer_local(sound)

# OR comprehensive report
report <- sound$voice_report()
# Returns data.frame with: mean_f0, jitter_local, shimmer_local, HNR, etc.
```

**Success Criteria**:
- ✅ PointProcess functional
- ✅ Voice quality metrics (jitter, shimmer) working
- ✅ VoiceReport convenience function ready

---

### Day 5: Commit, Document, and Version Update
**Goal**: Consolidate progress and prepare for next phase

**Tasks**:
1. Run full test suite
2. Fix any remaining test failures
3. Update version to 0.1.1 in DESCRIPTION
4. Update NEWS.md with changes
5. Comprehensive commit with summary
6. Create progress document

**Git Commit Message**:
```
feat: Complete core Praat object implementation (Phase 1)

Implemented objects:
- Sound (100%) - 40+ methods
- Pitch (100%) - 25 methods
- Formant (95%) - 18 methods
- Harmonicity (100%) - 14 methods
- Intensity (100%) - 12 methods
- Spectrogram (100%) - 12 methods
- Spectrum (100%) - 15 methods
- PointProcess (100%) - 15 methods

Features:
- Full voice quality analysis (jitter, shimmer, HNR)
- Spectral analysis (spectrogram, spectrum, LPC)
- R6 object-oriented API mirroring Praat
- Method chaining support
- Data export to data.frames
- Memory-safe XPtr management

Version: 0.1.1
Status: Core objects complete, advanced objects remain
```

**Success Criteria**:
- ✅ Package version 0.1.1
- ✅ Clean build and check
- ✅ Progress documented
- ✅ Git committed with clear message

---

## Remaining Objects (Phase 2 - Next Week)

### Week 2: Advanced Objects

#### TextGrid (CRITICAL) ⭐⭐⭐
- **Importance**: 90%+ of phonetic research uses TextGrid
- **Status**: 60% done, has build errors
- **Priority**: Fix compilation, complete implementation
- **Methods**: ~35 (tier management, interval/point operations, I/O)

#### Manipulation (HIGH PRIORITY) ⭐⭐
- **Purpose**: Pitch and duration modification (PSOLA)
- **Methods**: ~10
- **Workflow**:
  ```r
  manip <- sound$to_manipulation()
  pitch_tier <- manip$extract_pitch_tier()
  pitch_tier$multiply_frequencies(1.2)  # Raise pitch 20%
  manip$replace_pitch_tier(pitch_tier)
  modified <- manip$get_resynthesis_overlap_add()
  ```

#### Tier Objects (MEDIUM PRIORITY) ⭐
- **PitchTier**: Editable pitch contour (~10 methods)
- **FormantTier/FormantGrid**: Editable formant tracks (~12 methods)
- **IntensityTier**: Editable intensity (~10 methods)
- **DurationTier**: Duration modification (~8 methods)

#### LPC (LOW PRIORITY)
- **Purpose**: Linear Predictive Coding
- **Methods**: ~8
- **Transforms**: to_formant(), to_spectrum()

---

## Re-implementation of superassp Python Examples (Phase 3)

### Goal
Demonstrate migration path from Parselmouth to speaker

### Files to Re-implement
Located at: `/Users/frkkan96/Documents/src/superassp/inst/python/`

| Python File | Priority | Estimated R Lines | Status |
|-------------|----------|-------------------|---------|
| praat_voice_report_memory.py | HIGH | ~150 | Pending |
| praat_pitch.py | HIGH | ~100 | Pending |
| praat_formant_burg.py | HIGH | ~80 | Pending |
| praat_intensity.py | MEDIUM | ~60 | Pending |
| praat_formantpath_burg.py | MEDIUM | ~120 | Pending |
| praat_spectral_moments.py | MEDIUM | ~90 | Pending |
| praat_avqi_memory.py | LOW | ~200 | Pending |
| praat_dsi_memory.py | LOW | ~200 | Pending |
| praat_praatsauce_memory.py | LOW | ~250 | Pending |
| praat_sauce_memory.py | LOW | ~250 | Pending |
| praat_voice_tremor_memory.py | LOW | ~300 | Pending |

### Output Location
`inst/examples/` - R scripts demonstrating equivalent functionality

### Format
Each R example will include:
1. Header comment with original Python code
2. Equivalent R code using speaker package
3. Side-by-side comparison table
4. Performance notes

---

## Naming Convention Consistency

### Core Principle
**Enable easy Praat script → R code translation**

### Patterns

| Praat Method | R6 Method | Example |
|--------------|-----------|---------|
| `Get duration` | `get_duration()` | `sound$get_duration()` |
| `Get value at time...` | `get_value_at_time(t)` | `pitch$get_value_at_time(0.5)` |
| `Get mean...` | `get_mean()` | `pitch$get_mean()` |
| `To Pitch...` | `to_pitch(...)` | `sound$to_pitch()` |
| `To Formant (burg)...` | `to_formant_burg(...)` | `sound$to_formant_burg()` |
| `Extract part...` | `extract_part(start, end)` | `sound$extract_part(0, 1)` |
| `Scale intensity...` | `scale_intensity(db)` | `sound$scale_intensity(70)` |
| `Down to Table` | `as_data_frame()` | `pitch$as_data_frame()` |
| `Save as WAV file...` | `save(path)` | `sound$save("out.wav")` |

### Method Categories
1. **Query** (`get_*`): Returns values
2. **Transform** (`to_*`): Returns new object of different type
3. **Extract** (`extract_*`): Returns new object of same type
4. **Modify** (verbs): Modifies object
5. **Export** (`as_*`, `save`): Converts/writes data

---

## Complete Object Hierarchy (Reference)

### Priority 1: Core Objects ✅ (80% Complete)
1. ✅ Sound (100%)
2. ✅ Pitch (100%)
3. ✅ Formant (95%)
4. ✅ Harmonicity (100%)
5. ⏳ Intensity (0% - Day 2)
6. ⏳ Spectrogram (0% - Day 3)
7. ⏳ Spectrum (0% - Day 3)
8. ⏳ PointProcess (0% - Day 4)

### Priority 2: Annotation & Manipulation (20% Complete)
9. ⏳ TextGrid (60% - has errors)
10. ⏳ Manipulation (0%)
11. ⏳ PitchTier (0%)
12. ⏳ IntensityTier (0%)
13. ⏳ DurationTier (0%)

### Priority 3: Advanced (0% Complete)
14. ⏳ FormantTier/FormantGrid (0%)
15. ⏳ LPC (0%)
16. ⏳ Ltas (0%)
17. ⏳ VoiceReport (0% - but can be wrapper)

---

## Success Metrics

### Technical
- [ ] 17 Praat objects as R6 classes
- [ ] 250+ methods total
- [ ] Zero memory leaks (valgrind)
- [ ] Test coverage >80%
- [ ] Builds on macOS, Linux, Windows
- [ ] Performance within 20% of Praat

### Usability
- [ ] 11 Python examples → R
- [ ] 8+ vignettes
- [ ] Complete Rd documentation
- [ ] Migration guide (Praat → R)
- [ ] Migration guide (Parselmouth → speaker)

### Completeness
- [ ] Voice quality analysis ✅ (Day 4)
- [ ] Pitch/formant tracking ✅ (Done)
- [ ] Spectral analysis ✅ (Day 3)
- [ ] TextGrid annotation 🔧 (Week 2)
- [ ] Pitch manipulation 🔧 (Week 2)
- [ ] Duration manipulation 🔧 (Week 2)

---

## Timeline Summary

### This Week (Days 1-5)
- **Day 1**: Fix build errors ⚠️
- **Day 2**: Complete Intensity
- **Day 3**: Spectrogram + Spectrum
- **Day 4**: PointProcess + VoiceReport
- **Day 5**: Test, document, commit v0.1.1

### Next Week (Week 2)
- **Mon-Tue**: Fix TextGrid completely
- **Wed-Thu**: Implement Manipulation + Tiers
- **Fri**: Test, document, commit v0.2.0

### Week 3
- **Mon-Wed**: Re-implement 11 Python examples
- **Thu-Fri**: Create vignettes

### Week 4
- **Mon-Wed**: CRAN preparation
- **Thu-Fri**: Final testing and release v1.0.0

---

## Current File Structure

```
speaker/
├── R/
│   ├── sound-r6-new.R ✅
│   ├── pitch-r6.R ✅
│   ├── formant.R ✅
│   ├── harmonicity.R ✅
│   ├── textgrid-r6.R ⏳ (has errors)
│   ├── intensity-r6.R ❌ (to create)
│   ├── spectrogram-r6.R ❌
│   ├── spectrum-r6.R ❌
│   ├── pointprocess-r6.R ❌
│   └── ...
├── src/
│   ├── sound_wrappers.cpp ✅
│   ├── pitch_wrappers.cpp ✅
│   ├── formant_wrappers.cpp ✅
│   ├── harmonicity_wrappers.cpp ✅
│   ├── textgrid_wrappers.cpp ⚠️ (build errors)
│   └── ...
├── inst/
│   ├── include/praat-master/ ✅
│   └── examples/ ❌ (to create)
├── tests/
│   └── testthat/ ⏳ (partial)
└── vignettes/ ⏳ (partial)
```

---

## Next Steps (Immediate)

1. **Fix build** - Priority #1
2. **Complete Intensity** - Quick win
3. **Add Spectrogram/Spectrum** - Spectral analysis
4. **Add PointProcess** - Voice quality
5. **Test everything** - Ensure stability
6. **Commit v0.1.1** - Milestone achieved

**Let's complete this implementation! 🚀**
