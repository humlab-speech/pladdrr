# pladdrr v1.1.0 Development Roadmap
**Date**: 2025-11-29
**Current Version**: 1.0.9
**Target Version**: 1.1.0

## Status Summary

### ✅ Completed in v1.0.9
1. **GSL 2.8 Integration** - All 54 mathematical functions operational
2. **Phase 1-3 Plotting** - 16/17 functions (94% coverage, ~95% real-world)
3. **TextGrid/Table Conversion** - Bidirectional workflow support
4. **Audio Quality Assessment** - Comprehensive quality control utilities
5. **Parselmouth Benchmarks** - Performance comparison working

### Package Coverage Assessment
- **Core Acoustic Analysis**: 95%+ ✅
- **Plotting/Visualization**: 95%+ ✅
- **Mathematical Functions**: 100% ✅
- **Praat Script Re-implementation**: 80-85% 🟡

## Priority Gaps (from COMPREHENSIVE_FINAL_ASSESSMENT)

### HIGH PRIORITY - Core Voice Quality Analysis

Based on analysis of 1,213 Praat scripts across 124 repositories:

#### 1. Periodic PointProcess Detection (CRITICAL)
**Impact**: Blocks 20-25% of archive scripts

**Missing Wrappers**:
- `Sound_to_PointProcess_periodic_cc()` - Cross-correlation method
- `Sound_to_PointProcess_periodic_peaks()` - Peak finding method

**Use Cases**:
- Jitter/shimmer analysis
- Voice quality assessment
- Glottal pulse timing
- Prosodic analysis

**C++ Status**: ✅ Functions exist in `src/praat.github.io/fon/Sound_to_PointProcess.cpp`

**Current Workaround**: ⚠️ Partial - `Pitch_to_PointProcess()` approximates but not identical

**Estimated Effort**: 3-4 hours
- Add C++ wrappers
- Add R6 methods
- Test against Praat output
- Document usage

#### 2. LPC Inverse Filtering (HIGH)
**Impact**: Blocks 5-8% of archive scripts (voice source research)

**Missing Wrapper**:
- `Sound_LPC_filterInverse()` - Extract voice source via inverse filtering

**Use Cases**:
- Glottal flow analysis
- Voice source research
- Vocal fold dynamics
- Source-filter separation

**C++ Status**: ✅ Function exists in `src/praat.github.io/LPC/Sound_and_LPC.cpp`

**Current Workaround**: ❌ None (low-level filtering exists but not high-level interface)

**Estimated Effort**: 2-3 hours
- Add C++ wrapper
- Add to LPC R6 class
- Test output
- Document methodology

### MEDIUM PRIORITY - Extended Functionality

#### 3. MFCC (Mel-Frequency Cepstral Coefficients)
**Impact**: 5-8% of archive scripts

**Missing Wrapper**:
- `Sound_to_MFCC()` - MFCC extraction

**Use Cases**:
- Speech recognition features
- Speaker identification
- Phoneme classification

**C++ Status**: ✅ Function exists in `src/praat.github.io/dwtools/Sound_to_MFCC.cpp`

**Current Workaround**: ⚠️ Fair (R packages `tuneR`, `phonTools` have MFCC but different params)

**Estimated Effort**: 3-4 hours
- Add C++ wrappers for MFCC and MelFilter
- Create MFCC R6 class
- Test against Praat
- Document usage

**Note**: Consider deferring to v1.2.0 since R alternatives exist

#### 4. Guided Pulse Detection
**Impact**: 5-8% of archive scripts

**Missing Wrappers**:
- `Sound_Pitch_to_PointProcess_cc()` - Pitch-guided cross-correlation
- `Sound_Pitch_to_PointProcess_peaks()` - Pitch-guided peak finding

**Use Cases**:
- Accurate glottal pulse timing
- Pitch-synchronous analysis
- Voice quality refinement

**C++ Status**: ✅ Functions exist in `src/praat.github.io/fon/Sound_to_PointProcess.cpp`

**Estimated Effort**: 2-3 hours

#### 5. PowerCepstrum Object
**Impact**: Blocks `plot.PowerCepstrum()` function (already implemented)

**Missing Wrapper**:
- `Sound_to_PowerCepstrum()` - Cepstral analysis

**C++ Status**: ✅ Function exists in `src/praat.github.io/fon/Sound_to_PowerCepstrum.cpp`

**Current Status**: 
- ⏸️ `plot.PowerCepstrum()` method is implemented but can't be tested
- Code is ready and waiting

**Estimated Effort**: 2 hours
- Add C++ wrapper
- Add R6 class
- Test plot method
- Document

### LOW PRIORITY - Convenience Methods

#### 6. Synthesis Functions
**Impact**: 8-10% of scripts (but Manipulation provides alternative)

- `Pitch_to_Sound()` / `Pitch_to_Sound_sine()`
- Estimated effort: 2 hours

#### 7. Alternative Formant Method
**Impact**: 3-5% of scripts (but standard method is better)

- `Spectrum_to_Formant()`
- Estimated effort: 2 hours

## Recommended v1.1.0 Scope

### Core Implementation (8-10 hours)

**Phase 1: Periodic PointProcess** (HIGH PRIORITY - 4 hours)
1. Implement `Sound_to_PointProcess_periodic_cc()`
2. Implement `Sound_to_PointProcess_periodic_peaks()`
3. Add comprehensive tests
4. Document voice quality workflow

**Phase 2: LPC Inverse Filtering** (HIGH PRIORITY - 3 hours)
1. Implement `Sound_LPC_filterInverse()`
2. Add to LPC R6 class
3. Test voice source extraction
4. Document usage

**Phase 3: PowerCepstrum** (MEDIUM PRIORITY - 2 hours)
1. Implement `Sound_to_PowerCepstrum()`
2. Test plot method (already implemented)
3. Document cepstral analysis

**Total Core Work**: ~9 hours

### Optional Extensions (4-6 hours)

**Phase 4: Guided Pulse Detection** (3 hours)
- `Sound_Pitch_to_PointProcess_cc()`
- `Sound_Pitch_to_PointProcess_peaks()`

**Phase 5: MFCC** (defer to v1.2.0)
- Complex implementation
- Good R alternatives exist
- Can wait

### Documentation (3-4 hours)

1. **Comprehensive Plotting Vignette** (3 hours)
   - Overview of all 16 plot methods
   - ggplot2 customization guide
   - Publication workflow examples
   - Combined visualization patterns

2. **Update NEWS.md** (30 min)

3. **Update README** (30 min)

## Implementation Timeline

### Week 1: Core Voice Quality (v1.0.10)
- Days 1-2: Periodic PointProcess detection
- Day 3: LPC inverse filtering
- Day 4: PowerCepstrum
- Day 5: Testing and documentation

### Week 2: Polish and Release (v1.1.0)
- Days 1-2: Guided pulse detection (optional)
- Day 3-4: Plotting vignette
- Day 5: Final testing, CRAN check, release prep

## Expected Impact

### After v1.1.0 Release

**Praat Script Coverage**:
- Current: 80-85%
- After Core Implementation: 90-92%
- After Optional Extensions: 93-95%

**Use Case Coverage**:
- Voice Quality Analysis: 95% → 100% ✅
- Acoustic Phonetics: 95% → 98%
- Speech Research: 80% → 90%
- Clinical Applications: 90% → 100% ✅

**Key Unlocked Workflows**:
- ✅ Complete jitter/shimmer analysis (periodic PointProcess)
- ✅ Voice source extraction (LPC inverse filtering)
- ✅ Cepstral voice quality (PowerCepstrum + plot)
- ✅ Advanced pitch-synchronous analysis (guided detection)

## Not Planned (and Why)

### DTW (Dynamic Time Warping)
- **Status**: Intentionally stubbed
- **Reason**: R's `dtw` package is comprehensive and superior
- **Action**: Document R alternative in vignette

### FormantGrid Formulas
- **Status**: Deferred
- **Reason**: Complex manipulation tier, low usage (2-3%)
- **Action**: Defer to v1.2.0 or later

### Trajectory Extraction
- **Status**: Not a Praat function gap
- **Reason**: R's tidyverse tools are superior
- **Action**: Provide example workflows in vignette

## Success Metrics for v1.1.0

1. ✅ Can replicate 90%+ of Praat archive scripts
2. ✅ Voice quality analysis workflows complete
3. ✅ All plot methods operational (17/17)
4. ✅ Comprehensive plotting documentation
5. ✅ Clean CRAN check
6. ✅ Performance benchmarks documented

## Next Session Tasks

### Immediate (Start Now)
1. Implement periodic PointProcess detection
2. Implement LPC inverse filtering
3. Implement PowerCepstrum wrapper

### Follow-up
4. Create plotting vignette
5. Update all documentation
6. Version bump to 1.1.0

---

**Status**: Ready to begin v1.1.0 core implementation
**Estimated Completion**: 2-3 days for core features
**Target Release**: v1.1.0 by end of week
