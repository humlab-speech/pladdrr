# OOP Architecture Summary - 2025-11-12

## Executive Summary

The `speaker` package **successfully implements an object-oriented interface to Praat** that mirrors Praat's C++ architecture. This document confirms the architectural approach and provides a roadmap to completion.

## Current Status (v0.4.0)

### ✅ Successfully Implemented (13 Objects, ~270 Methods)

**Core Analysis Objects**:
- **Sound** (~50 methods) - Audio I/O, generation, all transformations
- **Pitch** (~30 methods) - F0 extraction and analysis
- **Formant** (~20 methods) - Formant tracking
- **Intensity** (~15 methods) - Intensity contours
- **Harmonicity** (~15 methods) - Harmonicity-to-noise ratio

**Spectral Objects**:
- **Spectrogram** (~15 methods) - Time-frequency representation
- **Spectrum** (~18 methods) - FFT analysis
- **Ltas** (~12 methods) - Long-term average spectrum

**Voice Quality & Manipulation**:
- **PointProcess** (~20 methods) - Jitter, shimmer calculations
- **Manipulation** (~12 methods) - PSOLA pitch modification
- **PitchTier** (~12 methods) - Modifiable pitch contour
- **IntensityTier** (~10 methods) - Modifiable intensity
- **DurationTier** (~10 methods) - Duration modification

### 🚧 Partially Complete (1 Object)

- **TextGrid** (28/35 methods, 80%) - Missing: tier management, extract_part()

### ❌ Not Yet Implemented (5 Objects)

- **LPC** - Linear predictive coding (stubbed)
- **FormantPath** - Modern multi-candidate formant tracking
- **FormantGrid** - Modifiable formant contours
- **Matrix** - 2D data operations (low priority)
- **Table** - Praat's data frame (low priority)

## Architectural Principles

### 1. R6 Classes with External Pointers

Objects wrap Praat C++ structs via `Rcpp::XPtr`:

```r
Sound <- R6Class("Sound",
  private = list(ptr = NULL),  # Rcpp::XPtr<structSound>
  public = list(
    to_pitch = function(...) {
      pitch_ptr <- .sound_to_pitch(private$ptr, ...)
      Pitch$new(.xptr = pitch_ptr)
    }
  )
)
```

**Benefits**:
- True object persistence
- Method chaining
- Memory managed by R + C++ finalizers
- Zero-copy operations

### 2. Consistent Naming Conventions

Praat commands map directly to R6 methods:

| Praat | R6 Method | Category |
|-------|-----------|----------|
| `Get duration` | `get_duration()` | Query |
| `To Pitch...` | `to_pitch(...)` | Transform |
| `Extract part...` | `extract_part(...)` | Extract |
| `Scale intensity...` | `scale_intensity(...)` | Modify |
| `Down to Matrix` | `as_matrix()` | Export |

### 3. Direct C++ Praat Integration

No Python layer - direct use of Praat source:

```cpp
#include "fon/Sound.h"

// [[Rcpp::export(.sound_to_pitch)]]
Rcpp::XPtr<structPitch> sound_to_pitch(
    Rcpp::XPtr<structSound> sound,
    double time_step,
    double pitch_floor,
    double pitch_ceiling
) {
    autoPitch pitch = Sound_to_Pitch(
        sound.get(), time_step, pitch_floor, pitch_ceiling
    );
    return create_xptr_from_auto<structPitch>(pitch);
}
```

## Comparison: Parselmouth vs. Speaker

### Parselmouth (Python)
```python
import parselmouth
sound = parselmouth.Sound("file.wav")
pitch = parselmouth.praat.call(sound, "To Pitch", 0.01, 75, 600)
mean_f0 = parselmouth.praat.call(pitch, "Get mean", 0, 0, "Hertz")
```

### Speaker (R)
```r
library(speaker)
sound <- Sound$new("file.wav")
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
mean_f0 <- pitch$get_mean(unit = "hertz")
```

**Advantages of Speaker**:
- ✅ Direct method calls (no `praat.call()`)
- ✅ Method discovery via autocomplete
- ✅ Type safety
- ✅ No Python dependency
- ✅ Native R integration

## Roadmap to v1.0.0 (10 Weeks)

| Week | Phase | Deliverable |
|------|-------|-------------|
| 1 | TextGrid completion | v0.4.1 |
| 2 | LPC implementation | v0.4.2 |
| 3 | FormantPath | v0.4.3 |
| 4 | FormantGrid | v0.4.4 |
| 5-6 | Examples (11 Python→R) | v0.5.0 |
| 7 | Documentation | v0.5.1 |
| 8-9 | Testing & validation | v0.6.0 |
| 10 | CRAN submission | v1.0.0 |

## Key Decisions Documented in CLAUDE.md

1. **Architecture**: R6 + XPtr pattern validated and complete
2. **Integration**: Direct C++ Praat source (no Python)
3. **Naming**: Consistent Praat→R mapping for easy translation
4. **Scope**: 19 core objects covering essential Praat workflows
5. **AV Integration**: Use humlab-speech/av for audio loading
6. **Future Extensions**: Script interpreter and plotting deferred

## Next Steps

### Immediate (Week 1)
1. Complete TextGrid object (7 remaining methods)
2. Comprehensive TextGrid testing with benchmark files
3. TextGrid vignette

### Short Term (Weeks 2-4)
1. Implement LPC fully
2. Add FormantPath and FormantGrid
3. Update documentation

### Medium Term (Weeks 5-7)
1. Re-implement 11 superassp Python examples in R
2. Create migration guide (Parselmouth→Speaker)
3. Complete all vignettes

### Long Term (Weeks 8-10)
1. Comprehensive testing and validation
2. Performance benchmarks
3. CRAN submission

## Success Criteria

### Completeness
- [ ] 19 Praat objects as R6 classes
- [ ] ~390 methods
- [ ] All major Praat workflows supported

### Quality
- [ ] Zero memory leaks (valgrind)
- [ ] >95% test coverage (R), >85% (C++)
- [ ] Performance within 10% of Praat desktop
- [ ] Validated against Praat desktop output

### Documentation
- [ ] 10 comprehensive vignettes
- [ ] Complete reference docs
- [ ] Migration guides (Praat, Parselmouth)
- [ ] 11 example scripts

### Distribution
- [ ] CRAN accepted
- [ ] Package website online
- [ ] DOI via Zenodo
- [ ] JOSS publication

## Conclusion

The speaker package has successfully adopted an object-oriented architecture that:

1. **Mirrors Praat's C++ design** - Objects, not procedures
2. **Enables natural workflows** - Method chaining, object interaction
3. **Provides direct access** - No Python dependency
4. **Maintains compatibility** - Same algorithms, same results
5. **Supports phonetic research** - Complete analysis toolkit

The foundation is solid. The path forward is clear: **complete the remaining objects, validate thoroughly, and submit to CRAN**.

**Current progress: 68% complete (13/19 objects, 270/390 methods)**

**Estimated completion: 10 weeks to v1.0.0**
