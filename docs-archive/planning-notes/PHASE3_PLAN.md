# Phase 3 Plan: Enhancements & Performance

**Date**: 2026-01-02  
**Version**: 1.9.3 → 2.0.0  
**Status**: PLANNING  
**Duration**: 5-10 days

---

## Overview

Phase 3 focuses on completing the package ecosystem: finishing module conversions, adding high-value features, and optimizing performance. This phase will bring pladdrr to v2.0 production-ready status.

---

## Goals

1. **Complete module conversions** - Convert remaining commonly-used R6 class (FormantTier)
2. **Expand operations** - Sound/Spectrum operations already started (Phase 3.1/3.2)
3. **Performance optimization** - SIMD improvements, batch processing
4. **User experience** - Vignettes, examples, polish

**Target**: v2.0.0 release-ready package

---

## Phase 3 Tasks

### 3.1 ✅ Sound Operations (COMPLETE)
**Status**: Already implemented (commit ab9560e)  
**File**: `src/modules/sound_operations_module.cpp`, `R/sound-operations.R`

**Functions**:
- `sounds_append()` - Concatenate with silence
- `sound_lengthen()` - Overlap-add time stretch
- `sound_deepen_band_modulation()` - Hearing enhancement
- `sounds_convolve()`, `sounds_cross_correlate()`, `sound_auto_correlate()`

**Action**: ✅ Nothing needed - already complete

---

### 3.2 ✅ Spectrum Operations (COMPLETE)
**Status**: Already implemented (commit 947874e)  
**Action**: ✅ Nothing needed - already complete

---

### 3.3 FormantTier Module Conversion (NEW)
**Priority**: HIGH  
**Effort**: 2-3 hours  
**Payoff**: HIGH - Completes commonly-used modules

**Goal**: Convert FormantTier from R6 to Rcpp Module (last commonly-used class)

**Tasks**:
1. Create `src/modules/formanttier_module.cpp`
   - RFormantTier class with XPtr wrapper
   - Methods: get_xmin/xmax, get_number_of_points, get_value_at_time
   - Transform: to_formant, filter_sound
   
2. Update `R/formanttier-r6.R`
   - Convert to function-based constructor
   - Wrap module methods
   
3. Add to `R/zzz.R` preload list

4. Test basic operations

**Success Criteria**:
- Package builds without errors
- FormantTier creates and queries work
- 25/28 modules converted (89%)

---

### 3.4 Vignettes for Phase 2 Modules (NEW)
**Priority**: HIGH  
**Effort**: 1-2 days  
**Payoff**: VERY HIGH - User adoption

**Goal**: Create comprehensive vignettes for new Phase 2 functionality

**Vignettes to Create**:

1. **`formantpath-analysis.Rmd`** (30-40 min)
   - Robust formant tracking with multiple ceilings
   - Comparison of candidates
   - Optimal path selection
   - Example: Analyzing difficult vowels
   
2. **`speech-synthesis.Rmd`** (30-40 min)
   - KlattGrid synthesis basics
   - Creating vowel inventory
   - Pitch contours and intonation
   - Example: Synthetic speech generation
   
3. **`analysis-resynthesis-workflow.Rmd`** (30-40 min)
   - FormantPath analysis
   - Extract formant parameters
   - Resynthesize with KlattGrid
   - Compare original vs synthetic
   - Example: Voice morphing

**Success Criteria**:
- All vignettes build without errors
- Working code examples
- Plots/visualizations included
- Published on pkgdown site

---

### 3.5 Performance Optimization (OPTIONAL)
**Priority**: MEDIUM  
**Effort**: 3-5 days  
**Payoff**: HIGH - Competitive performance

**Areas for Optimization**:

1. **SIMD for Statistical Operations** (2 days)
   - FormantPath uses heavy SVD/PCA
   - Vectorize inner loops
   - Target: 2-3x speedup on statistical ops
   
2. **Batch Processing** (1 day)
   - Parallel processing for multiple files
   - `batch_extract_formants(files, method="formantpath")`
   - Use `future` or `parallel` backend
   
3. **Memory Optimization** (1 day)
   - Profile FormantPath memory usage (5× Formant objects)
   - Streaming for large files
   - Reduce allocations in hot paths

4. **Benchmarking** (1 day)
   - Compare against Parselmouth
   - Document performance characteristics
   - Identify bottlenecks

**Success Criteria**:
- Measurable performance improvements
- Benchmarks documented
- No regressions in functionality

---

### 3.6 Package Polish (NEW)
**Priority**: MEDIUM  
**Effort**: 1-2 days  
**Payoff**: HIGH - Professional quality

**Tasks**:

1. **Documentation Audit** (half day)
   - Review all Rd files for completeness
   - Add examples to undocumented functions
   - Update package-level docs (`?pladdrr`)
   
2. **Error Messages** (half day)
   - Audit error messages for clarity
   - Add helpful suggestions (e.g., "Use KlattGrid_createFromVowel() instead")
   - Standardize error format
   
3. **NEWS.md Update** (1 hour)
   - Document all Phase 2 changes
   - Document Phase 3 additions
   - Migration guide for API changes
   
4. **README Update** (1 hour)
   - Add Phase 2 features showcase
   - Update installation instructions
   - Add badges (R-CMD-check, codecov, CRAN)
   
5. **DESCRIPTION Cleanup** (30 min)
   - Update version to 2.0.0
   - Review dependencies
   - Update author list if needed

**Success Criteria**:
- `R CMD check` passes with 0 warnings
- All exported functions documented
- Professional README/NEWS

---

## Priority Ranking

### Must Have (v2.0.0 blockers):
1. ✅ Sound operations (done)
2. ✅ Spectrum operations (done)
3. **FormantTier module** (2-3 hours) - Last common module
4. **Vignettes for Phase 2** (1-2 days) - Critical for adoption
5. **Package polish** (1 day) - Professional quality

### Should Have (v2.0.0 nice-to-have):
6. **Performance optimization** (3-5 days) - Competitive advantage
7. **Batch processing** (1 day) - User convenience

### Could Have (v2.1+):
8. More operations modules
9. Additional Praat classes (Phase 2B)
10. Advanced visualization tools

---

## Timeline

### Fast Track (5 days):
- Day 1: FormantTier module (3h) + start vignettes
- Day 2: Vignette 1 (formantpath-analysis.Rmd)
- Day 3: Vignette 2 (speech-synthesis.Rmd)  
- Day 4: Vignette 3 (analysis-resynthesis-workflow.Rmd)
- Day 5: Package polish + NEWS/README + final checks

**Result**: v2.0.0 ready with documentation

### Complete Track (10 days):
- Days 1-5: Fast track (above)
- Day 6-7: SIMD optimization for FormantPath
- Day 8: Batch processing
- Day 9: Memory optimization
- Day 10: Benchmarking + documentation

**Result**: v2.0.0 with performance optimizations

---

## Success Metrics

### Code Coverage
- 25/28 modules converted (89%)
- 31 Praat classes (32% coverage)
- 3+ comprehensive vignettes

### Documentation
- All Phase 2 modules documented
- Working examples for all features
- Migration guides

### Performance
- FormantPath: <1s for 1s audio (current: ~0.5s) ✓
- KlattGrid: <0.2s for 1s synthesis (current: <0.1s) ✓
- No regressions vs Phase 1

### Quality
- `R CMD check`: 0 errors, 0 warnings, 0 notes
- Test coverage: >80%
- Comprehensive vignettes

---

## Deliverables

### v2.0.0 Release Checklist:
- [ ] FormantTier module complete
- [ ] 3 Phase 2 vignettes written
- [ ] NEWS.md updated for v2.0.0
- [ ] README showcases Phase 2 features
- [ ] All documentation complete
- [ ] `R CMD check` passes cleanly
- [ ] Test suite passes (>80% coverage)
- [ ] Performance benchmarks documented

### Optional (v2.1):
- [ ] SIMD optimizations
- [ ] Batch processing utilities
- [ ] Parselmouth comparison benchmarks

---

## Risk Assessment

**Low Risk**:
- FormantTier conversion (well-established pattern)
- Vignette creation (straightforward documentation)
- Package polish (cleanup tasks)

**Medium Risk**:
- Performance optimization (may not yield expected gains)
- SIMD (platform-specific, complex)

**Mitigation**:
- Start with must-haves (FormantTier, vignettes, polish)
- Performance optimization is optional for v2.0
- Can defer to v2.1 if time-constrained

---

## Recommendation

**Start with Fast Track (5 days)**:

1. **Day 1**: FormantTier module (3h) - get to 89% conversion
2. **Days 2-4**: Write 3 comprehensive vignettes (critical for user adoption)
3. **Day 5**: Polish package (NEWS, README, docs)

This gets us to a **production-ready v2.0.0** with:
- ✅ 89% module conversion (25/28)
- ✅ Comprehensive Phase 2 documentation
- ✅ Professional quality polish
- ✅ All existing tests passing

**Then evaluate**: If time allows, add performance optimizations for v2.0.0, otherwise defer to v2.1.

---

## Next Action

**Immediate**: Proceed with FormantTier module conversion (Task 3.3)

**Estimated Time**: 2-3 hours

**Success Criteria**: FormantTier creates, queries work, package builds

---

**Plan Version**: 1.0  
**Last Updated**: 2026-01-02  
**Target Version**: 2.0.0  
**Recommended Track**: Fast Track (5 days)
