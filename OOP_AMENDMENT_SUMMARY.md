# OOP Strategic Amendment - Summary

**Date:** 2025-11-08  
**Action:** Strategic shift from functional to object-oriented implementation  
**Impact:** Comprehensive redesign prioritizing Praat's native architecture

## What Changed

### Previous Approach
- Function-based interface (procedural)
- Isolated operations: `praat_extract_pitch(file, ...)`
- Limited object persistence
- Missing critical features (TextGrid, Manipulation)

### New Approach
- Object-oriented interface (R6 classes)
- Mirrors Praat's C++ architecture
- Persistent objects with method chaining
- Complete coverage of Praat's 30+ object types

## Analysis Conducted

1. **Praat Source Code Analysis** (using Gemini CLI)
   - Analyzed `inst/praat.github.io/fon/` directory
   - Identified inheritance hierarchy: Thing → Function → Sampled/Vector/Matrix
   - Catalogued 30+ object types with ~10-40 methods each
   - Documented Praat's method naming patterns

2. **Current Implementation Review**
   - Sound: 19/40 methods (48% complete)
   - Pitch: 8/20 methods (40% complete)
   - PointProcess: 8/15 methods (53% complete)
   - Formant, Intensity, Harmonicity: S3 only (need R6 conversion)
   - TextGrid: NOT IMPLEMENTED (critical gap)
   - Manipulation: NOT IMPLEMENTED (critical gap)

## Key Documents Created

1. **`specs/001-praat-r-access/OOP-STRATEGIC-AMENDMENT.md`**
   - Executive summary of the strategic shift
   - Problem statement comparing old vs new approach
   - Complete Praat object catalog with priorities
   - 12-week implementation roadmap
   - Success metrics and deliverables

2. **`IMPLEMENTATION_ROADMAP_OOP.md`**
   - Detailed implementation plan for all objects
   - Method-by-method breakdown
   - Code examples for each object
   - Testing and documentation requirements
   - Phase-by-phase delivery schedule

3. **`CLAUDE.md` - Updated**
   - Added "STRATEGIC SHIFT" section
   - Documented object priority list
   - Implementation approach per object
   - Next immediate actions

## Priorities Identified

### Priority 1: Foundation Objects (Weeks 1-2)
- ✅ Sound - Expand from 19 to 40 methods
- ✅ Pitch - Expand from 8 to 20 methods
- 🔄 Formant - Convert S3 to R6 (15 methods)
- 🔄 Intensity - Convert S3 to R6 (12 methods)
- 🔄 Harmonicity - Convert S3 to R6 (10 methods)
- ✅ PointProcess - Expand voice quality methods

### Priority 2: Critical Missing Features (Weeks 3-6)
- ❌ **TextGrid** ⭐⭐⭐ (Weeks 3-4)
  - Most critical missing feature
  - Used by 90%+ of phonetic research
  - Essential for forced alignment
  - 35 methods needed

- ❌ **Manipulation** ⭐⭐ (Weeks 5-6)
  - Pitch/duration modification
  - PSOLA resynthesis
  - Includes PitchTier, DurationTier
  - 10+ methods needed

### Priority 3-6: Extended Features (Weeks 7-12)
- Spectral objects (Spectrogram, Spectrum, LPC, Ltas)
- Tier objects (IntensityTier, FormantGrid)
- Advanced analysis (VoiceReport, etc.)
- Examples and validation

## Implementation Strategy

### Per-Object Pattern
1. **Analyze Praat source** - Review header file for all methods
2. **Create C++ wrappers** - Bridge to Praat functions
3. **Create R6 class** - Expose methods with consistent naming
4. **Write tests** - Unit, integration, memory leak tests
5. **Document** - Roxygen2 + vignettes + examples

### Naming Conventions (Praat → R)
- `Get [property]` → `get_[property]()`
- `To [Object]` → `to_[object]()`
- `Extract [part]` → `extract_[part]()`
- `[Action]` → `[action]()`
- Export → `as_data_frame()`, `as_matrix()`
- I/O → `$new(path)`, `save(path)`

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
- [ ] Consistent naming conventions
- [ ] 10+ comprehensive vignettes
- [ ] 50+ documented examples
- [ ] Clear migration guides (Praat scripts, Parselmouth)

### Performance
- [ ] Within 10% speed of Praat desktop
- [ ] Efficient memory usage (no unnecessary copying)

## Current Status

**Progress:** ~25% complete (6 objects partially implemented, 0 complete)

**Completed Work:**
- R6 infrastructure with XPtr memory management ✅
- Sound R6 class (partial) ✅
- Pitch R6 class (partial) ✅
- PointProcess R6 class (partial) ✅
- Build system with Praat source ✅
- Error handling framework ✅

**Next Steps:**
1. Begin Week 1 implementation
2. Expand Sound class (+21 methods)
3. Expand Pitch class (+12 methods)
4. Convert Formant to R6 (15 methods)
5. Convert Intensity to R6 (12 methods)
6. Convert Harmonicity to R6 (10 methods)
7. Then implement TextGrid (critical)

## Timeline

- **Weeks 1-2:** Complete foundation objects (6 objects, 107 methods total)
- **Weeks 3-4:** TextGrid implementation (35 methods)
- **Weeks 5-6:** Manipulation + tier objects (30 methods)
- **Weeks 7-8:** Spectral objects (50 methods)
- **Weeks 9-10:** Remaining tier objects (30 methods)
- **Weeks 11-12:** Examples, validation, CRAN prep

**Total:** 12 weeks to complete implementation

## Commits Made

1. **Strategic Amendment Documentation**
   ```
   docs: Strategic amendment to full OOP implementation
   - Analyzed Praat source code architecture
   - Created comprehensive OOP-focused roadmap
   - Updated CLAUDE.md with implementation guidelines
   ```

2. **Implementation Roadmap**
   ```
   docs: Add comprehensive OOP implementation roadmap
   - Created detailed 12-week plan
   - Documented current status and gaps
   - Identified 70+ new methods needed
   ```

## Key Insights

1. **Praat is fundamentally OOP** - 30+ object types, not isolated functions
2. **TextGrid is critical** - Missing this limits 90% of research use cases
3. **Parselmouth got it right** - OOP design is proven successful
4. **Method count matters** - Need 200+ methods for comprehensive coverage
5. **Consistent naming enables easy translation** - Praat scripts → R code

## Conclusion

This strategic amendment transforms the `speaker` package from a limited functional interface into a **comprehensive, object-oriented phonetic analysis toolkit** that:

- Mirrors Praat's native C++ architecture
- Eliminates Python/Parselmouth dependency
- Enables complete research workflows
- Provides clear migration paths
- Prioritizes critical features (TextGrid, Manipulation)

**The package will be the most complete phonetic analysis tool for R, matching Praat desktop and Parselmouth capabilities while leveraging R's statistical ecosystem.**

---

**Status:** Documentation complete, ready to proceed with implementation  
**Next:** Begin Phase 1 - Expand foundation objects
