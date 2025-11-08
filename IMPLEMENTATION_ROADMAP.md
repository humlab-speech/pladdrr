# Speaker Package Implementation Roadmap

**Date**: 2025-11-08  
**Status**: Plan Complete - Implementation Starting  
**Branch**: 001-praat-r-access

## Current State

### ✅ Completed

1. **Comprehensive OOP Plan Created**
   - Document: `specs/001-praat-r-access/OOP-FOCUSED-PLAN.md`
   - Paradigm shift documented: procedures → objects
   - 12+ Praat objects specified
   - 200+ methods catalogued
   - Naming conventions established
   - 12-week implementation roadmap defined

2. **Build Infrastructure**
   - Makevars configured for praat.github.io source
   - Include paths corrected for all Praat directories
   - C++17 standard configured
   - Base infrastructure files created:
     - `praat_types.h` - Forward declarations
     - `praat_xptr_utils.h` - Memory management templates
     - `praat_error_handling.h` - Error bridge
   
3. **Base R6 Class**
   - `R/praat-object.R` - PraatObject base class
   - Inheritance hierarchy ready

4. **Initial Sound Implementation**
   - `R/sound-r6-new.R` - Complete R6 class definition
   - `src/sound_wrappers.cpp` - C++ wrapper skeleton (needs completion)
   - All methods specified

### ⚠️  In Progress

1. **Praat Source Compilation**
   - Headers include correctly
   - Some template warnings from Praat (non-fatal)
   - Need to fix sound_wrappers.cpp implementation details
   - Need to ensure Praat C++ code compiles cleanly

### 🚧 Blocked / Next Steps

**Immediate** (This Session):
1. Fix sound_wrappers.cpp compilation errors
2. Get minimal Sound object working (read, query duration)
3. Test end-to-end: R → C++ → Praat → back to R
4. Commit working Sound implementation

**Week 1-2** (Foundation):
5. Complete all Sound methods
6. Add proper error handling throughout
7. Memory leak testing with valgrind
8. Write unit tests for Sound
9. Document Sound thoroughly

## Implementation Strategy

### Phase-by-Phase Approach

**Phase 1**: Sound (Template for all others)
- Get Sound 100% working
- Establishes patterns for:
  - R6 class structure  
  - C++ wrapper style
  - XPtr memory management
  - Error handling
  - Testing approach
  - Documentation format

**Phase 2**: TextGrid (Most Critical Missing Feature)
- Enables linguistic annotation
- Required for most phonetic workflows
- Complex: interval tiers + point tiers
- Will validate our architecture with a different object type

**Phase 3**: Analysis Objects (Most Used)
- Pitch
- Formant
- Intensity
- Harmonicity
Priority order based on usage frequency

**Phase 4**: Spectral (Specialized)
- Spectrum
- Spectrogram
- Ltas

**Phase 5**: Advanced (Powerful Features)
- PointProcess
- Manipulation (PSOLA)
- VoiceReport

**Phase 6**: Tiers (Fine Control)
- PitchTier
- FormantTier
- IntensityTier
- DurationTier

**Phase 7**: Examples (Demonstrate Equivalence)
- Re-implement all superassp Python code
- Show Parselmouth → speaker translation
- Document in `inst/examples/`

**Phase 8**: Documentation (Make it Usable)
- 9+ vignettes
- Complete reference docs
- Migration guides

**Phase 9**: Testing & Validation (Make it Reliable)
- >95% R coverage
- >85% C++ coverage
- Valgrind clean
- Performance benchmarks
- Comparison with Praat/Parselmouth

## Critical Design Decisions

### 1. Object-Oriented vs Procedure-Based

**Decision**: Full OOP with R6 classes
**Rationale**:
- Mirrors Praat's native C++ design
- Matches Parselmouth's proven approach
- Enables method chaining
- Reduces data copying
- More intuitive for users

### 2. Memory Management

**Decision**: External pointers (XPtr) with automatic finalization
**Rationale**:
- Zero-copy between R and C++
- Automatic cleanup via R's GC
- Praat objects stay in C++ memory
- Efficient for large audio data

### 3. Naming Conventions

**Decision**: Praat commands → R6 methods with consistent patterns
**Pattern**:
- `Get *` → `get_*()`
- `To *` → `to_*()`
- `Extract *` → `extract_*()`
- Modification → verb, e.g., `scale_intensity()`
- Export → `as_matrix()`, `as_data_frame()`

**Rationale**:
- Easy translation from Praat scripts
- Familiar to Praat users
- Consistent within package
- R-idiomatic (snake_case)

### 4. Error Handling

**Decision**: Convert MelderError to R exceptions
**Implementation**: `praat_error_handling.h` with try/catch bridge
**Rationale**:
- R users expect R errors
- Provides useful error messages
- Allows graceful failure

### 5. Full Praat Source vs Minimal Subset

**Decision**: Embed full Praat source (praat.github.io)
**Rationale**:
- Access to all functionality
- Can implement any Praat feature
- Easier maintenance (track Praat repo)
- Complete compatibility

## Success Metrics

### Technical Excellence
- [ ] 12+ core objects implemented
- [ ] 200+ methods functional
- [ ] Zero memory leaks (valgrind)
- [ ] Test coverage >90% (R), >80% (C++)
- [ ] Performance within 10% of Praat
- [ ] Builds on macOS, Linux, Windows

### Usability
- [ ] Intuitive API matching Praat concepts
- [ ] 50+ working examples
- [ ] 9+ comprehensive vignettes
- [ ] Clear migration documentation
- [ ] Consistent naming throughout

### Completeness
- [ ] All superassp examples re-implemented
- [ ] TextGrid fully supported
- [ ] Voice quality metrics complete
- [ ] Pitch manipulation (PSOLA) working
- [ ] All major Praat workflows possible

## Timeline

| Week | Phase | Deliverable |
|------|-------|-------------|
| 1-2 | Foundation | Sound object 100% complete + tests |
| 3-4 | TextGrid | Full TextGrid support |
| 4-5 | Pitch | Pitch analysis complete |
| 5-6 | Formant | Formant tracking complete |
| 6 | Intensity + Harmonicity | Voice metrics |
| 7 | Spectral | Spectrum, Spectrogram, Ltas |
| 8 | Advanced | PointProcess, Manipulation |
| 9 | Tiers | All tier objects |
| 10 | Examples | Re-implement Python code |
| 11 | Documentation | Vignettes and reference |
| 12 | Testing | Validation and CRAN prep |

**Total**: 12 weeks to production-ready package

## Files Organization

```
speaker/
├── specs/001-praat-r-access/
│   └── OOP-FOCUSED-PLAN.md           ⭐ Master plan
├── OOP_IMPLEMENTATION_STATUS.md      Current status
├── IMPLEMENTATION_ROADMAP.md         This file
│
├── R/
│   ├── praat-object-base.R           Base class
│   ├── sound-r6.R                    Sound [IN PROGRESS]
│   ├── textgrid-r6.R                 [TODO]
│   ├── pitch-r6.R                    [TODO]
│   ├── formant-r6.R                  [TODO]
│   ├── intensity-r6.R                [TODO]
│   ├── harmonicity-r6.R              [TODO]
│   ├── spectrum-r6.R                 [TODO]
│   ├── spectrogram-r6.R              [TODO]
│   ├── manipulation-r6.R             [TODO]
│   ├── pointprocess-r6.R             [TODO]
│   └── voice-report-r6.R             [TODO]
│
├── src/
│   ├── praat_types.h                 ✅ Done
│   ├── praat_xptr_utils.h            ✅ Done
│   ├── praat_error_handling.h        ✅ Done
│   ├── sound_wrappers.cpp            [IN PROGRESS]
│   ├── textgrid_wrappers.cpp         [TODO]
│   ├── pitch_wrappers.cpp            [TODO]
│   ├── formant_wrappers.cpp          [TODO]
│   ├── intensity_wrappers.cpp        [TODO]
│   ├── harmonicity_wrappers.cpp      [TODO]
│   ├── spectrum_wrappers.cpp         [TODO]
│   ├── spectrogram_wrappers.cpp      [TODO]
│   ├── manipulation_wrappers.cpp     [TODO]
│   ├── pointprocess_wrappers.cpp     [TODO]
│   ├── voice_report_wrappers.cpp     [TODO]
│   ├── Makevars                      ✅ Configured
│   └── Makevars.win                  [TODO]
│
├── inst/examples/                    [TODO - Phase 7]
│   ├── voice_report.R
│   ├── pitch_tracking.R
│   ├── formant_tracking.R
│   └── ...
│
├── tests/testthat/                   [TODO - Ongoing]
│   ├── test-sound.R
│   ├── test-textgrid.R
│   └── ...
│
└── vignettes/                        [TODO - Phase 8]
    ├── getting-started.Rmd
    ├── textgrid-tutorial.Rmd
    ├── voice-quality.Rmd
    ├── pitch-manipulation.Rmd
    ├── praat-to-r.Rmd
    ├── parselmouth-to-speaker.Rmd
    └── ...
```

## Key References

1. **Master Plan**: `specs/001-praat-r-access/OOP-FOCUSED-PLAN.md`
2. **Praat Source**: `src/praat.github.io/`
3. **Parselmouth**: Reference for proven approach
4. **Original Spec**: `specs/001-praat-r-access/spec.md` (procedure-based - superseded)

## Risks and Mitigations

### Risk 1: Praat C++ Compilation Complexity
**Mitigation**: 
- Start with minimal subset (Sound only)
- Gradually add dependencies
- Use compiler flags to suppress warnings
- Test on multiple platforms early

### Risk 2: Memory Management Bugs
**Mitigation**:
- Use XPtr with automatic finalizers
- Extensive valgrind testing
- Clear ownership semantics
- Document memory model

### Risk 3: API Surface Too Large (200+ methods)
**Mitigation**:
- Prioritize by usage frequency
- Phase implementation
- Automated testing
- Code generation where possible

### Risk 4: Platform Compatibility (Windows)
**Mitigation**:
- Makevars.win configuration
- GitHub Actions CI/CD
- Test on all platforms
- Document platform-specific issues

## Next Immediate Actions

1. ✅ Create this roadmap document
2. ✅ Commit progress to git
3. 🚧 Fix sound_wrappers.cpp compilation
4. 🚧 Test Sound$new("file.wav")
5. 🚧 Test sound$get_duration()
6. 🚧 Write first unit test
7. 🚧 Document Sound class
8. 🚧 Commit working Sound

Then proceed systematically through the phases!

## Conclusion

This roadmap provides a clear path from the current state (plan complete, initial code written) to a production-ready, comprehensive Praat interface for R. The object-oriented approach will deliver a package that:

1. **Mirrors Praat's design** - Natural for Praat users
2. **Matches Parselmouth's capabilities** - But in pure R
3. **Exposes full functionality** - 12+ objects, 200+ methods
4. **Enables R-native workflows** - No Python dependency
5. **Provides clear migration paths** - From Praat scripts and Parselmouth

**This will be the definitive phonetic analysis toolkit for R!** 🎉
