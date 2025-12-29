# pladdrr: Efficient Praat Access Strategy

## Executive Summary

This plan outlines how to maximize efficient access to Praat's capabilities from R while faithfully reproducing Praat's output. Based on comprehensive codebase analysis.

**Current State:**
- 23 R6 classes exposing ~320 methods
- 24 C++ wrapper files + 15 SIMD optimizations
- Praat interpreter with script execution support
- 79 Praat fon/ classes available, ~30 wrapped

**Goal:** Expose 100% of Praat's phonetic analysis capabilities with minimal overhead.

---

## Strategy Overview

Three complementary approaches:

| Approach | Coverage | Performance | Effort |
|----------|----------|-------------|--------|
| **A. Interpreter-First** | 100% | Medium | Low |
| **B. Direct Wrappers** | Targeted | Highest | High |
| **C. Hybrid** | 100% + Hot paths | Highest | Medium |

**Recommended: Hybrid approach (C)** - Use interpreter for breadth, wrappers for hot paths.

---

## Part 1: Gap Analysis

### 1.1 Currently Wrapped Praat Objects (23)

| Object | Wrapper | R6 Class | Methods | SIMD |
|--------|---------|----------|---------|------|
| Sound | ✅ | ✅ | 62 | ✅ |
| Pitch | ✅ | ✅ | 29 | ✅ |
| Formant | ✅ | ✅ | 21 | ✅ |
| Intensity | ✅ | ✅ | 15 | ✅ |
| Spectrogram | ✅ | ✅ | 20 | ✅ |
| Spectrum | ✅ | ✅ | 31 | ✅ |
| TextGrid | ✅ | ✅ | 40 | - |
| PointProcess | ✅ | ✅ | 29 | - |
| Harmonicity | ✅ | ✅ | 14 | - |
| LPC | ✅ | ✅ | 19 | ✅ |
| Ltas | ✅ | ✅ | 16 | - |
| Manipulation | ✅ | ✅ | 11 | - |
| Matrix | ✅ | ✅ | 22 | ✅ |
| Table | ✅ | ✅ | 26 | - |
| PitchTier | ✅ | ✅ | 16 | - |
| FormantGrid | ✅ | ✅ | 16 | - |
| IntensityTier | ✅ | ✅ | 12 | - |
| DurationTier | ✅ | ✅ | 10 | - |
| AmplitudeTier | ✅ | ✅ | 14 | - |
| Cochleagram | ✅ | ✅ | 12 | ✅ |
| Excitation | ✅ | ✅ | 10 | ✅ |
| PowerCepstrum | ✅ | ✅ | 30 | - |
| Cepstrum | ✅ | ✅ | 15 | - |

### 1.2 Missing High-Value Praat Objects

**Priority 1 - Core Phonetics:**
| Object | Use Case | Praat Source Available |
|--------|----------|------------------------|
| VocalTract | Articulatory synthesis | ✅ |
| VoiceAnalysis | Complete voice quality metrics | ✅ |
| LongSound | Large file streaming | ✅ |
| FormantTier | Editable formant contours | ✅ |
| Electroglottogram | EGG analysis | ✅ (partial) |

**Priority 2 - Research Workflows:**
| Object | Use Case | Praat Source Available |
|--------|----------|------------------------|
| Distributions | Statistical analysis | ✅ |
| Transition | HMM/Markov chains | ✅ |
| Corpus | Multi-file management | ✅ |
| Categories | Categorical data | ✅ |
| Strings | String arrays | ✅ |

**Priority 3 - Specialized:**
| Object | Use Case | Praat Source Available |
|--------|----------|------------------------|
| ExperimentMFC | Perception experiments | ✅ |
| Photo | Image with sound | ✅ |
| Movie | Video analysis | ✅ |
| SpellingChecker | Dictionary lookup | ✅ |
| FujisakiPitch | Prosody modeling | ✅ |

### 1.3 Missing Commands/Operations

**Sound operations not exposed:**
- `Sound: Filter (one formant)...`
- `Sound: Filter (pre-emphasis)...` with custom frequency
- `Sound: Lengthen (overlap-add)...`
- `Sound: Deepen band modulation...`
- `Sound: Change gender...`
- `Sound: To Harmonics (gne)...`

**Pitch operations:**
- `Pitch: Interpolate`
- `Pitch: Smooth...` (various methods)
- `Pitch: Kill octave jumps`
- `Pitch: Subtract linear fit...`

**Formant operations:**
- `Formant: Track...` (constrained tracking)
- `Formant: Formula (frequencies)...`
- `Formant: Formula (bandwidths)...`

**Voice quality:**
- Complete voice report with all Praat defaults
- Shimmer (ddp), Shimmer (apq11)
- Mean autocorrelation, NHR

---

## Part 2: Interpreter Enhancement Strategy

### 2.1 Current Interpreter Capabilities

```r
# Currently works:
interp <- PraatInterpreter$new()
interp$run('
  Create Sound from formula: "test", 1, 0, 1, 44100, "sin(2*pi*440*x)"
  duration = Get duration
')
value <- interp$get_variable("duration")  # Returns 1.0
```

### 2.2 Missing Interpreter Features

| Feature | Status | Needed For |
|---------|--------|------------|
| Object extraction to R | ❌ | Full workflow |
| Object injection from R | ❌ | Hybrid workflows |
| Script file execution | ✅ | Batch processing |
| Variable access | ✅ | Data extraction |
| Error messages | ✅ | Debugging |
| Editor windows | ❌ N/A | Not needed (CLI) |

### 2.3 Proposed: Object Bridge

Add bidirectional object transfer between interpreter and R:

```cpp
// New functions needed in interpreter_wrappers.cpp:

// Extract Praat object from interpreter → R
// [[Rcpp::export(.praat_interpreter_get_object)]]
SEXP praat_interpreter_get_object(
    XPtr<structInterpreter> interp,
    std::string object_name,
    std::string expected_type
) {
    // Get object from Praat's object list
    // Return as appropriate XPtr type
}

// Inject R object → interpreter
// [[Rcpp::export(.praat_interpreter_set_object)]]
void praat_interpreter_set_object(
    XPtr<structInterpreter> interp,
    std::string object_name,
    SEXP r_object
) {
    // Convert R object to Praat object
    // Add to interpreter's object list
}
```

**R Interface:**
```r
PraatInterpreter <- R6::R6Class(
  public = list(
    # NEW: Extract object from interpreter
    get_object = function(name, type = "auto") {
      ptr <- .praat_interpreter_get_object(private$ptr, name, type)
      # Wrap in appropriate R6 class
      wrap_praat_object(ptr, type)
    },

    # NEW: Inject R object into interpreter
    set_object = function(name, object) {
      stopifnot(inherits(object, "PraatObject"))
      .praat_interpreter_set_object(private$ptr, name, object$ptr)
      invisible(self)
    }
  )
)
```

**Usage:**
```r
# Hybrid workflow: R → Praat script → R
interp <- PraatInterpreter$new()

# Create sound in R
sound <- Sound$create_tone(440, duration = 1.0)

# Send to interpreter
interp$set_object("mySound", sound)

# Run Praat script (can use any command!)
interp$run('
  selectObject: "Sound mySound"
  Filter (one formant): 1000, 100
  Rename: "filtered"
')

# Get result back to R
filtered <- interp$get_object("filtered", "Sound")
```

---

## Part 3: Performance Optimization

### 3.1 Current Overhead Sources

| Source | Impact | Solution |
|--------|--------|----------|
| R6 method dispatch | Medium | Rcpp Modules (2.0 plan) |
| XPtr validation | Low | Cached validation |
| Data copying R↔C++ | High | Zero-copy views |
| Per-call initialization | Low | Already lazy |

### 3.2 Batch Operations (v1.4.3 - DONE)

Already implemented in `batch-ops.R`:
```r
# Single call for multiple operations
results <- batch_pitch_analysis(
  sound,
  methods = c("ac", "cc"),
  time_step = 0.01
)
```

### 3.3 Zero-Copy Data Access

Add memory-mapped views for large data:

```cpp
// New: Return view of Sound samples without copying
// [[Rcpp::export(.sound_samples_view)]]
SEXP sound_samples_view(XPtr<structSound> sound, int channel) {
    // Return external pointer to raw data
    // R code wraps with proper dimensions
    double* data = &sound->z[channel][1];
    int n = sound->nx;

    // Return as external pointer with finalizer
    return Rcpp::XPtr<double>(data, false);  // false = don't delete
}
```

### 3.4 SIMD Expansion

Current: 15 SIMD-optimized modules
Target: Add SIMD for remaining hot paths:

| Operation | Current | SIMD Potential |
|-----------|---------|----------------|
| TextGrid parsing | Scalar | Low (string I/O bound) |
| PointProcess ops | Scalar | Medium |
| Harmonicity | Scalar | High (autocorr) |
| Voice metrics | Scalar | High (jitter/shimmer) |

---

## Part 4: Faithfulness to Praat

### 4.1 Validation Strategy

**Cross-validation test suite:**
```r
# tests/testthat/test-cross-validation.R
test_that("Pitch matches Praat output", {
  sound <- Sound$new("test.wav")

  # R result
  pitch_r <- sound$to_pitch(time_step = 0.01)
  mean_r <- pitch_r$get_mean()

  # Praat script result
  interp <- PraatInterpreter$new()
  interp$run('
    Read from file: "test.wav"
    To Pitch: 0.01, 75, 600
    mean = Get mean: 0, 0, "Hertz"
  ')
  mean_praat <- interp$get_variable("mean")

  # Must match exactly (or within floating point tolerance)
  expect_equal(mean_r, mean_praat, tolerance = 1e-10)
})
```

### 4.2 Known Divergences

| Operation | pladdrr | Praat | Resolution |
|-----------|---------|-------|------------|
| Formant Burg defaults | max_formant=5500 | Context-dependent | Document |
| Pitch path interpolation | Linear | Parabolic | Match Praat |
| Intensity averaging | Energy | Power | Make configurable |

### 4.3 Reference Generation

Script to generate Praat reference values:
```bash
# tests/generate_praat_reference.sh
#!/bin/bash
praat --run tests/generate_reference.praat test_data/ reference_values.json
```

---

## Part 5: Implementation Phases

### Phase 1: Interpreter Object Bridge (HIGH VALUE) ✅ COMPLETED

**Goal:** Enable 100% Praat coverage via scripts with R integration

**Status:** Implemented 2025-12-28

**Implemented:**
1. ✅ `get_object(name, type)` - Extract Praat object from interpreter to R
2. ✅ `get_object_by_id(id)` - Extract by object ID
3. ✅ `set_object(name, object)` - Inject R object into interpreter
4. ✅ `remove_object(name)` / `remove_object_by_id(id)` - Remove objects
5. ✅ `select_object(name, add)` - Select objects in list
6. ✅ `clear_objects()` - Remove all objects
7. ✅ `get_ptr()` added to PraatObject base class
8. ✅ `.wrap_praat_object()` helper for type-safe wrapping
9. ✅ 31 tests covering Sound, Pitch, TextGrid bridge operations

**Files modified:**
- `src/interpreter_wrappers.cpp` - Added 8 new C++ functions (~280 LOC)
- `R/praat-interpreter-r6.R` - Added object bridge methods (~100 LOC)
- `R/praat-object.R` - Added `get_ptr()` method
- `tests/testthat/test-interpreter-bridge.R` - New test file (150 LOC)

### Phase 2: High-Value Missing Wrappers

**Goal:** Direct wrappers for commonly needed objects

**Tasks:**
1. VocalTract wrapper (articulatory synthesis)
2. VoiceAnalysis functions (complete voice report)
3. LongSound wrapper (streaming large files)
4. FormantTier wrapper

**Files to create:**
- `src/vocaltract_wrappers.cpp`
- `src/voiceanalysis_wrappers.cpp`
- `src/longsound_wrappers.cpp`
- `R/vocaltract-r6.R`
- `R/voiceanalysis-r6.R`
- `R/longsound-r6.R`

**Estimated scope:** ~1500 LOC

### Phase 3: Missing Sound/Pitch/Formant Commands

**Goal:** Complete the most-used objects

**Tasks:**
1. Sound: Add remaining filter operations
2. Pitch: Add interpolation, smoothing, octave jump removal
3. Formant: Add tracking, formula application

**Files to modify:**
- `src/sound_wrappers.cpp`
- `src/pitch_wrappers.cpp`
- `src/formant_wrappers.cpp`

**Estimated scope:** ~800 LOC

### Phase 4: Rcpp Modules Migration (2.0) ✅ DONE

**Goal:** 40% code reduction, better type safety

**Completed:**
- Enabled dynamic symbol registration for all 24 Rcpp Module boot functions
- Added `R/zzz.R` with `get_module()` helper for cached module loading
- All modules now loadable via `Rcpp::Module("xxx_module", PACKAGE = "pladdrr")`
- Modules expose C++ classes directly (e.g., RPitch, RSound, RFormant) with lower dispatch overhead

Detailed in existing `.planning/PLADDRR-2.0-RCPP-MODULES-PLAN.md`

### Phase 5: Zero-Copy & SIMD Expansion ✅ DONE

**Goal:** Maximum performance

**Status:** Implemented 2025-12-29

**Completed:**
1. ✅ Zero-copy Sound sample access (`sound_zerocopy.cpp`)
   - `sound_get_sample()`, `sound_set_sample()` - single sample access
   - `sound_get_samples_range()`, `sound_set_samples_range()` - batch access with memcpy
   - `sound_get_values_at_times()` - vectorized interpolated access
   - `sound_get_windows()` - windowed processing for FFT/analysis
   - `sound_info()` - metadata without sample copy
2. ✅ In-place Sound modifications (avoid R copies)
   - `sound_scale_inplace()`, `sound_add_inplace()`
   - `sound_apply_gain_db_inplace()`, `sound_normalize_peak_inplace()`
3. ✅ SIMD jitter/shimmer calculations (`voice_quality_simd.cpp`)
   - `jitter_from_periods_simd()` - local, RAP, PPQ5, DDP metrics
   - `shimmer_from_amplitudes_simd()` - local, dB, APQ3/5/11, DDA metrics
   - `voice_quality_metrics_simd()` - combined batch calculation
4. ✅ SIMD harmonicity computation (already in `autocorrelation_simd.cpp`)

**Files created:**
- `src/sound_zerocopy.cpp` (249 LOC)
- `src/voice_quality_simd.cpp` (296 LOC)

---

## Part 6: Priority Recommendations

### Immediate (This Sprint)

1. **Interpreter Object Bridge** - Unlocks 100% Praat coverage
2. **Cross-validation test suite** - Ensures faithfulness

### Short-term

3. **VoiceAnalysis wrapper** - Most requested feature
4. **Missing Pitch operations** - Interpolate, smooth

### Medium-term

5. **LongSound support** - Large corpus processing
6. **Rcpp Modules (2.0)** - Architecture improvement

### Long-term

7. **Full command parity** - Every Praat menu command accessible
8. **Zero-copy optimization** - Maximum performance

---

## Appendix A: Complete Praat fon/ Object List

Objects in `src/praat/fon/` with wrapper status:

```
✅ = Has direct wrapper
🔄 = Accessible via interpreter
❌ = Not accessible

✅ AmplitudeTier
✅ Cochleagram
✅ DurationTier
✅ Excitation
✅ Formant
✅ FormantGrid
❌ FormantTier (NEEDS WRAPPER)
❌ FujisakiPitch
✅ Harmonicity
✅ Intensity
✅ IntensityTier
❌ LongSound (NEEDS WRAPPER)
✅ Ltas
✅ Manipulation
✅ Matrix
✅ Pitch
✅ PitchTier
✅ PointProcess
✅ PowerCepstrum
✅ Sound
✅ Spectrogram
✅ Spectrum
❌ SpectrumTier
✅ Table
✅ TextGrid
❌ Transition
❌ VocalTract (NEEDS WRAPPER)
🔄 VoiceAnalysis (partial, NEEDS EXPANSION)
❌ WordList
```

---

## Appendix B: Praat Commands by Category

### Sound Menu Commands

| Command | Direct | Interpreter | Priority |
|---------|--------|-------------|----------|
| To Pitch... | ✅ | ✅ | - |
| To Pitch (ac)... | ✅ | ✅ | - |
| To Pitch (cc)... | ✅ | ✅ | - |
| To Formant (burg)... | ✅ | ✅ | - |
| To Formant (keep all)... | ✅ | ✅ | - |
| To Intensity... | ✅ | ✅ | - |
| To Spectrogram... | ✅ | ✅ | - |
| To Spectrum... | ✅ | ✅ | - |
| To Harmonicity (cc)... | ✅ | ✅ | - |
| To Harmonicity (ac)... | ✅ | ✅ | - |
| To Harmonicity (gne)... | ❌ | ✅ | HIGH |
| To LPC... | ✅ | ✅ | - |
| To Cochleagram... | ✅ | ✅ | - |
| Filter (one formant)... | ❌ | ✅ | MEDIUM |
| Filter (pre-emphasis)... | Partial | ✅ | LOW |
| Lengthen (overlap-add)... | ❌ | ✅ | MEDIUM |
| Change gender... | ❌ | ✅ | LOW |

### Voice Analysis Commands

| Command | Direct | Interpreter | Priority |
|---------|--------|-------------|----------|
| Get jitter (local)... | ✅ | ✅ | - |
| Get jitter (rap)... | ✅ | ✅ | - |
| Get shimmer (local)... | ✅ | ✅ | - |
| Voice report... | Partial | ✅ | HIGH |

---

## Appendix C: Performance Benchmarks

Current performance (v1.4.3):

| Operation | Time (1s sound) | vs Praat GUI |
|-----------|-----------------|--------------|
| to_pitch() | 12ms | 0.8x |
| to_formant_burg() | 18ms | 0.9x |
| to_intensity() | 3ms | 1.0x |
| to_spectrogram() | 45ms | 0.95x |
| TextGrid read | 2ms | 0.7x |

**Known Performance Issue (2025-12-28):**
- VUV implementation shows ~18x slowdown vs Parselmouth (Python)
- Root cause: Purely computational overhead, NOT disk I/O
  - R6 class method dispatch
  - R ↔ C data marshalling
  - pladdrr's architecture vs Parselmouth's direct pybind11 bindings
- `to_pitch_cc()` is CPU-bound, not I/O-bound
- **Solution:** Rcpp Modules migration (Phase 4/v2.0) expected to reduce overhead by 20-40%

Target (v2.0):
- 20% improvement via Rcpp Modules
- 2-4x for SIMD-optimized paths
