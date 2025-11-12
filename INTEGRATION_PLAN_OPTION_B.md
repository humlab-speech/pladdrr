# Integration Plan - Option B: Hybrid Approach
**Date**: 2025-11-12  
**Package Version**: 0.4.1  
**Strategy**: Complete v1.0.0 with R6, maintain R7 prototypes for v2.0.0

## Executive Summary

**Option B** keeps the production-ready R6 implementation for v1.0.0 release while maintaining R7 prototypes for future v2.0.0 migration. This minimizes risk and accelerates the path to a stable CRAN release.

## Current Status

### R6 Implementation (Production - v1.0.0) ✅
- 19/19 Praat objects complete (~311 methods)
- All C++ wrappers working
- Memory management proven
- Basic documentation in place
- **Status**: Production-ready

### R7 Implementation (Prototype - v2.0.0) 🔬
- Base PraatObject_S7 class complete
- Harmonicity_S7 prototype complete (20 methods with S3 integration)
- Remaining 18 objects pending (for v2.0.0)
- **Status**: Proof-of-concept complete, not for v1.0.0

## Path to v1.0.0 (~4 weeks)

### Phase 1: Objects Complete ✅
- 19/19 objects implemented
- Ready to move forward

### Phase 2: Examples from superassp (~1 week)

**Goal**: Reimplement Python Parselmouth examples in native speaker R

**Location**: `/inst/examples/`  
**Source**: `/Users/frkkan96/Documents/src/superassp/inst/python`

**Files to Create**:

1. **`voice_quality_analysis.R`**
   - Jitter, shimmer calculations
   - HNR (Harmonicity) analysis
   - Voice quality metrics comparison
   - Example: Analyze sustained vowel for voice quality

2. **`formant_tracking.R`**
   - Formant extraction workflows
   - Formant statistics over time
   - Vowel space analysis
   - Example: Track formants in speech sample

3. **`pitch_manipulation.R`**
   - PSOLA pitch modification
   - PitchTier manipulation
   - Duration modification
   - Example: Raise pitch by 50Hz while preserving quality

4. **`spectral_analysis.R`**
   - Spectral moments
   - Filtering operations
   - LTAS analysis
   - Example: Long-term average spectrum of speech

5. **`textgrid_workflows.R`**
   - TextGrid creation and manipulation
   - Tier management
   - Label extraction and analysis
   - Example: Align TextGrid with formant data

6. **`integration_examples.R`**
   - Multi-object workflows
   - Complete analysis pipelines
   - Export workflows
   - Example: Full phonetic analysis pipeline

7. **`README.md`**
   - Overview of examples
   - Comparison with Parselmouth
   - Performance benchmarks
   - How to run examples

### Phase 3: Comprehensive Documentation (~1 week)

#### Vignettes (6 comprehensive guides)

1. **`vignettes/introduction.Rmd`** - Getting Started
   - Package philosophy (OOP, direct Praat access)
   - Installation
   - Basic workflow
   - Object model overview
   - First analysis example

2. **`vignettes/acoustic-analysis.Rmd`** - Core Analyses
   - Pitch extraction and analysis
   - Formant tracking
   - Intensity analysis
   - Harmonicity (HNR)
   - Voice quality metrics (jitter, shimmer)
   - Spectral analysis

3. **`vignettes/speech-synthesis.Rmd`** - Manipulation
   - PSOLA manipulation overview
   - Pitch modification with PitchTier
   - Duration modification with DurationTier
   - Intensity modification with IntensityTier
   - Formant synthesis with FormantGrid
   - Complete synthesis examples

4. **`vignettes/textgrids.Rmd`** - Annotation
   - TextGrid creation
   - Interval and point tiers
   - Label and boundary management
   - Reading and writing TextGrids
   - Integration with acoustic analyses
   - Batch processing annotations

5. **`vignettes/advanced-topics.Rmd`** - Expert Use
   - Custom analyses
   - Integration with tidyverse
   - Integration with other R packages
   - Performance optimization
   - Memory management tips
   - Extending the package

6. **`vignettes/from-parselmouth.Rmd`** - Migration Guide
   - Python Parselmouth vs R speaker
   - Side-by-side code comparisons
   - Advantages of speaker package
   - Common patterns translation
   - Performance comparisons
   - Workflow examples

#### Package Documentation

- [ ] Update README.md with comprehensive examples
- [ ] Ensure all functions have complete roxygen2 docs
- [ ] Add package-level documentation (`speaker-package.R`)
- [ ] Create pkgdown website configuration (`_pkgdown.yml`)
- [ ] Complete NEWS.md with all changes since start
- [ ] Add citation file (CITATION)

### Phase 4: Testing & Quality (~3-4 days)

#### Test Coverage
- [ ] Aim for 90%+ test coverage
- [ ] All object creation tests
- [ ] All method tests for all 19 objects
- [ ] Memory leak tests (valgrind)
- [ ] Edge case handling (empty inputs, invalid parameters)
- [ ] Integration tests (multi-object workflows)

#### Performance Benchmarking
- [ ] Create benchmarks vs Parselmouth (where possible)
- [ ] Profile critical paths
- [ ] Document performance characteristics
- [ ] Test with large files
- [ ] Memory usage profiling

#### CRAN Readiness
- [ ] `R CMD check --as-cran` (zero warnings, zero notes)
- [ ] All examples run successfully
- [ ] All vignettes build cleanly
- [ ] Check on Windows (win-builder)
- [ ] Check on multiple R versions (R-hub)
- [ ] Spell check all documentation
- [ ] Verify all URLs work
- [ ] Check DESCRIPTION metadata complete

#### Final Polish
- [ ] Consistent code style (lintr)
- [ ] Remove debug code and comments
- [ ] Clean up temporary files
- [ ] Verify all exports in NAMESPACE correct
- [ ] Remove unused imports
- [ ] Final pass on all error messages

### Phase 5: Release Preparation (1-2 days)

#### Version Bump
- Update DESCRIPTION: `Version: 1.0.0`
- Update Date field to release date
- Final NEWS.md entry for v1.0.0

#### Documentation Review
- [ ] All vignettes proofread
- [ ] README accurate and complete
- [ ] All links working
- [ ] Examples tested and working
- [ ] License correct (MIT)

#### Submission
- [ ] Create GitHub release v1.0.0
- [ ] Tag commit: `git tag v1.0.0`
- [ ] Build source package: `R CMD build .`
- [ ] Final check: `R CMD check --as-cran speaker_1.0.0.tar.gz`
- [ ] Submit to CRAN
- [ ] Prepare canned responses to potential CRAN feedback

## Path to v2.0.0 (R7 Migration - Future)

**Timeline**: 3-6 months after v1.0.0 release

### Phase 1: Ecosystem Monitoring (Passive - Months 1-3)
- Monitor S7 package development and updates
- Track other packages migrating to R7
- Collect user feedback on v1.0.0 R6 interface
- Identify pain points and improvement opportunities
- Watch for best practices emerging

### Phase 2: Full R7 Migration (~3 weeks - Months 4-5)
- Migrate all 19 objects from R6 to R7
- Use Harmonicity_S7 as template
- Comprehensive testing against R6 version
- Performance benchmarking
- Full documentation updates
- Migration vignette for users

### Phase 3: v2.0.0 Release (Month 6)
- Major version bump (signals breaking changes)
- Comprehensive migration guide
- Deprecation warnings for R6 (if removing)
- CRAN submission
- Announcement and promotion

## Maintaining R7 Prototypes in Parallel

### Current R7 Files (Keep for Reference - Not in Package)
Location: `/dev/r7-prototypes/` (to be created)

- `r7-praat-object.R` - Base class implementation
- `r7-harmonicity.R` - Full Harmonicity R7 implementation
- `R7_MIGRATION_SESSION_2025-11-12.md` - Strategy document
- `R7_IMPLEMENTATION_PROGRESS_2025-11-12.md` - Progress log

### Guidelines for R7 Prototypes
1. **Don't export** R7 objects in v1.0.0 NAMESPACE
2. **Document** R7 progress in separate markdown files
3. **Test** R7 implementations but don't include in package test suite
4. **Update** R7 prototypes as we improve R6 versions
5. **Maintain** architectural knowledge for smooth v2.0.0 transition

### Action: Move R7 Files
```bash
mkdir -p dev/r7-prototypes
mv R/r7-*.R dev/r7-prototypes/
mv R7_*.md dev/r7-prototypes/
```

## Timeline to v1.0.0

| Week | Phase | Deliverable | Version |
|------|-------|-------------|---------|
| 1 | Examples | superassp reimplementation | 0.5.0 |
| 2-3 | Documentation | 6 vignettes + docs | 0.9.0 |
| 3-4 | Testing | CRAN-ready package | 0.9.5 |
| 4 | Release | v1.0.0 submission | **1.0.0** |

**Total Time**: ~4 weeks to v1.0.0 🎉

## Next Immediate Actions

1. ✅ Document Option B plan (this file)
2. ⏭️ Move R7 prototypes to dev directory
3. ⏭️ Update CLAUDE.md with Option B strategy
4. ⏭️ Begin superassp examples analysis and reimplementation
5. ⏭️ Start writing first vignette (introduction)

## Success Criteria for v1.0.0

### Functionality ✅
- [x] All 19 Praat objects working
- [x] ~311 methods implemented
- [ ] Comprehensive examples (6-7 files)
- [ ] Full documentation (6 vignettes)

### Quality 🎯
- [ ] 90%+ test coverage
- [ ] Zero CRAN warnings/notes
- [ ] All vignettes build cleanly
- [ ] Performance benchmarked vs Parselmouth
- [ ] Memory safety verified (valgrind)

### Documentation 📚
- [ ] 6 vignettes complete and proofread
- [ ] All ~311 functions documented
- [ ] README comprehensive with examples
- [ ] Migration guide from Parselmouth
- [ ] pkgdown website ready

### Release 🚀
- [ ] GitHub release v1.0.0 created
- [ ] CRAN submission accepted
- [ ] Package website deployed
- [ ] Announcement prepared
- [ ] Social media/R community outreach

## Advantages of Option B

### 1. Faster to v1.0.0 ✅
- R6 implementation complete and stable
- No migration delays
- Focus on documentation and examples

### 2. Proven Stability ✅
- R6 is battle-tested in R ecosystem
- Memory management proven in speaker
- Users get stable API from day 1

### 3. Learning Time ✅
- Let S7/R7 ecosystem mature
- Learn from other packages' migrations
- Incorporate best practices discovered

### 4. User Confidence ✅
- Stable, well-tested v1.0.0
- Clear upgrade path to v2.0.0
- No breaking changes in minor versions

### 5. Risk Mitigation ✅
- R6 fallback if R7 has issues
- Can maintain both versions if needed
- Gradual deprecation possible

## Communication Strategy

### Now (v0.4.1)
- Package functional but beta
- R6 interface stable
- Examples and vignettes in progress
- "Use at your own risk" disclaimer

### v1.0.0 Release Message
- Production-ready R package
- Complete documentation
- CRAN availability
- Stable R6 interface
- "R7 migration planned for v2.0.0"

### Future (v2.0.0 announcement)
- Modern R7 implementation
- Better S3 integration (automatic print/plot/summary)
- Breaking changes but migration guide provided
- "Upgrade from v1.0.0 straightforward"

## Comparison with Other Approaches

### vs Option A (Full R7 Migration Now)
- ❌ Delays v1.0.0 by 2-3 weeks
- ❌ R7 ecosystem still maturing
- ✅ Modern from start
- ✅ Better S3 integration

### vs Option C (Dual Interface)
- ❌ Maintains two implementations
- ❌ More complex testing/docs
- ✅ Users choose preference
- ❌ Larger codebase

### Why Option B Wins
- Fastest path to stable v1.0.0
- Proven technology (R6)
- Natural upgrade path (v2.0.0)
- Lower risk
- Simpler maintenance

## Files to Update for Option B

### Documentation
- [x] Create INTEGRATION_PLAN_OPTION_B.md (this file)
- [ ] Update CLAUDE.md with Option B strategy
- [ ] Add note to README about future R7 in v2.0.0
- [ ] Update development roadmap documents

### Code Organization
- [ ] Move `R/r7-*.R` to `dev/r7-prototypes/`
- [ ] Move R7 markdown docs to `dev/r7-prototypes/`
- [ ] Add `.Rbuildignore` entry for `dev/` directory
- [ ] Add README in `dev/r7-prototypes/` explaining status

### Testing
- [ ] Ensure no R7 tests in package test suite
- [ ] Verify NAMESPACE doesn't export R7 objects
- [ ] Confirm package builds without R7 files

---

## Conclusion

**Option B (Hybrid Approach)** is the optimal strategy:

**Short-term Goal**: Deliver production-ready v1.0.0 with proven R6 implementation in ~4 weeks

**Long-term Goal**: Migrate to modern R7 for v2.0.0 when ecosystem matures (~6 months post v1.0.0)

This approach:
- ✅ Minimizes risk
- ✅ Maximizes stability
- ✅ Provides clear upgrade path
- ✅ Gets package to users faster
- ✅ Learns from R7 ecosystem evolution

**Next Step**: Begin superassp examples reimplementation

---

**Status**: Plan Approved for Execution  
**Current Version**: 0.4.1 (R6)  
**Target Version**: 1.0.0 (R6) → 2.0.0 (R7)  
**Estimated v1.0.0 Release**: 4 weeks from now  
**Date Created**: 2025-11-12
