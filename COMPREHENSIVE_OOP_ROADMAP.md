# Comprehensive Object-Oriented Implementation Roadmap

**Date**: 2025-11-08  
**Version**: 0.2.0 Development Cycle  
**Status**: Active Development Plan

## Overview

This document tracks the comprehensive implementation of the speaker package as a complete object-oriented interface to Praat, based on the analysis in `specs/001-praat-r-access/COMPREHENSIVE-OOP-AMENDMENT.md`.

## Current Status (v0.1.0)

### ✅ Completed Objects (6)

1. **Sound** - ~50 methods - ✅ COMPLETE
2. **Pitch** - ~30 methods - ✅ COMPLETE  
3. **Formant** - ~20 methods - ✅ COMPLETE
4. **Intensity** - ~15 methods - ✅ COMPLETE
5. **Harmonicity** - ~15 methods - ✅ COMPLETE
6. **TextGrid** - ~20/35 methods - 🚧 PARTIAL (structure complete, needs modification methods)

**Progress**: ~195/408 methods (~48% complete)

## Implementation Phases

### Phase 1: Critical Objects for Complete Workflows (Weeks 1-3)

Priority: ⭐⭐⭐ HIGHEST - Enables voice quality and manipulation

- [ ] **Week 1**: PointProcess (~20 methods)
  - Voice quality metrics (jitter, shimmer)
  - Integration with Sound and Pitch
  - Files: `R/pointprocess-r6.R`, `src/pointprocess_wrappers.cpp`

- [ ] **Week 2**: Tier Objects (~32 methods total)
  - PitchTier (~12 methods) - Modifiable pitch contour
  - DurationTier (~10 methods) - Duration control
  - IntensityTier (~10 methods) - Intensity control
  - Files: `R/*tier-r6.R`, `src/*tier_wrappers.cpp`

- [ ] **Week 3**: Manipulation (~12 methods) ⭐⭐⭐ CRITICAL
  - PSOLA-based pitch/duration modification
  - Extract/replace pitch/duration tiers
  - Resynthesis methods
  - Files: `R/manipulation-r6.R`, `src/manipulation_wrappers.cpp`
  - Vignette: `vignettes/pitch-manipulation.Rmd`

**Milestone**: Voice quality + pitch manipulation workflows complete

### Phase 2: Spectral Analysis Objects (Weeks 4-5)

Priority: ⭐⭐ HIGH - Essential for comprehensive analysis

- [ ] **Week 4**: Core Spectral (~43 methods total)
  - Spectrum (~18 methods) - FFT frequency domain
  - Spectrogram (~15 methods) - Time-frequency representation  
  - LPC (~10 methods) - Linear predictive coding
  - Files: `R/spectrum-r6.R`, `R/spectrogram-r6.R`, `R/lpc-r6.R`

- [ ] **Week 5**: Advanced Spectral (~41 methods total)
  - Ltas (~12 methods) - Long-term average spectrum
  - Excitation (~5 methods) - Auditory excitation
  - Cochleagram (~8 methods) - Filterbank output
  - MelFilter (~6 methods) - Mel-scale filtering
  - MFCC (~10 methods) - Mel-frequency cepstral coefficients
  - Files: `R/ltas-r6.R`, `R/excitation-r6.R`, etc.
  - Vignette: `vignettes/spectral-analysis.Rmd`

**Milestone**: Complete spectral analysis pipeline

### Phase 3: Advanced Analysis Objects (Weeks 6-7)

Priority: ⭐ MEDIUM - Advanced functionality

- [ ] **Week 6**: Formant Advanced (~35 methods total)
  - FormantPath (~10 methods) - Modern tracking
  - FormantGrid (~15 methods) - Modifiable formants
  - Matrix (~20 methods) - 2D numerical data (base class)
  - Files: `R/formantpath-r6.R`, `R/formantgrid-r6.R`, `R/matrix-r6.R`

- [ ] **Week 7**: Data Structures (~50+ methods total)
  - Table (~50 methods) - Praat's data frame
  - Collection (~5 methods) - Object container
  - Files: `R/table-r6.R`, `R/collection-r6.R`

**Milestone**: Advanced analysis complete

### Phase 4: Complete TextGrid (Week 8)

Priority: ⭐⭐⭐ CRITICAL - Essential for annotation

- [ ] **Week 8**: TextGrid Completion (~15 remaining methods)
  - Interval tier modification (insert_boundary, set_interval_text, etc.)
  - Point tier operations (insert_point, set_point_text, etc.)
  - Tier management (add_tier, remove_tier, etc.)
  - Extraction (extract_part)
  - Enable: `src/textgrid_wrappers.cpp` (currently disabled)
  - Update: `R/textgrid-r6.R`
  - Vignette: `vignettes/textgrid-annotation.Rmd`

**Milestone**: TextGrid fully functional

### Phase 5: Migrate superassp Examples (Weeks 9-10)

Priority: ⭐⭐ HIGH - Demonstrates capability

- [ ] **Week 9**: Core Analysis Examples (5 examples)
  - praat_pitch.R
  - praat_formant_burg.R
  - praat_formantpath_burg.R
  - praat_intensity.R
  - praat_spectral_moments.R

- [ ] **Week 10**: Voice Quality Examples (6 examples)
  - praat_voice_report.R ⭐
  - praat_avqi.R
  - praat_dsi.R
  - praat_praatsauce.R
  - praat_sauce.R
  - praat_voice_tremor.R

**Deliverables**:
- `inst/examples/*.R` - 11 complete scripts
- `inst/examples/README.md` - Overview
- `inst/examples/PYTHON_TO_R_MAPPING.md` - API comparison

**Milestone**: All Parselmouth workflows have R equivalents

### Phase 6: Documentation (Week 11)

Priority: ⭐⭐⭐ CRITICAL - User success

- [ ] **Vignettes** (10 comprehensive guides):
  1. Getting Started
  2. Sound Objects
  3. Pitch Analysis
  4. Formant Tracking
  5. TextGrid Annotation
  6. Voice Quality Assessment
  7. Spectral Analysis
  8. Pitch Manipulation
  9. Praat Scripts → R
  10. Parselmouth → speaker

- [ ] **Reference Documentation**:
  - Complete Rd files for 24 R6 classes
  - Method documentation with examples
  - Package overview
  - NEWS.md update

- [ ] **Package Website**:
  - pkgdown site
  - Tutorial articles
  - API reference

**Milestone**: Comprehensive documentation complete

### Phase 7: Testing & CRAN Preparation (Week 12)

Priority: ⭐⭐⭐ CRITICAL - Quality assurance

- [ ] **Unit Tests**: >300 tests, >95% coverage
- [ ] **Integration Tests**: 30+ workflows
- [ ] **Validation Tests**: Compare with Praat/Parselmouth
- [ ] **Memory Tests**: valgrind, ASAN, leak detection
- [ ] **Performance Benchmarks**: Within 10% of Praat
- [ ] **Platform Tests**: Windows, macOS (Intel + ARM), Linux
- [ ] **CRAN Preparation**:
  - R CMD check --as-cran (0 errors, 0 warnings, 0 notes)
  - CITATION file
  - cran-comments.md
  - Package size optimization

**Milestone**: CRAN submission ready

## Implementation Tracking

### Objects by Status

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Complete | 5 | 21% |
| 🚧 Partial | 1 | 4% |
| ❌ Planned | 18 | 75% |
| **Total** | **24** | **100%** |

### Methods by Status

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Implemented | ~195 | 48% |
| ❌ Remaining | ~213 | 52% |
| **Total** | **~408** | **100%** |

## Key Principles

1. **Mirror Praat's OOP Design**: R6 classes ↔ Praat C++ objects
2. **Consistent Naming**: `get_*()`, `to_*()`, `as_*()` patterns
3. **Memory Safety**: XPtr with automatic finalizers
4. **Full Coverage**: All major Praat workflows supported
5. **Quality First**: Comprehensive testing and validation
6. **User Focus**: Clear documentation and examples

## Success Metrics

- [ ] 24 Praat objects as R6 classes
- [ ] ~400 methods implemented
- [ ] Zero memory leaks (valgrind)
- [ ] >95% test coverage
- [ ] All superassp examples migrated
- [ ] 10 comprehensive vignettes
- [ ] CRAN submission ready
- [ ] Performance within 10% of Praat

## Timeline

- **Start**: Week of 2025-11-08
- **Phase 1 Complete**: Week of 2025-11-29 (3 weeks)
- **Phase 2 Complete**: Week of 2025-12-13 (2 weeks)
- **Phase 3 Complete**: Week of 2025-12-27 (2 weeks)
- **Phase 4 Complete**: Week of 2026-01-03 (1 week)
- **Phase 5 Complete**: Week of 2026-01-17 (2 weeks)
- **Phase 6 Complete**: Week of 2026-01-24 (1 week)
- **Phase 7 Complete**: Week of 2026-01-31 (1 week)
- **Total Duration**: 12 weeks

## Next Actions

1. ✅ Create comprehensive amendment plan
2. ✅ Document current status
3. ⬜ Begin PointProcess implementation (Phase 1, Week 1)
4. ⬜ Set up GitHub project board for tracking
5. ⬜ Update DESCRIPTION version to 0.2.0.9000 (development)
6. ⬜ Commit and push amendment

## References

- **Amendment Document**: `specs/001-praat-r-access/COMPREHENSIVE-OOP-AMENDMENT.md`
- **Original Plan**: `specs/001-praat-r-access/FINAL-OOP-IMPLEMENTATION-PLAN.md`
- **Praat Source**: `src/praat.github.io/`
- **Parselmouth Examples**: `/Users/frkkan96/Documents/src/superassp/inst/python/`

---

**Last Updated**: 2025-11-08  
**Next Review**: After Phase 1 completion
