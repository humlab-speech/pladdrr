# pladdrr Package Refocus Plan

**Date**: 2025-12-03
**Status**: PowerCepstrogram fix in progress
**Goal**: Make pladdrr a pure low-level Praat C++ binding package

## Package Purpose (Clarified)

**pladdrr** = Low-level R bindings to Praat C++ source code
- Exposes Praat objects (Sound, Pitch, Formant, etc.) as R6 classes
- Direct C++ bindings via Rcpp + external pointers
- Similar to Python's Parselmouth but for R
- NO high-level voice analysis functions

**superassp** = High-level voice analysis package (separate)
- Uses pladdrr for Praat functionality
- Implements AVQI, DSI, tremor, and other clinical metrics
- High-level user-friendly functions

## Current Status

### ✅ Completed (pladdrr core functionality)

Low-level Praat bindings:
- Sound object (read, write, extract, transform)
- Pitch extraction and analysis
- Formant tracking
- Intensity analysis
- Harmonicity (HNR)
- PointProcess (jitter, shimmer, voice report)
- Spectrogram
- Spectrum
- Ltas
- LPC
- TextGrid
- Manipulation (PSOLA)
- Tier objects (PitchTier, IntensityTier, DurationTier, AmplitudeTier)
- FormantGrid
- Electroglottogram
- Matrix operations
- Table operations
- Cochleagram
- Excitation
- Voice Activity Detection

**Total**: ~18 Praat object types with ~300+ methods

### 🚧 In Progress

**PowerCepstrogram fix**:
- ✅ Root cause identified: Missing `Sound_resampleAndOrPreemphasize()` implementation
- ✅ Fix implemented: Added `Sound_extensions.cpp` to build, removed stub
- ✅ Better error reporting added to `powercepstrum_wrappers.cpp`
- ⏳ Build in progress
- ⬜ Testing pending

### ⚠️ To Remove/Relocate

**High-level implementations** (belong in superassp, not pladdrr):
- `R/avqi.R` - AVQI implementation
- `R/dsi.R` - DSI implementation
- `R/tremor.R` - Tremor analysis
- `R/vad.R` - Voice activity detection (if high-level wrapper)
- Associated test files
- Associated documentation

**Action**: Comment out @export tags, add note about superassp migration

## Tasks Required

###  1: PowerCepstrogram Fix ⏳

**Current Status**: Building

**Steps**:
- [x] Identify root cause (Sound_resampleAndOrPreemphasize stubbed)
- [x] Add Sound_extensions.cpp to build
- [x] Remove sound_extensions_stubs.cpp from build
- [x] Improve error reporting
- [ ] Verify build completes
- [ ] Test PowerCepstrogram creation
- [ ] Test CPPS calculation

**Files Modified**:
- `src/Makevars` - Added Sound_extensions.cpp, removed stub
- `src/powercepstrum_wrappers.cpp` - Better error messages

### 2: Unexport High-Level Functions

**Goal**: Mark DSI/AVQI/tremor as test implementations only

**Steps**:
- [ ] Comment out `@export` tags in R/avqi.R
- [ ] Comment out `@export` tags in R/dsi.R
- [ ] Comment out `@export` tags in R/tremor.R
- [ ] Add header comment explaining these are test implementations
- [ ] Add note: "Will be moved to superassp package"
- [ ] Update NAMESPACE (run devtools::document())

**Template header to add**:
```r
# =============================================================================
# NOTE: This is a TEST IMPLEMENTATION for validating pladdrr completeness
# =============================================================================
#
# This code demonstrates that pladdrr exposes all necessary Praat functionality
# to implement [AVQI/DSI/tremor]. It is NOT intended to be part of the pladdrr
# package long-term.
#
# These implementations will be moved to the superassp package, which provides
# high-level voice analysis functions built on pladdrr.
#
# pladdrr = Low-level Praat C++ bindings
# superassp = High-level voice analysis (uses pladdrr)
#
# =============================================================================
```

### 3: Documentation Updates

**README.md**:
- [ ] Clarify package purpose (low-level bindings only)
- [ ] Remove references to AVQI/DSI/tremor as package features
- [ ] Add link to future superassp package
- [ ] Show example of low-level API usage

**DESCRIPTION**:
- [ ] Update Title: "Low-Level R Bindings to Praat C++ Source Code"
- [ ] Update Description to clarify scope
- [ ] Remove mentions of clinical metrics

**Vignettes**:
- [ ] Create "Introduction to pladdrr" showing low-level API
- [ ] Keep technical vignettes about Praat objects
- [ ] Remove or mark as "examples" any high-level analysis vignettes

### 4: Testing Strategy

**Unit tests** (keep these):
- Test each Praat object creation
- Test method calls
- Test error handling
- Test memory management

**Integration tests** (keep as examples):
- AVQI calculation (mark as "example workflow")
- DSI calculation (mark as "example workflow")
- Tremor analysis (mark as "example workflow")
- Keep in `tests/` but clearly marked as validation, not features

### 5: superassp Migration Plan (Future)

When superassp is ready to receive these implementations:

**Move to superassp**:
1. Copy R/avqi.R → superassp/R/avqi.R
2. Copy R/dsi.R → superassp/R/dsi.R
3. Copy R/tremor.R → superassp/R/tremor.R
4. Update superassp DESCRIPTION: `Imports: pladdrr`
5. Test in superassp context

**Remove from pladdrr**:
1. Delete (or move to inst/examples/) R/avqi.R, R/dsi.R, R/tremor.R
2. Delete associated man pages
3. Update NEWS.md documenting the migration

## What pladdrr SHOULD Expose

### Core Praat Objects ✅
- Sound, Pitch, Formant, Intensity, Harmonicity
- Spectrogram, Spectrum, Ltas
- PointProcess, Manipulation
- TextGrid
- Tier objects (PitchTier, etc.)
- PowerCepstrogram ← **FIXING NOW**
- LPC, Electroglottogram
- Matrix, Table

### Utility Functions ✅
- File I/O
- Format conversions
- Data export (as_data_frame, as_matrix)

### What pladdrr should NOT expose
- ❌ AVQI calculation
- ❌ DSI calculation
- ❌ Tremor analysis
- ❌ Any high-level clinical metrics
- ❌ Report generation
- ❌ Plotting functions (beyond maybe examples)

## File Organization

```
pladdrr/
├── R/
│   ├── sound-r6.R              ✅ Keep (Praat binding)
│   ├── pitch-r6.R              ✅ Keep (Praat binding)
│   ├── powercepstrogram-r6.R   ✅ Keep (Praat binding)
│   ├── avqi.R                  ⚠️ Mark as example/test
│   ├── dsi.R                   ⚠️ Mark as example/test
│   └── tremor.R                ⚠️ Mark as example/test
├── src/
│   ├── *_wrappers.cpp          ✅ Keep (C++ bindings)
│   ├── praat.github.io/        ✅ Keep (Praat source)
│   └── *_stubs.cpp             ✅ Keep (necessary stubs)
├── inst/
│   └── examples/               ✅ Good place for AVQI/DSI/tremor
└── tests/
    ├── testthat/
    │   ├── test-sound.R        ✅ Keep (unit tests)
    │   ├── test-avqi.R         ⚠️ Mark as integration example
    │   └── test-dsi.R          ⚠️ Mark as integration example
    └── validation/             ✅ Keep (validates completeness)
```

## Success Criteria

**pladdrr v1.0.8+**:
- [ ] PowerCepstrogram works correctly
- [ ] All Praat object bindings functional
- [ ] No exported high-level clinical functions
- [ ] Clear documentation of package scope
- [ ] Test implementations present but not exported
- [ ] Ready for superassp to use as dependency

**superassp (future)**:
- [ ] AVQI, DSI, tremor exported from superassp
- [ ] Imports pladdrr for Praat functionality
- [ ] High-level user-friendly API
- [ ] Clinical validation and documentation

## Next Immediate Steps

1. ⏳ Complete PowerCepstrogram build
2. ✅ Test PowerCepstrogram + CPPS
3. ⬜ Unexport AVQI/DSI/tremor
4. ⬜ Add clarifying comments
5. ⬜ Update documentation
6. ⬜ Commit changes
7. ⬜ Tag as v1.0.8

## Communication

**README badge** (add after fixing):
```markdown
## Status

✅ **pladdrr**: Low-level Praat bindings - STABLE
🚧 **superassp**: High-level voice analysis - IN DEVELOPMENT

pladdrr provides direct R access to Praat C++ functionality.
For clinical voice metrics (AVQI, DSI, tremor), see superassp (coming soon).
```

---

**Last Updated**: 2025-12-03 08:20 UTC
**Current Phase**: PowerCepstrogram fix, package scope clarification
